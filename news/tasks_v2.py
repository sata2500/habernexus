"""
Geliştirilmiş İçerik Üretim Sistemi - Yeni Görevler
Başlık puanlaması, sınıflandırma ve kalite kontrolü
"""

import logging
import time
import re
from datetime import timedelta
from io import BytesIO

from django.db import transaction
from django.utils import timezone
from django.utils.text import slugify

import feedparser
import requests
from celery import shared_task, group, chord
from PIL import Image

from authors.models import Author
from core.models import Setting
from core.tasks import log_error, log_info

from .models import Article, RssSource
from .models_extended import (
    HeadlineScore,
    ArticleClassification,
    ContentQualityMetrics,
    ResearchSource,
    ContentGenerationLog,
)

logger = logging.getLogger(__name__)


# ============================================================================
# AŞAMA 1: RSS TARAMA VE BAŞLIK PUANLAMASI
# ============================================================================

@shared_task
def fetch_rss_feeds_v2():
    """
    Tüm aktif RSS kaynaklarını tara ve başlıkları puanla.
    Her 15 dakikada bir çalışacak.
    """
    try:
        active_sources = RssSource.objects.filter(is_active=True)
        total_headlines = 0

        for source in active_sources:
            try:
                fetched = fetch_single_rss_v2(source)
                total_headlines += fetched
            except Exception as e:
                log_error(
                    "fetch_rss_feeds_v2",
                    f"RSS kaynağı taranırken hata: {source.name}",
                    traceback=str(e),
                    related_id=source.id,
                )

        log_info("fetch_rss_feeds_v2", f"Toplam {total_headlines} başlık puanlandı")

        # Başlık puanlamasını tetikle
        transaction.on_commit(lambda: score_headlines.delay())

        return f"Başarılı: {total_headlines} başlık işlendi"

    except Exception as e:
        log_error("fetch_rss_feeds_v2", f"RSS tarama görevinde kritik hata: {str(e)}", traceback=str(e))
        raise


def fetch_single_rss_v2(source):
    """
    Tek bir RSS kaynağını tara ve başlıkları kaydet.
    """
    try:
        feed = feedparser.parse(source.url)
        fetched_count = 0

        if feed.bozo:
            logger.warning(f"RSS feed parsing hatası: {source.url}")

        for entry in feed.entries[:20]:  # Son 20 haberi al
            # Başlık zaten var mı kontrol et
            if HeadlineScore.objects.filter(
                rss_source=source,
                original_headline=entry.get("title", "")
            ).exists():
                continue

            title = entry.get("title", "Başlıksız")

            # Başlık puanı oluştur (başlangıçta 0, score_headlines'da hesaplanacak)
            headline_score = HeadlineScore.objects.create(
                rss_source=source,
                original_headline=title,
                overall_score=0,
                word_count=len(title.split()),
                character_count=len(title),
                is_processed=False,
            )

            fetched_count += 1

        # Son tarama zamanını güncelle
        source.last_checked = timezone.now()
        source.save()

        return fetched_count

    except Exception as e:
        raise Exception(f"RSS tarama hatası ({source.name}): {str(e)}")


# ============================================================================
# AŞAMA 2: BAŞLIK PUANLAMASI
# ============================================================================

