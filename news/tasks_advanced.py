"""
HaberNexus - Geliştirilmiş Celery Task'ları (v2.0)
Pipeline orchestration, AI content generation, media processing
"""

import json
import logging
import time

import google.generativeai as genai
from celery import chain, shared_task

from news.content_utils import (
    ArticleClassifier,
    AuthorStyleSelector,
    ContentQualityScorer,
    DuplicateDetector,
    PromptGenerator,
    ReadabilityMetrics,
    RSSMediaExtractor,
)
from news.models import Article
from news.models_advanced import ArticleMedia, ArticleSEO
from news.models_extended import ContentGenerationLog

logger = logging.getLogger(__name__)

# Gemini API konfigürasyonu
genai.configure(api_key="GOOGLE_GEMINI_API_KEY")  # .env'den yüklenecek


# ============================================================================
# MAIN PIPELINE TASK
# ============================================================================


@shared_task
def process_article_pipeline(article_data: dict) -> dict:
    """
    Tüm içerik üretim pipeline'ını orchestrate et

    Aşamalar:
    1. Duplicate check
    2. Quality filtering
    3. Classification
    4. Author selection
    5. Content generation
    6. Media processing
    7. Image generation
    8. SEO optimization
    9. Quality assurance
    10. Publishing
    """

    try:
        # Pipeline'ı chain olarak tanımla
        pipeline = chain(
            check_duplicate_task.s(article_data),
            filter_quality_task.s(),
            classify_article_task.s(),
            select_author_style_task.s(),
            generate_content_task.s(),
            process_media_task.s(),
            generate_featured_image_task.s(),
            optimize_seo_task.s(),
            quality_assurance_task.s(),
            publish_article_task.s(),
        )

        # Pipeline'ı çalıştır
        result = pipeline.apply_async()

        logger.info(f"Article pipeline started: {result.id}")
        return {"status": "processing", "task_id": result.id}

    except Exception as e:
        logger.error(f"Pipeline failed: {str(e)}")
        raise


# ============================================================================
# AŞAMA 1: DUPLICATE CHECK
# ============================================================================


@shared_task(bind=True, max_retries=2)
def check_duplicate_task(self, article_data: dict) -> dict:
    """
    Benzer haberler var mı kontrol et
    """
    start_time = time.time()

    try:
        title = article_data.get("title", "")
        category = article_data.get("category", "Diğer")

        # Duplicate kontrol
        is_dup, similar_article = DuplicateDetector().find_similar_articles(title, category, days=7)

        if is_dup:
            logger.warning(f"Duplicate article found: {title}")
            article_data["is_duplicate"] = True
            article_data["duplicate_of"] = similar_article.id if similar_article else None
        else:
            article_data["is_duplicate"] = False

        # Log
        duration = time.time() - start_time
        log_generation_step("duplicate_check", article_data, duration, "completed")

        return article_data

    except Exception as exc:
        logger.error(f"Duplicate check failed: {str(exc)}")
        raise self.retry(exc=exc, countdown=60)


# ============================================================================
# AŞAMA 2: QUALITY FILTERING
# ============================================================================


@shared_task(bind=True, max_retries=2)
def filter_quality_task(self, article_data: dict) -> dict:
    """
    Başlık ve özet kalitesini kontrol et
    """
    start_time = time.time()

    try:
        title = article_data.get("title", "")
        article_data.get("summary", "")

        # Kalite puanı hesapla
        quality_score = ContentQualityScorer.score_headline(title)

        article_data["quality_score"] = quality_score

        # Düşük kaliteli haberleri filtrele
        if quality_score < 40:
            logger.warning(f"Low quality article: {title} (score: {quality_score})")
            article_data["filtered_out"] = True
            article_data["filter_reason"] = "low_quality"
        else:
            article_data["filtered_out"] = False

        # Log
        duration = time.time() - start_time
        log_generation_step("quality_filter", article_data, duration, "completed")

        return article_data

    except Exception as exc:
        logger.error(f"Quality filtering failed: {str(exc)}")
        raise self.retry(exc=exc, countdown=60)


# ============================================================================
# AŞAMA 3: CLASSIFICATION
# ============================================================================


@shared_task(bind=True, max_retries=2)
def classify_article_task(self, article_data: dict) -> dict:
    """
    Makaleyi kategori ve alt kategoriye sınıflandır
    """
    start_time = time.time()

    try:
        title = article_data.get("title", "")
        summary = article_data.get("summary", "")

        # Sınıflandır
        classification = ArticleClassifier.classify_article(title, summary)

        article_data.update(classification)

        logger.info(f"Article classified: {title} -> {classification['category']}")

        # Log
        duration = time.time() - start_time
        log_generation_step("classification", article_data, duration, "completed")

        return article_data

    except Exception as exc:
        logger.error(f"Classification failed: {str(exc)}")
        raise self.retry(exc=exc, countdown=60)


# ============================================================================
# AŞAMA 4: AUTHOR & STYLE SELECTION
# ============================================================================


