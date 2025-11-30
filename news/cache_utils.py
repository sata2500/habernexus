from functools import wraps

from django.core.cache import cache
from django.utils.text import slugify
from django.views.decorators.cache import cache_page

# Cache timeout değerleri (saniye cinsinden)
CACHE_TIMEOUT_HOME = 300  # 5 dakika
CACHE_TIMEOUT_ARTICLE_LIST = 600  # 10 dakika
CACHE_TIMEOUT_ARTICLE_DETAIL = 3600  # 1 saat
CACHE_TIMEOUT_CATEGORY = 600  # 10 dakika
CACHE_TIMEOUT_AUTHOR = 600  # 10 dakika
CACHE_TIMEOUT_SEARCH = 300  # 5 dakika


def get_cache_key(prefix, *args):
    """
    Cache anahtarı oluştur.
    """
    key_parts = [prefix] + [str(arg) for arg in args]
    return ":".join(key_parts)


def clear_article_cache(article_id=None):
    """
    Makale ile ilgili tüm cache'i temizle.
    """
    if article_id:
        # Belirli makale cache'ini temizle
        cache.delete(get_cache_key("article", article_id))

    # Genel cache'leri temizle
    cache.delete(get_cache_key("home"))
    cache.delete(get_cache_key("article_list"))
    cache.delete(get_cache_key("featured_articles"))


def clear_category_cache(category=None):
    """
    Kategori cache'ini temizle.
    """
    if category:
        cache.delete(get_cache_key("category", category))
    else:
        # Tüm kategori cache'lerini temizle
        for category_name in ["teknoloji", "spor", "siyaset", "ekonomi"]:
            cache.delete(get_cache_key("category", category_name))


def clear_author_cache(author_id=None):
    """
    Yazar cache'ini temizle.
    """
    if author_id:
        cache.delete(get_cache_key("author", author_id))


def clear_search_cache():
    """
    Arama cache'ini temizle.
    """
    # Arama cache'leri dinamik olduğu için genel bir temizlik yapıyoruz
    pass


def cache_view(timeout):
    """
    View'ı cache'leyen decorator.
    """

    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            # GET parametreleri ile cache anahtarı oluştur
            cache_key = f"view:{view_func.__name__}:{request.GET.urlencode()}"

            # Cache'den al
            response = cache.get(cache_key)
            if response:
                return response

            # Cache'de yoksa view'ı çalıştır
            response = view_func(request, *args, **kwargs)

            # Cache'e kaydet
            cache.set(cache_key, response, timeout)
            return response

        return wrapper

    return decorator


def get_featured_articles():
    """
    Öne çıkan makaleleri cache'den al veya oluştur.
    """
    cache_key = get_cache_key("featured_articles")
    articles = cache.get(cache_key)

    if articles is None:
        from .models import Article

        articles = Article.objects.filter(status="published").order_by("-views_count")[:3]

        cache.set(cache_key, articles, CACHE_TIMEOUT_ARTICLE_LIST)

    return articles


def get_latest_articles(limit=10):
    """
    Son makaleleri cache'den al veya oluştur.
    """
    cache_key = get_cache_key("latest_articles", limit)
    articles = cache.get(cache_key)

    if articles is None:
        from .models import Article

        articles = list(Article.objects.filter(status="published").order_by("-published_at")[:limit])

        cache.set(cache_key, articles, CACHE_TIMEOUT_ARTICLE_LIST)

    return articles


def get_category_articles(category, page=1, per_page=10):
    """
    Kategoriye göre makaleleri cache'den al veya oluştur.
    """
    cache_key = get_cache_key("category_articles", category, page)
    articles = cache.get(cache_key)

    if articles is None:
        from django.core.paginator import Paginator

        from .models import Article

        all_articles = Article.objects.filter(status="published", category=category).order_by("-published_at")

        paginator = Paginator(all_articles, per_page)
        articles = paginator.get_page(page)

        cache.set(cache_key, articles, CACHE_TIMEOUT_CATEGORY)

    return articles


def get_author_articles(author_id, page=1, per_page=10):
    """
    Yazara göre makaleleri cache'den al veya oluştur.
    """
    cache_key = get_cache_key("author_articles", author_id, page)
    articles = cache.get(cache_key)

    if articles is None:
        from django.core.paginator import Paginator

        from .models import Article

        all_articles = Article.objects.filter(status="published", author_id=author_id).order_by("-published_at")

        paginator = Paginator(all_articles, per_page)
        articles = paginator.get_page(page)

        cache.set(cache_key, articles, CACHE_TIMEOUT_AUTHOR)

    return articles


def get_article_detail(article_id):
    """
    Makale detayını cache'den al veya oluştur.
    """
    cache_key = get_cache_key("article_detail", article_id)
    article = cache.get(cache_key)

    if article is None:
        from .models import Article

        try:
            article = Article.objects.select_related("author", "rss_source").get(id=article_id, status="published")
            cache.set(cache_key, article, CACHE_TIMEOUT_ARTICLE_DETAIL)
        except Article.DoesNotExist:
            return None

    return article


def get_related_articles(article_id, category, limit=5):
    """
    İlgili makaleleri cache'den al veya oluştur.
    """
    cache_key = get_cache_key("related_articles", article_id, limit)
    articles = cache.get(cache_key)

    if articles is None:
        from .models import Article

        articles = list(
            Article.objects.filter(status="published", category=category)
            .exclude(id=article_id)
            .order_by("-published_at")[:limit]
        )

        cache.set(cache_key, articles, CACHE_TIMEOUT_ARTICLE_DETAIL)

    return articles
