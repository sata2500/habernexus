from django.shortcuts import render, get_object_or_404
from django.views.generic import ListView, DetailView
from django.db.models import Q
from django.core.paginator import Paginator
from django.utils import timezone
from .models import Article, RssSource


class ArticleListView(ListView):
    """
    Tüm yayınlanan haberleri listele.
    """
    model = Article
    template_name = 'article_list.html'
    context_object_name = 'articles'
    paginate_by = 10
    
    def get_queryset(self):
        return Article.objects.filter(
            status='published'
        ).select_related('author', 'rss_source').order_by('-published_at')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['featured_articles'] = Article.objects.filter(
            status='published'
        ).order_by('-views_count')[:3]
        return context


class ArticleDetailView(DetailView):
    """
    Tek bir haberin detaylı görünümü.
    """
    model = Article
    template_name = 'article_detail.html'
    context_object_name = 'article'
    slug_field = 'slug'
    slug_url_kwarg = 'slug'
    
    def get_queryset(self):
        return Article.objects.filter(status='published').select_related('author', 'rss_source')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        article = self.object
        
        # Görüntülenme sayısını artır
        article.views_count += 1
        article.save(update_fields=['views_count'])
        
        # İlgili haberleri bul (aynı kategori, farklı makale)
        context['related_articles'] = Article.objects.filter(
            status='published',
            category=article.category
        ).exclude(id=article.id).order_by('-published_at')[:5]
        
        # Önceki ve sonraki makaleler
        previous_article = Article.objects.filter(
            status='published',
            published_at__lt=article.published_at
        ).order_by('-published_at').first()
        
        next_article = Article.objects.filter(
            status='published',
            published_at__gt=article.published_at
        ).order_by('published_at').first()
        
        context['previous_article'] = previous_article
        context['next_article'] = next_article
        
        return context


def home(request):
    """
    Ana sayfa görünümü.
    """
    featured_articles = Article.objects.filter(
        status='published'
    ).order_by('-views_count')[:3]
    
    latest_articles = Article.objects.filter(
        status='published'
    ).order_by('-published_at')[:10]
    
    context = {
        'featured_articles': featured_articles,
        'latest_articles': latest_articles,
    }
    
    return render(request, 'home.html', context)


def category_view(request, category):
    """
    Kategoriye göre haberleri listele.
    """
    articles = Article.objects.filter(
        status='published',
        category=category
    ).order_by('-published_at')
    
    paginator = Paginator(articles, 10)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    context = {
        'category': category,
        'page_obj': page_obj,
        'articles': page_obj.object_list,
    }
    
    return render(request, 'category.html', context)


def author_detail(request, slug):
    """
    Yazarın tüm haberlerini listele.
    """
    from authors.models import Author
    author = get_object_or_404(Author, slug=slug, is_active=True)
    
    articles = Article.objects.filter(
        status='published',
        author=author
    ).order_by('-published_at')
    
    paginator = Paginator(articles, 10)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    context = {
        'author': author,
        'page_obj': page_obj,
        'articles': page_obj.object_list,
    }
    
    return render(request, 'author_detail.html', context)


def search(request):
    """
    Haberlerde arama yap.
    """
    query = request.GET.get('q', '')
    articles = Article.objects.none()
    
    if query:
        articles = Article.objects.filter(
            status='published'
        ).filter(
            Q(title__icontains=query) |
            Q(content__icontains=query) |
            Q(excerpt__icontains=query) |
            Q(tags__icontains=query)
        ).order_by('-published_at')
    
    paginator = Paginator(articles, 10)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    context = {
        'query': query,
        'page_obj': page_obj,
        'articles': page_obj.object_list,
    }
    
    return render(request, 'search.html', context)


def about(request):
    """
    Hakkımızda sayfası.
    """
    return render(request, 'about.html')


def contact(request):
    """
    İletişim sayfası.
    """
    if request.method == 'POST':
        # İletişim formu işleme (daha sonra geliştirilecek)
        pass
    
    return render(request, 'contact.html')


def tag_detail(request, tag):
    """
    Etikete göre haberleri listele.
    """
    articles = Article.objects.filter(
        status='published',
        tags__icontains=tag
    ).order_by('-published_at')
    
    paginator = Paginator(articles, 10)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    context = {
        'tag': tag,
        'page_obj': page_obj,
        'articles': page_obj.object_list,
    }
    
    return render(request, 'tag_detail.html', context)
