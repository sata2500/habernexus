"""
HaberNexus v10.4 - Comprehensive Task Tests
Test coverage artırma için kapsamlı testler.

Author: Salih TANRISEVEN
Updated: December 2025
"""

from io import BytesIO
from unittest.mock import MagicMock, Mock, patch

from django.test import TestCase
from django.utils import timezone

import pytest
from PIL import Image

from authors.models import Author
from core.models import Setting
from news.models import Article, RssSource
from news.tasks import (
    batch_regenerate_content,
    cleanup_draft_articles,
    create_thinking_config,
    download_article_image,
    fetch_rss_feeds,
    generate_ai_content,
    generate_article_image,
    get_ai_model_name,
    get_genai_client,
    get_image_model_name,
    get_thinking_budget,
    get_thinking_level,
    retry_with_backoff,
)

# =============================================================================
# Configuration Helper Tests
# =============================================================================


@pytest.mark.django_db
class TestConfigurationHelpers(TestCase):
    """Yapılandırma yardımcı fonksiyonları testleri."""

    def test_get_ai_model_name_default(self):
        """Varsayılan AI model adı testi."""
        model_name = get_ai_model_name()
        assert model_name == "gemini-2.5-flash"

    def test_get_ai_model_name_from_settings(self):
        """Ayarlardan AI model adı testi."""
        Setting.objects.create(key="AI_MODEL", value="gemini-2.0-pro")
        model_name = get_ai_model_name()
        assert model_name == "gemini-2.0-pro"

    def test_get_image_model_name_default(self):
        """Varsayılan image model adı testi."""
        model_name = get_image_model_name()
        assert model_name == "imagen-4.0-generate-001"

    def test_get_image_model_name_from_settings(self):
        """Ayarlardan image model adı testi."""
        Setting.objects.create(key="IMAGE_MODEL", value="imagen-3.0")
        model_name = get_image_model_name()
        assert model_name == "imagen-3.0"

    def test_get_thinking_budget_default(self):
        """Varsayılan thinking budget testi."""
        budget = get_thinking_budget()
        assert budget == 0

    def test_get_thinking_budget_from_settings(self):
        """Ayarlardan thinking budget testi."""
        Setting.objects.create(key="AI_THINKING_BUDGET", value="1024")
        budget = get_thinking_budget()
        assert budget == 1024

    def test_get_thinking_budget_invalid_value(self):
        """Geçersiz thinking budget değeri testi."""
        Setting.objects.create(key="AI_THINKING_BUDGET", value="invalid")
        budget = get_thinking_budget()
        assert budget == 0

    def test_get_thinking_level_default(self):
        """Varsayılan thinking level testi."""
        level = get_thinking_level()
        assert level is None

    def test_get_thinking_level_valid_values(self):
        """Geçerli thinking level değerleri testi."""
        # Yeni API: "low" ve "high" değerleri destekleniyor
        # Eski değerler (MINIMAL, MEDIUM) dönüştürülüyor
        test_cases = [
            ("low", "low"),
            ("high", "high"),
            ("LOW", "low"),
            ("HIGH", "high"),
            ("MINIMAL", "low"),  # Legacy: MINIMAL -> low
            ("MEDIUM", "high"),  # Legacy: MEDIUM -> high
        ]
        for input_value, expected in test_cases:
            Setting.objects.filter(key="AI_THINKING_LEVEL").delete()
            Setting.objects.create(key="AI_THINKING_LEVEL", value=input_value)
            level = get_thinking_level()
            assert level == expected, f"Input: {input_value}, Expected: {expected}, Got: {level}"

    def test_get_thinking_level_invalid_value(self):
        """Geçersiz thinking level değeri testi."""
        Setting.objects.create(key="AI_THINKING_LEVEL", value="INVALID")
        level = get_thinking_level()
        assert level is None

    def test_get_genai_client_no_api_key(self):
        """API anahtarı olmadan client oluşturma testi."""
        with pytest.raises(ValueError, match="API anahtarı bulunamadı"):
            get_genai_client()

    def test_get_genai_client_empty_api_key(self):
        """Boş API anahtarı ile client oluşturma testi."""
        Setting.objects.create(key="GOOGLE_GEMINI_API_KEY", value="")
        with pytest.raises(ValueError, match="API anahtarı boş"):
            get_genai_client()


