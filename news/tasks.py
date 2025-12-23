"""
HaberNexus v10.4 - News Tasks
Celery tasks for RSS fetching, AI content generation, and image generation.
Updated to use the new Google Gen AI SDK with proper ThinkingConfig support.
- Gemini 2.5 series: Uses thinkingBudget (integer)
- Gemini 3 series: Uses thinkingLevel (string: "low" or "high")

Author: Salih TANRISEVEN
Updated: December 2025
"""

import logging
import time
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


# =============================================================================
# Configuration Helpers
# =============================================================================


def get_genai_client():
    """
    Google Gen AI SDK client oluştur.
    Yeni SDK kullanımı: google-genai

    Returns:
        genai.Client: Yapılandırılmış Google Gen AI client

    Raises:
        ValueError: API anahtarı bulunamadığında veya boş olduğunda
    """
    try:
        api_key_setting = Setting.objects.get(key="GOOGLE_GEMINI_API_KEY")
        api_key = api_key_setting.value
    except Setting.DoesNotExist as err:
        raise ValueError("Google Gemini API anahtarı bulunamadı. Admin panelinden ayarlayın.") from err

    if not api_key:
        raise ValueError("Google Gemini API anahtarı boş. Admin panelinden ayarlayın.")

    from google import genai

    return genai.Client(api_key=api_key)


def get_ai_model_name() -> str:
    """
    AI model adını ayarlardan al.

    Returns:
        str: Model adı (varsayılan: gemini-2.5-flash)
    """
    try:
        ai_model_setting = Setting.objects.get(key="AI_MODEL")
        return ai_model_setting.value
    except Setting.DoesNotExist:
        return "gemini-2.5-flash"


def get_image_model_name() -> str:
    """
    Image model adını ayarlardan al.

    Returns:
        str: Image model adı (varsayılan: imagen-4.0-generate-001)
    """
    try:
        image_model_setting = Setting.objects.get(key="IMAGE_MODEL")
        return image_model_setting.value
    except Setting.DoesNotExist:
        return "imagen-4.0-generate-001"


def get_thinking_level() -> str | None:
    """
    Thinking level değerini ayarlardan al.
    Gemini 3 modelleri için: "low" veya "high" değerleri desteklenir.
    Gemini 2.5 modelleri için thinkingLevel desteklenmez, thinkingBudget kullanılmalı.

    Returns:
        Optional[str]: Thinking level (varsayılan: None - model varsayılanı)
    """
    try:
        thinking_setting = Setting.objects.get(key="AI_THINKING_LEVEL")
        level = thinking_setting.value.lower().strip()
        # Gemini 3 için sadece "low" ve "high" geçerli
        if level in ("low", "high"):
            return level
        # Eski değerleri yeni değerlere dönüştür (geriye uyumluluk)
        legacy_map = {
            "minimal": "low",
            "medium": "high",
        }
        return legacy_map.get(level)
    except Setting.DoesNotExist:
        return None  # Varsayılan: model kendi varsayılanını kullanır


def get_thinking_budget() -> int:
    """
    Thinking budget değerini ayarlardan al.
    0 = thinking devre dışı, pozitif değer = thinking aktif

    Returns:
        int: Thinking budget (varsayılan: 0 - devre dışı)
    """
    try:
        thinking_setting = Setting.objects.get(key="AI_THINKING_BUDGET")
        return int(thinking_setting.value)
    except (Setting.DoesNotExist, ValueError):
        return 0  # Varsayılan: thinking devre dışı (hız için)


