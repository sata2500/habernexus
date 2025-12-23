"""
HaberNexus v10.4 - Google Gen AI SDK Tests
ThinkingConfig ve içerik üretimi testleri.

Author: Salih TANRISEVEN
Updated: December 2025
"""

import sys
from unittest.mock import MagicMock, patch

from django.test import TestCase

import pytest

# Mock google module before importing tasks
mock_google = MagicMock()
mock_genai = MagicMock()
mock_types = MagicMock()
mock_google.genai = mock_genai
mock_genai.types = mock_types
sys.modules["google"] = mock_google
sys.modules["google.genai"] = mock_genai
sys.modules["google.genai.types"] = mock_types


class TestThinkingConfigCreation(TestCase):
    """ThinkingConfig oluşturma testleri."""

    def setUp(self):
        """Her test öncesi mock'ları sıfırla."""
        mock_types.ThinkingConfig.reset_mock()

    @patch("news.tasks.get_ai_model_name")
    @patch("news.tasks.get_thinking_level")
    @patch("news.tasks.get_thinking_budget")
    def test_gemini_25_with_budget_zero(self, mock_budget, mock_level, mock_model):
        """Gemini 2.5 ile thinking devre dışı testi."""
        mock_model.return_value = "gemini-2.5-flash"
        mock_level.return_value = None
        mock_budget.return_value = 0

        from news.tasks import create_thinking_config

        _ = create_thinking_config()

        mock_types.ThinkingConfig.assert_called_with(thinking_budget=0)

    @patch("news.tasks.get_ai_model_name")
    @patch("news.tasks.get_thinking_level")
    @patch("news.tasks.get_thinking_budget")
    def test_gemini_25_with_dynamic_thinking(self, mock_budget, mock_level, mock_model):
        """Gemini 2.5 ile dinamik thinking testi."""
        mock_model.return_value = "gemini-2.5-flash"
        mock_level.return_value = None
        mock_budget.return_value = -1

        from news.tasks import create_thinking_config

        _ = create_thinking_config()

        mock_types.ThinkingConfig.assert_called_with(thinking_budget=-1)

    @patch("news.tasks.get_ai_model_name")
    @patch("news.tasks.get_thinking_level")
    @patch("news.tasks.get_thinking_budget")
    def test_gemini_25_with_manual_budget(self, mock_budget, mock_level, mock_model):
        """Gemini 2.5 ile manuel budget testi."""
        mock_model.return_value = "gemini-2.5-flash"
        mock_level.return_value = None
        mock_budget.return_value = 1024

        from news.tasks import create_thinking_config

        _ = create_thinking_config()

        mock_types.ThinkingConfig.assert_called_with(thinking_budget=1024)

    @patch("news.tasks.get_ai_model_name")
    @patch("news.tasks.get_thinking_level")
    @patch("news.tasks.get_thinking_budget")
    def test_gemini_3_with_low_level(self, mock_budget, mock_level, mock_model):
        """Gemini 3 ile low thinking level testi."""
        mock_model.return_value = "gemini-3-pro-preview"
        mock_level.return_value = "low"
        mock_budget.return_value = 0

        from news.tasks import create_thinking_config

        _ = create_thinking_config()

        mock_types.ThinkingConfig.assert_called_with(thinking_level="low")

    @patch("news.tasks.get_ai_model_name")
    @patch("news.tasks.get_thinking_level")
    @patch("news.tasks.get_thinking_budget")
    def test_gemini_3_with_high_level(self, mock_budget, mock_level, mock_model):
        """Gemini 3 ile high thinking level testi."""
        mock_model.return_value = "gemini-3-pro"
        mock_level.return_value = "high"
        mock_budget.return_value = 0

        from news.tasks import create_thinking_config

        _ = create_thinking_config()

        mock_types.ThinkingConfig.assert_called_with(thinking_level="high")

    @patch("news.tasks.get_ai_model_name")
    @patch("news.tasks.get_thinking_level")
    @patch("news.tasks.get_thinking_budget")
    def test_gemini_3_default_level(self, mock_budget, mock_level, mock_model):
        """Gemini 3 varsayılan thinking level testi."""
        mock_model.return_value = "gemini-3-pro-preview"
        mock_level.return_value = None
        mock_budget.return_value = 0

        from news.tasks import create_thinking_config

        _ = create_thinking_config()

        # Gemini 3 için varsayılan "high" olmalı
        mock_types.ThinkingConfig.assert_called_with(thinking_level="high")


class TestGetThinkingLevel(TestCase):
    """get_thinking_level fonksiyonu testleri."""

    @patch("news.tasks.Setting")
    def test_low_level(self, mock_setting_class):
        """Low level değeri testi."""
        mock_setting = MagicMock()
        mock_setting.value = "low"
        mock_setting_class.objects.get.return_value = mock_setting

        from news.tasks import get_thinking_level

        result = get_thinking_level()
        assert result == "low"

    @patch("news.tasks.Setting")
    def test_high_level(self, mock_setting_class):
        """High level değeri testi."""
        mock_setting = MagicMock()
        mock_setting.value = "HIGH"  # Büyük harf
        mock_setting_class.objects.get.return_value = mock_setting

        from news.tasks import get_thinking_level

        result = get_thinking_level()
        assert result == "high"

    @patch("news.tasks.Setting")
    def test_legacy_minimal_conversion(self, mock_setting_class):
        """Eski MINIMAL değerinin low'a dönüşümü testi."""
        mock_setting = MagicMock()
        mock_setting.value = "MINIMAL"
        mock_setting_class.objects.get.return_value = mock_setting

        from news.tasks import get_thinking_level

        result = get_thinking_level()
        assert result == "low"

    @patch("news.tasks.Setting")
    def test_legacy_medium_conversion(self, mock_setting_class):
        """Eski MEDIUM değerinin high'a dönüşümü testi."""
        mock_setting = MagicMock()
        mock_setting.value = "MEDIUM"
        mock_setting_class.objects.get.return_value = mock_setting

        from news.tasks import get_thinking_level

        result = get_thinking_level()
        assert result == "high"

    @patch("news.tasks.Setting")
    def test_setting_not_exists(self, mock_setting_class):
        """Ayar yoksa None dönmeli."""
        from core.models import Setting

        mock_setting_class.DoesNotExist = Setting.DoesNotExist
        mock_setting_class.objects.get.side_effect = Setting.DoesNotExist

        from news.tasks import get_thinking_level

        result = get_thinking_level()
        assert result is None


class TestRetryWithBackoff(TestCase):
    """retry_with_backoff fonksiyonu testleri."""

    def test_success_on_first_try(self):
        """İlk denemede başarı testi."""
        from news.tasks import retry_with_backoff

        mock_func = MagicMock(return_value="success")
        result = retry_with_backoff(mock_func, max_retries=3)

        assert result == "success"
        assert mock_func.call_count == 1

    def test_success_on_retry(self):
        """Yeniden denemede başarı testi."""
        from news.tasks import retry_with_backoff

        mock_func = MagicMock(side_effect=[Exception("fail"), Exception("fail"), "success"])
        result = retry_with_backoff(mock_func, max_retries=3, initial_delay=0.01)

        assert result == "success"
        assert mock_func.call_count == 3

    def test_all_retries_fail(self):
        """Tüm denemelerin başarısız olması testi."""
        from news.tasks import retry_with_backoff

        mock_func = MagicMock(side_effect=Exception("always fail"))

        with pytest.raises(Exception) as exc_info:
            retry_with_backoff(mock_func, max_retries=3, initial_delay=0.01)

        assert "always fail" in str(exc_info.value)
        assert mock_func.call_count == 3
