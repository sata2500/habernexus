"""
HaberNexus API Permissions
REST API için izin sınıfları.
"""

from rest_framework import permissions


class IsAdminOrReadOnly(permissions.BasePermission):
    """
    Admin kullanıcılar tam erişim, diğerleri sadece okuma.
    """

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user and request.user.is_staff


class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Nesne sahibi tam erişim, diğerleri sadece okuma.
    """

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.author == request.user if hasattr(obj, "author") else False


class IsAuthenticatedOrReadOnly(permissions.BasePermission):
    """
    Kimliği doğrulanmış kullanıcılar yazma, diğerleri sadece okuma.
    """

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user and request.user.is_authenticated


class APIKeyPermission(permissions.BasePermission):
    """
    API Key ile kimlik doğrulama.
    Header: X-API-Key
    """

    def has_permission(self, request, view):
        from core.models import Setting

        api_key = request.headers.get("X-API-Key")
        if not api_key:
            return False

        try:
            setting = Setting.objects.get(key="API_KEY")
            return api_key == setting.value
        except Setting.DoesNotExist:
            return False