@shared_task
def score_headlines():
    """
    Son 2 saatte çekilen işlenmemiş başlıkları puanla.
    Hedef: En iyi 10 başlığı seç.
    """
    try:
        # Son 2 saatte çekilen işlenmemiş başlıkları al
        two_hours_ago = timezone.now() - timedelta(hours=2)
        unscored_headlines = HeadlineScore.objects.filter(
            is_processed=False,
            created_at__gte=two_hours_ago
        ).select_related('rss_source')

        logger.info(f"Puanlanacak başlık sayısı: {unscored_headlines.count()}")

        for headline in unscored_headlines:
            try:
                score_single_headline(headline)
            except Exception as e:
                logger.error(f"Başlık puanlaması hatası: {str(e)}")

        # En iyi 10 başlığı seç ve sınıflandırmaya gönder
        top_headlines = HeadlineScore.objects.filter(
            is_processed=False
        ).order_by('-overall_score')[:10]

        if top_headlines.exists():
            headline_ids = [h.id for h in top_headlines]
            log_info("score_headlines", f"Top 10 başlık seçildi: {len(headline_ids)}")

            # Sınıflandırma görevini tetikle
            transaction.on_commit(lambda: classify_headlines.delay(headline_ids))

        return f"Başarılı: {unscored_headlines.count()} başlık puanlandı"

    except Exception as e:
        log_error("score_headlines", f"Başlık puanlaması görevinde hata: {str(e)}", traceback=str(e))
        raise


def score_single_headline(headline_score):
    """
    Tek bir başlığı puanla.
    Puanlama bileşenleri:
    - Orijinallik (duplicate check)
    - Anahtar kelime uygunluğu
    - Engagement potansiyeli
    - Uzunluk ve yapı
    """
    title = headline_score.original_headline

    # 1. Orijinallik Puanı (0-30)
    uniqueness = calculate_uniqueness_score(headline_score)

    # 2. Engagement Puanı (0-30)
    engagement = calculate_engagement_score(title)

    # 3. Anahtar Kelime Puanı (0-20)
    keyword_relevance = calculate_keyword_relevance(title, headline_score.rss_source.category)

    # 4. Yapı Puanı (0-20)
    structure = calculate_structure_score(title)

    # Genel Puan
    overall_score = uniqueness + engagement + keyword_relevance + structure

    # Başlık özelliklerini kaydet
    headline_score.uniqueness_score = uniqueness
    headline_score.engagement_score = engagement
    headline_score.keyword_relevance = keyword_relevance
    headline_score.overall_score = overall_score
    headline_score.has_numbers = bool(re.search(r'\d+', title))
    headline_score.has_power_words = has_power_words(title)
    headline_score.is_question = title.strip().endswith('?')
    headline_score.is_listicle = bool(re.search(r'^\d+\s', title))

    headline_score.save()

    logger.info(f"Başlık puanlandı: {title[:50]} - Puan: {overall_score:.1f}")


def calculate_uniqueness_score(headline_score):
    """
    Başlığın orijinalliğini puanla.
    Aynı veya benzer başlıklar varsa puan düş.
    """
    # Aynı başlık sayısı
    same_count = HeadlineScore.objects.filter(
        original_headline=headline_score.original_headline
    ).count()

    # Benzer başlık sayısı (ilk 30 karakter aynı)
    similar_count = HeadlineScore.objects.filter(
        original_headline__startswith=headline_score.original_headline[:30]
    ).count()

    if same_count > 1:
        return 0  # Tam aynı başlık
    elif similar_count > 2:
        return 10  # Benzer başlıklar var
    else:
        return 30  # Orijinal


def calculate_engagement_score(title):
    """
    Başlığın katılım potansiyelini puanla.
    """
    score = 0

    # Uzunluk kontrolü (optimal: 50-70 karakter)
    if 50 <= len(title) <= 70:
        score += 10
    elif 40 <= len(title) <= 80:
        score += 5

    # Sayı varlığı (listicle potansiyeli)
    if re.search(r'\d+', title):
        score += 8

    # Güçlü kelimeler
    power_words_list = [
        'nasıl', 'neden', 'ne zaman', 'en iyi', 'harika', 'şaşırtıcı',
        'hızlı', 'kolay', 'basit', 'yeni', 'devrim', 'sır', 'ipucu'
    ]
    if any(word in title.lower() for word in power_words_list):
        score += 7

    # Soru işareti
    if title.endswith('?'):
        score += 5

    return min(score, 30)


