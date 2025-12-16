"""
HaberNexus Test Configuration
Pytest fixtures ve yapılandırması.
"""

import os

import django

import pytest

# Django ayarlarını yükle
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "habernexus_config.settings_test")
django.setup()


@pytest.fixture(scope="session")
def django_db_setup(django_db_blocker):
    """Django veritabanı kurulumu - migration'ları çalıştır."""
    from django.conf import settings
    from django.core.management import call_command

    settings.DATABASES["default"] = {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": ":memory:",
        "ATOMIC_REQUESTS": False,
        "TEST": {
            "NAME": ":memory:",
        },
    }

    with django_db_blocker.unblock():
        call_command("migrate", "--run-syncdb", verbosity=0)


@pytest.fixture
def sample_author(db):
    """Örnek yazar fixture'ı."""
    from authors.models import Author

    return Author.objects.create(
        name="Test Yazar",
        slug="test-yazar",
        bio="Test bio",
        expertise="Teknoloji",
        is_active=True,
    )


@pytest.fixture
def sample_article(db, sample_author):
    """Örnek makale fixture'ı."""
    from django.utils import timezone

    from news.models import Article

    return Article.objects.create(
        title="Test Haber",
        slug="test-haber",
        content="<p>Test içerik</p>",
        excerpt="Test özet",
        category="Teknoloji",
        author=sample_author,
        status="published",
        published_at=timezone.now(),
    )


@pytest.fixture
def sample_rss_source(db):
    """Örnek RSS kaynağı fixture'ı."""
    from news.models import RssSource

    return RssSource.objects.create(
        name="Test RSS",
        url="https://example.com/rss",
        category="Teknoloji",
        frequency_minutes=60,
        is_active=True,
    )


@pytest.fixture
def api_client():
    """REST API test client fixture'ı."""
    from rest_framework.test import APIClient

    return APIClient()


@pytest.fixture
def authenticated_api_client(db):
    """Kimlik doğrulamalı API client fixture'ı."""
    from django.contrib.auth import get_user_model

    from rest_framework.test import APIClient

    User = get_user_model()
    user = User.objects.create_user(
        username="testuser",
        email="test@example.com",
        password="testpass123",
    )
    client = APIClient()
    client.force_authenticate(user=user)
    return client


@pytest.fixture
def admin_api_client(db):
    """Admin API client fixture'ı."""
    from django.contrib.auth import get_user_model

    from rest_framework.test import APIClient

    User = get_user_model()
    admin = User.objects.create_superuser(
        username="admin",
        email="admin@example.com",
        password="adminpass123",
    )
    client = APIClient()
    client.force_authenticate(user=admin)
    return client
