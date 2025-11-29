from django.urls import path
from django.contrib.sitemaps.views import sitemap
from . import views
from .sitemaps import sitemaps

app_name = 'news'

urlpatterns = [
    # Ana sayfa
    path('', views.home, name='home'),
    
    # Haberler
    path('haberler/', views.ArticleListView.as_view(), name='article_list'),
    path('haber/<slug:slug>/', views.ArticleDetailView.as_view(), name='article_detail'),
    
    # Kategoriler
    path('kategori/<str:category>/', views.category_view, name='category'),
    
    # Yazarlar
    path('yazar/<slug:slug>/', views.author_detail, name='author_detail'),
    
    # Etiketler
    path('etiket/<slug:tag>/', views.tag_detail, name='tag_detail'),
    
    # Arama
    path('ara/', views.search, name='search'),
    
    # Statik Sayfalar
    path('hakkimizda/', views.about, name='about'),
    path('iletisim/', views.contact, name='contact'),
    
    # Sitemap
    path('sitemap.xml', sitemap, {'sitemaps': sitemaps}, name='sitemap'),
]
