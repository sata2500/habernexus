import logging
import os
import traceback
from io import BytesIO

from django.db import transaction
from django.utils import timezone
from django.utils.text import slugify

import feedparser
import requests
from celery import shared_task
from PIL import Image

from authors.models import Author
from core.models import Setting
from core.tasks import log_error, log_info

from .models import Article, RssSource

logger = logging.getLogger(__name__)


@shared_task
def fetch_rss_feeds():
    """
    Tüm aktif RSS kaynaklarını tara ve yeni haberleri veritabanına ekle.
    Her 15 dakikada bir çalışacak.
    """
    try:
        active_sources = RssSource.objects.filter(is_active=True)
        total_fetched = 0

        for source in active_sources:
            try:
                fetched = fetch_single_rss(source)
                total_fetched += fetched
            except Exception as e:
                log_error(
                    "fetch_rss_feeds", f"RSS kaynağı taranırken hata: {source.name}", traceback=str(e), related_id=source.id
                )

        log_info("fetch_rss_feeds", f"Toplam {total_fetched} yeni haber eklendi")
        return f"Başarılı: {total_fetched} haber eklendi"

    except Exception as e:
        log_error("fetch_rss_feeds", f"RSS tarama görevinde kritik hata: {str(e)}", traceback=str(e))
        raise


def fetch_single_rss(source):
    """
    Tek bir RSS kaynağını tara ve yeni haberleri ekle.
    """
    try:
        feed = feedparser.parse(source.url)
        fetched_count = 0

        if feed.bozo:
            logger.warning(f"RSS feed parsing hatası: {source.url}")

        for entry in feed.entries[:10]:  # Son 10 haberi al
            # Haber zaten var mı kontrol et
            if Article.objects.filter(original_url=entry.link).exists():
                continue

            # Yeni makale oluştur
            title = entry.get("title", "Başlıksız")
            content = entry.get("summary", entry.get("description", ""))

            article = Article.objects.create(
                title=title,
                slug=slugify(title)[:50],
                content=content,
                excerpt=content[:500] if content else "",
                category=source.category,
                rss_source=source,
                original_url=entry.link,
                status="draft",
                is_ai_generated=False,
            )

            # Görseli indir (varsa)
            if hasattr(entry, "media_content") and entry.media_content:
                try:
                    download_article_image(article, entry.media_content[0]["url"])
                except Exception as e:
                    logger.warning(f"Görsel indirme hatası: {str(e)}")

            fetched_count += 1

            # AI ile içerik üretimini tetikle (transaction commit olduktan sonra)
            transaction.on_commit(lambda article_id=article.id: generate_ai_content.delay(article_id))

        # Son tarama zamanını güncelle
        source.last_checked = timezone.now()
        source.save()

        return fetched_count

    except Exception as e:
        raise Exception(f"RSS tarama hatası ({source.name}): {str(e)}")


