"""
HaberNexus - Geliştirilmiş Modeller (v2.0)
Yazar-kategori mapping, prompt template'leri, SEO ve medya yönetimi
"""

from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from django.utils.text import slugify


# ============================================================================
# YAZAR-KATEGORİ MAPPING
# ============================================================================

class AuthorCategoryMapping(models.Model):
    """
    Yazarların hangi kategorilerde uzman olduğunu ve tercihlerini belirten model.
    Kategori-yazar eşleştirmesi ile doğru yazarın seçilmesini sağlar.
    """
    
    EXPERTISE_LEVELS = [
        (1, 'Başlangıç'),
        (2, 'Orta'),
        (3, 'İyi'),
        (4, 'Çok İyi'),
        (5, 'Uzman'),
    ]
    
    author = models.ForeignKey(
        'authors.Author',
        on_delete=models.CASCADE,
        related_name='category_mappings'
    )
    category = models.CharField(
        max_length=100,
        help_text="Kategori adı (Teknoloji, Sağlık, vb.)"
    )
    expertise_level = models.IntegerField(
        choices=EXPERTISE_LEVELS,
        default=1,
        help_text="Yazarın bu kategorideki uzmanlık seviyesi"
    )
    is_primary = models.BooleanField(
        default=False,
        help_text="Bu yazarın birincil kategorisi mi?"
    )
    
    # Yazı stili tercihleri
    preferred_tone = models.CharField(
        max_length=50,
        choices=[
            ('formal', 'Resmi'),
            ('professional', 'Profesyonel'),
            ('casual', 'Rahat'),
            ('academic', 'Akademik'),
        ],
        default='professional',
        help_text="Yazarın tercih ettiği ton"
    )
    
    average_word_count = models.IntegerField(
        default=700,
        validators=[MinValueValidator(300), MaxValueValidator(2000)],
        help_text="Yazarın ortalama yazı uzunluğu (kelime)"
    )
    
    # İstatistikler
    articles_written = models.IntegerField(default=0, help_text="Bu kategoride yazılan makale sayısı")
    average_engagement = models.FloatField(default=0, help_text="Ortalama engagement oranı")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('author', 'category')
        verbose_name = "Yazar Kategori Eşleştirmesi"
        verbose_name_plural = "Yazar Kategori Eşleştirmeleri"
        ordering = ['-expertise_level', '-is_primary', '-articles_written']
        indexes = [
            models.Index(fields=['category', '-expertise_level']),
            models.Index(fields=['author', 'category']),
        ]
    
    def __str__(self):
        return f"{self.author.name} - {self.category} (Level {self.expertise_level})"


# ============================================================================
# PROMPT TEMPLATE'LERİ
# ============================================================================

class PromptTemplate(models.Model):
    """
    Kategori ve yazı stiline göre dinamik prompt template'leri.
    AI modellerine gönderilen prompt'ları özelleştirir.
    """
    
    TEMPLATE_TYPES = [
        ('article', 'Makale'),
        ('summary', 'Özet'),
        ('headline', 'Başlık'),
        ('social', 'Sosyal Medya'),
    ]
    
    name = models.CharField(
        max_length=255,
        unique=True,
        help_text="Template adı (örn: 'Teknoloji Makalesi')"
    )
    
    category = models.CharField(
        max_length=100,
        help_text="Hangi kategoriye ait"
    )
    
    template_type = models.CharField(
        max_length=50,
        choices=TEMPLATE_TYPES,
        default='article',
        help_text="Template türü"
    )
    
    template_content = models.TextField(
        help_text="""
        Template değişkenleri:
        {title} - Başlık
        {summary} - Özet
        {author_name} - Yazar adı
        {author_expertise} - Yazar uzmanlığı
        {category} - Kategori
        {tone} - Ton
        {word_count} - Kelime sayısı
        {importance_level} - Önem seviyesi
        """
    )
    
    is_active = models.BooleanField(
        default=True,
        help_text="Bu template aktif mi?"
    )
    
    version = models.IntegerField(
        default=1,
        help_text="Template versiyonu"
    )
    
    # Performans metrikleri
    usage_count = models.IntegerField(default=0, help_text="Kaç kez kullanıldı")
    average_quality_score = models.FloatField(default=0, help_text="Ortalama kalite puanı")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Prompt Template"
        verbose_name_plural = "Prompt Template'leri"
        ordering = ['-is_active', '-usage_count', 'category']
        indexes = [
            models.Index(fields=['category', 'template_type', '-is_active']),
        ]
    
    def __str__(self):
        return f"{self.name} (v{self.version})"


# ============================================================================
# SEO OPTİMİZASYONU
# ============================================================================

