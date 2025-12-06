"""Core views için testler."""

import pytest
from django.contrib.auth.models import User
from django.contrib.messages import get_messages
from django.test import Client, TestCase
from django.urls import reverse

from core.models import Setting
from core.views import get_setting


@pytest.mark.django_db
class TestApiSettingsView(TestCase):
    """api_settings_view testi."""

    def setUp(self):
        """Test setup - staff user oluştur."""
        self.client = Client()
        self.staff_user = User.objects.create_user(username="staff", password="testpass123", is_staff=True)
        self.regular_user = User.objects.create_user(username="regular", password="testpass123", is_staff=False)
        self.url = reverse("core:api_settings")

    def test_api_settings_view_requires_staff(self):
        """Staff olmayan kullanıcı erişemez."""
        self.client.login(username="regular", password="testpass123")
        response = self.client.get(self.url)
        # staff_member_required decorator redirect eder
        assert response.status_code == 302

    def test_api_settings_view_get(self):
        """GET request ile ayarları görüntüleme."""
        self.client.login(username="staff", password="testpass123")

        # Bazı ayarlar oluştur
        Setting.objects.create(key="GOOGLE_GEMINI_API_KEY", value="test-key-123", is_secret=True)
        Setting.objects.create(key="RSS_FETCH_FREQUENCY_MINUTES", value="20", is_secret=False)

        response = self.client.get(self.url)

        assert response.status_code == 200
        assert "settings" in response.context
        assert "gemini_key_set" in response.context
        assert response.context["gemini_key_set"] is True
        # Secret key maskelenmiş olmalı
        assert response.context["settings"]["GOOGLE_GEMINI_API_KEY"] == "***"
        # Non-secret key görünür olmalı
        assert response.context["settings"]["RSS_FETCH_FREQUENCY_MINUTES"] == "20"

    def test_api_settings_view_post_gemini_key(self):
        """POST request ile Gemini API key kaydetme."""
        self.client.login(username="staff", password="testpass123")

        response = self.client.post(self.url, {"gemini_api_key": "new-gemini-key"})

        assert response.status_code == 302  # Redirect
        setting = Setting.objects.get(key="GOOGLE_GEMINI_API_KEY")
        assert setting.value == "new-gemini-key"
        assert setting.is_secret is True

        # Success message kontrolü (gemini + default rss + default content = 3 message)
        messages = list(get_messages(response.wsgi_request))
        assert len(messages) >= 1
        assert any("Google Gemini API Anahtarı kaydedildi" in str(m) for m in messages)

    def test_api_settings_view_post_imagen_key(self):
        """POST request ile Imagen API key kaydetme."""
        self.client.login(username="staff", password="testpass123")

        response = self.client.post(self.url, {"imagen_api_key": "new-imagen-key"})

        assert response.status_code == 302
        setting = Setting.objects.get(key="GOOGLE_IMAGEN_API_KEY")
        assert setting.value == "new-imagen-key"
        assert setting.is_secret is True

    def test_api_settings_view_post_rss_frequency(self):
        """POST request ile RSS frequency kaydetme."""
        self.client.login(username="staff", password="testpass123")

        response = self.client.post(self.url, {"rss_frequency": "30"})

        assert response.status_code == 302
        setting = Setting.objects.get(key="RSS_FETCH_FREQUENCY_MINUTES")
        assert setting.value == "30"
        assert setting.is_secret is False

        messages = list(get_messages(response.wsgi_request))
        assert "RSS tarama sıklığı 30 dakika olarak ayarlandı" in str(messages[0])

    def test_api_settings_view_post_content_frequency(self):
        """POST request ile content generation frequency kaydetme."""
        self.client.login(username="staff", password="testpass123")

        response = self.client.post(self.url, {"content_frequency": "45"})

        assert response.status_code == 302
        setting = Setting.objects.get(key="CONTENT_GENERATION_FREQUENCY_MINUTES")
        assert setting.value == "45"
        assert setting.is_secret is False

    def test_api_settings_view_post_all_settings(self):
        """POST request ile tüm ayarları birden kaydetme."""
        self.client.login(username="staff", password="testpass123")

        response = self.client.post(
            self.url,
            {
                "gemini_api_key": "gemini-123",
                "imagen_api_key": "imagen-456",
                "rss_frequency": "25",
                "content_frequency": "35",
            },
        )

        assert response.status_code == 302

        # Tüm ayarların kaydedildiğini doğrula
        assert Setting.objects.get(key="GOOGLE_GEMINI_API_KEY").value == "gemini-123"
        assert Setting.objects.get(key="GOOGLE_IMAGEN_API_KEY").value == "imagen-456"
        assert Setting.objects.get(key="RSS_FETCH_FREQUENCY_MINUTES").value == "25"
        assert Setting.objects.get(key="CONTENT_GENERATION_FREQUENCY_MINUTES").value == "35"

        # 4 success message olmalı
        messages = list(get_messages(response.wsgi_request))
        assert len(messages) == 4

    def test_api_settings_view_post_empty_values(self):
        """POST request ile boş değerler gönderildiğinde."""
        self.client.login(username="staff", password="testpass123")

        response = self.client.post(self.url, {"gemini_api_key": "", "rss_frequency": ""})

        assert response.status_code == 302
        # Boş değerler kaydedilmemeli
        assert not Setting.objects.filter(key="GOOGLE_GEMINI_API_KEY").exists()

    def test_api_settings_view_post_invalid_frequency(self):
        """POST request ile geçersiz frequency değeri."""
        self.client.login(username="staff", password="testpass123")

        response = self.client.post(self.url, {"rss_frequency": "invalid"})

        assert response.status_code == 302
        # Geçersiz değer kaydedilmemeli
        assert not Setting.objects.filter(key="RSS_FETCH_FREQUENCY_MINUTES").exists()

    def test_api_settings_view_update_existing(self):
        """Mevcut ayarı güncelleme."""
        self.client.login(username="staff", password="testpass123")

        # İlk ayar
        Setting.objects.create(key="GOOGLE_GEMINI_API_KEY", value="old-key", is_secret=True)

        # Güncelleme
        response = self.client.post(self.url, {"gemini_api_key": "new-key"})

        assert response.status_code == 302
        setting = Setting.objects.get(key="GOOGLE_GEMINI_API_KEY")
        assert setting.value == "new-key"
        # Sadece 1 ayar olmalı (update_or_create kullanıldığı için)
        assert Setting.objects.filter(key="GOOGLE_GEMINI_API_KEY").count() == 1

    def test_api_settings_view_get_with_no_settings(self):
        """Hiç ayar yokken GET request."""
        self.client.login(username="staff", password="testpass123")

        response = self.client.get(self.url)

        assert response.status_code == 200
        assert response.context["gemini_key_set"] is False
        assert response.context["imagen_key_set"] is False
        assert response.context["rss_frequency"] == "15"  # Default
        assert response.context["content_frequency"] == "30"  # Default


@pytest.mark.django_db
class TestGetSetting(TestCase):
    """get_setting helper fonksiyonu testi."""

    def test_get_setting_exists(self):
        """Ayar varsa değerini döndürme."""
        Setting.objects.create(key="TEST_KEY", value="test_value")

        result = get_setting("TEST_KEY")

        assert result == "test_value"

    def test_get_setting_not_exists_with_default(self):
        """Ayar yoksa default değer döndürme."""
        result = get_setting("NONEXISTENT_KEY", default="default_value")

        assert result == "default_value"

    def test_get_setting_not_exists_without_default(self):
        """Ayar yoksa ve default yoksa None döndürme."""
        result = get_setting("NONEXISTENT_KEY")

        assert result is None

    def test_get_setting_empty_value(self):
        """Ayar boş değer içeriyorsa."""
        Setting.objects.create(key="EMPTY_KEY", value="")

        result = get_setting("EMPTY_KEY")

        assert result == ""

    def test_get_setting_secret_value(self):
        """Secret ayar değerini döndürme."""
        Setting.objects.create(key="SECRET_KEY", value="secret_value", is_secret=True)

        result = get_setting("SECRET_KEY")

        assert result == "secret_value"
