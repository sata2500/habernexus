"""
HaberNexus Health Check
Sistem sağlık kontrolü endpoint'leri.
"""

import logging
import time
from typing import Any

from django.conf import settings
from django.core.cache import cache
from django.db import connection
from django.http import JsonResponse
from django.views import View

logger = logging.getLogger(__name__)


class HealthCheckView(View):
    """
    Sistem sağlık kontrolü view'ı.
    Kubernetes liveness ve readiness probe'ları için kullanılabilir.
    """

    def get(self, request) -> JsonResponse:
        """
        GET /health/
        Temel sağlık kontrolü - hızlı yanıt.
        """
        return JsonResponse(
            {
                "status": "healthy",
                "version": "10.0",
                "timestamp": time.time(),
            }
        )


class DetailedHealthCheckView(View):
    """
    Detaylı sistem sağlık kontrolü view'ı.
    Tüm bağımlılıkları kontrol eder.
    """

    def get(self, request) -> JsonResponse:
        """
        GET /health/detailed/
        Detaylı sağlık kontrolü - tüm bileşenleri kontrol eder.
        """
        checks = {}
        overall_status = "healthy"
        start_time = time.time()

        # Database check
        db_status = self._check_database()
        checks["database"] = db_status
        if db_status["status"] != "healthy":
            overall_status = "unhealthy"

        # Cache check
        cache_status = self._check_cache()
        checks["cache"] = cache_status
        if cache_status["status"] != "healthy":
            overall_status = "degraded" if overall_status == "healthy" else overall_status

        # Celery check
        celery_status = self._check_celery()
        checks["celery"] = celery_status
        if celery_status["status"] != "healthy":
            overall_status = "degraded" if overall_status == "healthy" else overall_status

        # Elasticsearch check
        es_status = self._check_elasticsearch()
        checks["elasticsearch"] = es_status
        if es_status["status"] != "healthy":
            overall_status = "degraded" if overall_status == "healthy" else overall_status

        # Disk space check
        disk_status = self._check_disk_space()
        checks["disk"] = disk_status
        if disk_status["status"] != "healthy":
            overall_status = "degraded" if overall_status == "healthy" else overall_status

        response_time = (time.time() - start_time) * 1000

        response_data = {
            "status": overall_status,
            "version": "10.0",
            "timestamp": time.time(),
            "response_time_ms": round(response_time, 2),
            "checks": checks,
        }

        status_code = 200 if overall_status == "healthy" else 503 if overall_status == "unhealthy" else 200

        return JsonResponse(response_data, status=status_code)

    def _check_database(self) -> dict[str, Any]:
        """Veritabanı bağlantısını kontrol et."""
        try:
            start = time.time()
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            latency = (time.time() - start) * 1000
            return {
                "status": "healthy",
                "latency_ms": round(latency, 2),
            }
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
            return {
                "status": "unhealthy",
                "error": str(e),
            }

    def _check_cache(self) -> dict[str, Any]:
        """Cache bağlantısını kontrol et."""
        try:
            start = time.time()
            cache.set("health_check", "ok", 10)
            value = cache.get("health_check")
            latency = (time.time() - start) * 1000

            if value == "ok":
                return {
                    "status": "healthy",
                    "latency_ms": round(latency, 2),
                }
            else:
                return {
                    "status": "unhealthy",
                    "error": "Cache read/write failed",
                }
        except Exception as e:
            logger.error(f"Cache health check failed: {e}")
            return {
                "status": "unhealthy",
                "error": str(e),
            }

    def _check_celery(self) -> dict[str, Any]:
        """Celery bağlantısını kontrol et."""
        try:
            from habernexus_config.celery import app

            start = time.time()
            inspect = app.control.inspect()
            stats = inspect.stats()
            latency = (time.time() - start) * 1000

            if stats:
                worker_count = len(stats)
                return {
                    "status": "healthy",
                    "workers": worker_count,
                    "latency_ms": round(latency, 2),
                }
            else:
                return {
                    "status": "degraded",
                    "error": "No workers available",
                }
        except Exception as e:
            logger.warning(f"Celery health check failed: {e}")
            return {
                "status": "degraded",
                "error": str(e),
            }

    def _check_elasticsearch(self) -> dict[str, Any]:
        """Elasticsearch bağlantısını kontrol et."""
        try:
            from elasticsearch import Elasticsearch

            es_host = settings.ELASTICSEARCH_DSL.get("default", {}).get("hosts", "localhost:9200")
            es = Elasticsearch([es_host])

            start = time.time()
            health = es.cluster.health()
            latency = (time.time() - start) * 1000

            status = health.get("status", "unknown")
            if status == "green":
                return {
                    "status": "healthy",
                    "cluster_status": status,
                    "latency_ms": round(latency, 2),
                }
            elif status == "yellow":
                return {
                    "status": "degraded",
                    "cluster_status": status,
                    "latency_ms": round(latency, 2),
                }
            else:
                return {
                    "status": "unhealthy",
                    "cluster_status": status,
                }
        except Exception as e:
            logger.warning(f"Elasticsearch health check failed: {e}")
            return {
                "status": "degraded",
                "error": str(e),
            }

    def _check_disk_space(self) -> dict[str, Any]:
        """Disk alanını kontrol et."""
        try:
            import shutil

            total, used, free = shutil.disk_usage("/")
            free_percent = (free / total) * 100

            if free_percent > 20:
                status = "healthy"
            elif free_percent > 10:
                status = "degraded"
            else:
                status = "unhealthy"

            return {
                "status": status,
                "total_gb": round(total / (1024**3), 2),
                "used_gb": round(used / (1024**3), 2),
                "free_gb": round(free / (1024**3), 2),
                "free_percent": round(free_percent, 2),
            }
        except Exception as e:
            logger.error(f"Disk space check failed: {e}")
            return {
                "status": "unknown",
                "error": str(e),
            }


class ReadinessCheckView(View):
    """
    Kubernetes readiness probe için view.
    Uygulama trafiği almaya hazır mı kontrol eder.
    """

    def get(self, request) -> JsonResponse:
        """
        GET /health/ready/
        Readiness kontrolü.
        """
        try:
            # Database bağlantısını kontrol et
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")

            return JsonResponse({"ready": True})
        except Exception as e:
            logger.error(f"Readiness check failed: {e}")
            return JsonResponse({"ready": False, "error": str(e)}, status=503)


class LivenessCheckView(View):
    """
    Kubernetes liveness probe için view.
    Uygulama çalışıyor mu kontrol eder.
    """

    def get(self, request) -> JsonResponse:
        """
        GET /health/live/
        Liveness kontrolü.
        """
        return JsonResponse({"alive": True})
