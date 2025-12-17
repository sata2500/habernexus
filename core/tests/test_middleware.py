"""
HaberNexus v10.3 - Middleware Tests
Middleware sınıfları için testler.

Author: Salih TANRISEVEN
Updated: December 2025
"""

from unittest.mock import MagicMock, Mock, patch

from django.http import HttpRequest, HttpResponse, JsonResponse
from django.test import RequestFactory, TestCase, override_settings

import pytest

from core.middleware import (
    ErrorHandlingMiddleware,
    MaintenanceModeMiddleware,
    PerformanceMonitoringMiddleware,
    RateLimitMiddleware,
    RequestContextMiddleware,
    RequestLoggingMiddleware,
    SecurityHeadersMiddleware,
    get_current_request,
    set_current_request,
)


class TestRequestContextMiddleware(TestCase):
    """RequestContextMiddleware testleri."""

    def setUp(self):
        """Test setup."""
        self.factory = RequestFactory()
        self.middleware = RequestContextMiddleware(get_response=lambda r: HttpResponse())

    def test_process_request_sets_request_id(self):
        """Request ID'nin ayarlandığını test et."""
        request = self.factory.get("/")
        self.middleware.process_request(request)

        assert hasattr(request, "request_id")
        assert len(request.request_id) == 8

    def test_process_request_sets_start_time(self):
        """Start time'ın ayarlandığını test et."""
        request = self.factory.get("/")
        self.middleware.process_request(request)

        assert hasattr(request, "start_time")
        assert request.start_time > 0

    def test_process_response_adds_header(self):
        """Response header'ının eklendiğini test et."""
        request = self.factory.get("/")
        request.request_id = "test1234"
        response = HttpResponse()

        result = self.middleware.process_response(request, response)

        assert result["X-Request-ID"] == "test1234"

    def test_thread_local_storage(self):
        """Thread-local storage'ın çalıştığını test et."""
        request = self.factory.get("/")
        set_current_request(request)

        assert get_current_request() == request

        set_current_request(None)
        assert get_current_request() is None


class TestRequestLoggingMiddleware(TestCase):
    """RequestLoggingMiddleware testleri."""

    def setUp(self):
        """Test setup."""
        self.factory = RequestFactory()

    def test_skip_static_paths(self):
        """Statik dosya yollarının atlandığını test et."""
        middleware = RequestLoggingMiddleware(get_response=lambda r: HttpResponse())

        assert middleware._should_skip_logging("/static/css/style.css") is True
        assert middleware._should_skip_logging("/media/images/test.jpg") is True
        assert middleware._should_skip_logging("/favicon.ico") is True
        assert middleware._should_skip_logging("/health") is True
        assert middleware._should_skip_logging("/api/articles/") is False

    def test_get_client_ip_direct(self):
        """Doğrudan IP adresinin alındığını test et."""
        middleware = RequestLoggingMiddleware(get_response=lambda r: HttpResponse())
        request = self.factory.get("/")
        request.META["REMOTE_ADDR"] = "192.168.1.1"

        ip = middleware._get_client_ip(request)
        assert ip == "192.168.1.1"

    def test_get_client_ip_forwarded(self):
        """X-Forwarded-For header'ından IP alındığını test et."""
        middleware = RequestLoggingMiddleware(get_response=lambda r: HttpResponse())
        request = self.factory.get("/")
        request.META["HTTP_X_FORWARDED_FOR"] = "10.0.0.1, 192.168.1.1"

        ip = middleware._get_client_ip(request)
        assert ip == "10.0.0.1"


class TestSecurityHeadersMiddleware(TestCase):
    """SecurityHeadersMiddleware testleri."""

    def setUp(self):
        """Test setup."""
        self.factory = RequestFactory()
        self.middleware = SecurityHeadersMiddleware(get_response=lambda r: HttpResponse())

    def test_adds_content_type_options(self):
        """X-Content-Type-Options header'ının eklendiğini test et."""
        request = self.factory.get("/")
        response = HttpResponse()

        result = self.middleware.process_response(request, response)

        assert result["X-Content-Type-Options"] == "nosniff"

    def test_adds_frame_options(self):
        """X-Frame-Options header'ının eklendiğini test et."""
        request = self.factory.get("/")
        response = HttpResponse()

        result = self.middleware.process_response(request, response)

        assert result["X-Frame-Options"] == "DENY"

    def test_adds_xss_protection(self):
        """X-XSS-Protection header'ının eklendiğini test et."""
        request = self.factory.get("/")
        response = HttpResponse()

        result = self.middleware.process_response(request, response)

        assert result["X-XSS-Protection"] == "1; mode=block"

    def test_adds_referrer_policy(self):
        """Referrer-Policy header'ının eklendiğini test et."""
        request = self.factory.get("/")
        response = HttpResponse()

        result = self.middleware.process_response(request, response)

        assert result["Referrer-Policy"] == "strict-origin-when-cross-origin"

    def test_adds_permissions_policy(self):
        """Permissions-Policy header'ının eklendiğini test et."""
        request = self.factory.get("/")
        response = HttpResponse()

        result = self.middleware.process_response(request, response)

        assert "Permissions-Policy" in result

    def test_does_not_override_existing_headers(self):
        """Mevcut header'ların üzerine yazılmadığını test et."""
        request = self.factory.get("/")
        response = HttpResponse()
        response["X-Frame-Options"] = "SAMEORIGIN"

        result = self.middleware.process_response(request, response)

        assert result["X-Frame-Options"] == "SAMEORIGIN"


