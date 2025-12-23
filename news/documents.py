from django_elasticsearch_dsl import Document, fields
from django_elasticsearch_dsl.registries import registry

from .models import Article


@registry.register_document
class ArticleDocument(Document):
    author = fields.ObjectField(
        properties={
            "name": fields.TextField(),
            "expertise": fields.TextField(),
        }
    )

    rss_source = fields.ObjectField(
        properties={
            "name": fields.TextField(),
            "category": fields.TextField(),
        }
    )

    class Index:
        name = "articles"
        settings = {"number_of_shards": 1, "number_of_replicas": 0}

    class Django:
        model = Article
        fields = [
            "title",
            "slug",
            "content",
            "excerpt",
            "category",
            "tags",
            "status",
            "published_at",
            "views_count",
            "is_ai_generated",
        ]
        related_models = ["author", "rss_source"]

    def get_queryset(self):
        """Only index published articles"""
        return super().get_queryset().select_related("author", "rss_source").filter(status="published")
