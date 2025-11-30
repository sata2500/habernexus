from django.contrib import admin
from django.utils.html import format_html

from .models import Setting, SystemLog


@admin.register(Setting)
class SettingAdmin(admin.ModelAdmin):
    list_display = ("key", "value_display", "is_secret", "updated_at")
    list_filter = ("is_secret", "created_at")
    search_fields = ("key", "description")
    readonly_fields = ("created_at", "updated_at")
    fieldsets = (
        ("Temel Bilgiler", {"fields": ("key", "value", "is_secret")}),
        ("Açıklama", {"fields": ("description",), "classes": ("collapse",)}),
        ("Tarihler", {"fields": ("created_at", "updated_at"), "classes": ("collapse",)}),
    )

    def value_display(self, obj):
        if obj.is_secret:
            return format_html('<span style="color: red;">***</span>')
        return obj.value[:50] + ("..." if len(obj.value) > 50 else "")

    value_display.short_description = "Değer"


@admin.register(SystemLog)
class SystemLogAdmin(admin.ModelAdmin):
    list_display = ("level_badge", "task_name", "message_preview", "created_at")
    list_filter = ("level", "task_name", "created_at")
    search_fields = ("task_name", "message")
    readonly_fields = ("created_at", "traceback", "message")
    date_hierarchy = "created_at"

    fieldsets = (
        ("Log Bilgileri", {"fields": ("level", "task_name", "message")}),
        ("Detaylar", {"fields": ("related_id", "traceback"), "classes": ("collapse",)}),
        ("Tarih", {"fields": ("created_at",), "classes": ("collapse",)}),
    )

    def level_badge(self, obj):
        colors = {
            "DEBUG": "#808080",
            "INFO": "#0066cc",
            "WARNING": "#ff9900",
            "ERROR": "#cc0000",
            "CRITICAL": "#990000",
        }
        color = colors.get(obj.level, "#000000")
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{}</span>',
            color,
            obj.level,
        )

    level_badge.short_description = "Seviye"

    def message_preview(self, obj):
        return obj.message[:100] + ("..." if len(obj.message) > 100 else "")

    message_preview.short_description = "Mesaj"

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return request.user.is_superuser