@shared_task(bind=True, max_retries=2)
def select_author_style_task(self, article_data: dict) -> dict:
    """
    Kategori ve önem seviyesine göre yazar seç
    """
    start_time = time.time()

    try:
        category = article_data.get("category", "Diğer")
        importance_level = article_data.get("importance_level", 1)

        # Yazar ve stil seç
        author, style = AuthorStyleSelector.select_author_and_style(category, importance_level)

        article_data["author_id"] = author.id
        article_data["author_name"] = author.name
        article_data["style"] = style

        logger.info(f"Author selected: {author.name} for {category}")

        # Log
        duration = time.time() - start_time
        log_generation_step("author_selection", article_data, duration, "completed")

        return article_data

    except Exception as exc:
        logger.error(f"Author selection failed: {str(exc)}")
        raise self.retry(exc=exc, countdown=60)


# ============================================================================
# AŞAMA 5: CONTENT GENERATION
# ============================================================================


@shared_task(bind=True, max_retries=3, time_limit=900)  # 15 dakika timeout
def generate_content_task(self, article_data: dict) -> dict:
    """
    Gemini API'yi kullanarak haber yazısı üret
    """
    start_time = time.time()

    try:
        from authors.models import Author

        # Yazar bilgisini al
        author = Author.objects.get(id=article_data["author_id"])
        style = article_data["style"]

        # Prompt oluştur
        prompt = PromptGenerator.generate_content_prompt(article_data, author, style)

        # Model seç
        importance_level = article_data.get("importance_level", 1)
        model = "gemini-3-pro" if importance_level >= 4 else "gemini-2.5-flash"

        # İçerik üret
        client = genai.Client()
        response = client.models.generate_content(
            model=model,
            contents=prompt,
            generation_config=genai.types.GenerationConfig(
                temperature=0.7,
                top_p=0.95,
                top_k=40,
                max_output_tokens=2000,
            ),
        )

        content = response.text

        # Kalite kontrol
        metrics = ReadabilityMetrics.calculate_content_metrics(content)
        quality_score = min(100, metrics["word_count"] / 10)  # Basit kalite puanı

        article_data["content"] = content
        article_data["content_quality_score"] = quality_score
        article_data["readability_metrics"] = metrics
        article_data["model_used"] = model

        logger.info(f"Content generated: {article_data['title'][:50]} (quality: {quality_score})")

        # Log
        duration = time.time() - start_time
        log_generation_step("content_generation", article_data, duration, "completed")

        return article_data

    except Exception as exc:
        logger.error(f"Content generation failed: {str(exc)}")
        raise self.retry(exc=exc, countdown=120)


# ============================================================================
# AŞAMA 6: MEDIA PROCESSING
# ============================================================================


@shared_task(bind=True, max_retries=2)
def process_media_task(self, article_data: dict) -> dict:
    """
    RSS kaynağından medya çıkar ve işle
    """
    start_time = time.time()

    try:
        source_url = article_data.get("source_url", "")
        article_url = article_data.get("link", "")

        # RSS'den medya çıkar
        media = RSSMediaExtractor.extract_media_from_rss(source_url, article_url)

        article_data["rss_media"] = media

        logger.info(f"Media extracted: {len(media['images'])} images, {len(media['videos'])} videos")

        # Log
        duration = time.time() - start_time
        log_generation_step("media_processing", article_data, duration, "completed")

        return article_data

    except Exception as exc:
        logger.error(f"Media processing failed: {str(exc)}")
        # Medya işleme başarısız olsa da devam et
        article_data["rss_media"] = {"images": [], "videos": [], "audio": []}
        return article_data


# ============================================================================
# AŞAMA 7: IMAGE GENERATION
# ============================================================================


@shared_task(bind=True, max_retries=2, time_limit=300)  # 5 dakika timeout
def generate_featured_image_task(self, article_data: dict) -> dict:
    """
    Haber başlığı için görsel üret (Imagen 3)
    """
    start_time = time.time()

    try:
        title = article_data.get("title", "")
        category = article_data.get("category", "Diğer")

        # Prompt oluştur
        PromptGenerator.generate_image_prompt(title, category)

        # Imagen 3 ile görsel üret
        genai.Client()

        # Imagen 3 API çağrısı (placeholder - gerçek implementasyon gerekli)
        # response = client.models.generate_images(
        #     model="imagen-3-generate-001",
        #     prompt=image_prompt,
        #     number_of_images=1,
        #     size="1920x1080"
        # )

        # Şimdilik placeholder
        article_data["featured_image_generated"] = True
        article_data["featured_image_url"] = None  # Gerçek URL'ye güncellenecek

        logger.info(f"Featured image generation started: {title[:50]}")

        # Log
        duration = time.time() - start_time
        log_generation_step("image_generation", article_data, duration, "completed")

        return article_data

    except Exception as exc:
        logger.error(f"Image generation failed: {str(exc)}")
        # Görsel üretimi başarısız olsa da devam et
        article_data["featured_image_generated"] = False
        return article_data


# ============================================================================
# AŞAMA 8: SEO OPTIMIZATION
# ============================================================================


