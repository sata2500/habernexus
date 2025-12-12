"""
Geliştirilmiş İçerik Üretim Sistemi için Genişletilmiş Modeller
"""

from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models

from .models import Article, RssSource


class ContentQualityMetrics(models.Model):
    """
    Makalenin kalite metriklerini saklar.
    Okunabilirlik, SEO, yapı ve diğer metrikleri içerir.
    """

    article = models.OneToOneField(
        Article, on_delete=models.CASCADE, related_name="quality_metrics", help_text="İlgili makale"
    )

    # Okunabilirlik Metrikleri
    flesch_kincaid_grade = models.FloatField(
        default=0, validators=[MinValueValidator(0), MaxValueValidator(18)], help_text="Flesch-Kincaid okuma seviyesi (0-18)"
    )

    gunning_fog_index = models.FloatField(default=0, help_text="Gunning Fog İndeksi")

    smog_index = models.FloatField(default=0, help_text="SMOG İndeksi")

    # İçerik Metrikleri
    word_count = models.IntegerField(default=0, help_text="Toplam kelime sayısı")

    sentence_count = models.IntegerField(default=0, help_text="Toplam cümle sayısı")

    paragraph_count = models.IntegerField(default=0, help_text="Toplam paragraf sayısı")

    avg_sentence_length = models.FloatField(default=0, help_text="Ortalama cümle uzunluğu (kelime)")

    avg_word_length = models.FloatField(default=0, help_text="Ortalama kelime uzunluğu (karakter)")

    # SEO Metrikleri
    primary_keyword = models.CharField(max_length=100, blank=True, help_text="Birincil anahtar kelime")

    primary_keyword_count = models.IntegerField(default=0, help_text="Birincil anahtar kelime kullanım sayısı")

    secondary_keyword_count = models.IntegerField(default=0, help_text="İkincil anahtar kelime kullanım sayısı")

    keyword_density = models.FloatField(
        default=0, validators=[MinValueValidator(0), MaxValueValidator(100)], help_text="Ana anahtar kelime yoğunluğu (%)"
    )

    meta_description_length = models.IntegerField(default=0, help_text="Meta açıklaması uzunluğu")

    has_internal_links = models.BooleanField(default=False, help_text="İç bağlantılar var mı?")

    internal_link_count = models.IntegerField(default=0, help_text="İç bağlantı sayısı")

    # Yapı Metrikleri
    has_headings = models.BooleanField(default=False, help_text="Başlıklar var mı?")

    heading_count = models.IntegerField(default=0, help_text="Başlık sayısı")

    h2_count = models.IntegerField(default=0, help_text="H2 başlık sayısı")

    h3_count = models.IntegerField(default=0, help_text="H3 başlık sayısı")

    has_lists = models.BooleanField(default=False, help_text="Listeler var mı?")

    list_count = models.IntegerField(default=0, help_text="Liste sayısı")

    has_images = models.BooleanField(default=False, help_text="Görseller var mı?")

    image_count = models.IntegerField(default=0, help_text="Görsel sayısı")

    has_bold_text = models.BooleanField(default=False, help_text="Kalın metin var mı?")

    bold_count = models.IntegerField(default=0, help_text="Kalın metin sayısı")

    # Genel Kalite Puanı
    overall_quality_score = models.FloatField(
        default=0, validators=[MinValueValidator(0), MaxValueValidator(100)], help_text="Genel kalite puanı (0-100)"
    )

    # Tarihler
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "İçerik Kalitesi Metrikleri"
        verbose_name_plural = "İçerik Kalitesi Metrikleri"
        ordering = ["-overall_quality_score"]

    def __str__(self):
        return f"Kalite Metrikleri: {self.article.title[:50]}"


