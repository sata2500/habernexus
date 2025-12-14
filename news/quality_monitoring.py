"""
HaberNexus - Kalite Kontrol ve Monitoring Sistemi (v2.0)
Metrikleri, alertleri, performans izleme
"""

import logging
from datetime import timedelta
from statistics import mean, stdev
from typing import Dict, List

from django.core.mail import send_mail
from django.db.models import Avg, Count, Q
from django.utils import timezone

from news.models import Article
from news.models_advanced import MediaProcessingLog
from news.models_extended import ContentGenerationLog

logger = logging.getLogger(__name__)


# ============================================================================
# KALITE METRIKLERI
# ============================================================================


class QualityMetrics:
    """
    İçerik kalitesi metrikleri hesapla
    """

    @staticmethod
    def calculate_article_quality_score(article) -> float:
        """
        Makale kalite puanını hesapla (0-100)
        """
        score = 0

        # 1. İçerik uzunluğu (25 puan)
        word_count = len(article.content.split()) if article.content else 0
        if 600 <= word_count <= 1000:
            score += 25
        elif 400 <= word_count <= 1200:
            score += 20
        elif word_count >= 300:
            score += 15

        # 2. SEO (25 puan)
        try:
            seo = article.seo
            if seo.meta_description and seo.meta_keywords:
                score += 15
            if seo.og_title and seo.og_description:
                score += 10
        except Exception:
            pass

        # 3. Medya (20 puan)
        try:
            media = article.media
            if media.featured_image_avif or media.featured_image_webp:
                score += 15
            if media.summary_video_1080p or media.summary_video_720p:
                score += 5
        except Exception:
            pass

        # 4. Yayın durumu (15 puan)
        if article.status == "published":
            score += 15
        elif article.status == "draft":
            score += 5

        # 5. Kategori (15 puan)
        if article.category:
            score += 15

        return min(100, score)

    @staticmethod
    def calculate_pipeline_efficiency() -> Dict:
        """
        Pipeline verimliliğini hesapla
        """
        # Son 24 saatteki işlemler
        logs = ContentGenerationLog.objects.filter(created_at__gte=timezone.now() - timedelta(hours=24))

        total_steps = logs.count()
        completed_steps = logs.filter(status="completed").count()
        failed_steps = logs.filter(status="failed").count()

        success_rate = (completed_steps / total_steps * 100) if total_steps > 0 else 0

        # Ortalama işlem süresi
        completed_logs = logs.filter(status="completed")
        if completed_logs.exists():
            avg_duration = completed_logs.aggregate(Avg("duration"))["duration__avg"] or 0
        else:
            avg_duration = 0

        return {
            "total_steps": total_steps,
            "completed_steps": completed_steps,
            "failed_steps": failed_steps,
            "success_rate": success_rate,
            "average_duration": avg_duration,
            "period": "24_hours",
        }

    @staticmethod
    def calculate_media_processing_stats() -> Dict:
        """
        Medya işleme istatistikleri hesapla
        """
        logs = MediaProcessingLog.objects.filter(created_at__gte=timezone.now() - timedelta(hours=24))

        image_logs = logs.filter(media_type="image")
        video_logs = logs.filter(media_type="video")

        return {
            "images": {
                "total": image_logs.count(),
                "completed": image_logs.filter(status="completed").count(),
                "failed": image_logs.filter(status="failed").count(),
                "avg_compression": image_logs.filter(status="completed").aggregate(Avg("compression_ratio"))[
                    "compression_ratio__avg"
                ]
                or 0,
                "avg_processing_time": image_logs.filter(status="completed").aggregate(Avg("processing_time"))[
                    "processing_time__avg"
                ]
                or 0,
            },
            "videos": {
                "total": video_logs.count(),
                "completed": video_logs.filter(status="completed").count(),
                "failed": video_logs.filter(status="failed").count(),
                "avg_compression": video_logs.filter(status="completed").aggregate(Avg("compression_ratio"))[
                    "compression_ratio__avg"
                ]
                or 0,
                "avg_processing_time": video_logs.filter(status="completed").aggregate(Avg("processing_time"))[
                    "processing_time__avg"
                ]
                or 0,
            },
        }

    @staticmethod
    def get_category_performance() -> Dict:
        """
        Kategoriye göre performans metrikleri
        """
        articles = (
            Article.objects.filter(created_at__gte=timezone.now() - timedelta(days=7))
            .values("category")
            .annotate(
                count=Count("id"),
                avg_quality=Avg("quality_score"),
                published_count=Count("id", filter=Q(status="published")),
            )
        )

        return {
            category["category"]: {
                "total_articles": category["count"],
                "published_articles": category["published_count"],
                "avg_quality_score": category["avg_quality"] or 0,
                "publication_rate": (
                    (category["published_count"] / category["count"] * 100) if category["count"] > 0 else 0
                ),
            }
            for category in articles
        }


# ============================================================================
# ALERT SİSTEMİ
# ============================================================================


