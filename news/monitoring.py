"""
İçerik Üretim Sistemi - Monitoring ve Analitik
Sistem performansını izlemek ve metrikler toplamak için araçlar.
"""

from datetime import timedelta

from django.core.cache import cache
from django.db.models import Avg, Count, Q, Sum
from django.utils import timezone

from .models import Article, RssSource
from .models_extended import ArticleClassification, ContentGenerationLog, HeadlineScore


class ContentGenerationMetrics:
    """
    İçerik üretim sisteminin metriklerini hesaplar ve izler.
    """

    @staticmethod
    def get_hourly_metrics(hours=24):
        """
        Son N saatin metriklerini al.
        """
        since = timezone.now() - timedelta(hours=hours)

        articles = Article.objects.filter(created_at__gte=since)
        headlines = HeadlineScore.objects.filter(created_at__gte=since)
        logs = ContentGenerationLog.objects.filter(created_at__gte=since)

        return {
            "articles_created": articles.count(),
            "articles_published": articles.filter(status="published").count(),
            "articles_draft": articles.filter(status="draft").count(),
            "headlines_processed": headlines.filter(is_processed=True).count(),
            "headlines_total": headlines.count(),
            "avg_quality_score": articles.aggregate(avg=Avg("quality_score"))["avg"] or 0,
            "avg_processing_time": logs.filter(status="completed").aggregate(avg=Avg("duration"))["avg"] or 0,
            "failed_tasks": logs.filter(status="failed").count(),
            "success_rate": ContentGenerationMetrics._calculate_success_rate(logs),
        }

    @staticmethod
    def get_daily_metrics(days=30):
        """
        Son N günün günlük metriklerini al.
        """
        since = timezone.now() - timedelta(days=days)

        articles = Article.objects.filter(created_at__gte=since)
        logs = ContentGenerationLog.objects.filter(created_at__gte=since)

        daily_data = []

        for i in range(days):
            date = timezone.now() - timedelta(days=i)
            date_start = date.replace(hour=0, minute=0, second=0, microsecond=0)
            date_end = date_start + timedelta(days=1)

            day_articles = articles.filter(created_at__gte=date_start, created_at__lt=date_end)

            day_logs = logs.filter(created_at__gte=date_start, created_at__lt=date_end)

            daily_data.append(
                {
                    "date": date_start.date(),
                    "articles_created": day_articles.count(),
                    "articles_published": day_articles.filter(status="published").count(),
                    "avg_quality_score": day_articles.aggregate(avg=Avg("quality_score"))["avg"] or 0,
                    "failed_tasks": day_logs.filter(status="failed").count(),
                }
            )

        return daily_data

    @staticmethod
    def get_category_metrics():
        """
        Kategoriye göre metrikler.
        """
        categories = (
            Article.objects.values("category")
            .annotate(
                count=Count("id"),
                avg_quality=Avg("quality_score"),
                published_count=Count("id", filter=Q(status="published")),
                avg_views=Avg("views_count"),
            )
            .order_by("-count")
        )

        return list(categories)

    @staticmethod
    def get_author_metrics():
        """
        Yazara göre metrikler.
        """
        authors = (
            Article.objects.values("author__name")
            .annotate(
                count=Count("id"),
                avg_quality=Avg("quality_score"),
                published_count=Count("id", filter=Q(status="published")),
                total_views=Sum("views_count"),
            )
            .order_by("-count")
        )

        return list(authors)

    @staticmethod
    def get_quality_distribution():
        """
        Kalite puanı dağılımı.
        """
        return {
            "excellent": Article.objects.filter(quality_score__gte=80).count(),
            "good": Article.objects.filter(quality_score__gte=60, quality_score__lt=80).count(),
            "average": Article.objects.filter(quality_score__gte=40, quality_score__lt=60).count(),
            "poor": Article.objects.filter(quality_score__lt=40).count(),
        }

    @staticmethod
    def get_article_type_distribution():
        """
        Makale türü dağılımı.
        """
        return (
            ArticleClassification.objects.values("article_type")
            .annotate(
                count=Count("id"),
                avg_quality=Avg("article__quality_score"),
            )
            .order_by("-count")
        )

    @staticmethod
    def get_headline_score_distribution():
        """
        Başlık puan dağılımı.
        """
        return {
            "excellent": HeadlineScore.objects.filter(overall_score__gte=80).count(),
            "good": HeadlineScore.objects.filter(overall_score__gte=60, overall_score__lt=80).count(),
            "average": HeadlineScore.objects.filter(overall_score__gte=40, overall_score__lt=60).count(),
            "poor": HeadlineScore.objects.filter(overall_score__lt=40).count(),
        }

    @staticmethod
    def get_rss_source_performance():
        """
        RSS kaynakları performansı.
        """
        sources = RssSource.objects.annotate(
            articles_count=Count("articles"),
            avg_quality=Avg("articles__quality_score"),
            published_count=Count("articles", filter=Q(articles__status="published")),
        ).order_by("-articles_count")

        return sources

    @staticmethod
    def get_processing_pipeline_stats():
        """
        İşlem hattı istatistikleri.
        """
        stages = (
            ContentGenerationLog.objects.values("stage")
            .annotate(
                total=Count("id"),
                completed=Count("id", filter=Q(status="completed")),
                failed=Count("id", filter=Q(status="failed")),
                avg_duration=Avg("duration"),
            )
            .order_by("stage")
        )

        return list(stages)

    @staticmethod
    def get_api_usage_stats():
        """
        API kullanım istatistikleri.
        """
        logs = ContentGenerationLog.objects.filter(status="completed").aggregate(
            total_calls=Sum("api_calls_count"),
            total_tokens=Sum("tokens_used"),
            avg_calls_per_task=Avg("api_calls_count"),
            avg_tokens_per_task=Avg("tokens_used"),
        )

        return logs

    @staticmethod
    def _calculate_success_rate(logs):
        """
        Başarı oranını hesapla.
        """
        total = logs.count()
        if total == 0:
            return 0

        completed = logs.filter(status="completed").count()
        return (completed / total) * 100

    @staticmethod
    def get_cached_metrics(cache_key="content_metrics", timeout=300):
        """
        Cache'lenmiş metrikleri al.
        """
        metrics = cache.get(cache_key)

        if metrics is None:
            metrics = {
                "hourly": ContentGenerationMetrics.get_hourly_metrics(),
                "categories": ContentGenerationMetrics.get_category_metrics(),
                "quality_distribution": ContentGenerationMetrics.get_quality_distribution(),
                "article_types": ContentGenerationMetrics.get_article_type_distribution(),
                "headline_distribution": ContentGenerationMetrics.get_headline_score_distribution(),
                "rss_performance": list(ContentGenerationMetrics.get_rss_source_performance()),
                "pipeline_stats": ContentGenerationMetrics.get_processing_pipeline_stats(),
            }

            cache.set(cache_key, metrics, timeout)

        return metrics


