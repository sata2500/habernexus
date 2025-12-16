"""
HaberNexus API URLs
REST API endpoint yönlendirmeleri.
"""

from django.urls import include, path

from rest_framework.routers import DefaultRouter

from .views import ArticleViewSet, AuthorViewSet, CategoryListView, HealthCheckView, RssSourceViewSet, StatsView

app_name = "api"

# Router ile ViewSet'leri kaydet
router = DefaultRouter()
router.register(r"articles", ArticleViewSet, basename="article")
router.register(r"authors", AuthorViewSet, basename="author")
router.register(r"rss-sources", RssSourceViewSet, basename="rss-source")

urlpatterns = [
    # Router URL'leri
    path("", include(router.urls)),
    # Özel endpoint'ler
    path("categories/", CategoryListView.as_view(), name="category-list"),
    path("stats/", StatsView.as_view(), name="stats"),
    path("health/", HealthCheckView.as_view(), name="health"),
]
