"""
HaberNexus Logging Configuration
Profesyonel logging yapılandırması.
"""

import json
import logging
import sys
import traceback
from datetime import datetime
from logging.handlers import RotatingFileHandler, TimedRotatingFileHandler
from pathlib import Path
from typing import Any, Dict, Optional

from django.conf import settings


class JSONFormatter(logging.Formatter):
    """
    JSON formatında log çıktısı üreten formatter.
    Structured logging için idealdir.
    """

    def __init__(self, include_traceback: bool = True):
        super().__init__()
        self.include_traceback = include_traceback

    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }

        # Extra fields
        if hasattr(record, "extra"):
            log_data["extra"] = record.extra

        # Request bilgileri
        if hasattr(record, "request_id"):
            log_data["request_id"] = record.request_id
        if hasattr(record, "user_id"):
            log_data["user_id"] = record.user_id
        if hasattr(record, "ip_address"):
            log_data["ip_address"] = record.ip_address

        # Exception bilgileri
        if record.exc_info and self.include_traceback:
            log_data["exception"] = {
                "type": record.exc_info[0].__name__ if record.exc_info[0] else None,
                "message": str(record.exc_info[1]) if record.exc_info[1] else None,
                "traceback": traceback.format_exception(*record.exc_info) if record.exc_info[2] else None,
            }

        return json.dumps(log_data, ensure_ascii=False, default=str)


class ColoredFormatter(logging.Formatter):
    """
    Renkli konsol çıktısı için formatter.
    Development ortamı için idealdir.
    """

    COLORS = {
        "DEBUG": "\033[36m",  # Cyan
        "INFO": "\033[32m",  # Green
        "WARNING": "\033[33m",  # Yellow
        "ERROR": "\033[31m",  # Red
        "CRITICAL": "\033[35m",  # Magenta
    }
    RESET = "\033[0m"

    def format(self, record: logging.LogRecord) -> str:
        color = self.COLORS.get(record.levelname, self.RESET)
        record.levelname = f"{color}{record.levelname}{self.RESET}"
        return super().format(record)


class RequestContextFilter(logging.Filter):
    """
    Request context bilgilerini log kayıtlarına ekleyen filter.
    """

    def filter(self, record: logging.LogRecord) -> bool:
        # Thread-local storage'dan request bilgilerini al
        from core.middleware import get_current_request

        request = get_current_request()
        if request:
            record.request_id = getattr(request, "request_id", "-")
            record.user_id = getattr(request.user, "id", "-") if hasattr(request, "user") else "-"
            record.ip_address = get_client_ip(request)
        else:
            record.request_id = "-"
            record.user_id = "-"
            record.ip_address = "-"
        return True


def get_client_ip(request) -> str:
    """Request'ten client IP adresini al."""
    x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
    if x_forwarded_for:
        return x_forwarded_for.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR", "-")


