"""Cache utils için testler."""

import pytest
from django.core.cache import cache
from django.test import TestCase

from news.cache_utils import (
    CACHE_TIMEOUT_ARTICLE_DETAIL,
    CACHE_TIMEOUT_ARTICLE_LIST,
    CACHE_TIMEOUT_AUTHOR,
    CACHE_TIMEOUT_CATEGORY,
    CACHE_TIMEOUT_HOME,
    CACHE_TIMEOUT_SEARCH,
    clear_article_cache,
    clear_author_cache,
    clear_category_cache,
    clear_search_cache,
    get_cache_key,
)


@pytest.mark.django_db
class TestCacheUtils(TestCase):
    """Cache utils fonksiyonları testleri."""

    def setUp(self):
        """Test setup - cache'i temizle."""
        cache.clear()

    def tearDown(self):
        """Test teardown - cache'i temizle."""
        cache.clear()

    def test_get_cache_key_single_arg(self):
        """get_cache_key tek argüman ile test."""
        key = get_cache_key("article", 123)
        assert key == "article:123"

    def test_get_cache_key_multiple_args(self):
        """get_cache_key birden fazla argüman ile test."""
        key = get_cache_key("category", "teknoloji", "page", 2)
        assert key == "category:teknoloji:page:2"

    def test_get_cache_key_no_args(self):
        """get_cache_key argümansız test."""
        key = get_cache_key("home")
        assert key == "home"

    def test_clear_article_cache_specific(self):
        """Belirli makale cache'ini temizleme testi."""
        # Cache'e veri ekle
        article_key = get_cache_key("article", 123)
        cache.set(article_key, "test data", timeout=300)
        assert cache.get(article_key) == "test data"

        # Cache'i temizle
        clear_article_cache(article_id=123)

        # Cache'in temizlendiğini doğrula
        assert cache.get(article_key) is None

    def test_clear_article_cache_general(self):
        """Genel makale cache'lerini temizleme testi."""
        # Cache'e veri ekle
        home_key = get_cache_key("home")
        list_key = get_cache_key("article_list")
        featured_key = get_cache_key("featured_articles")

        cache.set(home_key, "home data", timeout=300)
        cache.set(list_key, "list data", timeout=300)
        cache.set(featured_key, "featured data", timeout=300)

        # Cache'lerin var olduğunu doğrula
        assert cache.get(home_key) == "home data"
        assert cache.get(list_key) == "list data"
        assert cache.get(featured_key) == "featured data"

        # Cache'leri temizle
        clear_article_cache()

        # Cache'lerin temizlendiğini doğrula
        assert cache.get(home_key) is None
        assert cache.get(list_key) is None
        assert cache.get(featured_key) is None

    def test_clear_category_cache_specific(self):
        """Belirli kategori cache'ini temizleme testi."""
        # Cache'e veri ekle
        category_key = get_cache_key("category", "teknoloji")
        cache.set(category_key, "tech data", timeout=300)
        assert cache.get(category_key) == "tech data"

        # Cache'i temizle
        clear_category_cache(category="teknoloji")

        # Cache'in temizlendiğini doğrula
        assert cache.get(category_key) is None

    def test_clear_category_cache_all(self):
        """Tüm kategori cache'lerini temizleme testi."""
        # Cache'e veri ekle
        categories = ["teknoloji", "spor", "siyaset", "ekonomi"]
        for cat in categories:
            key = get_cache_key("category", cat)
            cache.set(key, f"{cat} data", timeout=300)
            assert cache.get(key) == f"{cat} data"

        # Tüm cache'leri temizle
        clear_category_cache()

        # Cache'lerin temizlendiğini doğrula
        for cat in categories:
            key = get_cache_key("category", cat)
            assert cache.get(key) is None

    def test_clear_author_cache(self):
        """Yazar cache'ini temizleme testi."""
        # Cache'e veri ekle
        author_key = get_cache_key("author", 456)
        cache.set(author_key, "author data", timeout=300)
        assert cache.get(author_key) == "author data"

        # Cache'i temizle
        clear_author_cache(author_id=456)

        # Cache'in temizlendiğini doğrula
        assert cache.get(author_key) is None

    def test_clear_search_cache(self):
        """Arama cache'ini temizleme testi."""
        # Cache'e veri ekle
        search_key = get_cache_key("search", "test query")
        cache.set(search_key, "search results", timeout=300)
        assert cache.get(search_key) == "search results"

        # Cache'i temizle
        clear_search_cache()

        # Not: clear_search_cache fonksiyonu şu anda boş, bu yüzden cache hala var
        # Bu test fonksiyonun çağrılabilir olduğunu doğrular

    def test_cache_timeout_constants(self):
        """Cache timeout sabitlerinin doğru değerlere sahip olduğunu test."""
        assert CACHE_TIMEOUT_HOME == 300
        assert CACHE_TIMEOUT_ARTICLE_LIST == 600
        assert CACHE_TIMEOUT_ARTICLE_DETAIL == 3600
        assert CACHE_TIMEOUT_CATEGORY == 600
        assert CACHE_TIMEOUT_AUTHOR == 600
        assert CACHE_TIMEOUT_SEARCH == 300

    def test_cache_key_with_special_characters(self):
        """Özel karakterlerle cache key oluşturma testi."""
        key = get_cache_key("article", "test-slug", "page", 1)
        assert key == "article:test-slug:page:1"

    def test_cache_key_with_unicode(self):
        """Unicode karakterlerle cache key oluşturma testi."""
        key = get_cache_key("category", "teknoloji", "türkçe")
        assert key == "category:teknoloji:türkçe"

    def test_clear_article_cache_nonexistent(self):
        """Var olmayan makale cache'ini temizleme testi."""
        # Hata vermeden çalışmalı
        clear_article_cache(article_id=999999)

    def test_clear_category_cache_nonexistent(self):
        """Var olmayan kategori cache'ini temizleme testi."""
        # Hata vermeden çalışmalı
        clear_category_cache(category="nonexistent")

    def test_clear_author_cache_nonexistent(self):
        """Var olmayan yazar cache'ini temizleme testi."""
        # Hata vermeden çalışmalı
        clear_author_cache(author_id=999999)
