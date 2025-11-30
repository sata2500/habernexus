from django.contrib.sitemaps import Sitemap
from django.urls import reverse

from .models import Article, Author


class ArticleSitemap(Sitemap):
    """
    Makaleler için sitemap.
    """

    changefreq = "weekly"
    priority = 0.8
    protocol = "https"

    def items(self):
        return Article.objects.filter(status="published").order_by("-published_at")

    def lastmod(self, item):
        return item.updated_at

    def location(self, item):
        return item.get_absolute_url()


class AuthorSitemap(Sitemap):
    """
    Yazarlar için sitemap.
    """

    changefreq = "monthly"
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
        return ["home", "article_list", "about", "contact"]

    def location(self, item):
        return reverse(item)


# Sitemap sözlüğü
sitemaps = {
    "articles": ArticleSitemap,
    "authors": AuthorSitemap,
    "static": StaticSitemap,
}