def setup_logging(
    log_level: str = "INFO",
    log_dir: Optional[Path] = None,
    json_format: bool = False,
    console_output: bool = True,
) -> None:
    """
    Logging sistemini yapılandır.

    Args:
        log_level: Log seviyesi (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        log_dir: Log dosyalarının kaydedileceği dizin
        json_format: JSON formatında log çıktısı
        console_output: Konsola log çıktısı
    """
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, log_level.upper()))

    # Mevcut handler'ları temizle
    root_logger.handlers = []

    # Console handler
    if console_output:
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.DEBUG)

        if json_format:
            console_handler.setFormatter(JSONFormatter())
        else:
            console_handler.setFormatter(
                ColoredFormatter(
                    fmt="%(asctime)s | %(levelname)-8s | %(name)s:%(funcName)s:%(lineno)d | %(message)s",
                    datefmt="%Y-%m-%d %H:%M:%S",
                )
            )

        root_logger.addHandler(console_handler)

    # File handlers
    if log_dir:
        log_dir = Path(log_dir)
        log_dir.mkdir(parents=True, exist_ok=True)

        # Application log (rotating)
        app_handler = RotatingFileHandler(
            log_dir / "app.log",
            maxBytes=10 * 1024 * 1024,  # 10MB
            backupCount=5,
            encoding="utf-8",
        )
        app_handler.setLevel(logging.INFO)
        app_handler.setFormatter(JSONFormatter())
        root_logger.addHandler(app_handler)

        # Error log (daily rotation)
        error_handler = TimedRotatingFileHandler(
            log_dir / "error.log",
            when="midnight",
            interval=1,
            backupCount=30,
            encoding="utf-8",
        )
        error_handler.setLevel(logging.ERROR)
        error_handler.setFormatter(JSONFormatter())
        root_logger.addHandler(error_handler)

        # Security log
        security_logger = logging.getLogger("security")
        security_handler = RotatingFileHandler(
            log_dir / "security.log",
            maxBytes=10 * 1024 * 1024,
            backupCount=10,
            encoding="utf-8",
        )
        security_handler.setFormatter(JSONFormatter())
        security_logger.addHandler(security_handler)

    # Request context filter ekle
    try:
        root_logger.addFilter(RequestContextFilter())
    except Exception:
        pass  # Middleware yüklenmemişse atla


# =============================================================================
# Logging Helpers
# =============================================================================


def log_request(request, response=None, duration=None) -> None:
    """
    HTTP request'i logla.

    Args:
        request: Django request nesnesi
        response: Django response nesnesi
        duration: İstek süresi (ms)
    """
    logger = logging.getLogger("requests")

    log_data = {
        "method": request.method,
        "path": request.path,
        "query_string": request.META.get("QUERY_STRING", ""),
        "user_agent": request.META.get("HTTP_USER_AGENT", ""),
        "ip_address": get_client_ip(request),
        "user_id": getattr(request.user, "id", None) if hasattr(request, "user") else None,
    }

    if response:
        log_data["status_code"] = response.status_code
        log_data["content_length"] = len(response.content) if hasattr(response, "content") else 0

    if duration:
        log_data["duration_ms"] = duration

    if response and response.status_code >= 400:
        logger.warning("Request completed with error", extra=log_data)
    else:
        logger.info("Request completed", extra=log_data)


def log_task(task_name: str, status: str, duration: Optional[float] = None, details: Optional[Dict] = None) -> None:
    """
    Celery task'ı logla.

    Args:
        task_name: Task adı
        status: Task durumu (started, completed, failed)
        duration: Task süresi (saniye)
        details: Ek detaylar
    """
    logger = logging.getLogger("tasks")

    log_data = {
        "task_name": task_name,
        "status": status,
    }

    if duration:
        log_data["duration_seconds"] = duration

    if details:
        log_data.update(details)

    if status == "failed":
        logger.error(f"Task failed: {task_name}", extra=log_data)
    else:
        logger.info(f"Task {status}: {task_name}", extra=log_data)


def log_security_event(event_type: str, details: Dict[str, Any], severity: str = "warning") -> None:
    """
    Güvenlik olayını logla.

    Args:
        event_type: Olay türü (login_failed, suspicious_activity, etc.)
        details: Olay detayları
        severity: Önem seviyesi (info, warning, error, critical)
    """
    logger = logging.getLogger("security")

    log_data = {
        "event_type": event_type,
        "timestamp": datetime.utcnow().isoformat(),
        **details,
    }

    log_method = getattr(logger, severity, logger.warning)
    log_method(f"Security event: {event_type}", extra=log_data)


