"""Core tasks için testler."""

from datetime import timedelta
from unittest.mock import patch

import pytest
from django.test import TestCase
from django.utils import timezone

from core.models import SystemLog
from core.tasks import cleanup_old_logs, log_error, log_info


@pytest.mark.django_db
class TestCleanupOldLogs(TestCase):
    """cleanup_old_logs task testi."""

    def test_cleanup_old_logs_success(self):
        """Eski logların başarıyla silindiği test."""
        # 40 gün önce log oluştur (silinmeli)
        old_date = timezone.now() - timedelta(days=40)
        old_log = SystemLog.objects.create(level="INFO", task_name="test_task", message="Eski log")
        SystemLog.objects.filter(id=old_log.id).update(created_at=old_date)

        # 20 gün önce log oluştur (silinmemeli)
        recent_date = timezone.now() - timedelta(days=20)
        recent_log = SystemLog.objects.create(level="INFO", task_name="test_task", message="Yeni log")
        SystemLog.objects.filter(id=recent_log.id).update(created_at=recent_date)

        # Task'ı çalıştır
        result = cleanup_old_logs()

        # Assertions
        assert "Başarılı: 1 log silindi" in result
        assert SystemLog.objects.filter(message="Eski log").count() == 0
        assert SystemLog.objects.filter(message="Yeni log").count() == 1

        # Cleanup log'unun oluşturulduğunu doğrula
        cleanup_log = SystemLog.objects.filter(task_name="cleanup_old_logs", level="INFO").first()
        assert cleanup_log is not None
        assert "1 eski log silindi" in cleanup_log.message

    def test_cleanup_old_logs_no_old_logs(self):
        """Eski log olmadığında test."""
        # Sadece yeni loglar oluştur
        SystemLog.objects.create(level="INFO", task_name="test_task", message="Yeni log 1")
        SystemLog.objects.create(level="INFO", task_name="test_task", message="Yeni log 2")

        # Task'ı çalıştır
        result = cleanup_old_logs()

        # Assertions
        assert "Başarılı: 0 log silindi" in result
        assert SystemLog.objects.filter(message__startswith="Yeni log").count() == 2

    def test_cleanup_old_logs_multiple_old_logs(self):
        """Birden fazla eski log olduğunda test."""
        # 5 eski log oluştur
        old_date = timezone.now() - timedelta(days=35)
        for i in range(5):
            log = SystemLog.objects.create(level="INFO", task_name="test_task", message=f"Eski log {i}")
            SystemLog.objects.filter(id=log.id).update(created_at=old_date)

        # Task'ı çalıştır
        result = cleanup_old_logs()

        # Assertions
        assert "Başarılı: 5 log silindi" in result
        assert SystemLog.objects.filter(message__startswith="Eski log").count() == 0

    @patch("core.tasks.SystemLog.objects.filter")
    def test_cleanup_old_logs_error(self, mock_filter):
        """Cleanup sırasında hata oluştuğunda test."""
        # Mock filter'ı hata fırlatacak şekilde ayarla
        mock_filter.side_effect = Exception("Database error")

        # Task'ın hata fırlattığını doğrula
        with pytest.raises(Exception) as exc_info:
            cleanup_old_logs()

        assert "Database error" in str(exc_info.value)


@pytest.mark.django_db
class TestLogError(TestCase):
    """log_error fonksiyonu testi."""

    def test_log_error_basic(self):
        """Temel hata kaydı testi."""
        log_error("test_task", "Test error message")

        # Log'un oluşturulduğunu doğrula
        error_log = SystemLog.objects.filter(task_name="test_task", level="ERROR").first()
        assert error_log is not None
        assert error_log.message == "Test error message"
        assert error_log.traceback == ""
        assert error_log.related_id is None

    def test_log_error_with_traceback(self):
        """Traceback ile hata kaydı testi."""
        traceback_text = "Traceback (most recent call last):\n  File test.py, line 10"
        log_error("test_task", "Test error with traceback", traceback=traceback_text)

        # Log'un oluşturulduğunu doğrula
        error_log = SystemLog.objects.filter(task_name="test_task", level="ERROR").first()
        assert error_log is not None
        assert error_log.message == "Test error with traceback"
        assert error_log.traceback == traceback_text

    def test_log_error_with_related_id(self):
        """Related ID ile hata kaydı testi."""
        log_error("test_task", "Test error with related ID", related_id=123)

        # Log'un oluşturulduğunu doğrula
        error_log = SystemLog.objects.filter(task_name="test_task", level="ERROR").first()
        assert error_log is not None
        assert error_log.message == "Test error with related ID"
        assert error_log.related_id == 123

    def test_log_error_all_parameters(self):
        """Tüm parametrelerle hata kaydı testi."""
        traceback_text = "Full traceback"
        log_error("test_task", "Complete error log", traceback=traceback_text, related_id=456)

        # Log'un oluşturulduğunu doğrula
        error_log = SystemLog.objects.filter(task_name="test_task", level="ERROR").first()
        assert error_log is not None
        assert error_log.message == "Complete error log"
        assert error_log.traceback == traceback_text
        assert error_log.related_id == 456


@pytest.mark.django_db
class TestLogInfo(TestCase):
    """log_info fonksiyonu testi."""

    def test_log_info_basic(self):
        """Temel bilgi kaydı testi."""
        log_info("test_task", "Test info message")

        # Log'un oluşturulduğunu doğrula
        info_log = SystemLog.objects.filter(task_name="test_task", level="INFO").first()
        assert info_log is not None
        assert info_log.message == "Test info message"
        assert info_log.related_id is None

    def test_log_info_with_related_id(self):
        """Related ID ile bilgi kaydı testi."""
        log_info("test_task", "Test info with related ID", related_id=789)

        # Log'un oluşturulduğunu doğrula
        info_log = SystemLog.objects.filter(task_name="test_task", level="INFO").first()
        assert info_log is not None
        assert info_log.message == "Test info with related ID"
        assert info_log.related_id == 789

    def test_log_info_multiple_logs(self):
        """Birden fazla bilgi kaydı testi."""
        log_info("task1", "Message 1")
        log_info("task2", "Message 2")
        log_info("task3", "Message 3")

        # Tüm logların oluşturulduğunu doğrula
        assert SystemLog.objects.filter(level="INFO").count() == 3
        assert SystemLog.objects.filter(task_name="task1").exists()
        assert SystemLog.objects.filter(task_name="task2").exists()
        assert SystemLog.objects.filter(task_name="task3").exists()
