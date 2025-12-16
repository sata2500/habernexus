"""
HaberNexus Newsletter Models
E-posta abonelik sistemi için modeller.
"""

import uuid

from django.db import models
from django.utils import timezone


class NewsletterSubscriber(models.Model):
    """
    Newsletter abonelerini yöneten model.
    """

    FREQUENCY_CHOICES = [
        ("daily", "Günlük"),
        ("weekly", "Haftalık"),
        ("monthly", "Aylık"),
    ]

    email = models.EmailField(unique=True, help_text="Abone e-posta adresi")
    name = models.CharField(max_length=100, blank=True, help_text="Abone adı (opsiyonel)")
    is_active = models.BooleanField(default=True, help_text="Abonelik aktif mi?")
    is_verified = models.BooleanField(default=False, help_text="E-posta doğrulandı mı?")
    frequency = models.CharField(
        max_length=20, choices=FREQUENCY_CHOICES, default="daily", help_text="E-posta gönderim sıklığı"
    )
    token = models.UUIDField(default=uuid.uuid4, unique=True, help_text="Abonelik yönetim tokeni")
    verification_token = models.UUIDField(default=uuid.uuid4, help_text="E-posta doğrulama tokeni")
    subscribed_at = models.DateTimeField(auto_now_add=True)
    verified_at = models.DateTimeField(null=True, blank=True, help_text="Doğrulama tarihi")
    unsubscribed_at = models.DateTimeField(null=True, blank=True, help_text="Abonelik iptal tarihi")
    last_email_sent = models.DateTimeField(null=True, blank=True, help_text="Son e-posta gönderim tarihi")
    ip_address = models.GenericIPAddressField(null=True, blank=True, help_text="Kayıt IP adresi")

    class Meta:
        verbose_name = "Newsletter Abonesi"
        verbose_name_plural = "Newsletter Aboneleri"
        ordering = ["-subscribed_at"]
        indexes = [
            models.Index(fields=["email"]),
            models.Index(fields=["is_active", "is_verified"]),
            models.Index(fields=["token"]),
        ]

    def __str__(self):
        status = "Aktif" if self.is_active else "Pasif"
        return f"{self.email} ({status})"

    def verify(self):
        """E-posta adresini doğrula."""
        self.is_verified = True
        self.verified_at = timezone.now()
        self.save(update_fields=["is_verified", "verified_at"])

    def unsubscribe(self):
        """Aboneliği iptal et."""
        self.is_active = False
        self.unsubscribed_at = timezone.now()
        self.save(update_fields=["is_active", "unsubscribed_at"])

    def resubscribe(self):
        """Aboneliği yeniden aktifleştir."""
        self.is_active = True
        self.unsubscribed_at = None
        self.token = uuid.uuid4()  # Yeni token oluştur
        self.save(update_fields=["is_active", "unsubscribed_at", "token"])


class NewsletterEmail(models.Model):
    """
    Gönderilen newsletter e-postalarını takip eden model.
    """

    STATUS_CHOICES = [
        ("draft", "Taslak"),
        ("scheduled", "Zamanlanmış"),
        ("sending", "Gönderiliyor"),
        ("sent", "Gönderildi"),
        ("failed", "Başarısız"),
    ]

    subject = models.CharField(max_length=255, help_text="E-posta konusu")
    content = models.TextField(help_text="E-posta içeriği (HTML)")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="draft", help_text="Gönderim durumu")
    scheduled_at = models.DateTimeField(null=True, blank=True, help_text="Zamanlanmış gönderim tarihi")
    sent_at = models.DateTimeField(null=True, blank=True, help_text="Gönderim tarihi")
    recipients_count = models.IntegerField(default=0, help_text="Alıcı sayısı")
    opened_count = models.IntegerField(default=0, help_text="Açılma sayısı")
    clicked_count = models.IntegerField(default=0, help_text="Tıklanma sayısı")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Newsletter E-postası"
        verbose_name_plural = "Newsletter E-postaları"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.subject} ({self.get_status_display()})"

    @property
    def open_rate(self):
        """Açılma oranını hesapla."""
        if self.recipients_count > 0:
            return round((self.opened_count / self.recipients_count) * 100, 1)
        return 0

    @property
    def click_rate(self):
        """Tıklanma oranını hesapla."""
        if self.recipients_count > 0:
            return round((self.clicked_count / self.recipients_count) * 100, 1)
        return 0