class HeadlineScore(models.Model):
    """
    RSS beslemelerinden çekilen başlıkların kalitesini puanlar.
    En iyi başlıkları seçmek için kullanılır.
    """

    rss_source = models.ForeignKey(
        RssSource, on_delete=models.CASCADE, related_name="headline_scores", help_text="Başlığın kaynağı"
    )

    original_headline = models.CharField(max_length=500, help_text="Orijinal başlık metni")

    # Genel Puan
    overall_score = models.FloatField(
        default=0, validators=[MinValueValidator(0), MaxValueValidator(100)], help_text="Genel başlık kalitesi puanı (0-100)"
    )

    # Puanlama Bileşenleri
    relevance_score = models.FloatField(
        default=0, validators=[MinValueValidator(0), MaxValueValidator(100)], help_text="Konu uygunluğu puanı"
    )

    uniqueness_score = models.FloatField(
        default=0, validators=[MinValueValidator(0), MaxValueValidator(100)], help_text="Orijinallik puanı"
    )

    engagement_score = models.FloatField(
        default=0, validators=[MinValueValidator(0), MaxValueValidator(100)], help_text="Katılım potansiyeli puanı"
    )

    keyword_relevance = models.FloatField(
        default=0, validators=[MinValueValidator(0), MaxValueValidator(100)], help_text="Anahtar kelime uygunluğu"
    )

    # Başlık Özellikleri
    word_count = models.IntegerField(default=0, help_text="Başlıktaki kelime sayısı")

    character_count = models.IntegerField(default=0, help_text="Başlıktaki karakter sayısı")

    has_numbers = models.BooleanField(default=False, help_text="Başlıkta sayı var mı?")

    has_power_words = models.BooleanField(default=False, help_text="Başlıkta güçlü kelimeler var mı?")

    power_words = models.CharField(max_length=255, blank=True, help_text="Bulunan güçlü kelimeler")

    is_question = models.BooleanField(default=False, help_text="Başlık soru mu?")

    is_listicle = models.BooleanField(default=False, help_text="Başlık listicle mi? (örn: '5 Yol')")

    # Durum
    is_processed = models.BooleanField(default=False, help_text="Makaleye dönüştürüldü mü?")

    article = models.ForeignKey(
        Article,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="headline_score",
        help_text="İlgili makale (varsa)",
    )

    # Tarihler
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Başlık Puanı"
        verbose_name_plural = "Başlık Puanları"
        ordering = ["-overall_score", "-created_at"]
        indexes = [
            models.Index(fields=["-overall_score"]),
            models.Index(fields=["is_processed"]),
            models.Index(fields=["rss_source", "-overall_score"]),
        ]

    def __str__(self):
        return f"{self.overall_score:.1f} - {self.original_headline[:50]}"


class ArticleClassification(models.Model):
    """
    Makalenin türü ve kategorisini saklar.
    Dinamik prompt oluşturma ve model seçimi için kullanılır.
    """

    ARTICLE_TYPE_CHOICES = [
        ("news", "Haber"),
        ("analysis", "Analiz"),
        ("feature", "Röportaj"),
        ("opinion", "Köşe Yazısı"),
        ("tutorial", "Rehber"),
        ("interview", "Röportaj"),
        ("breaking", "Son Dakika"),
    ]

    RESEARCH_DEPTH_CHOICES = [
        (0, "Minimal - Sadece RSS kaynağı"),
        (1, "Normal - Temel araştırma"),
        (2, "Derinlemesine - Kapsamlı araştırma"),
    ]

    article = models.OneToOneField(Article, on_delete=models.CASCADE, related_name="classification", help_text="İlgili makale")

    # Tür Sınıflandırması
    article_type = models.CharField(max_length=20, choices=ARTICLE_TYPE_CHOICES, default="news", help_text="Makale türü")

    type_confidence = models.FloatField(
        default=0, validators=[MinValueValidator(0), MaxValueValidator(1)], help_text="Tür sınıflandırması güven puanı (0-1)"
    )

    # Kategori
    primary_category = models.CharField(max_length=100, help_text="Birincil kategori")

    secondary_categories = models.CharField(max_length=500, blank=True, help_text="İkincil kategoriler (virgülle ayrılmış)")

    # Araştırma Derinliği
    research_depth = models.IntegerField(choices=RESEARCH_DEPTH_CHOICES, default=1, help_text="Gereken araştırma derinliği")

    # AI Model Seçimi
    recommended_ai_model = models.CharField(max_length=50, default="gemini-2.5-flash", help_text="Önerilen AI modeli")

    # Ek Bilgiler
    requires_fact_checking = models.BooleanField(default=True, help_text="Gerçeklik kontrolü gerekli mi?")

    is_time_sensitive = models.BooleanField(default=False, help_text="Zamana bağlı haber mi?")

    is_controversial = models.BooleanField(default=False, help_text="Tartışmalı bir konu mu?")

    target_audience = models.CharField(max_length=100, blank=True, help_text="Hedef kitle")

    tone = models.CharField(
        max_length=50,
        blank=True,
        choices=[
            ("formal", "Resmi"),
            ("casual", "Rahat"),
            ("technical", "Teknik"),
            ("emotional", "Duygusal"),
            ("neutral", "Tarafsız"),
        ],
        help_text="Yazının tonu",
    )

    # Tarihler
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Makale Sınıflandırması"
        verbose_name_plural = "Makale Sınıflandırmaları"

    def __str__(self):
        return f"{self.get_article_type_display()} - {self.article.title[:50]}"


