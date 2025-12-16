"""\nHaberNexus v10.2 Middleware\nRequest işleme, monitoring ve güvenlik için middleware sınıfları.\n\nAuthor: Salih TANRISEVEN\nUpdated: December 2025\n"""

import logging
import threading
import time
import uuid
from typing import Callable, Optional

from django.conf import settings
from django.http import HttpRequest, HttpResponse, JsonResponse
from django.utils.deprecation import MiddlewareMixin

logger = logging.getLogger(__name__)

# Thread-local storage for request context
_thread_locals = threading.local()


def get_current_request() -> Optional[HttpRequest]:
    """Mevcut thread'deki request nesnesini döndür."""
    return getattr(_thread_locals, "request", None)


def set_current_request(request: Optional[HttpRequest]) -> None:
    """Mevcut thread'e request nesnesini ata."""
    _thread_locals.request = request


class RequestContextMiddleware(MiddlewareMixin):
    """
    Request context'i thread-local storage'a kaydeden middleware.
    Logging ve hata takibi için kullanılır.
    """

    def process_request(self, request: HttpRequest) -> None:
        # Unique request ID oluştur
        request.request_id = str(uuid.uuid4())[:8]
        request.start_time = time.time()

        # Thread-local storage'a kaydet
        set_current_request(request)

    def process_response(self, request: HttpRequest, response: HttpResponse) -> HttpResponse:
        # Request ID'yi response header'a ekle
        if hasattr(request, "request_id"):
            response["X-Request-ID"] = request.request_id

        # Thread-local storage'ı temizle
        set_current_request(None)

        return response

    def process_exception(self, request: HttpRequest, exception: Exception) -> None:
        # Hata durumunda da thread-local'ı temizle
        set_current_request(None)


class RequestLoggingMiddleware(MiddlewareMixin):
    """
    HTTP request'leri loglayan middleware.
    """

    def __init__(self, get_response: Callable = None):
        self.get_response = get_response
        self.logger = logging.getLogger("requests")

    def __call__(self, request: HttpRequest) -> HttpResponse:
        # Request başlangıç zamanı
        start_time = time.time()

        # Response al
        response = self.get_response(request)

        # Süreyi hesapla
        duration_ms = (time.time() - start_time) * 1000

        # Loglama (static dosyaları atla)
        if not self._should_skip_logging(request.path):
            self._log_request(request, response, duration_ms)

        return response

    def _should_skip_logging(self, path: str) -> bool:
        """Belirli path'leri loglama dışında bırak."""
        skip_prefixes = ["/static/", "/media/", "/favicon.ico", "/health"]
        return any(path.startswith(prefix) for prefix in skip_prefixes)

    def _log_request(self, request: HttpRequest, response: HttpResponse, duration_ms: float) -> None:
        """Request'i logla."""
        log_data = {
            "method": request.method,
            "path": request.path,
            "status_code": response.status_code,
            "duration_ms": round(duration_ms, 2),
            "user_agent": request.META.get("HTTP_USER_AGENT", "")[:200],
            "ip": self._get_client_ip(request),
            "request_id": getattr(request, "request_id", "-"),
        }

        if hasattr(request, "user") and request.user.is_authenticated:
            log_data["user_id"] = request.user.id

        if response.status_code >= 500:
            self.logger.error("Request failed", extra=log_data)
        elif response.status_code >= 400:
            self.logger.warning("Request error", extra=log_data)
        else:
            self.logger.info("Request completed", extra=log_data)

    def _get_client_ip(self, request: HttpRequest) -> str:
        """Client IP adresini al."""
        x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
        if x_forwarded_for:
            return x_forwarded_for.split(",")[0].strip()
        return request.META.get("REMOTE_ADDR", "-")