@pytest.mark.django_db
class TestCreateThinkingConfig(TestCase):
    """ThinkingConfig oluşturma testleri."""

    @patch("news.tasks.get_ai_model_name")
    @patch("news.tasks.get_thinking_level")
    @patch("news.tasks.get_thinking_budget")
    def test_create_thinking_config_disabled(self, mock_budget, mock_level, mock_model):
        """Thinking devre dışı olduğunda test (Gemini 2.5)."""
        mock_model.return_value = "gemini-2.5-flash"
        mock_level.return_value = None
        mock_budget.return_value = 0

        with patch("google.genai.types") as mock_types:
            mock_config = MagicMock()
            mock_types.ThinkingConfig.return_value = mock_config

            config = create_thinking_config()

            mock_types.ThinkingConfig.assert_called_with(thinking_budget=0)

    @patch("news.tasks.get_ai_model_name")
    @patch("news.tasks.get_thinking_level")
    @patch("news.tasks.get_thinking_budget")
    def test_create_thinking_config_with_level(self, mock_budget, mock_level, mock_model):
        """Thinking level ile config oluşturma testi (Gemini 3)."""
        mock_model.return_value = "gemini-3-pro"
        mock_level.return_value = "high"
        mock_budget.return_value = 0

        with patch("google.genai.types") as mock_types:
            mock_config = MagicMock()
            mock_types.ThinkingConfig.return_value = mock_config

            result = create_thinking_config()

            mock_types.ThinkingConfig.assert_called_with(thinking_level="high")

    @patch("news.tasks.get_ai_model_name")
    @patch("news.tasks.get_thinking_level")
    @patch("news.tasks.get_thinking_budget")
    def test_create_thinking_config_with_budget(self, mock_budget, mock_level, mock_model):
        """Thinking budget ile config oluşturma testi (Gemini 2.5)."""
        mock_model.return_value = "gemini-2.5-flash"
        mock_level.return_value = None
        mock_budget.return_value = 2048

        with patch("google.genai.types") as mock_types:
            mock_config = MagicMock()
            mock_types.ThinkingConfig.return_value = mock_config

            result = create_thinking_config()

            mock_types.ThinkingConfig.assert_called_with(thinking_budget=2048)


# =============================================================================
# Retry Helper Tests
# =============================================================================


class TestRetryWithBackoff(TestCase):
    """Retry mekanizması testleri."""

    def test_retry_success_first_attempt(self):
        """İlk denemede başarılı olma testi."""
        mock_func = Mock(return_value="success")
        result = retry_with_backoff(mock_func, max_retries=3)
        assert result == "success"
        assert mock_func.call_count == 1

    def test_retry_success_after_failures(self):
        """Birkaç başarısız denemeden sonra başarılı olma testi."""
        mock_func = Mock(side_effect=[Exception("Error 1"), Exception("Error 2"), "success"])
        result = retry_with_backoff(mock_func, max_retries=3, initial_delay=0.01)
        assert result == "success"
        assert mock_func.call_count == 3

    def test_retry_all_failures(self):
        """Tüm denemelerin başarısız olması testi."""
        mock_func = Mock(side_effect=Exception("Persistent error"))
        with pytest.raises(Exception, match="Persistent error"):
            retry_with_backoff(mock_func, max_retries=3, initial_delay=0.01)
        assert mock_func.call_count == 3


# =============================================================================
# RSS Feed Task Tests
# =============================================================================


@pytest.mark.django_db
class TestFetchRssFeeds(TestCase):
    """fetch_rss_feeds task testleri."""

    def setUp(self):
        """Test setup."""
        self.author = Author.objects.create(name="Test Yazar", slug="test-yazar", expertise="Teknoloji")

    @patch("news.tasks.fetch_single_rss")
    @patch("news.tasks.log_info")
    def test_fetch_rss_feeds_no_sources(self, mock_log_info, mock_fetch_single):
        """Aktif kaynak olmadığında test."""
        result = fetch_rss_feeds()
        assert "0 haber eklendi" in result
        mock_fetch_single.assert_not_called()

    @patch("news.tasks.fetch_single_rss")
    @patch("news.tasks.log_info")
    def test_fetch_rss_feeds_success(self, mock_log_info, mock_fetch_single):
        """Başarılı RSS tarama testi."""
        RssSource.objects.create(
            name="Test RSS", url="https://example.com/rss", category="Teknoloji", frequency_minutes=60, is_active=True
        )
        mock_fetch_single.return_value = 5

        result = fetch_rss_feeds()

        assert "5 haber eklendi" in result
        mock_fetch_single.assert_called_once()

    @patch("news.tasks.fetch_single_rss")
    @patch("news.tasks.log_error")
    @patch("news.tasks.log_info")
    def test_fetch_rss_feeds_partial_failure(self, mock_log_info, mock_log_error, mock_fetch_single):
        """Kısmi başarısızlık testi."""
        # Önce başarılı kaynak
        RssSource.objects.create(
            name="Success RSS",
            url="https://example.com/rss1",
            category="Teknoloji",
            frequency_minutes=60,
            is_active=True,
        )
        # Sonra başarısız kaynak
        RssSource.objects.create(
            name="Failed RSS",
            url="https://example.com/rss2",
            category="Teknoloji",
            frequency_minutes=60,
            is_active=True,
        )

        # İlk kaynak başarılı, ikinci kaynak başarısız
        mock_fetch_single.side_effect = [3, Exception("Network error")]

        result = fetch_rss_feeds()

        # Sonuçta 3 haber eklendi ve başarısız kaynak adı olmalı
        assert "3 haber eklendi" in result
        # Başarısız kaynak adı sonuçta olmalı (sıra önemli değil)
        assert any(name in result for name in ["Success RSS", "Failed RSS"])


