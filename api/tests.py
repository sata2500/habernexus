"""
HaberNexus API Tests
REST API endpoint'leri için test sınıfları.
"""

import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from authors.models import Author
from news.models import Article


@pytest.fixture
def api_client():
    """API client fixture."""
    return APIClient()


@pytest.fixture
def test_author(db):
    """Test yazar fixture."""
    return Author.objects.create(
        name="Test Yazar",
        slug="test-yazar",
        bio="Test bio",
        expertise="Teknoloji",
        is_active=True,
    )


@pytest.fixture
def test_article(db, test_author):
    """Test makale fixture."""
    from django.utils import timezone

    return Article.objects.create(
        title="Test Haber",
        slug="test-haber",
        content="<p>Test içerik</p>",
        excerpt="Test özet",
        category="Teknoloji",
        author=test_author,
        status="published",
        published_at=timezone.now(),
    )


@pytest.mark.django_db
class TestArticleAPI:
    """Article API endpoint testleri."""

    def test_list_articles(self, api_client, test_article):
        """Haber listesi endpoint'ini test et."""
        url = reverse("api:article-list")
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert "results" in response.data

    def test_retrieve_article(self, api_client, test_article):
        """Haber detay endpoint'ini test et."""
        url = reverse("api:article-detail", kwargs={"slug": test_article.slug})
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["title"] == "Test Haber"

    def test_featured_articles(self, api_client, test_article):
        """Öne çıkan haberler endpoint'ini test et."""
        url = reverse("api:article-featured")
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK

    def test_latest_articles(self, api_client, test_article):
        """En son haberler endpoint'ini test et."""
        url = reverse("api:article-latest")
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK

    def test_search_articles(self, api_client, test_article):
        """Arama endpoint'ini test et."""
        url = reverse("api:article-search")
        response = api_client.get(url, {"q": "Test"})

        assert response.status_code == status.HTTP_200_OK

    def test_search_articles_short_query(self, api_client):
        """Kısa arama terimi hata döndürmeli."""
        url = reverse("api:article-search")
        response = api_client.get(url, {"q": "T"})

        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestAuthorAPI:
    """Author API endpoint testleri."""

    def test_list_authors(self, api_client, test_author):
        """Yazar listesi endpoint'ini test et."""
        url = reverse("api:author-list")
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK

    def test_retrieve_author(self, api_client, test_author):
        """Yazar detay endpoint'ini test et."""
        url = reverse("api:author-detail", kwargs={"slug": test_author.slug})
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["name"] == "Test Yazar"


@pytest.mark.django_db
class TestCategoryAPI:
    """Category API endpoint testleri."""

    def test_list_categories(self, api_client):
        """Kategori listesi endpoint'ini test et."""
        url = reverse("api:category-list")
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK


@pytest.mark.django_db
class TestStatsAPI:
    """Stats API endpoint testleri."""

    def test_stats(self, api_client):
        """İstatistik endpoint'ini test et."""
        url = reverse("api:stats")
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert "total_articles" in response.data
        assert "total_authors" in response.data


@pytest.mark.django_db
class TestHealthCheckAPI:
    """Health check API endpoint testleri."""

    def test_health_check(self, api_client):
        """Sağlık kontrolü endpoint'ini test et."""
        url = reverse("api:health")
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["status"] == "healthy"
        assert response.data["version"] == "10.0"