def create_thinking_config():
    """
    ThinkingConfig oluştur.

    Google Gen AI SDK Aralık 2025 güncellemesi:
    - Gemini 2.5 serisi: thinkingBudget kullanır (integer)
      - 0: Thinking devre dışı
      - -1: Dinamik thinking (model karar verir)
      - Pozitif değer: Manuel budget (örn: 1024, 2048)
    - Gemini 3 serisi: thinkingLevel kullanır (string)
      - "low": Düşük reasoning
      - "high": Yüksek reasoning (varsayılan)
      - Gemini 3 Pro için thinking devre dışı bırakılamaz

    Returns:
        ThinkingConfig: Thinking yapılandırması
    """
    from google.genai import types

    model_name = get_ai_model_name().lower()
    thinking_level = get_thinking_level()
    thinking_budget = get_thinking_budget()

    # Gemini 3 modelleri için thinkingLevel kullan
    if "gemini-3" in model_name:
        if thinking_level:
            return types.ThinkingConfig(thinking_level=thinking_level)
        # Gemini 3 için varsayılan: high
        return types.ThinkingConfig(thinking_level="high")

    # Gemini 2.5 ve diğer modeller için thinkingBudget kullan
    # -1: Dinamik thinking (model karar verir)
    # 0: Thinking devre dışı
    # Pozitif: Manuel budget
    if thinking_budget == -1:
        return types.ThinkingConfig(thinking_budget=-1)  # Dinamik
    elif thinking_budget > 0:
        return types.ThinkingConfig(thinking_budget=thinking_budget)
    else:
        return types.ThinkingConfig(thinking_budget=0)  # Devre dışı


# =============================================================================
# Retry Helper with Exponential Backoff
# =============================================================================


def retry_with_backoff(func, max_retries: int = 3, initial_delay: float = 1.0, max_delay: float = 60.0):
    """
    Exponential backoff ile retry mekanizması.

    Args:
        func: Çalıştırılacak fonksiyon
        max_retries: Maksimum deneme sayısı
        initial_delay: İlk bekleme süresi (saniye)
        max_delay: Maksimum bekleme süresi (saniye)

    Returns:
        Fonksiyon sonucu

    Raises:
        Exception: Tüm denemeler başarısız olduğunda
    """
    last_exception = None
    delay = initial_delay

    for attempt in range(max_retries):
        try:
            return func()
        except Exception as e:
            last_exception = e
            if attempt < max_retries - 1:
                logger.warning(f"Attempt {attempt + 1} failed: {e!s}. Retrying in {delay}s...")
                time.sleep(delay)
                delay = min(delay * 2, max_delay)
            else:
                logger.error(f"All {max_retries} attempts failed. Last error: {e!s}")

    raise last_exception


# =============================================================================
# RSS Feed Tasks
# =============================================================================


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={"max_retries": 3, "countdown": 60},
    retry_backoff=True,
    retry_backoff_max=300,
)
def fetch_rss_feeds(self):
    """
    Tüm aktif RSS kaynaklarını tara ve yeni haberleri veritabanına ekle.
    Her 15 dakikada bir çalışacak.

    Returns:
        str: İşlem sonucu mesajı
    """
    try:
        active_sources = RssSource.objects.filter(is_active=True)
        total_fetched = 0
        failed_sources = []

        for source in active_sources:
            try:
                fetched = fetch_single_rss(source)
                total_fetched += fetched
            except Exception as e:
                failed_sources.append(source.name)
                log_error(
                    "fetch_rss_feeds",
                    f"RSS kaynağı taranırken hata: {source.name}",
                    traceback=str(e),
                    related_id=source.id,
                )

        result_msg = f"Başarılı: {total_fetched} haber eklendi"
        if failed_sources:
            result_msg += f" | Başarısız kaynaklar: {', '.join(failed_sources)}"

        log_info("fetch_rss_feeds", result_msg)
        return result_msg

    except Exception as e:
        log_error("fetch_rss_feeds", f"RSS tarama görevinde kritik hata: {e!s}", traceback=str(e))
        raise


