"""
HaberNexus Custom Exceptions
Özel hata sınıfları ve hata yakalama mekanizması.
"""

import logging
import traceback
from functools import wraps
from typing import Any, Callable, Optional

from django.conf import settings
from django.core.exceptions import PermissionDenied
from django.http import Http404, JsonResponse

from rest_framework import status
from rest_framework.exceptions import APIException
from rest_framework.response import Response
from rest_framework.views import exception_handler

logger = logging.getLogger(__name__)


# =============================================================================
# Custom Exception Classes
# =============================================================================


class HaberNexusException(Exception):
    """
    HaberNexus temel exception sınıfı.
    Tüm özel hatalar bu sınıftan türetilir.
    """

    default_message = "Bir hata oluştu."
    default_code = "error"
    http_status = status.HTTP_500_INTERNAL_SERVER_ERROR

    def __init__(self, message: Optional[str] = None, code: Optional[str] = None, details: Optional[dict] = None):
        self.message = message or self.default_message
        self.code = code or self.default_code
        self.details = details or {}
        super().__init__(self.message)

    def to_dict(self) -> dict:
        """Hatayı dictionary formatına dönüştür."""
        return {
            "error": True,
            "code": self.code,
            "message": self.message,
            "details": self.details,
        }


class ValidationError(HaberNexusException):
    """Doğrulama hatası."""

    default_message = "Geçersiz veri."
    default_code = "validation_error"
    http_status = status.HTTP_400_BAD_REQUEST


class NotFoundError(HaberNexusException):
    """Kaynak bulunamadı hatası."""

    default_message = "İstenen kaynak bulunamadı."
    default_code = "not_found"
    http_status = status.HTTP_404_NOT_FOUND


class AuthenticationError(HaberNexusException):
    """Kimlik doğrulama hatası."""

    default_message = "Kimlik doğrulama başarısız."
    default_code = "authentication_error"
    http_status = status.HTTP_401_UNAUTHORIZED


class PermissionError(HaberNexusException):
    """Yetki hatası."""

    default_message = "Bu işlem için yetkiniz yok."
    default_code = "permission_denied"
    http_status = status.HTTP_403_FORBIDDEN


class RateLimitError(HaberNexusException):
    """Rate limit hatası."""

    default_message = "Çok fazla istek gönderdiniz. Lütfen bekleyin."
    default_code = "rate_limit_exceeded"
    http_status = status.HTTP_429_TOO_MANY_REQUESTS


class ExternalServiceError(HaberNexusException):
    """Harici servis hatası."""

    default_message = "Harici servis hatası."
    default_code = "external_service_error"
    http_status = status.HTTP_502_BAD_GATEWAY


class AIServiceError(ExternalServiceError):
    """AI servis hatası."""

    default_message = "AI servisi şu anda kullanılamıyor."
    default_code = "ai_service_error"


class DatabaseError(HaberNexusException):
    """Veritabanı hatası."""

    default_message = "Veritabanı hatası oluştu."
    default_code = "database_error"
    http_status = status.HTTP_500_INTERNAL_SERVER_ERROR


class ConfigurationError(HaberNexusException):
    """Yapılandırma hatası."""

    default_message = "Sistem yapılandırma hatası."
    default_code = "configuration_error"
    http_status = status.HTTP_500_INTERNAL_SERVER_ERROR


# =============================================================================
# REST Framework Exception Classes
# =============================================================================


class APIValidationError(APIException):
    """REST API doğrulama hatası."""

    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = "Geçersiz veri."
    default_code = "validation_error"


class APINotFoundError(APIException):
    """REST API kaynak bulunamadı hatası."""

    status_code = status.HTTP_404_NOT_FOUND
    default_detail = "İstenen kaynak bulunamadı."
    default_code = "not_found"


class APIRateLimitError(APIException):
    """REST API rate limit hatası."""

    status_code = status.HTTP_429_TOO_MANY_REQUESTS
    default_detail = "Çok fazla istek gönderdiniz."
    default_code = "rate_limit_exceeded"


class APIServiceUnavailableError(APIException):
    """REST API servis kullanılamıyor hatası."""

    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    default_detail = "Servis geçici olarak kullanılamıyor."
    default_code = "service_unavailable"


# =============================================================================
# Custom Exception Handler for REST Framework
# =============================================================================


