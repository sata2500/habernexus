"""Core modelleri için testler."""

from django.test import TestCase

import pytest

from core.models import Setting, SystemLog


@pytest.mark.django_db
class TestSettingModel(TestCase):
    """Setting modeli test sınıfı."""

    def test_setting_creation(self):
        """Ayar oluşturma testi."""
        setting = Setting.objects.create(key="TEST_KEY", value="test_value", description="Test ayarı", is_secret=False)

        assert setting.key == "TEST_KEY"
        assert setting.value == "test_value"
        assert setting.description == "Test ayarı"
        assert setting.is_secret is False

    def test_setting_str_representation(self):
        """Ayar string temsili testi."""
        setting = Setting.objects.create(key="API_KEY", value="secret123", is_secret=False)

        assert str(setting) == "API_KEY: secret123"

    def test_setting_str_representation_secret(self):
        """Gizli ayar string temsili testi."""
        setting = Setting.objects.create(key="API_KEY", value="secret123", is_secret=True)

        assert str(setting) == "API_KEY: ***"

    def test_setting_key_uniqueness(self):
        """Ayar key benzersizlik testi."""
        Setting.objects.create(key="UNIQUE_KEY", value="value1")

        # Aynı key ile ikinci ayar oluşturmaya çalış
        with pytest.raises(Exception):
            Setting.objects.create(key="UNIQUE_KEY", value="value2")


@pytest.mark.django_db
class TestSystemLogModel(TestCase):
    """SystemLog modeli test sınıfı."""

    def test_system_log_creation(self):
        """Sistem logu oluşturma testi."""
        log = SystemLog.objects.create(
            level="ERROR", task_name="test_task", message="Test hata mesajı", traceback="Test traceback"
        )

        assert log.level == "ERROR"
        assert log.task_name == "test_task"
        assert log.message == "Test hata mesajı"
        assert log.traceback == "Test traceback"

    def test_system_log_str_representation(self):
        """Sistem logu string temsili testi."""
        log = SystemLog.objects.create(level="INFO", task_name="test_task", message="Test mesaj")

        log_str = str(log)
        assert "[INFO]" in log_str
        assert "test_task" in log_str

    def test_system_log_ordering(self):
        """Sistem logu sıralama testi."""
        log1 = SystemLog.objects.create(level="INFO", task_name="task1", message="Mesaj 1")
        log2 = SystemLog.objects.create(level="ERROR", task_name="task2", message="Mesaj 2")

        logs = SystemLog.objects.all()
        assert logs[0] == log2  # En son oluşturulan önce (created_at DESC)
        assert logs[1] == log1