class SecurityHeadersMiddleware(MiddlewareMixin):
    """
    Güvenlik header'larını ekleyen middleware.
    """

    def process_response(self, request: HttpRequest, response: HttpResponse) -> HttpResponse:
        # Content Security Policy
        if not response.has_header("Content-Security-Policy"):
            response["Content-Security-Policy"] = (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net; "
                "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://fonts.googleapis.com; "
                "font-src 'self' https://fonts.gstatic.com; "
                "img-src 'self' data: https:; "
                "connect-src 'self' https://api.habernexus.com; "
                "frame-ancestors 'none';"
            )

        # X-Content-Type-Options
        if not response.has_header("X-Content-Type-Options"):
            response["X-Content-Type-Options"] = "nosniff"

        # X-Frame-Options
        if not response.has_header("X-Frame-Options"):
            response["X-Frame-Options"] = "DENY"

        # X-XSS-Protection
        if not response.has_header("X-XSS-Protection"):
            response["X-XSS-Protection"] = "1; mode=block"

        # Referrer-Policy
        if not response.has_header("Referrer-Policy"):
            response["Referrer-Policy"] = "strict-origin-when-cross-origin"

        # Permissions-Policy
        if not response.has_header("Permissions-Policy"):
            response["Permissions-Policy"] = (
                "accelerometer=(), camera=(), geolocation=(), gyroscope=(), "
                "magnetometer=(), microphone=(), payment=(), usb=()"
            )

        return response


class ErrorHandlingMiddleware(MiddlewareMixin):
    """
    Beklenmeyen hataları yakalayan ve uygun yanıt döndüren middleware.
    """

    def process_exception(self, request: HttpRequest, exception: Exception) -> Optional[HttpResponse]:
        from core.exceptions import HaberNexusException

        # HaberNexus özel hatalarını işle
        if isinstance(exception, HaberNexusException):
            logger.warning(
                f"HaberNexus Exception: {exception.code}",
                extra={
                    "code": exception.code,
                    "message": exception.message,
                    "details": exception.details,
                    "request_id": getattr(request, "request_id", "-"),
                },
            )

            if request.content_type == "application/json" or request.path.startswith("/api/"):
                return JsonResponse(exception.to_dict(), status=exception.http_status)

        # Beklenmeyen hatalar için
        logger.error(
            f"Unhandled exception: {type(exception).__name__}",
            exc_info=True,
            extra={
                "request_id": getattr(request, "request_id", "-"),
                "path": request.path,
                "method": request.method,
            },
        )

        # API istekleri için JSON yanıt
        if request.content_type == "application/json" or request.path.startswith("/api/"):
            error_message = str(exception) if settings.DEBUG else "Beklenmeyen bir hata oluştu."
            return JsonResponse(
                {
                    "error": True,
                    "code": "internal_error",
                    "message": error_message,
                    "request_id": getattr(request, "request_id", "-"),
                },
                status=500,
            )

        # Normal istekler için None döndür (Django'nun varsayılan hata sayfası)
        return None


class PerformanceMonitoringMiddleware(MiddlewareMixin):
    """
    Performans metriklerini izleyen middleware.
    """

    # Yavaş istek eşiği (ms)
    SLOW_REQUEST_THRESHOLD = 1000

    def __init__(self, get_response: Callable = None):
        self.get_response = get_response
        self.logger = logging.getLogger("performance")

    def __call__(self, request: HttpRequest) -> HttpResponse:
        start_time = time.time()

        response = self.get_response(request)

        duration_ms = (time.time() - start_time) * 1000

        # Yavaş istekleri logla
        if duration_ms > self.SLOW_REQUEST_THRESHOLD:
            self.logger.warning(
                f"Slow request detected: {request.path}",
                extra={
                    "path": request.path,
                    "method": request.method,
                    "duration_ms": round(duration_ms, 2),
                    "request_id": getattr(request, "request_id", "-"),
                },
            )

        # Performance header ekle
        response["X-Response-Time"] = f"{round(duration_ms, 2)}ms"

        return response


class MaintenanceModeMiddleware(MiddlewareMixin):
    """
    Bakım modu için middleware.
    """

    def process_request(self, request: HttpRequest) -> Optional[HttpResponse]:
        # Bakım modu aktif mi kontrol et
        maintenance_mode = getattr(settings, "MAINTENANCE_MODE", False)

        if maintenance_mode:
            # Admin ve health check isteklerini atla
            allowed_paths = ["/admin/", "/api/health/", "/health/"]
            if any(request.path.startswith(path) for path in allowed_paths):
                return None

            # Bakım modu yanıtı
            if request.path.startswith("/api/"):
                return JsonResponse(
                    {
                        "error": True,
                        "code": "maintenance_mode",
                        "message": "Sistem bakımda. Lütfen daha sonra tekrar deneyin.",
                    },
                    status=503,
                )

            # HTML yanıt için template render edilebilir
            from django.shortcuts import render

            return render(request, "maintenance.html", status=503)

        return None


