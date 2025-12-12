"""News views için testler."""

from django.test import Client, TestCase
from django.urls import reverse
from django.utils import timezone

import pytest

from authors.models import Author
from news.models import Article, RssSource


@pytest.mark.django_db
class TestArticleViews(TestCase):
    """Article view testleri."""

    def setUp(self):
        """Test setup."""
        self.client = Client()
        self.author = Author.objects.create(name="Test Yazar", slug="test-yazar", expertise="Teknoloji", is_active=True)
        self.rss_source = RssSource.objects.create(
            name="Test RSS", url="https://test.com/rss", category="teknoloji", is_active=True
        )

        self.article = Article.objects.create(
            title="Test Makale",
            slug="test-makale",
            content="Test içerik",
            excerpt="Test özet",
            author=self.author,
            rss_source=self.rss_source,
            category="teknoloji",
            tags="python,django,test",
            status="published",
            published_at=timezone.now(),
        )

    def test_home_view(self):
        """Ana sayfa view testi."""
        response = self.client.get("/")
        assert response.status_code == 200

    def test_article_list_view(self):
        """Makale listesi view testi."""
        response = self.client.get(reverse("news:article_list"))
        assert response.status_code == 200
        assert "articles" in response.context

    def test_article_detail_view(self):
        """Makale detay view testi."""
        response = self.client.get(reverse("news:article_detail", kwargs={"slug": self.article.slug}))
        assert response.status_code == 200
        assert response.context["article"] == self.article

    def test_article_detail_view_not_found(self):
        """Olmayan makale detay view testi."""
        response = self.client.get(reverse("news:article_detail", kwargs={"slug": "olmayan-makale"}))
        assert response.status_code == 404

    def test_search_view(self):
        """Arama view testi."""
        response = self.client.get(reverse("news:search"), {"q": "Test"})
        assert response.status_code == 200
        assert "articles" in response.context

    def test_search_view_empty_query(self):
        """Boş arama sorgusu testi."""
        response = self.client.get(reverse("news:search"))
        assert response.status_code == 200

    def test_category_view(self):
        """Kategori view'ı test."""
        response = self.client.get(reverse("news:category", kwargs={"category": "teknoloji"}))
        assert response.status_code == 200
        assert self.article in response.context["articles"]
        assert response.context["category"] == "teknoloji"

    def test_category_view_empty(self):
        """Boş kategori view'ı test."""
        response = self.client.get(reverse("news:category", kwargs={"category": "ekonomi"}))
        assert response.status_code == 200
        assert len(response.context["articles"]) == 0

    def test_author_detail_view(self):
        """Author detail view'ı test."""
        response = self.client.get(reverse("news:author_detail", kwargs={"slug": self.author.slug}))
        assert response.status_code == 200
        assert self.article in response.context["articles"]
        assert response.context["author"] == self.author

    def test_author_detail_view_not_found(self):
        """Olmayan yazar detail view'ı test."""
        response = self.client.get(reverse("news:author_detail", kwargs={"slug": "olmayan-yazar"}))
        assert response.status_code == 404

    def test_about_view(self):
        """About view'ı test."""
        response = self.client.get(reverse("news:about"))
        assert response.status_code == 200

    def test_contact_view_get(self):
        """Contact view GET test."""
        response = self.client.get(reverse("news:contact"))
        assert response.status_code == 200

    def test_contact_view_post(self):
        """Contact view POST test."""
        response = self.client.post(reverse("news:contact"), {"name": "Test", "email": "test@test.com"})
        assert response.status_code == 200

    def test_search_view_title_match(self):
        """Arama view'ı başlık eşleşmesi test."""
        response = self.client.get(reverse("news:search"), {"q": "Test Makale"})
        assert response.status_code == 200
        assert self.article in response.context["articles"]

    def test_search_view_content_match(self):
        """Arama view'ı içerik eşleşmesi test."""
        response = self.client.get(reverse("news:search"), {"q": "içerik"})
        assert response.status_code == 200
        assert self.article in response.context["articles"]

    def test_search_view_tags_match(self):
        """Arama view'ı tag eşleşmesi test."""
        response = self.client.get(reverse("news:search"), {"q": "django"})
        assert response.status_code == 200
        assert self.article in response.context["articles"]

    def test_category_view_pagination(self):
        """Kategori view pagination test."""
        # 15 makale oluştur (sayfa başına 10)
        for i in range(15):
            Article.objects.create(
                title=f"Makale {i}",
                slug=f"makale-{i}",
                content="İçerik",
                category="spor",
                status="published",
                author=self.author,
                rss_source=self.rss_source,
                published_at=timezone.now(),
            )

        response = self.client.get(reverse("news:category", kwargs={"category": "spor"}))
        assert response.status_code == 200
        assert len(response.context["articles"]) == 10

        # 2. sayfa
        response = self.client.get(reverse("news:category", kwargs={"category": "spor"}), {"page": 2})
        assert response.status_code == 200
        assert len(response.context["articles"]) == 5

    def test_search_view_pagination(self):
        """Arama view pagination test."""
        # 15 makale oluştur
        for i in range(15):
            Article.objects.create(
                title=f"Search Test {i}",
                slug=f"search-test-{i}",
                content="Search içerik",
                status="published",
                author=self.author,
                rss_source=self.rss_source,
                published_at=timezone.now(),
            )

        response = self.client.get(reverse("news:search"), {"q": "Search"})
        assert response.status_code == 200
        assert len(response.context["articles"]) == 10

    def test_author_detail_inactive(self):
        """İnaktif yazar detail view'ı test."""
        inactive_author = Author.objects.create(
            name="Inactive Author", slug="inactive-author", expertise="Test", is_active=False
        )
        response = self.client.get(reverse("news:author_detail", kwargs={"slug": inactive_author.slug}))
        assert response.status_code == 404