class TestErrorHandlingMiddleware(TestCase):
    """ErrorHandlingMiddleware testleri."""

    def setUp(self):
        """Test setup."""
        self.factory = RequestFactory()
        self.middleware = ErrorHandlingMiddleware(get_response=lambda r: HttpResponse())

    def test_handles_api_exception(self):
        """API exception'larının işlendiğini test et."""
        request = self.factory.get("/api/test/")
        request.request_id = "test1234"
        request.content_type = "application/json"

        exception = Exception("Test error")

        with patch("core.middleware.settings") as mock_settings:
            mock_settings.DEBUG = False
            result = self.middleware.process_exception(request, exception)

        assert isinstance(result, JsonResponse)
        assert result.status_code == 500

    def test_returns_none_for_html_requests(self):
        """HTML istekleri için None döndürüldüğünü test et."""
        request = self.factory.get("/test/")
        request.request_id = "test1234"
        request.content_type = "text/html"

        exception = Exception("Test error")

        with patch("core.middleware.settings") as mock_settings:
            mock_settings.DEBUG = False
            result = self.middleware.process_exception(request, exception)

        # Django'nun varsayılan hata sayfası için None dönmeli
        assert result is None


class TestPerformanceMonitoringMiddleware(TestCase):
    """PerformanceMonitoringMiddleware testleri."""

    def setUp(self):
        """Test setup."""
        self.factory = RequestFactory()

    def test_adds_response_time_header(self):
        """X-Response-Time header'ının eklendiğini test et."""
        middleware = PerformanceMonitoringMiddleware(get_response=lambda r: HttpResponse())
        request = self.factory.get("/")

        response = middleware(request)

        assert "X-Response-Time" in response
        assert "ms" in response["X-Response-Time"]


@override_settings(MAINTENANCE_MODE=True)
class TestMaintenanceModeMiddleware(TestCase):
    """MaintenanceModeMiddleware testleri."""

    def setUp(self):
        """Test setup."""
        self.factory = RequestFactory()
        self.middleware = MaintenanceModeMiddleware(get_response=lambda r: HttpResponse())

    def test_allows_admin_paths(self):
        """Admin yollarının izin verildiğini test et."""
        request = self.factory.get("/admin/")

        result = self.middleware.process_request(request)

        assert result is None

    def test_allows_health_check(self):
        """Health check yollarının izin verildiğini test et."""
        request = self.factory.get("/api/health/")

        result = self.middleware.process_request(request)

        assert result is None

    def test_returns_503_for_api(self):
        """API istekleri için 503 döndürüldüğünü test et."""
        request = self.factory.get("/api/articles/")

        result = self.middleware.process_request(request)

        assert isinstance(result, JsonResponse)
        assert result.status_code == 503


class TestRateLimitMiddleware(TestCase):
    """RateLimitMiddleware testleri."""

    def setUp(self):
        """Test setup."""
        self.factory = RequestFactory()

    def test_allows_requests_under_limit(self):
        """Limit altındaki isteklerin izin verildiğini test et."""
        middleware = RateLimitMiddleware(get_response=lambda r: HttpResponse())
        request = self.factory.get("/")
        request.META["REMOTE_ADDR"] = "192.168.1.1"

        response = middleware(request)

        assert response.status_code == 200

    def test_get_client_ip(self):
        """Client IP'nin doğru alındığını test et."""
        middleware = RateLimitMiddleware(get_response=lambda r: HttpResponse())
        request = self.factory.get("/")
        request.META["REMOTE_ADDR"] = "192.168.1.1"

        ip = middleware._get_client_ip(request)
        assert ip == "192.168.1.1"

    def test_get_client_ip_with_forwarded(self):
        """X-Forwarded-For ile client IP'nin alındığını test et."""
        middleware = RateLimitMiddleware(get_response=lambda r: HttpResponse())
        request = self.factory.get("/")
        request.META["HTTP_X_FORWARDED_FOR"] = "10.0.0.1, 192.168.1.1"

        ip = middleware._get_client_ip(request)
        assert ip == "10.0.0.1"
