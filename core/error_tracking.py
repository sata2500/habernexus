"""
HaberNexus v10.4 - Error Tracking Module
Gelişmiş hata takibi ve Sentry entegrasyonu.

Author: Salih TANRISEVEN
Updated: December 2025
"""

import functools
import logging
import sys
import traceback
from collections.abc import Callable
from contextlib import contextmanager
from datetime import datetime
from typing import Any

from django.conf import settings
from django.db import connection
from django.http import HttpRequest

logger = logging.getLogger(__name__)


# =============================================================================
# Error Context Manager
# =============================================================================


class ErrorContext:
    """
    Hata bağlamı yönetimi için sınıf.
    Hata oluştuğunda ek bilgi toplar.
    """

    def __init__(self):
        self._context: dict[str, Any] = {}
        self._tags: dict[str, str] = {}
        self._breadcrumbs: list[dict[str, Any]] = []

    def set_context(self, key: str, value: Any) -> None:
        """Bağlam bilgisi ekle."""
        self._context[key] = value

    def set_tag(self, key: str, value: str) -> None:
        """Etiket ekle."""
        self._tags[key] = value

    def add_breadcrumb(
        self,
        message: str,
        category: str = "default",
        level: str = "info",
        data: dict | None = None,
    ) -> None:
        """Breadcrumb ekle (işlem geçmişi)."""
        self._breadcrumbs.append(
            {
                "timestamp": datetime.utcnow().isoformat(),
                "message": message,
                "category": category,
                "level": level,
                "data": data or {},
            }
        )
        # Son 50 breadcrumb'ı tut
        if len(self._breadcrumbs) > 50:
            self._breadcrumbs = self._breadcrumbs[-50:]

    def get_context(self) -> dict[str, Any]:
        """Tüm bağlam bilgisini döndür."""
        return {
            "context": self._context,
            "tags": self._tags,
            "breadcrumbs": self._breadcrumbs,
        }

    def clear(self) -> None:
        """Bağlamı temizle."""
        self._context.clear()
        self._tags.clear()
        self._breadcrumbs.clear()


# Global error context
_error_context = ErrorContext()


def get_error_context() -> ErrorContext:
    """Global error context'i döndür."""
    return _error_context


# =============================================================================
# Sentry Integration
# =============================================================================


def init_sentry() -> bool:
    """
    Sentry SDK'yı başlat.

    Returns:
        bool: Başlatma başarılı mı
    """
    sentry_dsn = getattr(settings, "SENTRY_DSN", None)

    if not sentry_dsn:
        logger.info("Sentry DSN not configured, skipping initialization")
        return False

    try:
        import sentry_sdk
        from sentry_sdk.integrations.celery import CeleryIntegration
        from sentry_sdk.integrations.django import DjangoIntegration
        from sentry_sdk.integrations.logging import LoggingIntegration
        from sentry_sdk.integrations.redis import RedisIntegration

        sentry_sdk.init(
            dsn=sentry_dsn,
            integrations=[
                DjangoIntegration(
                    transaction_style="url",
                    middleware_spans=True,
                    signals_spans=True,
                ),
                CeleryIntegration(
                    monitor_beat_tasks=True,
                    propagate_traces=True,
                ),
                LoggingIntegration(
                    level=logging.INFO,
                    event_level=logging.ERROR,
                ),
                RedisIntegration(),
            ],
            # Performance monitoring
            traces_sample_rate=getattr(settings, "SENTRY_TRACES_SAMPLE_RATE", 0.1),
            profiles_sample_rate=getattr(settings, "SENTRY_PROFILES_SAMPLE_RATE", 0.1),
            # Environment
            environment=getattr(settings, "ENVIRONMENT", "development"),
            release=getattr(settings, "VERSION", "10.4"),
            # Error filtering
            before_send=_before_send_filter,
            # Additional options
            send_default_pii=False,
            attach_stacktrace=True,
            max_breadcrumbs=50,
        )

        logger.info("Sentry initialized successfully")
        return True

    except ImportError:
        logger.warning("sentry-sdk not installed, skipping Sentry initialization")
        return False
    except Exception as e:
        logger.error(f"Failed to initialize Sentry: {e}")
        return False


