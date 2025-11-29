from django.db import models
from django.core.validators import URLValidator


class Author(models.Model):
    """
    Haber yazarlarını temsil eden model.
    Her yazı bir yazar tarafından yazılmış gibi görünecektir.
    """
    name = models.CharField(
        max_length=255,
        help_text="Yazarın tam adı"
    )
    slug = models.SlugField(
        unique=True,
        help_text="URL'de kullanılacak slug (örn: salih-tanriseven)"
    )
    bio = models.TextField(
        blank=True,
        help_text="Yazarın biyografisi"
    )
    expertise = models.CharField(
        max_length=255,
        help_text="Yazarın uzmanlık alanı (örn: Teknoloji, Spor, Siyaset)"
    )
    profile_image = models.ImageField(
        upload_to='authors/',
        null=True,
        blank=True,
        help_text="Yazarın profil resmi"
    )
    email = models.EmailField(
        blank=True,
        help_text="Yazarın e-posta adresi"
    )
    website = models.URLField(
        blank=True,
        help_text="Yazarın web sitesi"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Yazar aktif mi?"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Yazar"
        verbose_name_plural = "Yazarlar"
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.expertise})"

    def get_absolute_url(self):
        from django.urls import reverse
        return reverse('author_detail', kwargs={'slug': self.slug})
