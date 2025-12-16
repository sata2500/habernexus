"""
HaberNexus API Serializers
REST API için veri serileştirme sınıfları.
"""

from rest_framework import serializers

from authors.models import Author
from news.models import Article, RssSource


class AuthorSerializer(serializers.ModelSerializer):
    """
    Yazar bilgilerini serileştiren sınıf.
    """

    articles_count = serializers.SerializerMethodField()
    profile_image_url = serializers.SerializerMethodField()

    class Meta:
        model = Author
        fields = [
            "id",
            "name",
            "slug",
            "bio",
            "expertise",
            "profile_image_url",
            "twitter",
            "linkedin",
            "articles_count",
            "is_active",
            "created_at",
        ]
        read_only_fields = ["id", "slug", "created_at", "articles_count"]

    def get_articles_count(self, obj):
        return obj.articles.filter(status="published").count()

    def get_profile_image_url(self, obj):
        if obj.profile_image:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.profile_image.url)
            return obj.profile_image.url
        return None


class AuthorListSerializer(serializers.ModelSerializer):
    """
    Yazar listesi için kısa serileştirme.
    """

    class Meta:
        model = Author
        fields = ["id", "name", "slug", "expertise"]


class RssSourceSerializer(serializers.ModelSerializer):
    """
    RSS kaynağı serileştirme sınıfı.
    """

    articles_count = serializers.SerializerMethodField()

    class Meta:
        model = RssSource
        fields = [
            "id",
            "name",
            "url",
            "category",
            "frequency_minutes",
            "is_active",
            "last_checked",
            "articles_count",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "last_checked", "created_at", "updated_at", "articles_count"]

    def get_articles_count(self, obj):
        return obj.articles.count()


class ArticleListSerializer(serializers.ModelSerializer):
    """
    Haber listesi için kısa serileştirme.
    Performans için optimize edilmiş.
    """

    author = AuthorListSerializer(read_only=True)
    featured_image_url = serializers.SerializerMethodField()

    class Meta:
        model = Article
        fields = [
            "id",
            "title",
            "slug",
            "excerpt",
            "featured_image_url",
            "category",
            "author",
            "views_count",
            "is_ai_generated",
            "published_at",
        ]

    def get_featured_image_url(self, obj):
        if obj.featured_image:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.featured_image.url)
            return obj.featured_image.url
        return None


class ArticleDetailSerializer(serializers.ModelSerializer):
    """
    Haber detayı için tam serileştirme.
    """

    author = AuthorSerializer(read_only=True)
    rss_source = RssSourceSerializer(read_only=True)
    featured_image_url = serializers.SerializerMethodField()
    tags_list = serializers.SerializerMethodField()
    related_articles = serializers.SerializerMethodField()

    class Meta:
        model = Article
        fields = [
            "id",
            "title",
            "slug",
            "content",
            "excerpt",
            "featured_image_url",
            "featured_image_alt",
            "category",
            "tags",
            "tags_list",
            "author",
            "rss_source",
            "original_url",
            "status",
            "is_ai_generated",
            "is_ai_image",
            "views_count",
            "created_at",
            "updated_at",
            "published_at",
            "related_articles",
        ]

    def get_featured_image_url(self, obj):
        if obj.featured_image:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.featured_image.url)
            return obj.featured_image.url
        return None

    def get_tags_list(self, obj):
        if obj.tags:
            return [tag.strip() for tag in obj.tags.split(",")]
        return []

    def get_related_articles(self, obj):
        related = (
            Article.objects.filter(status="published", category=obj.category)
            .exclude(id=obj.id)
            .select_related("author")
            .order_by("-published_at")[:5]
        )
        return ArticleListSerializer(related, many=True, context=self.context).data


class ArticleCreateSerializer(serializers.ModelSerializer):
    """
    Haber oluşturma için serileştirme.
    """

    class Meta:
        model = Article
        fields = [
            "title",
            "content",
            "excerpt",
            "featured_image",
            "featured_image_alt",
            "category",
            "tags",
            "author",
            "status",
        ]

    def create(self, validated_data):
        # Slug otomatik oluşturulacak
        return super().create(validated_data)


class ArticleUpdateSerializer(serializers.ModelSerializer):
    """
    Haber güncelleme için serileştirme.
    """

    class Meta:
        model = Article
        fields = [
            "title",
            "content",
            "excerpt",
            "featured_image",
            "featured_image_alt",
            "category",
            "tags",
            "author",
            "status",
        ]


class CategorySerializer(serializers.Serializer):
    """
    Kategori serileştirme (model yok, dinamik).
    """

    name = serializers.CharField()
    slug = serializers.CharField()
    articles_count = serializers.IntegerField()


class SearchSerializer(serializers.Serializer):
    """
    Arama sonuçları için serileştirme.
    """

    query = serializers.CharField(required=True, min_length=2)
    category = serializers.CharField(required=False)
    author = serializers.CharField(required=False)
    date_from = serializers.DateField(required=False)
    date_to = serializers.DateField(required=False)