def fetch_single_rss(source: RssSource) -> int:
    """
    Tek bir RSS kaynağını tara ve yeni haberleri ekle.

    Args:
        source: RSS kaynağı

    Returns:
        int: Eklenen haber sayısı

    Raises:
        Exception: RSS tarama hatası
    """
    try:
        feed = feedparser.parse(source.url)
        fetched_count = 0

        if feed.bozo:
            logger.warning(f"RSS feed parsing hatası: {source.url} - {feed.bozo_exception}")

        for entry in feed.entries[:10]:  # Son 10 haberi al
            # Haber zaten var mı kontrol et
            if Article.objects.filter(original_url=entry.link).exists():
                continue

            # Yeni makale oluştur
            title = entry.get("title", "Başlıksız")
            content = entry.get("summary", entry.get("description", ""))

            # Slug benzersizliğini sağla
            base_slug = slugify(title)[:50]
            slug = base_slug
            counter = 1
            while Article.objects.filter(slug=slug).exists():
                slug = f"{base_slug[:45]}-{counter}"
                counter += 1

            article = Article.objects.create(
                title=title,
                slug=slug,
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
                    logger.warning(f"Görsel indirme hatası: {e!s}")

            fetched_count += 1

            # AI ile içerik üretimini tetikle (transaction commit olduktan sonra)
            transaction.on_commit(lambda article_id=article.id: generate_ai_content.delay(article_id))

        # Son tarama zamanını güncelle
        source.last_checked = timezone.now()
        source.save()

        return fetched_count

    except Exception as e:
        raise Exception(f"RSS tarama hatası ({source.name}): {e!s}") from e


def download_article_image(article: Article, image_url: str) -> None:
    """
    Haber için görseli indir ve optimize et.

    Args:
        article: Haber makalesi
        image_url: Görsel URL'i

    Raises:
        Exception: Görsel işleme hatası
    """
    try:
        response = requests.get(
            image_url,
            timeout=15,
            headers={"User-Agent": "HaberNexus/10.3 (News Aggregator)"},
        )
        response.raise_for_status()

        # Görseli aç ve optimize et
        img = Image.open(BytesIO(response.content))

        # RGB'ye dönüştür (RGBA veya P modundaysa)
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")

        # WebP formatına dönüştür
        webp_buffer = BytesIO()
        img.save(webp_buffer, format="WebP", quality=85, optimize=True)
        webp_buffer.seek(0)

        # Dosyayı kaydet
        filename = f"{article.slug}.webp"
        article.featured_image.save(filename, webp_buffer, save=True)
        article.featured_image_alt = article.title
        article.save()

    except requests.RequestException as e:
        logger.error(f"Görsel indirme hatası: {e!s}")
        raise
    except Exception as e:
        logger.error(f"Görsel işleme hatası: {e!s}")
        raise


# =============================================================================
# AI Content Generation Tasks
# =============================================================================


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={"max_retries": 3, "countdown": 10},
    retry_backoff=True,
    retry_backoff_max=600,
    retry_jitter=True,
)
def generate_ai_content(self, article_id: int) -> str:
    """
    Yapay zeka kullanarak haber içeriğini oluştur.
    RSS'den çekilen ham veriyi profesyonel bir metne dönüştür.

    Yeni Google Gen AI SDK kullanılıyor.
    Idempotent: Bu task birden fazla çalıştırılsa bile aynı sonucu verir.
    Retry stratejisi: API hataları durumunda otomatik yeniden deneme.

    Args:
        article_id: Makale ID'si

    Returns:
        str: İşlem sonucu mesajı
    """
    try:
        article = Article.objects.get(id=article_id)

        # Idempotency kontrolü: Eğer makale zaten AI tarafından üretilmişse, tekrar işleme
        if article.is_ai_generated and article.status == "published":
            log_info(
                "generate_ai_content",
                f"Makale zaten AI tarafından üretilmiş: {article.title}",
                related_id=article_id,
            )
            return f"Makale zaten işlenmiş: {article.title}"

        # Rastgele bir yazar seç
        authors = Author.objects.filter(is_active=True)
        if not authors.exists():
            log_error("generate_ai_content", "Aktif yazar bulunamadı", related_id=article_id)
            return "Hata: Aktif yazar bulunamadı"

        import random

        author = random.choice(list(authors))
        article.author = author

        try:
            # Yeni Google Gen AI SDK kullanımı
            from google.genai import types

            client = get_genai_client()
            model_name = get_ai_model_name()

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

            # Config oluştur - ThinkingConfig ile
            thinking_config = create_thinking_config()

            config_params = {
                "temperature": 0.7,
                "top_p": 0.95,
                "top_k": 40,
                "max_output_tokens": 2048,
            }

            # Thinking config ekle (varsa)
            if thinking_config:
                config_params["thinking_config"] = thinking_config

            # Yeni SDK ile içerik üretimi (retry ile)
            def generate_content():
                return client.models.generate_content(
                    model=model_name,
                    contents=prompt,
                    config=types.GenerateContentConfig(**config_params),
                )

            response = retry_with_backoff(generate_content, max_retries=3)

            if response and response.text:
                article.content = response.text
                article.is_ai_generated = True
                article.status = "published"
                article.published_at = timezone.now()
                article.save()

                log_info(
                    "generate_ai_content",
                    f"Haber başarıyla oluşturuldu: {article.title}",
                    related_id=article_id,
                )

                # Görsel üretimini tetikle (transaction commit olduktan sonra)
                transaction.on_commit(lambda: generate_article_image.delay(article_id))

                return f"Başarılı: {article.title}"
            else:
                log_error("generate_ai_content", "AI yanıt boş", related_id=article_id)
                return "Hata: AI yanıt boş"

        except ImportError as e:
            log_error(
                "generate_ai_content",
                f"Google Gen AI SDK import hatası: {e!s}",
                traceback=str(e),
                related_id=article_id,
            )
            raise
        except Exception as e:
            log_error(
                "generate_ai_content",
                f"Google AI API hatası: {e!s}",
                traceback=str(e),
                related_id=article_id,
            )
            raise

    except Article.DoesNotExist:
        log_error("generate_ai_content", f"Makale bulunamadı (ID: {article_id})", related_id=article_id)
        return f"Hata: Makale bulunamadı (ID: {article_id})"
    except Exception as e:
        log_error("generate_ai_content", f"Kritik hata: {e!s}", traceback=str(e), related_id=article_id)
        raise