def _before_send_filter(event: dict, hint: dict) -> dict | None:
    """
    Sentry'ye gönderilmeden önce event'leri filtrele.

    Args:
        event: Sentry event
        hint: Ek bilgiler

    Returns:
        Filtrelenmiş event veya None (göndermemek için)
    """
    # Belirli hataları filtrele
    if "exc_info" in hint:
        exc_type, exc_value, tb = hint["exc_info"]

        # 404 hatalarını gönderme
        if exc_type.__name__ == "Http404":
            return None

        # Rate limit hatalarını gönderme
        if exc_type.__name__ in ("RateLimitError", "APIRateLimitError"):
            return None

    # Hassas bilgileri temizle
    if "request" in event:
        request_data = event["request"]

        # Authorization header'ını maskele
        if "headers" in request_data:
            headers = request_data["headers"]
            if "Authorization" in headers:
                headers["Authorization"] = "[FILTERED]"
            if "Cookie" in headers:
                headers["Cookie"] = "[FILTERED]"

    return event


def capture_exception(
    exception: Exception,
    extra: dict | None = None,
    tags: dict | None = None,
) -> str | None:
    """
    Exception'ı Sentry'ye gönder.

    Args:
        exception: Yakalanacak exception
        extra: Ek bağlam bilgisi
        tags: Etiketler

    Returns:
        Sentry event ID veya None
    """
    try:
        import sentry_sdk

        with sentry_sdk.push_scope() as scope:
            # Ek bağlam ekle
            if extra:
                for key, value in extra.items():
                    scope.set_extra(key, value)

            # Etiketler ekle
            if tags:
                for key, value in tags.items():
                    scope.set_tag(key, value)

            # Global context'i ekle
            error_ctx = get_error_context()
            ctx_data = error_ctx.get_context()

            for key, value in ctx_data.get("context", {}).items():
                scope.set_extra(key, value)

            for key, value in ctx_data.get("tags", {}).items():
                scope.set_tag(key, value)

            for breadcrumb in ctx_data.get("breadcrumbs", []):
                sentry_sdk.add_breadcrumb(**breadcrumb)

            return sentry_sdk.capture_exception(exception)

    except ImportError:
        # Sentry yüklü değilse sadece logla
        logger.error(f"Exception captured (Sentry not available): {exception}", exc_info=True)
        return None
    except Exception as e:
        logger.error(f"Failed to capture exception in Sentry: {e}")
        return None


def capture_message(
    message: str,
    level: str = "info",
    extra: dict | None = None,
    tags: dict | None = None,
) -> str | None:
    """
    Mesajı Sentry'ye gönder.

    Args:
        message: Gönderilecek mesaj
        level: Log seviyesi (info, warning, error)
        extra: Ek bağlam bilgisi
        tags: Etiketler

    Returns:
        Sentry event ID veya None
    """
    try:
        import sentry_sdk

        with sentry_sdk.push_scope() as scope:
            if extra:
                for key, value in extra.items():
                    scope.set_extra(key, value)

            if tags:
                for key, value in tags.items():
                    scope.set_tag(key, value)

            return sentry_sdk.capture_message(message, level=level)

    except ImportError:
        logger.log(
            getattr(logging, level.upper(), logging.INFO),
            f"Message captured (Sentry not available): {message}",
        )
        return None
    except Exception as e:
        logger.error(f"Failed to capture message in Sentry: {e}")
        return None


# =============================================================================
# Error Tracking Decorators
# =============================================================================


def track_errors(
    operation_name: str,
    capture_to_sentry: bool = True,
    log_level: str = "error",
    reraise: bool = True,
) -> Callable:
    """
    Fonksiyonlardaki hataları izleyen dekoratör.

    Args:
        operation_name: İşlem adı
        capture_to_sentry: Sentry'ye gönder
        log_level: Log seviyesi
        reraise: Hatayı tekrar fırlat

    Usage:
        @track_errors("fetch_rss_feed")
        def fetch_feed(url):
            ...
    """

    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            error_ctx = get_error_context()
            error_ctx.add_breadcrumb(
                message=f"Starting {operation_name}",
                category="function",
                level="info",
            )

            try:
                result = func(*args, **kwargs)
                error_ctx.add_breadcrumb(
                    message=f"Completed {operation_name}",
                    category="function",
                    level="info",
                )
                return result

            except Exception as e:
                error_ctx.add_breadcrumb(
                    message=f"Error in {operation_name}: {e!s}",
                    category="function",
                    level="error",
                )

                # Logla
                log_func = getattr(logger, log_level, logger.error)
                log_func(
                    f"Error in {operation_name}: {type(e).__name__} - {e}",
                    exc_info=True,
                    extra={
                        "operation": operation_name,
                        "function": func.__name__,
                    },
                )

                # Sentry'ye gönder
                if capture_to_sentry:
                    capture_exception(
                        e,
                        extra={"operation": operation_name},
                        tags={"operation": operation_name},
                    )

                if reraise:
                    raise
                return None

        return wrapper

    return decorator