class ArticleSEO(models.Model):
    """
    Makale SEO optimizasyonu ve meta tag'ları.
    Arama motoru ve sosyal medya görünürlüğünü artırır.
    """
    
    article = models.OneToOneField(
        'Article',
        on_delete=models.CASCADE,
        related_name='seo'
    )
    
    # Meta Tag'ları
    meta_description = models.CharField(
        max_length=160,
        help_text="Google'da görünecek açıklama (max 160 karakter)"
    )
    
    meta_keywords = models.CharField(
        max_length=255,
        help_text="Anahtar kelimeler (virgülle ayrılmış)"
    )
    
    # Canonical URL
    canonical_url = models.URLField(
        blank=True,
        help_text="Canonical URL (duplicate content'i önlemek için)"
    )
    
    # Open Graph Tag'ları (Sosyal Medya)
    og_title = models.CharField(
        max_length=95,
        help_text="Sosyal medyada görünecek başlık"
    )
    
    og_description = models.CharField(
        max_length=200,
        help_text="Sosyal medyada görünecek açıklama"
    )
    
    og_image = models.URLField(
        blank=True,
        help_text="Sosyal medyada görünecek görsel URL"
    )
    
    # Twitter Card'ları
    twitter_title = models.CharField(
        max_length=70,
        blank=True,
        help_text="Twitter'da görünecek başlık"
    )
    
    twitter_description = models.CharField(
        max_length=200,
        blank=True,
        help_text="Twitter'da görünecek açıklama"
    )
    
    # Structured Data (Schema.org)
    schema_type = models.CharField(
        max_length=50,
        choices=[
            ('NewsArticle', 'Haber Makalesi'),
            ('BlogPosting', 'Blog Yazısı'),
            ('Report', 'Rapor'),
        ],
        default='NewsArticle',
        help_text="Structured data türü"
    )
    
    # SEO Puanlaması
    seo_score = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Genel SEO puanı (0-100)"
    )
    
    readability_score = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Okunabilirlik puanı (0-100)"
    )
    
    keyword_optimization_score = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Anahtar kelime optimizasyonu puanı (0-100)"
    )
    
    # Teknik SEO
    has_h1 = models.BooleanField(default=False, help_text="H1 tag'ı var mı?")
    has_meta_description = models.BooleanField(default=False, help_text="Meta description var mı?")
    has_alt_text = models.BooleanField(default=False, help_text="Görsellerde alt text var mı?")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Makale SEO"
        verbose_name_plural = "Makale SEO'ları"
        ordering = ['-seo_score', '-created_at']
    
    def __str__(self):
        return f"SEO - {self.article.title[:50]}"
    
    def calculate_seo_score(self):
        """
        SEO puanını hesapla
        """
        score = 0
        
        # Meta description (25 puan)
        if self.meta_description and 120 <= len(self.meta_description) <= 160:
            score += 25
        elif self.meta_description:
            score += 15
        
        # Keywords (25 puan)
        if self.meta_keywords and len(self.meta_keywords.split(',')) >= 3:
            score += 25
        elif self.meta_keywords:
            score += 15
        
        # Open Graph (20 puan)
        if self.og_title and self.og_description and self.og_image:
            score += 20
        elif self.og_title and self.og_description:
            score += 10
        
        # Teknik SEO (30 puan)
        if self.has_h1:
            score += 10
        if self.has_meta_description:
            score += 10
        if self.has_alt_text:
            score += 10
        
        self.seo_score = min(100, score)
        return self.seo_score


# ============================================================================
# MEDYA YÖNETİMİ
# ============================================================================

