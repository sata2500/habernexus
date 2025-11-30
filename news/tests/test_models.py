"""
News modelleri için unit testler.
"""

from django.utils import timezone
from django.utils.text import slugify

import pytest

from authors.models import Author
from news.models import Article, RssSource


@pytest.mark.django_db
class TestArticleModel:
    """Article modeli testleri."""

    def test_article_creation(self):
        """Makale oluşturma testi."""
        # Yazar oluştur
        author = Author.objects.create(name="Test Yazar", slug="test-yazar", expertise="Teknoloji")

        # Makale oluştur
        article = Article.objects.create(
            title="Test Makale",
            content="Test içerik",
            excerpt="Test özet",
            category="Teknoloji",
            author=author,
            status="published",
            published_at=timezone.now(),
        )

        assert article.title == "Test Makale"
        assert article.slug == slugify("Test Makale")
        assert article.author == author
        assert article.status == "published"

    def test_article_slug_auto_generation(self):
        """Slug otomatik oluşturma testi."""
        author = Author.objects.create(name="Test Yazar", slug="test-yazar", expertise="Teknoloji")

        article = Article.objects.create(title="Türkçe Başlık İçeren Makale", content="Test içerik", author=author)

        assert article.slug is not None
        assert article.slug == slugify("Türkçe Başlık İçeren Makale")

    def test_article_get_absolute_url(self):
        """Makale URL testi."""
        author = Author.objects.create(name="Test Yazar", slug="test-yazar", expertise="Teknoloji")

        article = Article.objects.create(title="Test Makale", slug="test-makale", content="Test içerik", author=author)

        url = article.get_absolute_url()
        assert url == f"/haber/{article.slug}/"

    def test_article_ordering(self):
        """Makale sıralama testi."""
        author = Author.objects.create(name="Test Yazar", slug="test-yazar", expertise="Teknoloji")

        # İki makale oluştur
        article1 = Article.objects.create(
            title="Eski Makale",
            content="Test",
            author=author,
            status="published",
            published_at=timezone.now() - timezone.timedelta(days=1),
        )

        article2 = Article.objects.create(
            title="Yeni Makale", content="Test", author=author, status="published", published_at=timezone.now()
        )

        articles = Article.objects.filter(status="published")
        assert articles.first() == article2  # En yeni önce gelir


@pytest.mark.django_db
class TestRssSourceModel:
    """RssSource modeli testleri."""

    def test_rss_source_creation(self):
        """RSS kaynağı oluşturma testi."""
        source = RssSource.objects.create(
            name="Test RSS", url="https://example.com/rss", category="Teknoloji", frequency_minutes=60
        )

        assert source.name == "Test RSS"
        assert source.is_active is True
        assert source.frequency_minutes == 60

    def test_rss_source_str_representation(self):
        """RSS kaynağı string temsili testi."""
        source = RssSource.objects.create(name="Test RSS", url="https://example.com/rss", category="Teknoloji")

        assert str(source) == "Test RSS (Teknoloji)"