# =============================================================================
# Download Article Image Tests
# =============================================================================


@pytest.mark.django_db
class TestDownloadArticleImage(TestCase):
    """download_article_image fonksiyonu testleri."""

    def setUp(self):
        """Test setup."""
        self.article = Article.objects.create(
            title="Test Makale",
            slug="test-makale",
            content="Test içerik",
            category="Teknoloji",
            status="draft",
        )

    @patch("news.tasks.requests.get")
    def test_download_image_success(self, mock_get):
        """Başarılı görsel indirme testi."""
        # Mock image response
        img = Image.new("RGB", (100, 100), color="red")
        img_buffer = BytesIO()
        img.save(img_buffer, format="JPEG")
        img_buffer.seek(0)

        mock_response = Mock()
        mock_response.content = img_buffer.getvalue()
        mock_response.raise_for_status = Mock()
        mock_get.return_value = mock_response

        download_article_image(self.article, "https://example.com/image.jpg")

        self.article.refresh_from_db()
        assert self.article.featured_image_alt == "Test Makale"

    @patch("news.tasks.requests.get")
    def test_download_image_rgba_conversion(self, mock_get):
        """RGBA görsel dönüşüm testi."""
        # Mock RGBA image
        img = Image.new("RGBA", (100, 100), color=(255, 0, 0, 128))
        img_buffer = BytesIO()
        img.save(img_buffer, format="PNG")
        img_buffer.seek(0)

        mock_response = Mock()
        mock_response.content = img_buffer.getvalue()
        mock_response.raise_for_status = Mock()
        mock_get.return_value = mock_response

        download_article_image(self.article, "https://example.com/image.png")

        self.article.refresh_from_db()
        assert self.article.featured_image_alt == "Test Makale"

    @patch("news.tasks.requests.get")
    def test_download_image_network_error(self, mock_get):
        """Ağ hatası testi."""
        import requests

        mock_get.side_effect = requests.RequestException("Network error")

        with pytest.raises(requests.RequestException):
            download_article_image(self.article, "https://example.com/image.jpg")


# =============================================================================
# AI Content Generation Tests
# =============================================================================


@pytest.mark.django_db
class TestGenerateAIContent(TestCase):
    """generate_ai_content task testleri."""

    def setUp(self):
        """Test setup."""
        self.author = Author.objects.create(name="Test Yazar", slug="test-yazar", expertise="Teknoloji", is_active=True)
        self.article = Article.objects.create(
            title="Test Makale",
            slug="test-makale",
            content="Test içerik",
            category="Teknoloji",
            status="draft",
        )

    def test_generate_ai_content_article_not_found(self):
        """Makale bulunamadığında test."""
        result = generate_ai_content(99999)
        assert "Makale bulunamadı" in result

    def test_generate_ai_content_already_processed(self):
        """Zaten işlenmiş makale testi."""
        self.article.is_ai_generated = True
        self.article.status = "published"
        self.article.save()

        result = generate_ai_content(self.article.id)
        assert "zaten işlenmiş" in result

    def test_generate_ai_content_no_active_author(self):
        """Aktif yazar olmadığında test."""
        Author.objects.all().update(is_active=False)

        result = generate_ai_content(self.article.id)
        assert "Aktif yazar bulunamadı" in result

    @patch("news.tasks.get_genai_client")
    @patch("news.tasks.create_thinking_config")
    @patch("news.tasks.retry_with_backoff")
    @patch("news.tasks.transaction.on_commit")
    def test_generate_ai_content_success(self, mock_on_commit, mock_retry, mock_thinking, mock_client):
        """Başarılı AI içerik üretimi testi."""
        mock_response = MagicMock()
        mock_response.text = "<p>AI generated content</p>"
        mock_retry.return_value = mock_response
        mock_thinking.return_value = None

        result = generate_ai_content(self.article.id)

        self.article.refresh_from_db()
        assert "Başarılı" in result
        assert self.article.is_ai_generated is True
        assert self.article.status == "published"
        assert self.article.content == "<p>AI generated content</p>"

    @patch("news.tasks.get_genai_client")
    @patch("news.tasks.create_thinking_config")
    @patch("news.tasks.retry_with_backoff")
    def test_generate_ai_content_empty_response(self, mock_retry, mock_thinking, mock_client):
        """Boş AI yanıtı testi."""
        mock_response = MagicMock()
        mock_response.text = None
        mock_retry.return_value = mock_response
        mock_thinking.return_value = None

        result = generate_ai_content(self.article.id)
        assert "AI yanıt boş" in result


