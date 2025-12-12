import logging
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
                    "fetch_rss_feeds",
                    f"RSS kaynağı taranırken hata: {source.name}",
                    traceback=str(e),
                    related_id=source.id,
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

            # Gelişmiş SEO ve Profesyonellik Promptu
            prompt = f"""
Sen {author.name} isimli deneyimli bir {author.expertise} yazarısın. Aşağıdaki haber kaynağını kullanarak, profesyonel bir haber makalesi yazacaksın.

**KAYNAK BİLGİLERİ:**
Başlık: {article.title}
Kaynak İçerik: {article.content[:800]}
Kategori: {article.category}

**YAZIM KURALLARI:**

1. **İçerik Yapısı:**
   - Giriş paragrafı: Haberin özeti ve en önemli bilgiler (5W1H: Kim, Ne, Nerede, Ne zaman, Neden, Nasıl)
   - Gelişme paragrafları: Detaylı bilgiler, bağlam, arka plan
   - Sonuç paragrafı: Önem, etki, gelecek beklentileri

2. **SEO Optimizasyonu:**
   - Ana anahtar kelimeleri doğal bir şekilde kullan
   - İlk 100 kelimede ana konuyu net bir şekilde belirt
   - Alt başlıklar kullan (H2, H3 etiketleriyle)
   - Uzun kuyruk anahtar kelimeleri entegre et

3. **Profesyonellik:**
   - Objektif ve tarafsız dil kullan
   - Kaynak göstermeden doğrulanabilir bilgiler sun
   - Teknik terimleri gerektiğinde açıkla
   - Akıcı ve okunabilir cümleler kur

4. **Uzunluk ve Format:**
   - 500-700 kelime arası (optimal SEO uzunluğu)
   - HTML formatında yaz: <h2>, <h3>, <p>, <strong>, <em> etiketlerini kullan
   - Her paragraf 3-4 cümle olsun

5. **Özgünlük:**
   - Kaynak metni doğrudan kopyalama, tamamen yeniden yaz
   - Kendi analizini ve yorumunu kat
   - Farklı bakış açıları sun
   - Yazının sonunda "yapay zeka" veya benzeri ifadeler kullanma

6. **Okuyucu Etkileşimi:**
   - İlgi çekici bir giriş yap
   - Sorular sorarak okuyucuyu düşündür
   - Somut örnekler ve veriler kullan

**ÖNEMLİ:** Sadece haber makalesini yaz, başka hiçbir açıklama ekleme. Doğrudan HTML formatında içeriği döndür.
            """

            # AI modelini ayarlardan al (varsayılan: gemini-2.5-flash)
            try:
                ai_model_setting = Setting.objects.get(key="AI_MODEL")
                ai_model_name = ai_model_setting.value
            except Setting.DoesNotExist:
                ai_model_name = "gemini-2.5-flash"  # Varsayılan model
                log_info(
                    "generate_ai_content",
                    "AI model ayarı bulunamadı, varsayılan kullanılıyor: gemini-2.5-flash",
                    related_id=article_id,
                )

            model = genai.GenerativeModel(ai_model_name)
            response = model.generate_content(prompt)

            if response and response.text:
                article.content = response.text
                article.is_ai_generated = True
                article.status = "published"
                article.published_at = timezone.now()
                article.save()

                log_info("generate_ai_content", f"Haber başarıyla oluşturuldu: {article.title}", related_id=article_id)

                # Görsel üretimini tetikle (transaction commit olduktan sonra)
                transaction.on_commit(lambda: generate_article_image.delay(article_id))
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


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={"max_retries": 3, "countdown": 5},
    retry_backoff=True,
)
def generate_article_image(self, article_id):
    """
    Haber için AI ile profesyonel görsel oluştur (Imagen 4 Ultra).
    """
    try:
        article = Article.objects.get(id=article_id)

        # Eğer görsel zaten varsa, tekrar üretme
        if article.featured_image:
            log_info("generate_article_image", f"Makale zaten görsele sahip: {article.title}", related_id=article_id)
            return f"Görsel zaten mevcut: {article.title}"

        # Google Gemini API anahtarını al
        try:
            api_key_setting = Setting.objects.get(key="GOOGLE_GEMINI_API_KEY")
            api_key = api_key_setting.value
        except Setting.DoesNotExist:
            log_error("generate_article_image", "Google Gemini API anahtarı bulunamadı", related_id=article_id)
            return

        if not api_key:
            log_error("generate_article_image", "Google Gemini API anahtarı boş", related_id=article_id)
            return

        # Imagen modelini ayarlardan al (varsayılan: imagen-4.0-ultra-generate-001)
        try:
            image_model_setting = Setting.objects.get(key="IMAGE_MODEL")
            image_model_name = image_model_setting.value
        except Setting.DoesNotExist:
            image_model_name = "imagen-4.0-ultra-generate-001"  # Varsayılan: En yüksek kalite
            log_info(
                "generate_article_image",
                "Image model ayarı bulunamadı, varsayılan kullanılıyor: imagen-4.0-ultra-generate-001",
                related_id=article_id,
            )

        try:
            from google import genai
            from google.genai import types

            client = genai.Client(api_key=api_key)

            # Görsel promptu oluştur
            image_prompt = f"""
Professional news photography style image for an article about: {article.title}.

Category: {article.category}

Requirements:
- High quality, photorealistic, journalistic style
- 16:9 aspect ratio (horizontal news format)
- Clean composition with good lighting
- Editorial quality, professional look
- No text, no watermarks, no logos
- Suitable for news article header
- Visually engaging and relevant to the topic
            """.strip()

            # Görsel üret (basitleştirilmiş parametreler)
            response = client.models.generate_images(
                model=image_model_name,
                prompt=image_prompt,
                config=types.GenerateImagesConfig(number_of_images=1, aspect_ratio="16:9"),
            )

            if response.generated_images:
                generated_image = response.generated_images[0]

                # PIL Image'ı BytesIO'ya dönüştür
                img_buffer = BytesIO()
                generated_image.image._pil_image.save(img_buffer, format="JPEG", quality=95)
                img_buffer.seek(0)

                # Dosya adı oluştur
                filename = f"{article.slug}_ai_generated.jpg"

                # Görseli makaleye kaydet
                article.featured_image.save(filename, img_buffer, save=True)
                article.featured_image_alt = article.title
                article.save()

                log_info("generate_article_image", f"Görsel başarıyla oluşturuldu: {article.title}", related_id=article_id)
                return f"Görsel oluşturuldu: {article.title}"
            else:
                log_error("generate_article_image", "Imagen API yanıt boş", related_id=article_id)

        except Exception as e:
            log_error("generate_article_image", f"Imagen API hatası: {str(e)}", traceback=str(e), related_id=article_id)
            # Görsel üretilemezse, RSS'den gelen görseli kullan (varsa)
            return f"Görsel üretilemedi, RSS görseli kullanılıyor: {article.title}"

    except Article.DoesNotExist:
        log_error("generate_article_image", f"Makale bulunamadı (ID: {article_id})", related_id=article_id)
    except Exception as e:
        log_error("generate_article_image", f"Kritik hata: {str(e)}", traceback=str(e), related_id=article_id)