class ArticleMedia(models.Model):
    """
    Makale medya dosyaları (görsel, video) ve metadata.
    Çoklu format desteği (AVIF, WebP, JPEG, MP4, HLS).
    """
    
    article = models.OneToOneField(
        'Article',
        on_delete=models.CASCADE,
        related_name='media'
    )
    
    # ===== GÖRSEL =====
    # Orijinal görsel
    featured_image_original = models.ImageField(
        upload_to='articles/original/',
        null=True,
        blank=True,
        help_text="Orijinal görsel dosyası"
    )
    
    # Optimize edilmiş görseller
    featured_image_avif = models.ImageField(
        upload_to='articles/featured/',
        null=True,
        blank=True,
        help_text="AVIF format (en iyi sıkıştırma)"
    )
    
    featured_image_webp = models.ImageField(
        upload_to='articles/featured/',
        null=True,
        blank=True,
        help_text="WebP format (fallback)"
    )
    
    featured_image_jpeg = models.ImageField(
        upload_to='articles/featured/',
        null=True,
        blank=True,
        help_text="JPEG format (legacy)"
    )
    
    # Görsel metadata
    featured_image_alt = models.CharField(
        max_length=255,
        blank=True,
        help_text="Görsel alt text (SEO ve accessibility)"
    )
    
    featured_image_credit = models.CharField(
        max_length=255,
        blank=True,
        help_text="Görsel kaynağı/fotoğrafçı"
    )
    
    featured_image_width = models.IntegerField(null=True, blank=True)
    featured_image_height = models.IntegerField(null=True, blank=True)
    
    # ===== VİDEO =====
    # Orijinal video
    summary_video_original = models.FileField(
        upload_to='articles/video/',
        null=True,
        blank=True,
        help_text="Orijinal video dosyası"
    )
    
    # Encode edilmiş videolar
    summary_video_1080p = models.FileField(
        upload_to='articles/video/',
        null=True,
        blank=True,
        help_text="1080p video (yüksek kalite)"
    )
    
    summary_video_720p = models.FileField(
        upload_to='articles/video/',
        null=True,
        blank=True,
        help_text="720p video (orta kalite)"
    )
    
    summary_video_480p = models.FileField(
        upload_to='articles/video/',
        null=True,
        blank=True,
        help_text="480p video (mobil)"
    )
    
    # HLS Streaming
    summary_video_hls_manifest = models.FileField(
        upload_to='articles/video/hls/',
        null=True,
        blank=True,
        help_text="HLS manifest dosyası"
    )
    
    # Video metadata
    video_duration = models.IntegerField(
        null=True,
        blank=True,
        help_text="Video uzunluğu (saniye)"
    )
    
    video_width = models.IntegerField(null=True, blank=True)
    video_height = models.IntegerField(null=True, blank=True)
    
    # ===== KALİTE METRİKLERİ =====
    image_quality_score = models.FloatField(
        null=True,
        blank=True,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Görsel kalite puanı (0-100)"
    )
    
    video_quality_score = models.FloatField(
        null=True,
        blank=True,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Video kalite puanı (0-100)"
    )
    
    # ===== İŞLEME BİLGİLERİ =====
    image_processing_status = models.CharField(
        max_length=50,
        choices=[
            ('pending', 'Beklemede'),
            ('processing', 'İşleniyor'),
            ('completed', 'Tamamlandı'),
            ('failed', 'Başarısız'),
        ],
        default='pending',
        help_text="Görsel işleme durumu"
    )
    
    video_processing_status = models.CharField(
        max_length=50,
        choices=[
            ('pending', 'Beklemede'),
            ('processing', 'İşleniyor'),
            ('completed', 'Tamamlandı'),
            ('failed', 'Başarısız'),
        ],
        default='pending',
        help_text="Video işleme durumu"
    )
    
    image_processing_error = models.TextField(blank=True, help_text="Görsel işleme hatası")
    video_processing_error = models.TextField(blank=True, help_text="Video işleme hatası")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Makale Medyası"
        verbose_name_plural = "Makale Medyaları"
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Media - {self.article.title[:50]}"


# ============================================================================
# MEDYA İŞLEME LOG'U
# ============================================================================

class MediaProcessingLog(models.Model):
    """
    Medya işleme (görsel, video) log'ları ve performans metrikleri.
    """
    
    MEDIA_TYPES = [
        ('image', 'Görsel'),
        ('video', 'Video'),
    ]
    
    STATUSES = [
        ('processing', 'İşleniyor'),
        ('completed', 'Tamamlandı'),
        ('failed', 'Başarısız'),
    ]
    
    article = models.ForeignKey(
        'Article',
        on_delete=models.CASCADE,
        related_name='media_logs'
    )
    
    media_type = models.CharField(
        max_length=50,
        choices=MEDIA_TYPES,
        help_text="Medya türü"
    )
    
    status = models.CharField(
        max_length=50,
        choices=STATUSES,
        help_text="İşleme durumu"
    )
    
    # Dosya boyutları
    original_size = models.BigIntegerField(
        help_text="Orijinal dosya boyutu (bytes)"
    )
    
    optimized_size = models.BigIntegerField(
        null=True,
        blank=True,
        help_text="Optimize edilmiş dosya boyutu (bytes)"
    )
    
    compression_ratio = models.FloatField(
        null=True,
        blank=True,
        help_text="Sıkıştırma oranı (%)"
    )
    
    # Performans
    processing_time = models.FloatField(
        help_text="İşleme süresi (saniye)"
    )
    
    # Hata
    error_message = models.TextField(
        blank=True,
        help_text="Hata mesajı (varsa)"
    )
    
    # Metadata
    source_url = models.URLField(
        blank=True,
        help_text="Medya kaynağı URL"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Medya İşleme Log'u"
        verbose_name_plural = "Medya İşleme Log'ları"
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['article', 'media_type', '-created_at']),
            models.Index(fields=['status', '-created_at']),
        ]
    
    def __str__(self):
        return f"{self.get_media_type_display()} - {self.article.title[:30]} ({self.status})"


# ContentGenerationLog modeli models_extended.py'de zaten tanımlanmıştır
# Bu dosyada tekrar tanımlanmaz - çakışmayı önlemek için

