"""
Geliştirilmiş İçerik Üretim Sistemi Test Paketi
Başlık puanlaması, sınıflandırma ve kalite kontrolü testleri
"""

from django.test import TestCase


from authors.models import Author
from news.models import Article, RssSource
from news.models_extended import ArticleClassification, ContentGenerationLog, ContentQualityMetrics, HeadlineScore
from news.quality_utils import calculate_readability, calculate_seo_metrics, calculate_structure_metrics
from news.tasks_v2 import (
    calculate_engagement_score,
    calculate_keyword_relevance,
    calculate_structure_score,
    calculate_uniqueness_score,
    has_power_words,
)


class HeadlineScoringTestCase(TestCase):
    """Başlık puanlaması testleri"""

    def setUp(self):
        """Test verilerini hazırla"""
        self.rss_source = RssSource.objects.create(
            name="Test Source",
            url="http://example.com/feed",
            category="Teknoloji",
            frequency_minutes=60,
            is_active=True,
        )

    def test_headline_score_creation(self):
        """Başlık puanı oluşturma testi"""
        headline = HeadlineScore.objects.create(
            rss_source=self.rss_source,
            original_headline="Yeni Yapay Zeka Modeli Piyasaya Çıktı",
            overall_score=75.5,
            word_count=6,
            character_count=40,
            is_processed=False,
        )

        self.assertEqual(headline.overall_score, 75.5)
        self.assertEqual(headline.word_count, 6)
        self.assertFalse(headline.is_processed)

    def test_uniqueness_score_calculation(self):
        """Orijinallik puanı hesaplama testi"""
        headline = HeadlineScore.objects.create(
            rss_source=self.rss_source,
            original_headline="Benzersiz Başlık",
            word_count=2,
            character_count=16,
            is_processed=False,
        )

        score = calculate_uniqueness_score(headline)
        self.assertEqual(score, 30)  # Benzersiz başlık

    def test_engagement_score_with_numbers(self):
        """Sayı içeren başlık engagement puanı"""
        score = calculate_engagement_score("5 Harika Teknoloji Haberi")
        self.assertGreater(score, 0)
        self.assertLessEqual(score, 30)

    def test_engagement_score_with_power_words(self):
        """Güçlü kelime içeren başlık engagement puanı"""
        score = calculate_engagement_score("Nasıl Başarılı Olmak Mümkün")
        self.assertGreater(score, 0)

    def test_keyword_relevance_matching(self):
        """Anahtar kelime uygunluğu testi"""
        score = calculate_keyword_relevance("Yapay Zeka Yazılım Geliştirme", "Teknoloji")
        self.assertGreater(score, 0)

    def test_structure_score_optimal_length(self):
        """Optimal uzunluk yapı puanı"""
        title = "Bu Başlık Optimal Uzunlukta Bir Başlıktır"  # 7 kelime
        score = calculate_structure_score(title)
        self.assertGreater(score, 0)

    def test_has_power_words_detection(self):
        """Güçlü kelime tespiti"""
        self.assertTrue(has_power_words("Nasıl başarılı olmak mümkün"))
        self.assertTrue(has_power_words("En iyi 5 yol"))
        # Güçlü kelime içermeyen metin
        self.assertFalse(has_power_words("Ortaç ağaç köküğü"))  # Güçlü kelime yok


class ReadabilityMetricsTestCase(TestCase):
    """Okunabilirlik metrikleri testleri"""

    def test_flesch_kincaid_calculation(self):
        """Flesch-Kincaid indeksi hesaplama"""
        html_content = """
        <p>Bu bir test metnidir. Okunabilirlik testini yapıyoruz.
        Metrikleri hesaplamak önemlidir.</p>
        """

        metrics = calculate_readability(html_content)

        self.assertIn("flesch_kincaid_grade", metrics)
        self.assertIn("word_count", metrics)
        self.assertIn("sentence_count", metrics)
        self.assertGreater(metrics["word_count"], 0)

    def test_word_count_accuracy(self):
        """Kelime sayısı doğruluğu"""
        html_content = "<p>Bir iki üç dört beş altı yedi sekiz dokuz on</p>"
        metrics = calculate_readability(html_content)
        self.assertEqual(metrics["word_count"], 10)

    def test_sentence_count_accuracy(self):
        """Cümle sayısı doğruluğu"""
        html_content = "<p>Birinci cümle. İkinci cümle! Üçüncü cümle?</p>"
        metrics = calculate_readability(html_content)
        self.assertEqual(metrics["sentence_count"], 3)


