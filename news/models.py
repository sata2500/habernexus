from django.db import models
from django.utils.text import slugify

from authors.models import Author


class RssSource(models.Model):
    """
    RSS kaynaklarını yönetmek için model.
    Taranacak RSS feed'leri ve tarama sıklıkları burada tanımlanır.
    """

    FREQUENCY_CHOICES = [
        (15, "15 dakika"),
        (30, "30 dakika"),
        (60, "1 saat"),
        (240, "4 saat"),
        (480, "8 saat"),
        (1440, "1 gün"),
    ]

    name = models.CharField(max_length=255, help_text="RSS kaynağının adı (örn: BBC News)")
    url = models.URLField(unique=True, help_text="RSS feed URL'si")
    category = models.CharField(max_length=100, help_text="Kategori (örn: Teknoloji, Spor, Siyaset)")
    frequency_minutes = models.IntegerField(
        choices=FREQUENCY_CHOICES, default=60, help_text="Tarama sıklığı (dakika cinsinden)"
    )
    is_active = models.BooleanField(default=True, help_text="Kaynak aktif mi?")
    last_checked = models.DateTimeField(null=True, blank=True, help_text="Son tarama zamanı")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "RSS Kaynağı"
        verbose_name_plural = "RSS Kaynakları"
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} ({self.category})"


class Article(models.Model):
    """
    Yayınlanan haber yazılarını temsil eden model.
    RSS'den çekilen veriler veya yapay zeka ile üretilen içerikler burada saklanır.
    """

    STATUS_CHOICES = [
        ("draft", "Taslak"),
        ("published", "Yayınlandı"),
        ("archived", "Arşivlendi"),
    ]

    title = models.CharField(max_length=500, help_text="Haber başlığı")
    slug = models.SlugField(unique=True, help_text="URL'de kullanılacak slug")
    content = models.TextField(help_text="Haber içeriği (HTML destekler)")
    excerpt = models.TextField(max_length=500, blank=True, help_text="Haber özeti (SEO için)")
    featured_image = models.ImageField(upload_to="articles/", null=True, blank=True, help_text="Haber başlık görseli")
    featured_image_alt = models.CharField(max_length=255, blank=True, help_text="Görselin alt metni (SEO için)")
    author = models.ForeignKey(Author, on_delete=models.SET_NULL, null=True, related_name="articles", help_text="Yazarı")
    category = models.CharField(max_length=100, help_text="Kategori")
    tags = models.CharField(max_length=500, blank=True, help_text="Etiketler (virgülle ayrılmış)")
    rss_source = models.ForeignKey(
        RssSource,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="articles",
        help_text="Kaynaklandığı RSS kaynağı",
    )
    original_url = models.URLField(blank=True, help_text="Orijinal haber URL'si (RSS'den gelmişse)")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="draft", help_text="Yayın durumu")
    is_ai_generated = models.BooleanField(default=False, help_text="Yapay zeka tarafından mı üretildi?")
    is_ai_image = models.BooleanField(default=False, help_text="Görsel yapay zeka tarafından mı üretildi?")
    views_count = models.IntegerField(default=0, help_text="Görüntülenme sayısı")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    published_at = models.DateTimeField(null=True, blank=True, help_text="Yayınlanma tarihi")

    class Meta:
        verbose_name = "Haber"
        verbose_name_plural = "Haberler"
        ordering = ["-published_at", "-created_at"]
        indexes = [
            models.Index(fields=["-published_at"]),
            models.Index(fields=["category"]),
            models.Index(fields=["status"]),
            models.Index(fields=["author"]),
        ]

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.title)
        super().save(*args, **kwargs)

    def get_absolute_url(self):
        from django.urls import reverse

        return reverse("news:article_detail", kwargs={"slug": self.slug})