class AlertManager:
    """
    Sistem alertlerini yönet ve gönder
    """

    ALERT_THRESHOLDS = {
        "failure_rate": 0.10,  # %10'dan fazla başarısızlık
        "slow_processing": 300,  # 5 dakikadan fazla
        "low_quality_score": 40,  # 40'tan düşük kalite puanı
        "media_processing_failure": 0.20,  # %20'den fazla medya işleme hatası
    }

    @staticmethod
    def check_pipeline_health() -> List[Dict]:
        """
        Pipeline sağlığını kontrol et ve alert'ler oluştur
        """
        alerts = []

        # Başarısızlık oranı kontrolü
        metrics = QualityMetrics.calculate_pipeline_efficiency()
        if metrics["success_rate"] < (1 - AlertManager.ALERT_THRESHOLDS["failure_rate"]) * 100:
            alerts.append(
                {
                    "type": "high_failure_rate",
                    "severity": "critical",
                    "message": f"Pipeline başarısızlık oranı: {100 - metrics['success_rate']:.1f}%",
                    "value": 100 - metrics["success_rate"],
                    "threshold": AlertManager.ALERT_THRESHOLDS["failure_rate"] * 100,
                }
            )

        # Yavaş işleme kontrolü
        if metrics["average_duration"] > AlertManager.ALERT_THRESHOLDS["slow_processing"]:
            alerts.append(
                {
                    "type": "slow_processing",
                    "severity": "warning",
                    "message": f"Ortalama işlem süresi: {metrics['average_duration']:.1f}s",
                    "value": metrics["average_duration"],
                    "threshold": AlertManager.ALERT_THRESHOLDS["slow_processing"],
                }
            )

        # Medya işleme başarısızlığı
        media_stats = QualityMetrics.calculate_media_processing_stats()

        for media_type, stats in media_stats.items():
            if stats["total"] > 0:
                failure_rate = stats["failed"] / stats["total"]
                if failure_rate > AlertManager.ALERT_THRESHOLDS["media_processing_failure"]:
                    alerts.append(
                        {
                            "type": f"{media_type}_processing_failure",
                            "severity": "warning",
                            "message": f"{media_type.capitalize()} işleme başarısızlığı: {failure_rate*100:.1f}%",
                            "value": failure_rate * 100,
                            "threshold": AlertManager.ALERT_THRESHOLDS["media_processing_failure"] * 100,
                        }
                    )

        return alerts

    @staticmethod
    def check_content_quality() -> List[Dict]:
        """
        İçerik kalitesini kontrol et
        """
        alerts = []

        # Son 24 saatteki düşük kaliteli makaleler
        low_quality_articles = Article.objects.filter(
            created_at__gte=timezone.now() - timedelta(hours=24),
            quality_score__lt=AlertManager.ALERT_THRESHOLDS["low_quality_score"],
        ).count()

        if low_quality_articles > 0:
            alerts.append(
                {
                    "type": "low_quality_content",
                    "severity": "warning",
                    "message": f"Son 24 saatte {low_quality_articles} düşük kaliteli makale",
                    "value": low_quality_articles,
                    "threshold": 0,
                }
            )

        return alerts

    @staticmethod
    def send_alert_email(alert: Dict, recipients: List[str]):
        """
        Alert e-postası gönder
        """
        subject = f"[{alert['severity'].upper()}] HaberNexus Alert: {alert['type']}"

        message = f"""
Alert Tipi: {alert['type']}
Şiddet: {alert['severity']}
Mesaj: {alert['message']}

Değer: {alert['value']}
Eşik: {alert['threshold']}

Lütfen sistemi kontrol edin.
        """.strip()

        try:
            send_mail(subject, message, "noreply@habernexus.com", recipients, fail_silently=False)
            logger.info(f"Alert email sent: {subject}")
        except Exception as e:
            logger.error(f"Failed to send alert email: {str(e)}")


# ============================================================================
# DASHBOARD VERİLERİ
# ============================================================================