def calculate_keyword_relevance(title, category):
    """
    Başlığın kategori ile uygunluğunu puanla.
    """
    category_keywords = {
        'Teknoloji': ['teknoloji', 'yazılım', 'yapay zeka', 'app', 'web', 'veri', 'siber'],
        'Spor': ['spor', 'futbol', 'basketbol', 'tenis', 'maç', 'takım', 'oyuncu'],
        'Siyaset': ['siyaset', 'hükümet', 'seçim', 'kanun', 'parlamento', 'başkan'],
        'Ekonomi': ['ekonomi', 'finans', 'pazar', 'yatırım', 'borsa', 'dolar', 'enflasyon'],
        'Sağlık': ['sağlık', 'tıp', 'doktor', 'hastalık', 'ilaç', 'tedavi', 'hastane'],
    }

    keywords = category_keywords.get(category, [])
    title_lower = title.lower()

    matching_keywords = sum(1 for kw in keywords if kw in title_lower)

    if matching_keywords >= 2:
        return 20
    elif matching_keywords == 1:
        return 15
    else:
        return 5


def calculate_structure_score(title):
    """
    Başlığın yapısını puanla.
    """
    score = 0

    # Kelime sayısı (optimal: 5-12 kelime)
    word_count = len(title.split())
    if 5 <= word_count <= 12:
        score += 10
    elif 4 <= word_count <= 15:
        score += 5

    # Büyük harf kullanımı (başlık kurallarına uygunluk)
    if title[0].isupper():
        score += 5

    # Noktalama işareti (uygun kullanım)
    if title.count('!') <= 1 and title.count('?') <= 1:
        score += 5

    return min(score, 20)


def has_power_words(title):
    """
    Başlıkta güçlü kelimeler var mı kontrol et.
    """
    power_words_list = [
        'nasıl', 'neden', 'ne zaman', 'en iyi', 'harika', 'şaşırtıcı',
        'hızlı', 'kolay', 'basit', 'yeni', 'devrim', 'sır', 'ipucu',
        'önemli', 'kritik', 'acil', 'başarı', 'kazanç', 'kaybetme'
    ]
    return any(word in title.lower() for word in power_words_list)


# ============================================================================
# AŞAMA 3: BAŞLIK SINIFLAMA VE MAKALE OLUŞTURMA
# ============================================================================

@shared_task
def classify_headlines(headline_ids):
    """
    Başlıkları sınıflandır ve makale oluştur.
    """
    try:
        headlines = HeadlineScore.objects.filter(id__in=headline_ids)

        # Paralel olarak sınıflandırma yap
        classification_tasks = group(
            classify_and_create_article.s(headline.id) for headline in headlines
        )

        result = classification_tasks.apply_async()

        log_info("classify_headlines", f"{len(headline_ids)} başlık sınıflandırıldı")
        return f"Başarılı: {len(headline_ids)} başlık sınıflandırıldı"

    except Exception as e:
        log_error("classify_headlines", f"Sınıflandırma görevinde hata: {str(e)}", traceback=str(e))
        raise


@shared_task
def classify_and_create_article(headline_id):
    """
    Tek bir başlığı sınıflandır ve makale oluştur.
    """
    try:
        headline = HeadlineScore.objects.get(id=headline_id)

        # Başlığı sınıflandır (Gemini kullanarak)
        classification_data = classify_headline_with_ai(headline)

        # Makale oluştur
        article = Article.objects.create(
            title=headline.original_headline,
            slug=slugify(headline.original_headline)[:50],
            content="",  # İçerik daha sonra üretilecek
            excerpt="",
            category=classification_data['primary_category'],
            rss_source=headline.rss_source,
            status='draft',
            is_ai_generated=False,
        )

        # Sınıflandırma bilgilerini kaydet
        ArticleClassification.objects.create(
            article=article,
            article_type=classification_data['article_type'],
            type_confidence=classification_data['confidence'],
            primary_category=classification_data['primary_category'],
            secondary_categories=','.join(classification_data.get('secondary_categories', [])),
            research_depth=classification_data.get('research_depth', 1),
            recommended_ai_model=classification_data.get('ai_model', 'gemini-2.5-flash'),
            is_time_sensitive=classification_data.get('is_time_sensitive', False),
            is_controversial=classification_data.get('is_controversial', False),
            tone=classification_data.get('tone', 'neutral'),
        )

        # Başlık işlendi olarak işaretle
        headline.is_processed = True
        headline.article = article
        headline.save()

        log_info("classify_and_create_article", f"Makale oluşturuldu: {article.title}", related_id=article.id)

        # İçerik üretimini tetikle
        transaction.on_commit(lambda: generate_ai_content_v2.delay(article.id))

        return f"Makale oluşturuldu: {article.title}"

    except Exception as e:
        log_error("classify_and_create_article", f"Makale oluşturma hatası: {str(e)}", traceback=str(e))
        raise