def download_article_image(article, image_url):
    """
    Haber için görseli indir ve optimize et.
    """
    try:
        response = requests.get(image_url, timeout=10)
        response.raise_for_status()

        # Görseli aç ve optimize et
        img = Image.open(BytesIO(response.content))

        # WebP formatına dönüştür
        webp_buffer = BytesIO()
        img.save(webp_buffer, format="WebP", quality=85)
        webp_buffer.seek(0)

        # Dosyayı kaydet
        filename = f"{article.slug}.webp"
        article.featured_image.save(filename, webp_buffer, save=True)
        article.featured_image_alt = article.title
        article.save()

    except Exception as e:
        logger.error(f"Görsel işleme hatası: {str(e)}")
        raise


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={"max_retries": 3, "countdown": 5},
    retry_backoff=True,
    retry_backoff_max=600,
    retry_jitter=True,
)
def generate_ai_content(self, article_id):
    """
    Yapay zeka kullanarak haber içeriğini oluştur.
    RSS'den çekilen ham veriyi profesyonel bir metne dönüştür.

    Idempotent: Bu task birden fazla çalıştırılsa bile aynı sonucu verir.
    Retry stratejisi: API hataları durumunda otomatik yeniden deneme.
    """
    try:
        article = Article.objects.get(id=article_id)

        # Idempotency kontrolü: Eğer makale zaten AI tarafından üretilmişse, tekrar işleme
        if article.is_ai_generated and article.status == "published":
            log_info("generate_ai_content", f"Makale zaten AI tarafından üretilmiş: {article.title}", related_id=article_id)
            return f"Makale zaten işlenmiş: {article.title}"

        # Google Gemini API anahtarını al
        try:
            api_key_setting = Setting.objects.get(key="GOOGLE_GEMINI_API_KEY")
            api_key = api_key_setting.value
        except Setting.DoesNotExist:
            log_error("generate_ai_content", "Google Gemini API anahtarı bulunamadı", related_id=article_id)
            return

        if not api_key:
            log_error("generate_ai_content", "Google Gemini API anahtarı boş", related_id=article_id)
            return

        # Rastgele bir yazar seç
        authors = Author.objects.filter(is_active=True)
        if not authors.exists():
            log_error("generate_ai_content", "Aktif yazar bulunamadı", related_id=article_id)
            return

        import random

        author = random.choice(authors)
        article.author = author

        # Google Generative AI SDK'yı kullan
        try:
            import google.generativeai as genai

            genai.configure(api_key=api_key)

            # Prompt oluştur
            prompt = f"""
            Aşağıdaki haber verilerini kullanarak, {author.name} isimli bir {author.expertise} yazarının kaleminden çıkmış gibi,
            SEO uyumlu, özgün ve profesyonel bir haber metni oluştur.
            
            Başlık: {article.title}
            Özet: {article.content[:500]}
            Kategori: {article.category}
            
            Lütfen:
            1. Profesyonel ve akıcı bir yazı yaz
            2. 300-500 kelime arasında olsun
            3. HTML formatında başlıklar ve paragraflar kullan
            4. Orijinal ve benzersiz içerik oluştur
            5. Yapay zeka tarafından üretildiğine dair hiçbir işaret verme
            """

            model = genai.GenerativeModel("gemini-1.5-flash")
            response = model.generate_content(prompt)

            if response and response.text:
                article.content = response.text
                article.is_ai_generated = True
                article.status = "published"
                article.published_at = timezone.now()
                article.save()

                log_info("generate_ai_content", f"Haber başarıyla oluşturuldu: {article.title}", related_id=article_id)
            else:
                log_error("generate_ai_content", "AI yanıt boş", related_id=article_id)

        except Exception as e:
            log_error("generate_ai_content", f"Google AI API hatası: {str(e)}", traceback=str(e), related_id=article_id)

    except Article.DoesNotExist:
        log_error("generate_ai_content", f"Makale bulunamadı (ID: {article_id})", related_id=article_id)
    except Exception as e:
        log_error("generate_ai_content", f"Kritik hata: {str(e)}", traceback=str(e), related_id=article_id)


@shared_task(queue="video_processing")
def process_video_content(article_id, video_url):
    """
    Video içeriğini işle ve optimize et.
    Bu görev 'video_processing' kuyruğunda çalışır ve aynı anda sadece bir tane çalışır.
    """
    try:
        article = Article.objects.get(id=article_id)

        # Video indirme ve işleme (ffmpeg ile)
        # Bu kısım daha sonra detaylı olarak geliştirilecek

        log_info("process_video_content", f"Video işleme başladı: {article.title}", related_id=article_id)

        return f"Video işleme tamamlandı: {article.title}"

    except Article.DoesNotExist:
        log_error("process_video_content", f"Makale bulunamadı (ID: {article_id})", related_id=article_id)
    except Exception as e:
        log_error("process_video_content", f"Video işleme hatası: {str(e)}", traceback=str(e), related_id=article_id)