class ContentQualityAnalyzer:
    """
    İçerik kalitesini analiz eder ve iyileştirme önerileri sunar.
    """

    @staticmethod
    def analyze_article(article):
        """
        Makaleyi detaylı olarak analiz et.
        """
        try:
            metrics = article.quality_metrics
        except Exception:
            return None

        issues = []
        recommendations = []

        # Kelime sayısı kontrolü
        if metrics.word_count < 400:
            issues.append("Çok kısa makale (< 400 kelime)")
            recommendations.append("Makaleyi genişletmek için daha fazla detay ekleyin")
        elif metrics.word_count > 1000:
            issues.append("Çok uzun makale (> 1000 kelime)")
            recommendations.append("Makaleyi kısaltmak için gereksiz detayları çıkarın")

        # Okunabilirlik kontrolü
        if metrics.flesch_kincaid_grade > 14:
            issues.append("Çok zor okunabilirlik seviyesi")
            recommendations.append("Daha basit cümleler ve kelimeler kullanın")
        elif metrics.flesch_kincaid_grade < 6:
            issues.append("Çok basit okunabilirlik seviyesi")
            recommendations.append("Daha detaylı açıklamalar ekleyin")

        # Anahtar kelime yoğunluğu
        if metrics.keyword_density < 1.5:
            issues.append("Az anahtar kelime yoğunluğu")
            recommendations.append(f"'{metrics.primary_keyword}' kelimesini daha sık kullanın")
        elif metrics.keyword_density > 3.0:
            issues.append("Çok fazla anahtar kelime yoğunluğu")
            recommendations.append("Anahtar kelime istiflemesinden kaçının")

        # Yapı kontrolü
        if metrics.heading_count < 2:
            issues.append("Az sayıda başlık")
            recommendations.append("İçeriği organize etmek için daha fazla başlık ekleyin")

        if not metrics.has_lists:
            recommendations.append("Listeleri kullanarak içeriği daha okunabilir hale getirin")

        if metrics.image_count == 0:
            recommendations.append("Makaleyi görsel olarak desteklemek için görseller ekleyin")

        return {
            "article_id": article.id,
            "article_title": article.title,
            "overall_score": metrics.overall_quality_score,
            "issues": issues,
            "recommendations": recommendations,
            "metrics": {
                "word_count": metrics.word_count,
                "readability": metrics.flesch_kincaid_grade,
                "keyword_density": metrics.keyword_density,
                "heading_count": metrics.heading_count,
                "image_count": metrics.image_count,
            },
        }

    @staticmethod
    def get_improvement_suggestions(article):
        """
        Makale iyileştirmesi için öneriler al.
        """
        analysis = ContentQualityAnalyzer.analyze_article(article)

        if not analysis:
            return []

        suggestions = []

        # Kalite puanına göre öneriler
        if analysis["overall_score"] < 60:
            suggestions.append(
                {
                    "priority": "high",
                    "message": "Makale kalitesi düşük, kapsamlı bir revizyon gereklidir",
                    "actions": analysis["recommendations"],
                }
            )
        elif analysis["overall_score"] < 75:
            suggestions.append(
                {
                    "priority": "medium",
                    "message": "Makale kalitesi orta düzey, iyileştirmeler yapılabilir",
                    "actions": analysis["recommendations"],
                }
            )

        return suggestions


