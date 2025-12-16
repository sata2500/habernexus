from django.contrib.sitemaps.views import sitemap
from django.urls import path

from . import views
from .sitemaps import sitemaps
from .views_newsletter import (
    NewsletterSubscribeView,
    NewsletterVerifyView,
    NewsletterUnsubscribeView,
    NewsletterPreferencesView,
)

app_name = "news"

urlpatterns = [
    # Ana sayfa
    path("", views.home, name="home"),
    # Haberler
    path("haberler/", views.ArticleListView.as_view(), name="article_list"),
    path("haber/<slug:slug>/", views.ArticleDetailView.as_view(), name="article_detail"),
    # Kategoriler
    path("kategori/<str:category>/", views.category_view, name="category"),
    # Yazarlar
    path("yazar/<slug:slug>/", views.author_detail, name="author_detail"),
    # Etiketler
    path("etiket/<slug:tag>/", views.tag_detail, name="tag_detail"),
    # Arama
    path("ara/", views.search, name="search"),
    # Statik Sayfalar
    path("hakkimizda/", views.about, name="about"),
    path("iletisim/", views.contact, name="contact"),
    path("gizlilik-politikasi/", views.privacy_policy, name="privacy_policy"),
    path("kullanim-kosullari/", views.terms_of_service, name="terms_of_service"),
    # Sitemap
    path("sitemap.xml", sitemap, {"sitemaps": sitemaps}, name="sitemap"),
    # Newsletter
    path("newsletter/subscribe/", NewsletterSubscribeView.as_view(), name="newsletter_subscribe"),
    path("newsletter/verify/<uuid:token>/", NewsletterVerifyView.as_view(), name="newsletter_verify"),
    path("newsletter/unsubscribe/<uuid:token>/", NewsletterUnsubscribeView.as_view(), name="newsletter_unsubscribe"),
    path("newsletter/preferences/<uuid:token>/", NewsletterPreferencesView.as_view(), name="newsletter_preferences"),
]