@contextmanager
def error_tracking_context(
    operation_name: str,
    extra: dict | None = None,
):
    """
    Hata takibi için context manager.

    Usage:
        with error_tracking_context("process_article", extra={"article_id": 123}):
            process_article(article)
    """
    error_ctx = get_error_context()

    # Bağlam bilgisi ekle
    error_ctx.set_context("operation", operation_name)
    if extra:
        for key, value in extra.items():
            error_ctx.set_context(key, value)

    error_ctx.add_breadcrumb(
        message=f"Entering context: {operation_name}",
        category="context",
        level="info",
    )

    try:
        yield error_ctx
        error_ctx.add_breadcrumb(
            message=f"Exiting context: {operation_name}",
            category="context",
            level="info",
        )
    except Exception as e:
        error_ctx.add_breadcrumb(
            message=f"Error in context {operation_name}: {e!s}",
            category="context",
            level="error",
        )
        capture_exception(e, extra={"operation": operation_name})
        raise


# =============================================================================
# Error Reporting
# =============================================================================


class ErrorReport:
    """
    Hata raporu oluşturma sınıfı.
    """

    def __init__(self, exception: Exception, request: HttpRequest | None = None):
        self.exception = exception
        self.request = request
        self.timestamp = datetime.utcnow()

    def to_dict(self) -> dict[str, Any]:
        """Hata raporunu dictionary olarak döndür."""
        report = {
            "timestamp": self.timestamp.isoformat(),
            "exception_type": type(self.exception).__name__,
            "exception_message": str(self.exception),
            "traceback": traceback.format_exc(),
        }

        # Request bilgisi ekle
        if self.request:
            report["request"] = {
                "method": self.request.method,
                "path": self.request.path,
                "user": str(self.request.user) if hasattr(self.request, "user") else None,
                "ip": self._get_client_ip(),
            }

        # Sistem bilgisi ekle
        report["system"] = {
            "python_version": sys.version,
            "django_version": settings.VERSION if hasattr(settings, "VERSION") else "unknown",
        }

        # Veritabanı bağlantı durumu
        try:
            connection.ensure_connection()
            report["database"] = {"status": "connected"}
        except Exception as e:
            report["database"] = {"status": "error", "error": str(e)}

        return report

    def _get_client_ip(self) -> str | None:
        """Client IP adresini al."""
        if not self.request:
            return None

        x_forwarded_for = self.request.META.get("HTTP_X_FORWARDED_FOR")
        if x_forwarded_for:
            return x_forwarded_for.split(",")[0].strip()
        return self.request.META.get("REMOTE_ADDR")


def create_error_report(
    exception: Exception,
    request: HttpRequest | None = None,
) -> dict[str, Any]:
    """
    Hata raporu oluştur.

    Args:
        exception: Yakalanan exception
        request: HTTP request (varsa)

    Returns:
        Hata raporu dictionary
    """
    report = ErrorReport(exception, request)
    return report.to_dict()


# =============================================================================
# Health Check Integration
# =============================================================================


def check_error_tracking_health() -> dict[str, Any]:
    """
    Hata takip sisteminin sağlık durumunu kontrol et.

    Returns:
        Sağlık durumu dictionary
    """
    health = {
        "status": "healthy",
        "sentry_configured": bool(getattr(settings, "SENTRY_DSN", None)),
        "sentry_initialized": False,
    }

    try:
        import sentry_sdk

        health["sentry_initialized"] = sentry_sdk.Hub.current.client is not None
    except ImportError:
        health["sentry_installed"] = False

    return health