# =============================================================================
# Video Processing Tasks
# =============================================================================


@shared_task(queue="video_processing")
def process_video_content(article_id: int, video_url: str) -> str:
    """
    Video içeriğini işle ve optimize et.
    Bu görev 'video_processing' kuyruğunda çalışır ve aynı anda sadece bir tane çalışır.

    Args:
        article_id: Makale ID'si
        video_url: Video URL'i

    Returns:
        str: İşlem sonucu mesajı
    """
    try:
        article = Article.objects.get(id=article_id)

        # Video indirme ve işleme (ffmpeg ile)
        # Bu kısım daha sonra detaylı olarak geliştirilecek

        log_info("process_video_content", f"Video işleme başladı: {article.title}", related_id=article_id)

        return f"Video işleme tamamlandı: {article.title}"

    except Article.DoesNotExist:
        log_error("process_video_content", f"Makale bulunamadı (ID: {article_id})", related_id=article_id)
        return f"Hata: Makale bulunamadı (ID: {article_id})"
    except Exception as e:
        log_error("process_video_content", f"Video işleme hatası: {e!s}", traceback=str(e), related_id=article_id)
        return f"Hata: {e!s}"


# =============================================================================
# Image Generation Tasks
# =============================================================================


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={"max_retries": 3, "countdown": 10},
    retry_backoff=True,
)
def generate_article_image(self, article_id: int) -> str:
    """
    Haber için AI ile profesyonel görsel oluştur (Imagen 4).
    Yeni Google Gen AI SDK kullanılıyor.

    Args:
        article_id: Makale ID'si

    Returns:
        str: İşlem sonucu mesajı
    """
    try:
        article = Article.objects.get(id=article_id)

        # Eğer görsel zaten varsa, tekrar üretme
        if article.featured_image:
            log_info(
                "generate_article_image",
                f"Makale zaten görsele sahip: {article.title}",
                related_id=article_id,
            )
            return f"Görsel zaten mevcut: {article.title}"

        try:
            from google.genai import types

            client = get_genai_client()
            image_model_name = get_image_model_name()

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

            # Yeni SDK ile görsel üretimi (retry ile)
            def generate_image():
                return client.models.generate_images(
                    model=image_model_name,
                    prompt=image_prompt,
                    config=types.GenerateImagesConfig(
                        number_of_images=1,
                        aspect_ratio="16:9",
                        output_mime_type="image/jpeg",
                    ),
                )

            response = retry_with_backoff(generate_image, max_retries=3)

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
                article.is_ai_image = True
                article.save()

                log_info(
                    "generate_article_image",
                    f"Görsel başarıyla oluşturuldu: {article.title}",
                    related_id=article_id,
                )
                return f"Görsel oluşturuldu: {article.title}"
            else:
                log_error("generate_article_image", "Imagen API yanıt boş", related_id=article_id)
                return "Hata: Imagen API yanıt boş"

        except ImportError as e:
            log_error(
                "generate_article_image",
                f"Google Gen AI SDK import hatası: {e!s}",
                traceback=str(e),
                related_id=article_id,
            )
            return "Hata: SDK import hatası"
        except Exception as e:
            log_error(
                "generate_article_image",
                f"Imagen API hatası: {e!s}",
                traceback=str(e),
                related_id=article_id,
            )
            # Görsel üretilemezse, RSS'den gelen görseli kullan (varsa)
            return f"Görsel üretilemedi, RSS görseli kullanılıyor: {article.title}"

    except Article.DoesNotExist:
        log_error("generate_article_image", f"Makale bulunamadı (ID: {article_id})", related_id=article_id)
        return f"Hata: Makale bulunamadı (ID: {article_id})"
    except Exception as e:
        log_error("generate_article_image", f"Kritik hata: {e!s}", traceback=str(e), related_id=article_id)
        return f"Hata: {e!s}"