def classify_headline_with_ai(headline):
    """
    Başlığı Gemini API kullanarak sınıflandır.
    """
    try:
        api_key_setting = Setting.objects.get(key="GOOGLE_GEMINI_API_KEY")
        api_key = api_key_setting.value
    except Setting.DoesNotExist:
        return get_default_classification()

    if not api_key:
        return get_default_classification()

    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-2.5-flash')

        prompt = f"""
Aşağıdaki haber başlığını analiz et ve sınıflandır:

Başlık: {headline.original_headline}
Kategori: {headline.rss_source.category}

Lütfen aşağıdaki bilgileri JSON formatında döndür:
{{
    "article_type": "news|analysis|feature|opinion|tutorial|interview|breaking",
    "confidence": 0.0-1.0,
    "primary_category": "kategori adı",
    "secondary_categories": ["kategori1", "kategori2"],
    "research_depth": 0|1|2,
    "ai_model": "gemini-2.5-flash|gemini-2.5-pro",
    "is_time_sensitive": true|false,
    "is_controversial": true|false,
    "tone": "formal|casual|technical|emotional|neutral",
    "summary": "kısa açıklama"
}}

Sadece JSON'u döndür, başka hiçbir şey ekleme.
        """

        response = model.generate_content(prompt)

        if response and response.text:
            import json
            try:
                data = json.loads(response.text)
                return data
            except json.JSONDecodeError:
                return get_default_classification()

    except Exception as e:
        logger.error(f"AI sınıflandırma hatası: {str(e)}")

    return get_default_classification()


def get_default_classification():
    """
    Varsayılan sınıflandırma bilgileri.
    """
    return {
        'article_type': 'news',
        'confidence': 0.5,
        'primary_category': 'Genel Haberler',
        'secondary_categories': [],
        'research_depth': 1,
        'ai_model': 'gemini-2.5-flash',
        'is_time_sensitive': False,
        'is_controversial': False,
        'tone': 'neutral',
    }


# ============================================================================
# AŞAMA 4: İÇERİK ÜRETIMI (Geliştirilmiş)
# ============================================================================

