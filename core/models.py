from django.db import models


class Setting(models.Model):
    """
    Sistem ayarlarını tutan model.
    Google AI API anahtarı ve diğer genel ayarlar burada saklanır.
    """

    key = models.CharField(max_length=255, unique=True, help_text="Ayar anahtarı (örn: GOOGLE_API_KEY)")
    value = models.TextField(help_text="Ayar değeri")
    description = models.TextField(blank=True, help_text="Ayarın açıklaması")
    is_secret = models.BooleanField(default=False, help_text="Gizli bilgi mi? (Yönetim panelinde maskelenecek)")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Sistem Ayarı"
        verbose_name_plural = "Sistem Ayarları"
        ordering = ["key"]

    def __str__(self):
        return f"{self.key}: {self.value[:50] if not self.is_secret else '***'}"


class SystemLog(models.Model):
    """
    Sistem hatalarını ve önemli olayları kaydeden model.
    Celery görevleri başarısız olduğunda, hatalar buraya kaydedilir.
    """

    LOG_LEVELS = [
        ("DEBUG", "Debug"),
        ("INFO", "Bilgi"),
        ("WARNING", "Uyarı"),
        ("ERROR", "Hata"),
        ("CRITICAL", "Kritik"),
    ]

    level = models.CharField(max_length=10, choices=LOG_LEVELS, default="INFO", help_text="Log seviyesi")
    task_name = models.CharField(max_length=255, help_text="Görevi tetikleyen Celery task'ının adı")
    message = models.TextField(help_text="Hata veya olay mesajı")
    traceback = models.TextField(blank=True, help_text="Hata stack trace'i (varsa)")
    related_id = models.IntegerField(null=True, blank=True, help_text="İlgili nesnenin ID'si (örn: Article ID)")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Sistem Günlüğü"
        verbose_name_plural = "Sistem Günlükleri"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["-created_at"]),
            models.Index(fields=["task_name"]),
            models.Index(fields=["level"]),
        ]

    def __str__(self):
        return f"[{self.level}] {self.task_name} - {self.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