# =============================================================================
# Image Generation Tests
# =============================================================================


@pytest.mark.django_db
class TestGenerateArticleImage(TestCase):
    """generate_article_image task testleri."""

    def setUp(self):
        """Test setup."""
        self.article = Article.objects.create(
            title="Test Makale",
            slug="test-makale",
            content="Test içerik",
            category="Teknoloji",
            status="published",
        )

    def test_generate_image_article_not_found(self):
        """Makale bulunamadığında test."""
        result = generate_article_image(99999)
        assert "Makale bulunamadı" in result

    def test_generate_image_already_exists(self):
        """Görsel zaten varsa test."""
        # Mock featured_image
        self.article.featured_image = "test.jpg"
        self.article.save()

        result = generate_article_image(self.article.id)
        assert "zaten mevcut" in result


# =============================================================================
# Batch Processing Tests
# =============================================================================


@pytest.mark.django_db
class TestBatchProcessing(TestCase):
    """Toplu işlem testleri."""

    def setUp(self):
        """Test setup."""
        self.articles = []
        for i in range(5):
            article = Article.objects.create(
                title=f"Test Makale {i}",
                slug=f"test-makale-{i}",
                content=f"Test içerik {i}",
                category="Teknoloji",
                status="draft",
            )
            self.articles.append(article)

    @patch("news.tasks.generate_ai_content.delay")
    def test_batch_regenerate_content_success(self, mock_delay):
        """Başarılı toplu içerik üretimi testi."""
        article_ids = [a.id for a in self.articles]
        result = batch_regenerate_content(article_ids)

        assert "5 başarılı" in result
        assert mock_delay.call_count == 5

    @patch("news.tasks.generate_ai_content.delay")
    def test_batch_regenerate_content_partial_failure(self, mock_delay):
        """Kısmi başarısızlık testi."""
        mock_delay.side_effect = [None, None, Exception("Error"), None, None]
        article_ids = [a.id for a in self.articles]

        result = batch_regenerate_content(article_ids)

        assert "4 başarılı" in result
        assert "1 başarısız" in result


@pytest.mark.django_db
class TestCleanupDraftArticles(TestCase):
    """Taslak makale temizleme testleri."""

    def test_cleanup_no_old_drafts(self):
        """Eski taslak olmadığında test."""
        Article.objects.create(
            title="Yeni Taslak",
            slug="yeni-taslak",
            content="İçerik",
            category="Teknoloji",
            status="draft",
        )

        result = cleanup_draft_articles(days_old=7)
        assert "bulunamadı" in result

    def test_cleanup_old_drafts(self):
        """Eski taslakları temizleme testi."""
        from datetime import timedelta

        old_date = timezone.now() - timedelta(days=10)

        article = Article.objects.create(
            title="Eski Taslak",
            slug="eski-taslak",
            content="İçerik",
            category="Teknoloji",
            status="draft",
        )
        Article.objects.filter(id=article.id).update(created_at=old_date)

        result = cleanup_draft_articles(days_old=7)

        assert "1 eski taslak makale silindi" in result
        assert not Article.objects.filter(id=article.id).exists()

    def test_cleanup_preserves_published(self):
        """Yayınlanmış makaleleri koruma testi."""
        from datetime import timedelta

        old_date = timezone.now() - timedelta(days=10)

        article = Article.objects.create(
            title="Eski Yayın",
            slug="eski-yayin",
            content="İçerik",
            category="Teknoloji",
            status="published",
        )
        Article.objects.filter(id=article.id).update(created_at=old_date)

        result = cleanup_draft_articles(days_old=7)

        assert "bulunamadı" in result
        assert Article.objects.filter(id=article.id).exists()