# =============================================================================
# Batch Processing Tasks
# =============================================================================


@shared_task(bind=True)
def batch_regenerate_content(self, article_ids: list) -> str:
    """
    Birden fazla makale için toplu içerik yeniden üretimi.

    Args:
        article_ids: Makale ID listesi

    Returns:
        str: İşlem sonucu mesajı
    """
    success_count = 0
    failed_count = 0

    for article_id in article_ids:
        try:
            # Her makale için içerik üretimini tetikle
            generate_ai_content.delay(article_id)
            success_count += 1
        except Exception as e:
            failed_count += 1
            log_error(
                "batch_regenerate_content",
                f"Makale için görev oluşturulamadı (ID: {article_id}): {e!s}",
                related_id=article_id,
            )

    result_msg = f"Toplu işlem başlatıldı: {success_count} başarılı, {failed_count} başarısız"
    log_info("batch_regenerate_content", result_msg)
    return result_msg


@shared_task(bind=True)
def cleanup_draft_articles(self, days_old: int = 7) -> str:
    """
    Belirli bir süreden eski taslak makaleleri temizle.

    Args:
        days_old: Kaç günden eski taslaklar silinecek

    Returns:
        str: İşlem sonucu mesajı
    """
    from datetime import timedelta

    cutoff_date = timezone.now() - timedelta(days=days_old)

    old_drafts = Article.objects.filter(status="draft", created_at__lt=cutoff_date)
    count = old_drafts.count()

    if count > 0:
        old_drafts.delete()
        log_info("cleanup_draft_articles", f"{count} eski taslak makale silindi")
        return f"{count} eski taslak makale silindi"

    return "Silinecek eski taslak makale bulunamadı"
