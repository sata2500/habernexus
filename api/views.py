"""
HaberNexus API Views
REST API endpoint'leri için view sınıfları.
"""

from django.db.models import Count, Q
from django.utils import timezone

from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from authors.models import Author
from news.models import Article, RssSource

from .pagination import SmallResultsSetPagination, StandardResultsSetPagination
from .permissions import IsAdminOrReadOnly
from .serializers import (
    ArticleCreateSerializer,
    ArticleDetailSerializer,
    ArticleListSerializer,
    ArticleUpdateSerializer,
    AuthorSerializer,
    CategorySerializer,
    RssSourceSerializer,
)


class ArticleViewSet(viewsets.ModelViewSet):
    """
    Haber CRUD işlemleri için ViewSet.

    list: Tüm yayınlanan haberleri listele
    retrieve: Tek bir haberin detayını getir
    create: Yeni haber oluştur (admin)
    update: Haber güncelle (admin)
    destroy: Haber sil (admin)
    """

    queryset = Article.objects.all()
    permission_classes = [IsAdminOrReadOnly]
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ["category", "status", "is_ai_generated", "author"]
    search_fields = ["title", "content", "excerpt", "tags"]
    ordering_fields = ["published_at", "views_count", "created_at"]
    ordering = ["-published_at"]
    lookup_field = "slug"

    def get_queryset(self):
        queryset = Article.objects.select_related("author", "rss_source")

        # Sadece yayınlanan haberleri göster (admin hariç)
        if not self.request.user.is_staff:
            queryset = queryset.filter(status="published")

        return queryset

    def get_serializer_class(self):
        if self.action == "list":
            return ArticleListSerializer
        elif self.action == "create":
            return ArticleCreateSerializer
        elif self.action in ["update", "partial_update"]:
            return ArticleUpdateSerializer
        return ArticleDetailSerializer

    def retrieve(self, request, *args, **kwargs):
        """
        Haber detayını getir ve görüntülenme sayısını artır.
        """
        instance = self.get_object()

        # Görüntülenme sayısını artır
        instance.views_count += 1
        instance.save(update_fields=["views_count"])

        serializer = self.get_serializer(instance)
        return Response(serializer.data)

    @action(detail=False, methods=["get"])
    def featured(self, request):
        """
        Öne çıkan haberleri getir (en çok görüntülenen 6 haber).
        """
        featured = self.get_queryset().filter(status="published").order_by("-views_count")[:6]
        serializer = ArticleListSerializer(featured, many=True, context={"request": request})
        return Response(serializer.data)

    @action(detail=False, methods=["get"])
    def latest(self, request):
        """
        En son haberleri getir.
        """
        latest = self.get_queryset().filter(status="published").order_by("-published_at")[:10]
        serializer = ArticleListSerializer(latest, many=True, context={"request": request})
        return Response(serializer.data)

    @action(detail=False, methods=["get"])
    def by_category(self, request):
        """
        Kategoriye göre haberleri getir.
        Query param: category
        """
        category = request.query_params.get("category")
        if not category:
            return Response({"error": "category parametresi gerekli"}, status=status.HTTP_400_BAD_REQUEST)

        articles = self.get_queryset().filter(status="published", category=category).order_by("-published_at")
        page = self.paginate_queryset(articles)
        if page is not None:
            serializer = ArticleListSerializer(page, many=True, context={"request": request})
            return self.get_paginated_response(serializer.data)

        serializer = ArticleListSerializer(articles, many=True, context={"request": request})
        return Response(serializer.data)

    @action(detail=False, methods=["get"])
    def search(self, request):
        """
        Haberlerde arama yap.
        Query param: q (arama terimi)
        """
        query = request.query_params.get("q", "")
        if len(query) < 2:
            return Response({"error": "Arama terimi en az 2 karakter olmalı"}, status=status.HTTP_400_BAD_REQUEST)

        articles = (
            self.get_queryset()
            .filter(status="published")
            .filter(Q(title__icontains=query) | Q(content__icontains=query) | Q(tags__icontains=query))
            .order_by("-published_at")
        )

        page = self.paginate_queryset(articles)
        if page is not None:
            serializer = ArticleListSerializer(page, many=True, context={"request": request})
            return self.get_paginated_response(serializer.data)

        serializer = ArticleListSerializer(articles, many=True, context={"request": request})
        return Response(serializer.data)


class AuthorViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Yazar bilgileri için ViewSet (sadece okuma).

    list: Tüm aktif yazarları listele
    retrieve: Tek bir yazarın detayını getir
    """

    queryset = Author.objects.filter(is_active=True)
    serializer_class = AuthorSerializer
    permission_classes = [AllowAny]
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["name", "expertise"]
    ordering_fields = ["name", "created_at"]
    ordering = ["name"]
    lookup_field = "slug"

    @action(detail=True, methods=["get"])
    def articles(self, request, slug=None):
        """
        Yazarın haberlerini getir.
        """
        author = self.get_object()
        articles = Article.objects.filter(status="published", author=author).order_by("-published_at")

        page = self.paginate_queryset(articles)
        if page is not None:
            serializer = ArticleListSerializer(page, many=True, context={"request": request})
            return self.get_paginated_response(serializer.data)

        serializer = ArticleListSerializer(articles, many=True, context={"request": request})
        return Response(serializer.data)


class RssSourceViewSet(viewsets.ModelViewSet):
    """
    RSS kaynakları için ViewSet (admin only).

    list: Tüm RSS kaynaklarını listele
    retrieve: Tek bir kaynağın detayını getir
    create: Yeni kaynak ekle
    update: Kaynak güncelle
    destroy: Kaynak sil
    """

    queryset = RssSource.objects.all()
    serializer_class = RssSourceSerializer
    permission_classes = [IsAdminUser]
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ["category", "is_active"]
    search_fields = ["name", "url"]
    ordering = ["name"]


class CategoryListView(APIView):
    """
    Tüm kategorileri ve haber sayılarını listele.
    """

    permission_classes = [AllowAny]

    def get(self, request):
        categories = (
            Article.objects.filter(status="published")
            .values("category")
            .annotate(articles_count=Count("id"))
            .order_by("-articles_count")
        )

        result = []
        for cat in categories:
            result.append(
                {
                    "name": cat["category"],
                    "slug": cat["category"].lower().replace(" ", "-"),
                    "articles_count": cat["articles_count"],
                }
            )

        return Response(result)


class StatsView(APIView):
    """
    Site istatistiklerini getir.
    """

    permission_classes = [AllowAny]

    def get(self, request):
        total_articles = Article.objects.filter(status="published").count()
        total_views = Article.objects.filter(status="published").aggregate(total=Count("views_count"))["total"] or 0
        total_authors = Author.objects.filter(is_active=True).count()
        total_sources = RssSource.objects.filter(is_active=True).count()

        # Son 24 saat içinde yayınlanan haberler
        last_24h = timezone.now() - timezone.timedelta(hours=24)
        recent_articles = Article.objects.filter(status="published", published_at__gte=last_24h).count()

        # AI tarafından üretilen haberler
        ai_articles = Article.objects.filter(status="published", is_ai_generated=True).count()

        return Response(
            {
                "total_articles": total_articles,
                "total_views": total_views,
                "total_authors": total_authors,
                "total_sources": total_sources,
                "recent_articles_24h": recent_articles,
                "ai_generated_articles": ai_articles,
                "ai_percentage": round((ai_articles / total_articles * 100) if total_articles > 0 else 0, 1),
            }
        )


class HealthCheckView(APIView):
    """
    API sağlık kontrolü.
    """

    permission_classes = [AllowAny]

    def get(self, request):
        return Response(
            {
                "status": "healthy",
                "version": "10.0",
                "timestamp": timezone.now().isoformat(),
            }
        )