@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={"max_retries": 3, "countdown": 5},
    retry_backoff=True,
    retry_backoff_max=600,
    retry_jitter=True,
)
def generate_ai_content_v2(self, article_id):
    """
    Geliştirilmiş içerik üretimi.
    """
    start_time = time.time()

    try:
        article = Article.objects.get(id=article_id)
        classification = article.classification

        # Üretim logunu başlat
        log_entry = ContentGenerationLog.objects.create(
            article=article,
            stage='generate',
            status='started',
            input_data={'article_id': article_id}
        )

        # Araştırma verilerini al (varsa)
        research_data = get_research_data(article)

        # Dinamik prompt oluştur
        prompt = create_dynamic_prompt(article, classification, research_data)

        # AI modeli seç
        ai_model = classification.recommended_ai_model if classification else 'gemini-2.5-flash'

        # İçerik üret
        content = generate_content_with_gemini(article, prompt, ai_model)

        if content:
            # İçeriği kaydet
            article.content = content
            article.is_ai_generated = True
            article.status = 'published'
            article.published_at = timezone.now()
            article.save()

            # Kalite metrikleri hesapla
            calculate_quality_metrics(article)

            # Logu güncelle
            duration = int((time.time() - start_time) * 1000)
            log_entry.status = 'completed'
            log_entry.duration = duration
            log_entry.output_data = {'content_length': len(content)}
            log_entry.ai_model_used = ai_model
            log_entry.save()

            log_info("generate_ai_content_v2", f"İçerik başarıyla oluşturuldu: {article.title}", related_id=article_id)

            # Görsel üretimini tetikle
            transaction.on_commit(lambda: generate_article_image_v2.delay(article_id))
        else:
            log_entry.status = 'failed'
            log_entry.error_message = 'AI yanıt boş'
            log_entry.save()
            log_error("generate_ai_content_v2", "AI yanıt boş", related_id=article_id)

    except Article.DoesNotExist:
        log_error("generate_ai_content_v2", f"Makale bulunamadı (ID: {article_id})", related_id=article_id)
    except Exception as e:
        log_error("generate_ai_content_v2", f"İçerik üretim hatası: {str(e)}", traceback=str(e), related_id=article_id)
        raise


def get_research_data(article):
    """
    Makale için araştırma verilerini al.
    """
    # Şimdilik boş dict döndür, daha sonra araştırma sistemi eklenecek
    return {}


def create_dynamic_prompt(article, classification, research_data):
    """
    Makale türüne göre dinamik prompt oluştur.
    """
    article_type = classification.article_type if classification else 'news'

    # Tür bazlı prompt şablonları
    prompts = {
        'news': create_news_prompt,
        'analysis': create_analysis_prompt,
        'feature': create_feature_prompt,
        'opinion': create_opinion_prompt,
        'tutorial': create_tutorial_prompt,
    }

    prompt_func = prompts.get(article_type, create_news_prompt)
    return prompt_func(article, classification, research_data)


def create_news_prompt(article, classification, research_data):
    """
    Haber türü için prompt.
    """
    return f"""
Sen profesyonel bir haber yazarısın. Aşağıdaki başlık için hızlı, güncel ve doğru bir haber yazacaksın.

Başlık: {article.title}
Kategori: {article.category}

YAZIM KURALLARI:
1. Giriş: 5W1H (Kim, Ne, Nerede, Ne zaman, Neden, Nasıl) kuralına uy
2. Uzunluk: 400-600 kelime
3. Format: HTML (h2, h3, p, strong, em etiketleri)
4. Stil: Objektif, tarafsız, profesyonel
5. SEO: Ana anahtar kelimeleri doğal olarak kullan

Sadece HTML formatında haber içeriğini yaz.
    """


def create_analysis_prompt(article, classification, research_data):
    """
    Analiz türü için prompt.
    """
    return f"""
Sen deneyimli bir analist yazarısın. Aşağıdaki başlık hakkında derinlemesine bir analiz yazacaksın.

Başlık: {article.title}
Kategori: {article.category}

YAZIM KURALLARI:
1. Giriş: Konunun önemini vurgula
2. Arka Plan: Tarihçe ve bağlam
3. Analiz: Farklı bakış açıları
4. Sonuç: Etki ve çıkarımlar
5. Uzunluk: 600-800 kelime
6. Format: HTML (h2, h3, p, strong, em etiketleri)

Sadece HTML formatında analiz yazacaksın.
    """


def create_feature_prompt(article, classification, research_data):
    """
    Röportaj türü için prompt.
    """
    return f"""
Sen yaratıcı bir röportaj yazarısın. Aşağıdaki başlık için ilgi çekici bir röportaj yazacaksın.

Başlık: {article.title}
Kategori: {article.category}

YAZIM KURALLARI:
1. Giriş: Hikaye anlatıcı tarzı
2. Detaylar: Somut örnekler ve tanıklamalar
3. Derinlik: İnsan yönü vurgula
4. Sonuç: Etkileyici kapanış
5. Uzunluk: 700-900 kelime
6. Format: HTML (h2, h3, p, strong, em etiketleri)

Sadece HTML formatında röportajı yazacaksın.
    """


