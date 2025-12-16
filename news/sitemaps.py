"""
HaberNexus Sitemaps
SEO için sitemap yapılandırması.
"""

from django.contrib.sitemaps import Sitemap
from django.urls import reverse

from authors.models import Author

from .models import Article


class ArticleSitemap(Sitemap):
    """
    Makaleler için sitemap.
    Google News için optimize edilmiş.
    """

    changefreq = "daily"
    priority = 0.9
    protocol = "https"
    limit = 1000  # Her sitemap dosyasında maksimum 1000 URL

    def items(self):
        return Article.objects.filter(status="published").order_by("-published_at")

    def lastmod(self, item):
        return item.updated_at

    def location(self, item):
        return item.get_absolute_url()


class NewsSitemap(Sitemap):
    """
    Google News için özel sitemap.
    Son 2 günün haberlerini içerir.
    """

    changefreq = "always"
    priority = 1.0
    protocol = "https"

    def items(self):
        from django.utils import timezone
        from datetime import timedelta

        two_days_ago = timezone.now() - timedelta(days=2)
        return Article.objects.filter(status="published", published_at__gte=two_days_ago).order_by("-published_at")

    def lastmod(self, item):
        return item.published_at

    def location(self, item):
        return item.get_absolute_url()


class CategorySitemap(Sitemap):
    """
    Kategoriler için sitemap.
    """

    changefreq = "daily"
    priority = 0.7
    protocol = "https"

    def items(self):
        # Benzersiz kategorileri al
        categories = Article.objects.filter(status="published").values_list("category", flat=True).distinct()
        return list(categories)

    def location(self, item):
        return reverse("news:category", kwargs={"category": item})


class AuthorSitemap(Sitemap):
    """
    Yazarlar için sitemap.
    """

    changefreq = "weekly"
    priority = 0.6
    protocol = "https"

    def items(self):
        return Author.objects.filter(is_active=True).order_by("name")

    def lastmod(self, item):
        return item.updated_at

    def location(self, item):
        return item.get_absolute_url()


class StaticSitemap(Sitemap):
    """
    Statik sayfalar için sitemap.
    """

    changefreq = "monthly"
    priority = 0.5
    protocol = "https"

    def items(self):
        return [
            ("news:home", 1.0),
            ("news:article_list", 0.8),
            ("news:about", 0.4),
            ("news:contact", 0.4),
            ("news:privacy_policy", 0.3),
            ("news:terms_of_service", 0.3),
        ]

    def location(self, item):
        return reverse(item[0])

    def priority(self, item):
        return item[1]


# Sitemap sözlüğü
sitemaps = {
    "articles": ArticleSitemap,
    "news": NewsSitemap,
    "categories": CategorySitemap,
    "authors": AuthorSitemap,
    "static": StaticSitemap,
}
