from django.urls import path

from . import views, views_migration
from .health import DetailedHealthCheckView, HealthCheckView, LivenessCheckView, ReadinessCheckView

app_name = "core"

urlpatterns = [
    # Legacy health check
    path("health/", views.health_check, name="health_check"),
    # New health check endpoints
    path("health/status/", HealthCheckView.as_view(), name="health_status"),
    path("health/detailed/", DetailedHealthCheckView.as_view(), name="health_detailed"),
    path("health/ready/", ReadinessCheckView.as_view(), name="health_ready"),
    path("health/live/", LivenessCheckView.as_view(), name="health_live"),
    # Admin endpoints
    path("admin/api-settings/", views.api_settings_view, name="api_settings"),
    # Migration endpoints
    path("api/migration/stream/", views_migration.StreamBackupView.as_view(), name="migration_stream"),
]