@shared_task(bind=True, max_retries=2)
def optimize_seo_task(self, article_data: dict) -> dict:
    """
    SEO optimizasyonu yap
    """
    start_time = time.time()

    try:
        title = article_data.get("title", "")
        article_data.get("content", "")
        category = article_data.get("category", "")

        # Meta description oluştur
        summary = article_data.get("summary", "")
        meta_description = summary[:160] if summary else title[:160]

        # Meta keywords oluştur
        keywords = [category]
        if article_data.get("subcategory"):
            keywords.append(article_data["subcategory"])
        meta_keywords = ", ".join(keywords)

        # Open Graph tags
        og_title = title[:95]
        og_description = summary[:200] if summary else title[:200]

        article_data["seo"] = {
            "meta_description": meta_description,
            "meta_keywords": meta_keywords,
            "og_title": og_title,
            "og_description": og_description,
            "canonical_url": article_data.get("link", ""),
        }

        logger.info(f"SEO optimization completed: {title[:50]}")

        # Log
        duration = time.time() - start_time
        log_generation_step("seo_optimization", article_data, duration, "completed")

        return article_data

    except Exception as exc:
        logger.error(f"SEO optimization failed: {str(exc)}")
        raise self.retry(exc=exc, countdown=60)


# ============================================================================
# AŞAMA 9: QUALITY ASSURANCE
# ============================================================================


@shared_task(bind=True, max_retries=2)
def quality_assurance_task(self, article_data: dict) -> dict:
    """
    Kalite kontrol ve validasyon
    """
    start_time = time.time()

    try:
        content = article_data.get("content", "")

        # Kalite metrikleri hesapla
        metrics = ReadabilityMetrics.calculate_content_metrics(content)

        # Kalite puanı hesapla
        quality_score = 0

        # Uzunluk kontrolü
        if 400 <= metrics["word_count"] <= 1000:
            quality_score += 25

        # Okunabilirlik
        lix = metrics["lix_index"]
        if 20 <= lix <= 50:
            quality_score += 25

        # Yapı kontrolü
        if "<h2>" in content and "<p>" in content:
            quality_score += 25

        # Anahtar kelimeler
        if content.count("<strong>") >= 3:
            quality_score += 25

        article_data["qa_quality_score"] = min(100, quality_score)

        # Eğer kalite puanı düşükse, manual review'e gönder
        if quality_score < 60:
            article_data["requires_manual_review"] = True
            logger.warning(f"Article requires manual review: {article_data['title'][:50]} (QA score: {quality_score})")
        else:
            article_data["requires_manual_review"] = False

        # Log
        duration = time.time() - start_time
        log_generation_step("quality_assurance", article_data, duration, "completed")

        return article_data

    except Exception as exc:
        logger.error(f"Quality assurance failed: {str(exc)}")
        raise self.retry(exc=exc, countdown=60)


# ============================================================================
# AŞAMA 10: PUBLISHING
# ============================================================================


@shared_task(bind=True, max_retries=2)
def publish_article_task(self, article_data: dict) -> dict:
    """
    Makaleyi veritabanına kaydet ve yayınla
    """
    start_time = time.time()

    try:
        from authors.models import Author

        # Makale oluştur
        author = Author.objects.get(id=article_data["author_id"])

        article = Article.objects.create(
            title=article_data["title"],
            slug=article_data["title"][:50].lower().replace(" ", "-"),
            content=article_data["content"],
            excerpt=article_data.get("summary", ""),
            author=author,
            category=article_data["category"],
            rss_source_id=article_data.get("rss_source_id"),
            original_url=article_data.get("link", ""),
            status="published",
            is_ai_generated=True,
        )

        # SEO kaydet
        seo_data = article_data.get("seo", {})
        ArticleSEO.objects.create(
            article=article,
            meta_description=seo_data.get("meta_description", ""),
            meta_keywords=seo_data.get("meta_keywords", ""),
            og_title=seo_data.get("og_title", ""),
            og_description=seo_data.get("og_description", ""),
            canonical_url=seo_data.get("canonical_url", ""),
        )

        # Medya kaydet (varsa)
        if article_data.get("featured_image_generated"):
            ArticleMedia.objects.create(
                article=article, featured_image_alt=article_data["title"], image_processing_status="completed"
            )

        article_data["article_id"] = article.id
        article_data["published"] = True

        logger.info(f"Article published: {article.title} (ID: {article.id})")

        # Log
        duration = time.time() - start_time
        log_generation_step("publishing", article_data, duration, "completed")

        return article_data

    except Exception as exc:
        logger.error(f"Publishing failed: {str(exc)}")
        raise self.retry(exc=exc, countdown=60)


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================


def log_generation_step(step: str, article_data: dict, duration: float, status: str):
    """
    İçerik üretim aşamasını log'a kaydet
    """
    try:
        # Makale ID'si varsa log'u kaydet
        if "article_id" in article_data:
            ContentGenerationLog.objects.create(
                article_id=article_data["article_id"],
                step=step,
                status=status,
                duration=duration,
                input_data=json.dumps(article_data, default=str)[:1000],
                model_used=article_data.get("model_used", ""),
            )
    except Exception as e:
        logger.error(f"Failed to log generation step: {str(e)}")