class ResearchSource(models.Model):
    """
    Makale üretimi sırasında kullanılan araştırma kaynaklarını saklar.
    """

    article = models.ForeignKey(Article, on_delete=models.CASCADE, related_name="research_sources", help_text="İlgili makale")

    source_url = models.URLField(help_text="Kaynağın URL'si")

    source_title = models.CharField(max_length=500, help_text="Kaynağın başlığı")

    source_type = models.CharField(
        max_length=50,
        choices=[
            ("news", "Haber Sitesi"),
            ("academic", "Akademik"),
            ("official", "Resmi Kaynak"),
            ("blog", "Blog"),
            ("social", "Sosyal Medya"),
            ("other", "Diğer"),
        ],
        default="news",
        help_text="Kaynağın türü",
    )

    relevance_score = models.FloatField(
        default=0, validators=[MinValueValidator(0), MaxValueValidator(1)], help_text="Makaleye uygunluk puanı (0-1)"
    )

    used_for = models.CharField(max_length=255, blank=True, help_text="Kaynağın hangi amaç için kullanıldığı")

    extracted_text = models.TextField(blank=True, help_text="Kaynaktan çıkarılan metin")

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Araştırma Kaynağı"
        verbose_name_plural = "Araştırma Kaynakları"
        ordering = ["-relevance_score", "-created_at"]

    def __str__(self):
        return f"{self.source_title[:50]} - {self.article.title[:30]}"


class ContentGenerationLog(models.Model):
    """
    İçerik üretim sürecinin her aşamasını loglar.
    Hata ayıklama ve performans analizi için kullanılır.
    """

    STAGE_CHOICES = [
        ("fetch", "RSS Tarama"),
        ("score", "Başlık Puanlaması"),
        ("classify", "Sınıflandırma"),
        ("research", "Araştırma"),
        ("generate", "İçerik Üretimi"),
        ("quality_check", "Kalite Kontrol"),
        ("image_generation", "Görsel Üretimi"),
        ("publish", "Yayınlama"),
    ]

    article = models.ForeignKey(Article, on_delete=models.CASCADE, related_name="generation_logs", help_text="İlgili makale")

    stage = models.CharField(max_length=20, choices=STAGE_CHOICES, help_text="İşlem aşaması")

    status = models.CharField(
        max_length=20,
        choices=[
            ("started", "Başladı"),
            ("in_progress", "Devam Ediyor"),
            ("completed", "Tamamlandı"),
            ("failed", "Başarısız"),
            ("skipped", "Atlandı"),
        ],
        help_text="Aşama durumu",
    )

    duration = models.IntegerField(default=0, help_text="İşlem süresi (milisaniye)")

    input_data = models.JSONField(default=dict, blank=True, help_text="Aşamaya gelen veriler")

    output_data = models.JSONField(default=dict, blank=True, help_text="Aşamadan çıkan veriler")

    error_message = models.TextField(blank=True, help_text="Hata mesajı (varsa)")

    error_traceback = models.TextField(blank=True, help_text="Hata izlemesi (varsa)")

    ai_model_used = models.CharField(max_length=50, blank=True, help_text="Kullanılan AI modeli")

    api_calls_count = models.IntegerField(default=0, help_text="Yapılan API çağrısı sayısı")

    tokens_used = models.IntegerField(default=0, help_text="Kullanılan token sayısı")

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "İçerik Üretim Logu"
        verbose_name_plural = "İçerik Üretim Logları"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["article", "stage"]),
            models.Index(fields=["status"]),
            models.Index(fields=["-created_at"]),
        ]

    def __str__(self):
        return f"{self.get_stage_display()} - {self.get_status_display()}"
