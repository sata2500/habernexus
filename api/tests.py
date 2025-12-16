"""
HaberNexus API Tests
REST API endpoint'leri için test sınıfları.
"""

from django.test import TestCase
from django.urls import reverse

from rest_framework import status
from rest_framework.test import APITestCase

from authors.models import Author
from news.models import Article


class ArticleAPITests(APITestCase):
    """
    Article API endpoint testleri.
    """

    def setUp(self):
        """Test verilerini oluştur."""
        self.author = Author.objects.create(
            name="Test Yazar",
            slug="test-yazar",
            bio="Test bio",
            expertise="Teknoloji",
            is_active=True,
        )

        self.article = Article.objects.create(
            title="Test Haber",
            slug="test-haber",
            content="<p>Test içerik</p>",
            excerpt="Test özet",
            category="Teknoloji",
            author=self.author,
            status="published",
            is_ai_generated=True,
        )

    def test_list_articles(self):
        """Haber listesi endpoint'ini test et."""
        url = reverse("api:article-list")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("results", response.data)

    def test_retrieve_article(self):
        """Haber detay endpoint'ini test et."""
        url = reverse("api:article-detail", kwargs={"slug": self.article.slug})
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], "Test Haber")

    def test_featured_articles(self):
        """Öne çıkan haberler endpoint'ini test et."""
        url = reverse("api:article-featured")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_latest_articles(self):
        """En son haberler endpoint'ini test et."""
        url = reverse("api:article-latest")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_search_articles(self):
        """Arama endpoint'ini test et."""
        url = reverse("api:article-search")
        response = self.client.get(url, {"q": "Test"})

        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_search_articles_short_query(self):
        """Kısa arama terimi hata döndürmeli."""
        url = reverse("api:article-search")
        response = self.client.get(url, {"q": "T"})

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class AuthorAPITests(APITestCase):
    """
    Author API endpoint testleri.
    """

    def setUp(self):
        """Test verilerini oluştur."""
        self.author = Author.objects.create(
            name="Test Yazar",
            slug="test-yazar",
            bio="Test bio",
            expertise="Teknoloji",
            is_active=True,
        )

    def test_list_authors(self):
        """Yazar listesi endpoint'ini test et."""
        url = reverse("api:author-list")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_retrieve_author(self):
        """Yazar detay endpoint'ini test et."""
        url = reverse("api:author-detail", kwargs={"slug": self.author.slug})
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["name"], "Test Yazar")


class CategoryAPITests(APITestCase):
    """
    Category API endpoint testleri.
    """

    def test_list_categories(self):
        """Kategori listesi endpoint'ini test et."""
        url = reverse("api:category-list")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)


class StatsAPITests(APITestCase):
    """
    Stats API endpoint testleri.
    """

    def test_stats(self):
        """İstatistik endpoint'ini test et."""
        url = reverse("api:stats")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("total_articles", response.data)
        self.assertIn("total_authors", response.data)


class HealthCheckAPITests(APITestCase):
    """
    Health check API endpoint testleri.
    """

    def test_health_check(self):
        """Sağlık kontrolü endpoint'ini test et."""
        url = reverse("api:health")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "healthy")
        self.assertEqual(response.data["version"], "10.0")
