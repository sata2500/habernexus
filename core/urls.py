from django.urls import path
from . import views

app_name = 'core'

urlpatterns = [
    path('admin/api-settings/', views.api_settings_view, name='api_settings'),
]