class RateLimitMiddleware(MiddlewareMixin):
    """
    Basit rate limiting middleware.
    Redis tabanlı rate limiting için django-ratelimit kullanılabilir.
    """

    # Varsayılan limitler
    DEFAULT_RATE_LIMIT = 100  # istek/dakika
    API_RATE_LIMIT = 60  # API istekleri için

    def __init__(self, get_response: Callable = None):
        self.get_response = get_response
        self._request_counts = {}  # In-memory cache (production'da Redis kullanın)

    def __call__(self, request: HttpRequest) -> HttpResponse:
        client_ip = self._get_client_ip(request)
        current_minute = int(time.time() / 60)
        cache_key = f"{client_ip}:{current_minute}"

        # Rate limit kontrolü
        is_api = request.path.startswith("/api/")
        limit = self.API_RATE_LIMIT if is_api else self.DEFAULT_RATE_LIMIT

        # İstek sayısını kontrol et
        count = self._request_counts.get(cache_key, 0)
        if count >= limit:
            logger.warning(
                f"Rate limit exceeded for {client_ip}",
                extra={
                    "ip": client_ip,
                    "path": request.path,
                    "count": count,
                    "limit": limit,
                },
            )
            return JsonResponse(
                {
                    "error": True,
                    "code": "rate_limit_exceeded",
                    "message": "Çok fazla istek gönderdiniz. Lütfen bir dakika bekleyin.",
                },
                status=429,
            )

        # İstek sayısını artır
        self._request_counts[cache_key] = count + 1

        # Eski kayıtları temizle (basit garbage collection)
        self._cleanup_old_entries(current_minute)

        response = self.get_response(request)

        # Rate limit header'ları ekle
        response["X-RateLimit-Limit"] = str(limit)
        response["X-RateLimit-Remaining"] = str(max(0, limit - count - 1))

        return response

    def _get_client_ip(self, request: HttpRequest) -> str:
        """Client IP adresini al."""
        x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
        if x_forwarded_for:
            return x_forwarded_for.split(",")[0].strip()
        return request.META.get("REMOTE_ADDR", "unknown")

    def _cleanup_old_entries(self, current_minute: int) -> None:
        """Eski rate limit kayıtlarını temizle."""
        keys_to_delete = [key for key in self._request_counts.keys() if int(key.split(":")[1]) < current_minute - 1]
        for key in keys_to_delete:
            del self._request_counts[key]


class CORSMiddleware(MiddlewareMixin):
    """
    CORS (Cross-Origin Resource Sharing) middleware.
    django-cors-headers ile birlikte veya yerine kullanılabilir.
    """

    ALLOWED_ORIGINS = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "https://habernexus.com",
        "https://www.habernexus.com",
    ]

    def process_response(self, request: HttpRequest, response: HttpResponse) -> HttpResponse:
        origin = request.META.get("HTTP_ORIGIN")

        if origin in self.ALLOWED_ORIGINS:
            response["Access-Control-Allow-Origin"] = origin
            response["Access-Control-Allow-Credentials"] = "true"
            response["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
            response["Access-Control-Allow-Headers"] = (
                "Accept, Accept-Language, Content-Language, Content-Type, "
                "Authorization, X-Requested-With, X-CSRFToken"
            )
            response["Access-Control-Max-Age"] = "86400"  # 24 saat

        return response

    def process_request(self, request: HttpRequest) -> Optional[HttpResponse]:
        # OPTIONS preflight isteklerini işle
        if request.method == "OPTIONS":
            response = HttpResponse()
            origin = request.META.get("HTTP_ORIGIN")
            if origin in self.ALLOWED_ORIGINS:
                response["Access-Control-Allow-Origin"] = origin
                response["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
                response["Access-Control-Allow-Headers"] = (
                    "Accept, Accept-Language, Content-Language, Content-Type, "
                    "Authorization, X-Requested-With, X-CSRFToken"
                )
                response["Access-Control-Max-Age"] = "86400"
            return response
        return None
