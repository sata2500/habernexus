"""
HaberNexus Newsletter Admin
Newsletter modelleri için admin paneli yapılandırması.
"""

from django.contrib import admin

from .models_newsletter import NewsletterEmail, NewsletterSubscriber


@admin.register(NewsletterSubscriber)
class NewsletterSubscriberAdmin(admin.ModelAdmin):
    """
    Newsletter aboneleri için admin paneli.
    """

    list_display = [
        "email",
        "name",
        "frequency",
        "is_active",
        "is_verified",
        "subscribed_at",
        "last_email_sent",
    ]
    list_filter = ["is_active", "is_verified", "frequency", "subscribed_at"]
    search_fields = ["email", "name"]
    readonly_fields = ["token", "verification_token", "subscribed_at", "verified_at", "unsubscribed_at", "ip_address"]
    ordering = ["-subscribed_at"]

    fieldsets = (
        (
            "Abone Bilgileri",
            {
                "fields": ("email", "name", "frequency"),
            },
        ),
        (
            "Durum",
            {
                "fields": ("is_active", "is_verified"),
            },
        ),
        (
            "Tarihler",
            {
                "fields": ("subscribed_at", "verified_at", "unsubscribed_at", "last_email_sent"),
                "classes": ("collapse",),
            },
        ),
        (
            "Teknik Bilgiler",
            {
                "fields": ("token", "verification_token", "ip_address"),
                "classes": ("collapse",),
            },
        ),
    )

    actions = ["activate_subscribers", "deactivate_subscribers"]

    def activate_subscribers(self, request, queryset):
        """Seçili aboneleri aktifleştir."""
        updated = queryset.update(is_active=True)
        self.message_user(request, f"{updated} abone aktifleştirildi.")

    activate_subscribers.short_description = "Seçili aboneleri aktifleştir"

    def deactivate_subscribers(self, request, queryset):
        """Seçili aboneleri deaktifleştir."""
        updated = queryset.update(is_active=False)
        self.message_user(request, f"{updated} abone deaktifleştirildi.")

    deactivate_subscribers.short_description = "Seçili aboneleri deaktifleştir"


@admin.register(NewsletterEmail)
class NewsletterEmailAdmin(admin.ModelAdmin):
    """
    Newsletter e-postaları için admin paneli.
    """

    list_display = [
        "subject",
        "status",
        "recipients_count",
        "opened_count",
        "clicked_count",
        "open_rate_display",
        "sent_at",
        "created_at",
    ]
    list_filter = ["status", "created_at", "sent_at"]
    search_fields = ["subject"]
    readonly_fields = [
        "recipients_count",
        "opened_count",
        "clicked_count",
        "sent_at",
        "created_at",
        "updated_at",
    ]
    ordering = ["-created_at"]

    fieldsets = (
        (
            "E-posta İçeriği",
            {
                "fields": ("subject", "content"),
            },
        ),
        (
            "Durum",
            {
                "fields": ("status", "scheduled_at"),
            },
        ),
        (
            "İstatistikler",
            {
                "fields": ("recipients_count", "opened_count", "clicked_count"),
                "classes": ("collapse",),
            },
        ),
        (
            "Tarihler",
            {
                "fields": ("sent_at", "created_at", "updated_at"),
                "classes": ("collapse",),
            },
        ),
    )

    def open_rate_display(self, obj):
        """Açılma oranını göster."""
        return f"{obj.open_rate}%"

    open_rate_display.short_description = "Açılma Oranı"