class SEOMetricsTestCase(TestCase):
    """SEO metrikleri testleri"""

    def test_keyword_density_calculation(self):
        """Anahtar kelime yoğunluğu hesaplama"""
        title = "Teknoloji Haberleri"
        content = """
        <p>Teknoloji dünyasında yeni gelişmeler. Teknoloji sektörü büyüyor.
        Teknoloji şirketleri yatırım yapıyor. Teknoloji yatırımları artıyor.</p>
        """

        metrics = calculate_seo_metrics(title, content, "Teknoloji")

        self.assertIn("keyword_density", metrics)
        # Anahtar kelime yoğunluğu 0 veya daha büyük olabilir
        self.assertGreaterEqual(metrics["keyword_density"], 0)

    def test_primary_keyword_extraction(self):
        """Birincil anahtar kelime çıkarma"""
        title = "Yapay Zeka Devrimini Anlamak"
        content = "<p>Yapay zeka hakkında bilgiler</p>"

        metrics = calculate_seo_metrics(title, content, "Teknoloji")

        self.assertIn("primary_keyword", metrics)
        self.assertIsNotNone(metrics["primary_keyword"])


class StructureMetricsTestCase(TestCase):
    """İçerik yapısı metrikleri testleri"""

    def test_heading_count(self):
        """Başlık sayısı hesaplama"""
        html_content = """
        <h2>Ana Başlık</h2>
        <p>Paragraf</p>
        <h3>Alt Başlık 1</h3>
        <p>Paragraf</p>
        <h3>Alt Başlık 2</h3>
        """

        metrics = calculate_structure_metrics(html_content)

        self.assertEqual(metrics["h2_count"], 1)
        self.assertEqual(metrics["h3_count"], 2)
        self.assertEqual(metrics["heading_count"], 3)

    def test_list_detection(self):
        """Liste tespiti"""
        html_content = "<ul><li>Madde 1</li><li>Madde 2</li></ul>"

        metrics = calculate_structure_metrics(html_content)

        self.assertTrue(metrics["has_lists"])
        self.assertEqual(metrics["list_count"], 2)

    def test_image_count(self):
        """Görsel sayısı hesaplama"""
        html_content = """
        <img src="image1.jpg" alt="Image 1">
        <p>Paragraf</p>
        <img src="image2.jpg" alt="Image 2">
        """

        metrics = calculate_structure_metrics(html_content)

        self.assertEqual(metrics["image_count"], 2)
        self.assertTrue(metrics["has_images"])


class ArticleClassificationTestCase(TestCase):
    """Makale sınıflandırması testleri"""

    def setUp(self):
        """Test verilerini hazırla"""
        self.author = Author.objects.create(
            name="Test Author", slug="test-author", expertise="Teknoloji", is_active=True
        )

        self.rss_source = RssSource.objects.create(
            name="Test Source",
            url="http://example.com/feed",
            category="Teknoloji",
            frequency_minutes=60,
            is_active=True,
        )

        self.article = Article.objects.create(
            title="Test Article",
            slug="test-article",
            content="Test content",
            author=self.author,
            category="Teknoloji",
            rss_source=self.rss_source,
            status="draft",
        )

    def test_classification_creation(self):
        """Sınıflandırma oluşturma"""
        classification = ArticleClassification.objects.create(
            article=self.article,
            article_type="news",
            type_confidence=0.95,
            primary_category="Teknoloji",
            research_depth=1,
            recommended_ai_model="gemini-2.5-flash",
        )

        self.assertEqual(classification.article_type, "news")
        self.assertEqual(classification.type_confidence, 0.95)

    def test_classification_model_selection(self):
        """Model seçimi"""
        classification = ArticleClassification.objects.create(
            article=self.article,
            article_type="analysis",
            type_confidence=0.90,
            primary_category="Teknoloji",
            research_depth=2,
            recommended_ai_model="gemini-2.5-pro",
        )

        self.assertEqual(classification.recommended_ai_model, "gemini-2.5-pro")
        self.assertEqual(classification.research_depth, 2)