def create_opinion_prompt(article, classification, research_data):
    """
    Köşe yazısı türü için prompt.
    """
    return f"""
Sen deneyimli bir köşe yazarısın. Aşağıdaki başlık hakkında düşünceli bir köşe yazısı yazacaksın.

Başlık: {article.title}
Kategori: {article.category}

YAZIM KURALLARI:
1. Giriş: Güçlü bir açıklama
2. Argümanlar: Mantıksal ve ikna edici
3. Karşı Görüşler: Adil bir şekilde ele al
4. Sonuç: Çağrı hareketi
5. Uzunluk: 500-700 kelime
6. Format: HTML (h2, h3, p, strong, em etiketleri)
7. Ton: Taraflı ama saygılı

Sadece HTML formatında köşe yazısını yazacaksın.
    """


def create_tutorial_prompt(article, classification, research_data):
    """
    Rehber türü için prompt.
    """
    return f"""
Sen faydalı bir rehber yazarısın. Aşağıdaki başlık için adım adım bir rehber yazacaksın.

Başlık: {article.title}
Kategori: {article.category}

YAZIM KURALLARI:
1. Giriş: Rehberin faydalarını açıkla
2. Adımlar: Numaralı, net ve açık
3. Örnekler: Her adım için pratik örnek
4. İpuçları: Faydalı tavsiyeler
5. Sonuç: Özet ve sonraki adımlar
6. Uzunluk: 500-800 kelime
7. Format: HTML (h2, h3, p, strong, em, ol, li etiketleri)

Sadece HTML formatında rehberi yazacaksın.
    """


def generate_content_with_gemini(article, prompt, ai_model):
    """
    Gemini API kullanarak içerik üret.
    """
    try:
        api_key_setting = Setting.objects.get(key="GOOGLE_GEMINI_API_KEY")
        api_key = api_key_setting.value
    except Setting.DoesNotExist:
        return None

    if not api_key:
        return None

    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel(ai_model)

        response = model.generate_content(prompt)

        if response and response.text:
            return response.text

    except Exception as e:
        logger.error(f"Gemini API hatası: {str(e)}")

    return None


def calculate_quality_metrics(article):
    """
    Makale için kalite metriklerini hesapla.
    """
    from .quality_utils import calculate_readability, calculate_seo_metrics, calculate_structure_metrics

    try:
        content = article.content

        # Okunabilirlik metrikleri
        readability = calculate_readability(content)

        # SEO metrikleri
        seo = calculate_seo_metrics(article.title, content, article.category)

        # Yapı metrikleri
        structure = calculate_structure_metrics(content)

        # Kalite metrikleri kaydını oluştur veya güncelle
        metrics, created = ContentQualityMetrics.objects.get_or_create(article=article)

        metrics.flesch_kincaid_grade = readability.get('flesch_kincaid_grade', 0)
        metrics.gunning_fog_index = readability.get('gunning_fog_index', 0)
        metrics.smog_index = readability.get('smog_index', 0)
        metrics.word_count = readability.get('word_count', 0)
        metrics.sentence_count = readability.get('sentence_count', 0)
        metrics.paragraph_count = readability.get('paragraph_count', 0)
        metrics.avg_sentence_length = readability.get('avg_sentence_length', 0)
        metrics.avg_word_length = readability.get('avg_word_length', 0)

        metrics.primary_keyword = seo.get('primary_keyword', '')
        metrics.primary_keyword_count = seo.get('primary_keyword_count', 0)
        metrics.keyword_density = seo.get('keyword_density', 0)
        metrics.meta_description_length = len(article.excerpt) if article.excerpt else 0

        metrics.heading_count = structure.get('heading_count', 0)
        metrics.h2_count = structure.get('h2_count', 0)
        metrics.h3_count = structure.get('h3_count', 0)
        metrics.has_lists = structure.get('has_lists', False)
        metrics.has_images = structure.get('has_images', False)
        metrics.has_bold_text = structure.get('has_bold_text', False)

        # Genel kalite puanı hesapla
        overall_score = calculate_overall_quality_score(metrics)
        metrics.overall_quality_score = overall_score

        article.quality_score = overall_score
        article.readability_score = readability.get('flesch_kincaid_grade', 0)
        article.keyword_density = seo.get('keyword_density', 0)

        metrics.save()
        article.save()

        logger.info(f"Kalite metrikleri hesaplandı: {article.title} - Puan: {overall_score:.1f}")

    except Exception as e:
        logger.error(f"Kalite metrikleri hesaplama hatası: {str(e)}")