class DashboardData:
    """
    Dashboard için veri sağla
    """

    @staticmethod
    def get_overview_metrics() -> Dict:
        """
        Genel metrikleri al
        """
        now = timezone.now()

        # Zaman periyotları
        today = now.replace(hour=0, minute=0, second=0, microsecond=0)
        week_ago = now - timedelta(days=7)
        month_ago = now - timedelta(days=30)

        return {
            "today": {
                "total_articles": Article.objects.filter(created_at__gte=today).count(),
                "published_articles": Article.objects.filter(created_at__gte=today, status="published").count(),
                "avg_quality_score": Article.objects.filter(created_at__gte=today).aggregate(Avg("quality_score"))[
                    "quality_score__avg"
                ]
                or 0,
            },
            "this_week": {
                "total_articles": Article.objects.filter(created_at__gte=week_ago).count(),
                "published_articles": Article.objects.filter(created_at__gte=week_ago, status="published").count(),
                "avg_quality_score": Article.objects.filter(created_at__gte=week_ago).aggregate(Avg("quality_score"))[
                    "quality_score__avg"
                ]
                or 0,
            },
            "this_month": {
                "total_articles": Article.objects.filter(created_at__gte=month_ago).count(),
                "published_articles": Article.objects.filter(created_at__gte=month_ago, status="published").count(),
                "avg_quality_score": Article.objects.filter(created_at__gte=month_ago).aggregate(Avg("quality_score"))[
                    "quality_score__avg"
                ]
                or 0,
            },
        }

    @staticmethod
    def get_pipeline_status() -> Dict:
        """
        Pipeline durumunu al
        """
        metrics = QualityMetrics.calculate_pipeline_efficiency()

        return {
            "status": "healthy" if metrics["success_rate"] > 95 else "degraded",
            "success_rate": metrics["success_rate"],
            "total_processed": metrics["total_steps"],
            "failed_count": metrics["failed_steps"],
            "average_duration": metrics["average_duration"],
            "alerts": AlertManager.check_pipeline_health(),
        }

    @staticmethod
    def get_category_stats() -> Dict:
        """
        Kategori istatistikleri al
        """
        return QualityMetrics.get_category_performance()

    @staticmethod
    def get_media_stats() -> Dict:
        """
        Medya işleme istatistikleri al
        """
        return QualityMetrics.calculate_media_processing_stats()

    @staticmethod
    def get_top_articles(limit: int = 10) -> List[Dict]:
        """
        En iyi makaleleri al
        """
        articles = Article.objects.filter(
            created_at__gte=timezone.now() - timedelta(days=7), status="published"
        ).order_by("-quality_score")[:limit]

        return [
            {
                "id": article.id,
                "title": article.title,
                "category": article.category,
                "quality_score": article.quality_score,
                "published_at": article.published_at.isoformat() if article.published_at else None,
                "view_count": article.view_count or 0,
            }
            for article in articles
        ]

    @staticmethod
    def get_recent_alerts(limit: int = 10) -> List[Dict]:
        """
        Son alert'leri al
        """
        alerts = []

        # Pipeline alert'leri
        alerts.extend(AlertManager.check_pipeline_health())

        # İçerik kalitesi alert'leri
        alerts.extend(AlertManager.check_content_quality())

        # Tarihe göre sırala ve sınırla
        return sorted(alerts, key=lambda x: x.get("severity"), reverse=True)[:limit]


# ============================================================================
# PERFORMANS ANALİZİ
# ============================================================================


class PerformanceAnalyzer:
    """
    Sistem performansını analiz et
    """

    @staticmethod
    def analyze_step_performance(step: str, days: int = 7) -> Dict:
        """
        Belirli bir aşamanın performansını analiz et
        """
        logs = ContentGenerationLog.objects.filter(step=step, created_at__gte=timezone.now() - timedelta(days=days))

        if not logs.exists():
            return {}

        durations = [log.duration for log in logs if log.duration]

        return {
            "step": step,
            "total_runs": logs.count(),
            "successful_runs": logs.filter(status="completed").count(),
            "failed_runs": logs.filter(status="failed").count(),
            "success_rate": (logs.filter(status="completed").count() / logs.count() * 100) if logs.count() > 0 else 0,
            "avg_duration": mean(durations) if durations else 0,
            "min_duration": min(durations) if durations else 0,
            "max_duration": max(durations) if durations else 0,
            "std_deviation": stdev(durations) if len(durations) > 1 else 0,
            "period_days": days,
        }

    @staticmethod
    def get_bottlenecks(days: int = 7) -> List[Dict]:
        """
        Sistem darboğazlarını tespit et
        """
        steps = (
            ContentGenerationLog.objects.filter(created_at__gte=timezone.now() - timedelta(days=days))
            .values_list("step", flat=True)
            .distinct()
        )

        bottlenecks = []

        for step in steps:
            analysis = PerformanceAnalyzer.analyze_step_performance(step, days)

            # Eğer ortalama süre 60 saniyeden fazlaysa darboğaz
            if analysis.get("avg_duration", 0) > 60:
                bottlenecks.append(
                    {
                        "step": step,
                        "avg_duration": analysis["avg_duration"],
                        "severity": "critical" if analysis["avg_duration"] > 300 else "warning",
                    }
                )

        return sorted(bottlenecks, key=lambda x: x["avg_duration"], reverse=True)

    @staticmethod
    def get_optimization_recommendations() -> List[str]:
        """
        Optimizasyon önerileri sun
        """
        recommendations = []

        # Darboğazları analiz et
        bottlenecks = PerformanceAnalyzer.get_bottlenecks()

        for bottleneck in bottlenecks:
            step = bottleneck["step"]

            if step == "content_generation":
                recommendations.append(
                    "İçerik üretimi yavaş. Daha hızlı AI modeli (Gemini 2.5 Flash) kullanmayı düşün."
                )
            elif step == "image_generation":
                recommendations.append("Görsel üretimi yavaş. Batch processing'i etkinleştir veya CDN kullan.")
            elif step == "media_processing":
                recommendations.append("Medya işleme yavaş. FFmpeg parallelization'ını etkinleştir.")

        # Başarısızlık oranı yüksekse
        metrics = QualityMetrics.calculate_pipeline_efficiency()
        if metrics["success_rate"] < 90:
            recommendations.append(
                "Başarısızlık oranı yüksek. Hata loglarını kontrol et ve retry mekanizmasını iyileştir."
            )

        return recommendations