def log_ai_operation(
    operation: str,
    model: str,
    status: str,
    duration: Optional[float] = None,
    tokens_used: Optional[int] = None,
    details: Optional[Dict] = None,
) -> None:
    """
    AI operasyonunu logla.

    Args:
        operation: Operasyon türü (generate_content, generate_image, etc.)
        model: Kullanılan model
        status: Operasyon durumu
        duration: Süre (saniye)
        tokens_used: Kullanılan token sayısı
        details: Ek detaylar
    """
    logger = logging.getLogger("ai")

    log_data = {
        "operation": operation,
        "model": model,
        "status": status,
    }

    if duration:
        log_data["duration_seconds"] = duration

    if tokens_used:
        log_data["tokens_used"] = tokens_used

    if details:
        log_data.update(details)

    if status == "failed":
        logger.error(f"AI operation failed: {operation}", extra=log_data)
    else:
        logger.info(f"AI operation: {operation}", extra=log_data)


# =============================================================================
# Django Logging Configuration
# =============================================================================


def get_logging_config(debug: bool = False, log_dir: Optional[str] = None) -> Dict:
    """
    Django LOGGING ayarları için yapılandırma döndür.

    Args:
        debug: Debug modu
        log_dir: Log dizini

    Returns:
        Dict: Django LOGGING yapılandırması
    """
    config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "verbose": {
                "format": "{asctime} | {levelname:8} | {name}:{funcName}:{lineno} | {message}",
                "style": "{",
                "datefmt": "%Y-%m-%d %H:%M:%S",
            },
            "simple": {
                "format": "{levelname} {message}",
                "style": "{",
            },
            "json": {
                "()": JSONFormatter,
            },
        },
        "filters": {
            "require_debug_false": {
                "()": "django.utils.log.RequireDebugFalse",
            },
            "require_debug_true": {
                "()": "django.utils.log.RequireDebugTrue",
            },
        },
        "handlers": {
            "console": {
                "level": "DEBUG" if debug else "INFO",
                "class": "logging.StreamHandler",
                "formatter": "verbose" if debug else "simple",
            },
            "mail_admins": {
                "level": "ERROR",
                "filters": ["require_debug_false"],
                "class": "django.utils.log.AdminEmailHandler",
            },
        },
        "loggers": {
            "django": {
                "handlers": ["console"],
                "level": "INFO",
                "propagate": True,
            },
            "django.request": {
                "handlers": ["console", "mail_admins"],
                "level": "ERROR",
                "propagate": False,
            },
            "django.security": {
                "handlers": ["console", "mail_admins"],
                "level": "WARNING",
                "propagate": False,
            },
            "news": {
                "handlers": ["console"],
                "level": "DEBUG" if debug else "INFO",
                "propagate": False,
            },
            "core": {
                "handlers": ["console"],
                "level": "DEBUG" if debug else "INFO",
                "propagate": False,
            },
            "api": {
                "handlers": ["console"],
                "level": "DEBUG" if debug else "INFO",
                "propagate": False,
            },
            "celery": {
                "handlers": ["console"],
                "level": "INFO",
                "propagate": False,
            },
            "security": {
                "handlers": ["console"],
                "level": "WARNING",
                "propagate": False,
            },
            "ai": {
                "handlers": ["console"],
                "level": "INFO",
                "propagate": False,
            },
        },
        "root": {
            "handlers": ["console"],
            "level": "WARNING",
        },
    }

    # File handlers ekle (production için)
    if log_dir and not debug:
        log_path = Path(log_dir)
        log_path.mkdir(parents=True, exist_ok=True)

        config["handlers"]["file"] = {
            "level": "INFO",
            "class": "logging.handlers.RotatingFileHandler",
            "filename": str(log_path / "app.log"),
            "maxBytes": 10 * 1024 * 1024,
            "backupCount": 5,
            "formatter": "json",
        }

        config["handlers"]["error_file"] = {
            "level": "ERROR",
            "class": "logging.handlers.TimedRotatingFileHandler",
            "filename": str(log_path / "error.log"),
            "when": "midnight",
            "backupCount": 30,
            "formatter": "json",
        }

        # File handler'ları logger'lara ekle
        for logger_name in ["django", "news", "core", "api", "celery"]:
            config["loggers"][logger_name]["handlers"].append("file")

        config["loggers"]["django.request"]["handlers"].append("error_file")

    return config