def calculate_overall_quality_score(metrics):
    """
    Genel kalite puanı hesapla.
    """
    score = 0

    # Okunabilirlik (30 puan)
    if 8 <= metrics.flesch_kincaid_grade <= 12:
        score += 30
    elif 6 <= metrics.flesch_kincaid_grade <= 14:
        score += 20
    else:
        score += 10

    # SEO (30 puan)
    if 1.5 <= metrics.keyword_density <= 3.0:
        score += 30
    elif 1.0 <= metrics.keyword_density <= 4.0:
        score += 20
    else:
        score += 10

    # Uzunluk (20 puan)
    if 400 <= metrics.word_count <= 1000:
        score += 20
    elif 300 <= metrics.word_count <= 1200:
        score += 15
    else:
        score += 5

    # Yapı (20 puan)
    structure_score = 0
    if metrics.heading_count >= 2:
        structure_score += 5
    if metrics.has_lists:
        structure_score += 5
    if metrics.has_bold_text:
        structure_score += 5
    if metrics.paragraph_count >= 3:
        structure_score += 5

    score += structure_score

    return min(score, 100)


# ============================================================================
# AŞAMA 5: GÖRSEL ÜRETIMI
# ============================================================================

@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={"max_retries": 2, "countdown": 10},
    retry_backoff=True,
)
def generate_article_image_v2(self, article_id):
    """
    Makale için profesyonel görsel üret.
    """
    try:
        article = Article.objects.get(id=article_id)

        if article.featured_image:
            log_info("generate_article_image_v2", f"Makale zaten görsele sahip: {article.title}", related_id=article_id)
            return

        try:
            api_key_setting = Setting.objects.get(key="GOOGLE_GEMINI_API_KEY")
            api_key = api_key_setting.value
        except Setting.DoesNotExist:
            return

        if not api_key:
            return

        try:
            from google import genai
            from google.genai import types

            client = genai.Client(api_key=api_key)

            image_prompt = f"""
Professional news photography for: {article.title}
Category: {article.category}
Style: Editorial, 16:9 aspect ratio, high quality, photorealistic
            """.strip()

            response = client.models.generate_images(
                model="imagen-4.0-ultra-generate-001",
                prompt=image_prompt,
                config=types.GenerateImagesConfig(
                    number_of_images=1,
                    aspect_ratio='16:9'
                )
            )

            if response.generated_images:
                generated_image = response.generated_images[0]

                img_buffer = BytesIO()
                generated_image.image._pil_image.save(img_buffer, format='JPEG', quality=95)
                img_buffer.seek(0)

                filename = f"{article.slug}_ai_generated.jpg"
                article.featured_image.save(filename, img_buffer, save=True)
                article.featured_image_alt = article.title
                article.is_ai_image = True
                article.save()

                log_info("generate_article_image_v2", f"Görsel başarıyla oluşturuldu: {article.title}", related_id=article_id)

        except Exception as e:
            log_error("generate_article_image_v2", f"Görsel üretim hatası: {str(e)}", traceback=str(e), related_id=article_id)

    except Article.DoesNotExist:
        log_error("generate_article_image_v2", f"Makale bulunamadı (ID: {article_id})", related_id=article_id)