class PerformanceMonitor:
    """
    Sistem performansını izler.
    """

    @staticmethod
    def get_task_performance(hours=24):
        """
        Görev performansı.
        """
        since = timezone.now() - timedelta(hours=hours)

        logs = ContentGenerationLog.objects.filter(created_at__gte=since)

        performance = {}

        for stage in [
            "fetch",
            "score",
            "classify",
            "research",
            "generate",
            "quality_check",
            "image_generation",
            "publish",
        ]:
            stage_logs = logs.filter(stage=stage)

            if stage_logs.exists():
                performance[stage] = {
                    "total": stage_logs.count(),
                    "completed": stage_logs.filter(status="completed").count(),
                    "failed": stage_logs.filter(status="failed").count(),
                    "avg_duration": stage_logs.filter(status="completed").aggregate(avg=Avg("duration"))["avg"] or 0,
                    "success_rate": (
                        stage_logs.filter(status="completed").count() / stage_logs.count() * 100
                        if stage_logs.count() > 0
                        else 0
                    ),
                }

        return performance

    @staticmethod
    def get_bottlenecks(hours=24):
        """
        Sistem darboğazlarını tespit et.
        """
        performance = PerformanceMonitor.get_task_performance(hours)

        bottlenecks = []

        for stage, stats in performance.items():
            # Başarısızlık oranı yüksekse
            if stats["success_rate"] < 90:
                bottlenecks.append(
                    {
                        "stage": stage,
                        "issue": "Yüksek başarısızlık oranı",
                        "rate": stats["success_rate"],
                        "failed_count": stats["failed"],
                    }
                )

            # Ortalama süre çok uzunsa
            if stats["avg_duration"] > 30000:  # 30 saniyeden fazla
                bottlenecks.append(
                    {
                        "stage": stage,
                        "issue": "Yavaş işlem",
                        "duration": stats["avg_duration"],
                    }
                )

        return sorted(bottlenecks, key=lambda x: x.get("rate", 0) or x.get("duration", 0), reverse=True)

    @staticmethod
    def get_health_status():
        """
        Sistem sağlık durumunu al.
        """
        metrics = ContentGenerationMetrics.get_hourly_metrics(hours=1)
        bottlenecks = PerformanceMonitor.get_bottlenecks(hours=1)

        # Sağlık puanı hesapla
        health_score = 100

        if metrics["success_rate"] < 95:
            health_score -= (95 - metrics["success_rate"]) * 0.5

        if metrics["failed_tasks"] > 5:
            health_score -= min(metrics["failed_tasks"] - 5, 20)

        if metrics["avg_quality_score"] < 70:
            health_score -= (70 - metrics["avg_quality_score"]) * 0.2

        if len(bottlenecks) > 0:
            health_score -= len(bottlenecks) * 5

        health_score = max(0, min(100, health_score))

        # Durum belirle
        if health_score >= 90:
            status = "excellent"
        elif health_score >= 75:
            status = "good"
        elif health_score >= 50:
            status = "warning"
        else:
            status = "critical"

        return {
            "health_score": round(health_score, 1),
            "status": status,
            "metrics": metrics,
            "bottlenecks": bottlenecks,
        }