def custom_exception_handler(exc: Exception, context: dict) -> Optional[Response]:
    """
    REST Framework için özel exception handler.
    Tüm hataları tutarlı bir formatta döndürür.
    """
    # Önce varsayılan handler'ı çağır
    response = exception_handler(exc, context)

    # HaberNexus özel hatalarını işle
    if isinstance(exc, HaberNexusException):
        logger.warning(f"HaberNexus Exception: {exc.code} - {exc.message}", extra={"details": exc.details})
        return Response(exc.to_dict(), status=exc.http_status)

    # Django Http404'ü işle
    if isinstance(exc, Http404):
        return Response(
            {
                "error": True,
                "code": "not_found",
                "message": str(exc) or "İstenen kaynak bulunamadı.",
                "details": {},
            },
            status=status.HTTP_404_NOT_FOUND,
        )

    # Django PermissionDenied'ı işle
    if isinstance(exc, PermissionDenied):
        return Response(
            {
                "error": True,
                "code": "permission_denied",
                "message": str(exc) or "Bu işlem için yetkiniz yok.",
                "details": {},
            },
            status=status.HTTP_403_FORBIDDEN,
        )

    # Eğer response varsa, formatı düzenle
    if response is not None:
        error_data = {
            "error": True,
            "code": getattr(exc, "default_code", "error"),
            "message": str(exc.detail) if hasattr(exc, "detail") else str(exc),
            "details": response.data if isinstance(response.data, dict) else {"errors": response.data},
        }
        response.data = error_data
        return response

    # Beklenmeyen hatalar için
    if settings.DEBUG:
        error_message = str(exc)
        error_traceback = traceback.format_exc()
    else:
        error_message = "Beklenmeyen bir hata oluştu."
        error_traceback = None

    logger.error(f"Unhandled Exception: {type(exc).__name__} - {exc}", exc_info=True)

    return Response(
        {
            "error": True,
            "code": "internal_error",
            "message": error_message,
            "details": {"traceback": error_traceback} if error_traceback else {},
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )


# =============================================================================
# Error Handling Decorators
# =============================================================================


def handle_exceptions(
    default_message: str = "İşlem sırasında bir hata oluştu.",
    log_errors: bool = True,
    reraise: bool = False,
) -> Callable:
    """
    Fonksiyonlardaki hataları yakalayan ve işleyen dekoratör.

    Args:
        default_message: Varsayılan hata mesajı
        log_errors: Hataları logla
        reraise: Hatayı tekrar fırlat

    Usage:
        @handle_exceptions(default_message="Makale oluşturulamadı")
        def create_article(data):
            ...
    """

    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            try:
                return func(*args, **kwargs)
            except HaberNexusException:
                raise
            except Exception as e:
                if log_errors:
                    logger.error(
                        f"Error in {func.__name__}: {type(e).__name__} - {e}",
                        exc_info=True,
                        extra={
                            "function": func.__name__,
                            "args": str(args)[:200],
                            "kwargs": str(kwargs)[:200],
                        },
                    )
                if reraise:
                    raise
                raise HaberNexusException(
                    message=default_message,
                    code="operation_failed",
                    details={"original_error": str(e)},
                ) from e

        return wrapper

    return decorator


def retry_on_failure(
    max_retries: int = 3,
    delay: float = 1.0,
    backoff: float = 2.0,
    exceptions: tuple = (Exception,),
) -> Callable:
    """
    Başarısız olan fonksiyonları yeniden deneyen dekoratör.

    Args:
        max_retries: Maksimum deneme sayısı
        delay: İlk bekleme süresi (saniye)
        backoff: Bekleme süresi çarpanı
        exceptions: Yakalanacak exception türleri

    Usage:
        @retry_on_failure(max_retries=3, delay=1.0)
        def fetch_external_data():
            ...
    """
    import time

    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            last_exception = None
            current_delay = delay

            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    last_exception = e
                    if attempt < max_retries - 1:
                        logger.warning(
                            f"Retry {attempt + 1}/{max_retries} for {func.__name__}: {e}",
                            extra={"function": func.__name__, "attempt": attempt + 1},
                        )
                        time.sleep(current_delay)
                        current_delay *= backoff
                    else:
                        logger.error(
                            f"All retries failed for {func.__name__}: {e}",
                            exc_info=True,
                        )

            raise last_exception

        return wrapper

    return decorator


# =============================================================================
# Error Response Helpers
# =============================================================================


def error_response(
    message: str,
    code: str = "error",
    status_code: int = 400,
    details: Optional[dict] = None,
) -> JsonResponse:
    """
    Standart hata yanıtı oluştur.

    Args:
        message: Hata mesajı
        code: Hata kodu
        status_code: HTTP durum kodu
        details: Ek detaylar

    Returns:
        JsonResponse: Formatlanmış hata yanıtı
    """
    return JsonResponse(
        {
            "error": True,
            "code": code,
            "message": message,
            "details": details or {},
        },
        status=status_code,
    )


def success_response(
    data: Any = None,
    message: str = "İşlem başarılı.",
    status_code: int = 200,
) -> JsonResponse:
    """
    Standart başarı yanıtı oluştur.

    Args:
        data: Yanıt verisi
        message: Başarı mesajı
        status_code: HTTP durum kodu

    Returns:
        JsonResponse: Formatlanmış başarı yanıtı
    """
    return JsonResponse(
        {
            "error": False,
            "message": message,
            "data": data,
        },
        status=status_code,
    )
