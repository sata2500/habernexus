"""News tasks için testler."""

from unittest.mock import MagicMock, patch

from django.test import TestCase
from django.utils import timezone

import pytest

from authors.models import Author
from news.models import Article, RssSource
from news.tasks import fetch_single_rss


@pytest.mark.django_db
class TestFetchSingleRss(TestCase):
    """fetch_single_rss fonksiyonu testleri."""

    def setUp(self):
        """Test setup."""
        self.author = Author.objects.create(name="Test Yazar", slug="test-yazar", expertise="Teknoloji")

        self.rss_source = RssSource.objects.create(
            name="Test RSS", url="https://example.com/rss", category="Teknoloji", frequency_minutes=60, is_active=True
        )

    @patch("news.tasks.feedparser.parse")
    def test_fetch_single_rss_success(self, mock_parse):
        """RSS tarama başarılı olduğunda test."""
        # Mock RSS feed response
        mock_entry = MagicMock()
        mock_entry.title = "Test Haber Başlığı"
        mock_entry.link = "https://example.com/test-haber"
        mock_entry.summary = "Test haber içeriği"
        mock_entry.get = lambda key, default="": {"title": "Test Haber Başlığı", "summary": "Test haber içeriği"}.get(
            key, default
        )

        mock_feed = MagicMock()
        mock_feed.bozo = False
        mock_feed.entries = [mock_entry]

        mock_parse.return_value = mock_feed

        # Fonksiyonu çalıştır
        fetched_count = fetch_single_rss(self.rss_source)

        # Assertions
        assert fetched_count == 1
        assert Article.objects.filter(original_url="https://example.com/test-haber").exists()

        article = Article.objects.get(original_url="https://example.com/test-haber")
        assert article.title == "Test Haber Başlığı"
        assert article.category == "Teknoloji"
        assert article.status == "draft"
        assert article.rss_source == self.rss_source

    @patch("news.tasks.feedparser.parse")
    def test_fetch_single_rss_duplicate(self, mock_parse):
        """Aynı haber zaten varsa test."""
        # Önce bir makale oluştur
        Article.objects.create(
            title="Mevcut Haber",
            slug="mevcut-haber",
            content="İçerik",
            category="Teknoloji",
            original_url="https://example.com/mevcut-haber",
            status="draft",
            published_at=timezone.now(),
        )

        # Mock RSS feed response (aynı URL)
        mock_entry = MagicMock()
        mock_entry.title = "Mevcut Haber"
        mock_entry.link = "https://example.com/mevcut-haber"
        mock_entry.summary = "İçerik"
        mock_entry.get = lambda key, default="": {"title": "Mevcut Haber", "summary": "İçerik"}.get(key, default)

        mock_feed = MagicMock()
        mock_feed.bozo = False
        mock_feed.entries = [mock_entry]

        mock_parse.return_value = mock_feed

        # Fonksiyonu çalıştır
        fetched_count = fetch_single_rss(self.rss_source)

        # Assertions - yeni makale eklenmemeli
        assert fetched_count == 0
        assert Article.objects.filter(original_url="https://example.com/mevcut-haber").count() == 1

    @patch("news.tasks.feedparser.parse")
    def test_fetch_single_rss_bozo_feed(self, mock_parse):
        """Hatalı RSS feed olduğunda test."""
        # Mock hatalı RSS feed
        mock_feed = MagicMock()
        mock_feed.bozo = True  # Parsing hatası
        mock_feed.entries = []

        mock_parse.return_value = mock_feed

        # Fonksiyonu çalıştır
        fetched_count = fetch_single_rss(self.rss_source)

        # Assertions - hata olsa bile fonksiyon çalışmalı
        assert fetched_count == 0

    @patch("news.tasks.feedparser.parse")
    def test_fetch_single_rss_empty_feed(self, mock_parse):
        """Boş RSS feed olduğunda test."""
        # Mock boş RSS feed
        mock_feed = MagicMock()
        mock_feed.bozo = False
        mock_feed.entries = []

        mock_parse.return_value = mock_feed

        # Fonksiyonu çalıştır
        fetched_count = fetch_single_rss(self.rss_source)

        # Assertions
        assert fetched_count == 0

    @patch("news.tasks.feedparser.parse")
    def test_fetch_single_rss_multiple_entries(self, mock_parse):
        """Birden fazla haber olduğunda test."""
        # Mock RSS feed with multiple entries
        mock_entries = []
        for i in range(3):
            mock_entry = MagicMock()
            mock_entry.title = f"Test Haber {i}"
            mock_entry.link = f"https://example.com/test-haber-{i}"
            mock_entry.summary = f"Test içerik {i}"
            mock_entry.get = lambda key, default="", idx=i: {
                "title": f"Test Haber {idx}",
                "summary": f"Test içerik {idx}",
            }.get(key, default)
            mock_entries.append(mock_entry)

        mock_feed = MagicMock()
        mock_feed.bozo = False
        mock_feed.entries = mock_entries

        mock_parse.return_value = mock_feed

        # Fonksiyonu çalıştır
        fetched_count = fetch_single_rss(self.rss_source)

        # Assertions
        assert fetched_count == 3
        assert Article.objects.count() == 3
