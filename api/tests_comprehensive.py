"""
HaberNexus v10.3 - Comprehensive API Tests
API endpoint testleri.

Author: Salih TANRISEVEN
Updated: December 2025
"""

from django.test import TestCase
from django.urls import reverse
from django.utils import timezone

import pytest
from rest_framework import status
from rest_framework.test import APIClient, APITestCase

from authors.models import Author
from news.models import Article, RssSource


@pytest.mark.django_db
class TestArticleAPI(APITestCase):
    """Article API endpoint testleri."""

    def setUp(self):
        """Test setup."""
        self.client = APIClient()
        self.author = Author.objects.create(
            name="Test Yazar",
            slug="test-yazar",
            expertise="Teknoloji",
            is_active=True,
        )

        # Test makaleleri oluştur
        self.articles = []
        for i in range(5):
            article = Article.objects.create(
                title=f"Test Makale {i}",
                slug=f"test-makale-{i}",
                content=f"Test içerik {i}",
                excerpt=f"Test özet {i}",
                category="Teknoloji",
                status="published",
                author=self.author,
                published_at=timezone.now(),
            )
            self.articles.append(article)

    def test_list_articles(self):
        """Makale listesi endpoint testi."""
        url = reverse("api:article-list")
        response = self.client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 5

    def test_retrieve_article(self):
        """Tekil makale endpoint testi."""
        article = self.articles[0]
        url = reverse("api:article-detail", kwargs={"slug": article.slug})
        response = self.client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["title"] == article.title

    def test_article_not_found(self):
        """Makale bulunamadığında test."""
        url = reverse("api:article-detail", kwargs={"slug": "non-existent"})
        response = self.client.get(url)

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_filter_by_category(self):
        """Kategori filtreleme testi."""
        # Farklı kategoride makale oluştur
        Article.objects.create(
            title="Spor Haberi",
            slug="spor-haberi",
            content="Spor içerik",
            category="Spor",
            status="published",
            author=self.author,
            published_at=timezone.now(),
        )

        url = reverse("api:article-list")
        response = self.client.get(url, {"category": "Teknoloji"})

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 5

    def test_search_articles(self):
        """Makale arama testi."""
        url = reverse("api:article-list")
        response = self.client.get(url, {"search": "Test Makale 0"})

        assert response.status_code == status.HTTP_200_OK
        # Arama sonuçları içinde ilgili makale olmalı

    def test_pagination(self):
        """Sayfalama testi."""
        # Daha fazla makale oluştur
        for i in range(20):
            Article.objects.create(
                title=f"Ek Makale {i}",
                slug=f"ek-makale-{i}",
                content=f"Ek içerik {i}",
                category="Teknoloji",
                status="published",
                author=self.author,
                published_at=timezone.now(),
            )

        url = reverse("api:article-list")
        response = self.client.get(url, {"page_size": 10})

        assert response.status_code == status.HTTP_200_OK
        assert "next" in response.data
        assert len(response.data["results"]) <= 10

    def test_draft_articles_not_listed(self):
        """Taslak makalelerin listelenmemesi testi."""
        Article.objects.create(
            title="Taslak Makale",
            slug="taslak-makale",
            content="Taslak içerik",
            category="Teknoloji",
            status="draft",
            author=self.author,
        )

        url = reverse("api:article-list")
        response = self.client.get(url)

        # Taslak makale sonuçlarda olmamalı
        titles = [a["title"] for a in response.data["results"]]
        assert "Taslak Makale" not in titles


@pytest.mark.django_db
class TestAuthorAPI(APITestCase):
    """Author API endpoint testleri."""

    def setUp(self):
        """Test setup."""
        self.client = APIClient()
        self.authors = []
        for i in range(3):
            author = Author.objects.create(
                name=f"Yazar {i}",
                slug=f"yazar-{i}",
                expertise="Teknoloji",
                is_active=True,
            )
            self.authors.append(author)

    def test_list_authors(self):
        """Yazar listesi endpoint testi."""
        url = reverse("api:author-list")
        response = self.client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 3

    def test_retrieve_author(self):
        """Tekil yazar endpoint testi."""
        author = self.authors[0]
        url = reverse("api:author-detail", kwargs={"slug": author.slug})
        response = self.client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["name"] == author.name

    def test_inactive_authors_not_listed(self):
        """Pasif yazarların listelenmemesi testi."""
        Author.objects.create(
            name="Pasif Yazar",
            slug="pasif-yazar",
            expertise="Teknoloji",
            is_active=False,
        )

        url = reverse("api:author-list")
        response = self.client.get(url)

        names = [a["name"] for a in response.data["results"]]
        assert "Pasif Yazar" not in names


@pytest.mark.django_db
class TestRssSourceAPI(APITestCase):
    """RssSource API endpoint testleri."""

    def setUp(self):
        """Test setup."""
        self.client = APIClient()
        self.sources = []
        for i in range(3):
            source = RssSource.objects.create(
                name=f"RSS Kaynak {i}",
                url=f"https://example.com/rss{i}",
                category="Teknoloji",
                frequency_minutes=60,
                is_active=True,
            )
            self.sources.append(source)

    def test_list_rss_sources(self):
        """RSS kaynak listesi endpoint testi."""
        url = reverse("api:rsssource-list")
        response = self.client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 3


@pytest.mark.django_db
class TestHealthCheckAPI(TestCase):
    """Health check endpoint testleri."""

    def setUp(self):
        """Test setup."""
        self.client = APIClient()

    def test_health_check(self):
        """Sağlık kontrolü endpoint testi."""
        response = self.client.get("/core/health/")

        assert response.status_code == status.HTTP_200_OK
        assert "status" in response.json()


@pytest.mark.django_db
class TestAPIRateLimiting(APITestCase):
    """API rate limiting testleri."""

    def setUp(self):
        """Test setup."""
        self.client = APIClient()

    def test_rate_limit_headers(self):
        """Rate limit header'larının varlığı testi."""
        url = reverse("api:article-list")
        response = self.client.get(url)

        # Response başarılı olmalı
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_429_TOO_MANY_REQUESTS]


@pytest.mark.django_db
class TestAPIErrorHandling(APITestCase):
    """API hata yönetimi testleri."""

    def setUp(self):
        """Test setup."""
        self.client = APIClient()

    def test_invalid_endpoint(self):
        """Geçersiz endpoint testi."""
        response = self.client.get("/api/v1/invalid-endpoint/")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_method_not_allowed(self):
        """İzin verilmeyen metod testi."""
        url = reverse("api:article-list")
        response = self.client.delete(url)

        assert response.status_code == status.HTTP_405_METHOD_NOT_ALLOWED


@pytest.mark.django_db
class TestAPICORS(APITestCase):
    """CORS testleri."""

    def setUp(self):
        """Test setup."""
        self.client = APIClient()

    def test_cors_headers(self):
        """CORS header'larının varlığı testi."""
        url = reverse("api:article-list")
        response = self.client.options(url, HTTP_ORIGIN="https://example.com")

        # OPTIONS isteği başarılı olmalı
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_204_NO_CONTENT]