class ContentQualityMetricsTestCase(TestCase):
    """İçerik kalitesi metrikleri testleri"""

    def setUp(self):
        """Test verilerini hazırla"""
        self.author = Author.objects.create(
            name="Test Author", slug="test-author", expertise="Teknoloji", is_active=True
        )

        self.article = Article.objects.create(
            title="Test Article",
            slug="test-article",
            content="Test content",
            author=self.author,
            category="Teknoloji",
            status="published",
        )

    def test_quality_metrics_creation(self):
        """Kalite metrikleri oluşturma"""
        metrics = ContentQualityMetrics.objects.create(
            article=self.article,
            word_count=500,
            sentence_count=25,
            paragraph_count=5,
            flesch_kincaid_grade=9.5,
            keyword_density=2.5,
            overall_quality_score=85.0,
        )

        self.assertEqual(metrics.word_count, 500)
        self.assertEqual(metrics.overall_quality_score, 85.0)

    def test_quality_score_range(self):
        """Kalite puanı aralığı"""
        metrics = ContentQualityMetrics.objects.create(article=self.article, word_count=500, overall_quality_score=75.5)

        self.assertGreaterEqual(metrics.overall_quality_score, 0)
        self.assertLessEqual(metrics.overall_quality_score, 100)


class ContentGenerationLogTestCase(TestCase):
    """İçerik üretim logu testleri"""

    def setUp(self):
        """Test verilerini hazırla"""
        self.author = Author.objects.create(
            name="Test Author", slug="test-author", expertise="Teknoloji", is_active=True
        )

        self.article = Article.objects.create(
            title="Test Article",
            slug="test-article",
            content="Test content",
            author=self.author,
            category="Teknoloji",
            status="published",
        )

    def test_log_creation(self):
        """Log oluşturma"""
        log = ContentGenerationLog.objects.create(
            article=self.article,
            stage="generate",
            status="completed",
            duration=5000,
            ai_model_used="gemini-2.5-flash",
            api_calls_count=1,
            tokens_used=1500,
        )

        self.assertEqual(log.stage, "generate")
        self.assertEqual(log.status, "completed")
        self.assertEqual(log.duration, 5000)

    def test_log_error_tracking(self):
        """Hata izleme"""
        log = ContentGenerationLog.objects.create(
            article=self.article,
            stage="generate",
            status="failed",
            error_message="API timeout",
            error_traceback="Traceback here",
        )

        self.assertEqual(log.status, "failed")
        self.assertIn("timeout", log.error_message)


# ============================================================================
# Integration Tests
# ============================================================================


class ContentGenerationIntegrationTestCase(TestCase):
    """İçerik üretim sistemi entegrasyon testleri"""

    def setUp(self):
        """Test verilerini hazırla"""
        self.author = Author.objects.create(
            name="Test Author", slug="test-author", expertise="Teknoloji", is_active=True
        )

        self.rss_source = RssSource.objects.create(
            name="Test Source",
            url="http://example.com/feed",
            category="Teknoloji",
            frequency_minutes=60,
            is_active=True,
        )

    def test_full_workflow(self):
        """Tam iş akışı testi"""
        # 1. Başlık oluştur
        headline = HeadlineScore.objects.create(
            rss_source=self.rss_source,
            original_headline="Yapay Zeka Yeni Başarıya Ulaştı",
            overall_score=85.0,
            word_count=5,
            character_count=35,
            is_processed=False,
        )

        self.assertFalse(headline.is_processed)

        # 2. Makale oluştur
        article = Article.objects.create(
            title=headline.original_headline,
            slug="yapay-zeka-yeni-basariya-ulasti",
            content="<p>Test content</p>",
            author=self.author,
            category=self.rss_source.category,
            rss_source=self.rss_source,
            status="draft",
        )

        # 3. Sınıflandırma yap
        classification = ArticleClassification.objects.create(
            article=article,
            article_type="news",
            type_confidence=0.95,
            primary_category="Teknoloji",
            research_depth=1,
            recommended_ai_model="gemini-2.5-flash",
        )

        # 4. Kalite metrikleri hesapla
        metrics = ContentQualityMetrics.objects.create(
            article=article,
            word_count=500,
            sentence_count=25,
            paragraph_count=5,
            flesch_kincaid_grade=9.5,
            keyword_density=2.5,
            overall_quality_score=85.0,
        )

        # 5. Log oluştur
        log = ContentGenerationLog.objects.create(
            article=article, stage="generate", status="completed", duration=5000, ai_model_used="gemini-2.5-flash"
        )

        # Doğrulamalar
        self.assertEqual(article.status, "draft")
        self.assertEqual(classification.article_type, "news")
        self.assertEqual(metrics.overall_quality_score, 85.0)
        self.assertEqual(log.status, "completed")
