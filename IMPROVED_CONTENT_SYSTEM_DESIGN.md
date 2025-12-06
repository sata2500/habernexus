# Geliştirilmiş İçerik Üretim Sistemi - Tasarım Dökümanı

## 1. Sistem Mimarisi Genel Bakış

### 1.1 Yeni İş Akışı

```
RSS Kaynakları
    ↓
[1] Beslenme Tarama (fetch_rss_feeds)
    ↓
[2] Başlık Kalitesi Puanlaması (score_headlines)
    ↓
[3] Haber Sınıflandırması (classify_articles)
    ↓
[4] İçerik Üretimi (generate_ai_content) - Paralel
    ├─ Araştırma Yapma (research_content)
    ├─ Prompt Oluşturma (create_dynamic_prompt)
    └─ AI Çağrısı (call_gemini_api)
    ↓
[5] Kalite Kontrol (quality_check)
    ├─ Okunabilirlik Kontrol
    ├─ Gerçeklik Kontrolü
    └─ SEO Kontrolü
    ↓
[6] Görsel Üretimi (generate_article_image)
    ↓
[7] Yayınlama (publish_article)
```

## 2. Veritabanı Şeması Genişletmeleri

### 2.1 Article Model Yeni Alanları

```python
class Article(models.Model):
    # Mevcut alanlar...
    
    # YENİ ALANLAR
    article_type = models.CharField(
        max_length=20,
        choices=[
            ('news', 'Haber'),
            ('analysis', 'Analiz'),
            ('feature', 'Röportaj'),
            ('opinion', 'Köşe Yazısı'),
            ('tutorial', 'Rehber'),
        ],
        default='news'
    )
    
    quality_score = models.FloatField(
        default=0.0,
        help_text="0-100 arası içerik kalitesi puanı"
    )
    
    headline_score = models.FloatField(
        default=0.0,
        help_text="0-100 arası başlık kalitesi puanı"
    )
    
    source_reliability = models.FloatField(
        default=0.5,
        help_text="0-1 arası kaynak güvenilirliği"
    )
    
    ai_model_used = models.CharField(
        max_length=50,
        default='gemini-2.5-flash',
        help_text="Hangi AI modeli kullanıldı"
    )
    
    research_depth = models.IntegerField(
        default=0,
        choices=[(0, 'Minimal'), (1, 'Normal'), (2, 'Derinlemesine')],
        help_text="Araştırma derinliği"
    )
    
    fact_check_status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'Beklemede'),
            ('verified', 'Doğrulandı'),
            ('partial', 'Kısmen Doğru'),
            ('disputed', 'Tartışmalı'),
        ],
        default='pending'
    )
    
    readability_score = models.FloatField(
        default=0.0,
        help_text="Flesch-Kincaid okunabilirlik puanı"
    )
    
    keyword_density = models.FloatField(
        default=0.0,
        help_text="Ana anahtar kelime yoğunluğu (%)"
    )
    
    research_sources = models.JSONField(
        default=list,
        blank=True,
        help_text="Araştırma sırasında kullanılan kaynaklar"
    )
    
    ai_confidence = models.FloatField(
        default=0.0,
        help_text="AI'nın kendi güven puanı (0-1)"
    )
    
    processing_time = models.IntegerField(
        default=0,
        help_text="İşlem süresi (saniye)"
    )
```

### 2.2 Yeni Model: ContentQualityMetrics

```python
class ContentQualityMetrics(models.Model):
    article = models.OneToOneField(
        Article,
        on_delete=models.CASCADE,
        related_name='quality_metrics'
    )
    
    # Okunabilirlik Metrikleri
    flesch_kincaid_grade = models.FloatField(default=0)
    gunning_fog_index = models.FloatField(default=0)
    smog_index = models.FloatField(default=0)
    
    # İçerik Metrikleri
    word_count = models.IntegerField(default=0)
    sentence_count = models.IntegerField(default=0)
    paragraph_count = models.IntegerField(default=0)
    avg_sentence_length = models.FloatField(default=0)
    
    # SEO Metrikleri
    primary_keyword_count = models.IntegerField(default=0)
    secondary_keyword_count = models.IntegerField(default=0)
    meta_description_length = models.IntegerField(default=0)
    has_internal_links = models.BooleanField(default=False)
    
    # Yapı Metrikleri
    has_headings = models.BooleanField(default=False)
    heading_count = models.IntegerField(default=0)
    has_lists = models.BooleanField(default=False)
    has_images = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

### 2.3 Yeni Model: HeadlineScore

```python
class HeadlineScore(models.Model):
    rss_source = models.ForeignKey(RssSource, on_delete=models.CASCADE)
    
    original_headline = models.CharField(max_length=500)
    score = models.FloatField(help_text="0-100 arası başlık kalitesi")
    
    # Puanlama Bileşenleri
    relevance_score = models.FloatField(default=0)
    uniqueness_score = models.FloatField(default=0)
    engagement_score = models.FloatField(default=0)
    keyword_relevance = models.FloatField(default=0)
    
    # Meta Bilgiler
    word_count = models.IntegerField(default=0)
    character_count = models.IntegerField(default=0)
    has_numbers = models.BooleanField(default=False)
    has_power_words = models.BooleanField(default=False)
    
    is_processed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
```

## 3. Görev Tasarımı (Tasks)

### 3.1 Başlık Puanlaması Görevi

```python
@shared_task(queue='default')
def score_headlines():
    """
    RSS beslemelerinden çekilen başlıkları puanla ve en iyilerini seç.
    Hedef: 2 saatte 10 kaliteli başlık seçmek
    """
    # 1. Son 2 saatte çekilen işlenmemiş başlıkları al
    # 2. Her başlık için puanlama yap:
    #    - Orijinallik (duplicate check)
    #    - Anahtar kelime uygunluğu
    #    - Engagement potansiyeli
    #    - Uzunluk ve yapı
    # 3. Top 10'u seç
    # 4. Sınıflandırma görevine gönder
```

### 3.2 Sınıflandırma Görevi

```python
@shared_task(queue='default')
def classify_articles(headline_ids):
    """
    Başlıkları haber türüne göre sınıflandır.
    Türler: news, analysis, feature, opinion, tutorial
    """
    # 1. Her başlık için Gemini'ye çağrı yap
    # 2. Tür ve alt-kategori belirle
    # 3. Araştırma derinliğini ayarla
    # 4. İçerik üretim görevine gönder
```

### 3.3 Araştırma Görevi

```python
@shared_task(queue='default')
def research_content(article_id, research_depth):
    """
    Makale için ek araştırma yap.
    research_depth: 0 (minimal), 1 (normal), 2 (derinlemesine)
    """
    # 1. Makale başlığından arama terimleri çıkar
    # 2. Gemini'yi kullanarak güncel bilgiler ara
    # 3. Kaynakları kaydet
    # 4. Araştırma sonuçlarını döndür
```

### 3.4 Dinamik Prompt Oluşturma

```python
def create_dynamic_prompt(article, research_data, article_type):
    """
    Makale türüne ve araştırma verilerine göre dinamik prompt oluştur.
    """
    # Prompt şablonları:
    # - News: Hızlı, güncel, 5W1H yapısı
    # - Analysis: Derinlemesine, analitik, karşılaştırma
    # - Feature: Hikaye anlatıcı, detaylı, insani
    # - Opinion: Argüman tabanlı, taraflı ama açık
    # - Tutorial: Adım adım, pratik, örnekli
```

### 3.5 Gelişmiş İçerik Üretimi

```python
@shared_task(queue='high_priority', bind=True)
def generate_ai_content_v2(self, article_id):
    """
    Geliştirilmiş içerik üretimi:
    - Dinamik prompt
    - Araştırma verisi entegrasyonu
    - Model seçimi
    - Kalite kontrol
    """
    # 1. Araştırma verilerini al
    # 2. Dinamik prompt oluştur
    # 3. En uygun modeli seç (Flash/Pro/Advanced)
    # 4. İçerik üret
    # 5. Kalite metrikleri hesapla
    # 6. Kalite eşiğini geçerse yayınla
```

### 3.6 Kalite Kontrol Görevi

```python
@shared_task(queue='default')
def quality_check(article_id):
    """
    İçerik kalitesini kontrol et:
    - Okunabilirlik metrikleri
    - SEO uygunluğu
    - Yapı ve format
    - Gerçeklik kontrolü
    """
    # 1. Okunabilirlik metrikleri hesapla
    # 2. SEO parametrelerini kontrol et
    # 3. İçerik yapısını doğrula
    # 4. Kalite puanı hesapla
    # 5. Başarısız ise düzeltme öner
```

## 4. Paralel İşleme Stratejisi

### 4.1 Celery Chord Kullanımı

```python
from celery import chord, group

def process_headlines_parallel(headline_ids):
    """
    Başlıkları paralel olarak işle.
    """
    # Başlıkları sınıflandır (paralel)
    classification_group = group(
        classify_articles.s(hid) for hid in headline_ids
    )
    
    # Sınıflandırma sonrası içerik üret (paralel)
    content_generation = chord(classification_group)(
        process_classified_articles.s()
    )
```

### 4.2 Batch Processing

```python
@shared_task
def batch_process_articles(article_ids):
    """
    Makaleleri batch'ler halinde işle.
    """
    # 10 makaleyi paralel olarak işle
    # Sonra sonraki batch'e geç
```

## 5. Konfigürasyon Ayarları

### 5.1 Yeni Settings

```python
# İçerik Üretim Ayarları
CONTENT_GENERATION_CONFIG = {
    'max_headlines_per_hour': 10,
    'min_headline_score': 60,
    'quality_threshold': 75,
    'research_depth_default': 1,
    'max_retries': 3,
    'timeout': 300,
}

# Model Seçimi
AI_MODEL_SELECTION = {
    'news': 'gemini-2.5-flash',
    'analysis': 'gemini-2.5-pro',
    'feature': 'gemini-2.5-pro',
    'opinion': 'gemini-2.5-flash',
    'tutorial': 'gemini-2.5-flash',
}

# Kalite Metrikleri
QUALITY_METRICS = {
    'min_word_count': 400,
    'max_word_count': 1000,
    'target_readability': 8,  # Flesch-Kincaid
    'min_keyword_density': 1.5,
    'max_keyword_density': 3.0,
}
```

## 6. Monitoring ve Logging

### 6.1 Metrikleri İzleme

```python
class ContentGenerationMetrics:
    - headlines_processed_per_hour
    - articles_generated_per_hour
    - average_quality_score
    - average_processing_time
    - api_calls_per_hour
    - error_rate
    - success_rate
```

### 6.2 Sistem Logları

```python
# Her aşama için detaylı logging
- Başlık puanlaması sonuçları
- Sınıflandırma kararları
- Araştırma kaynakları
- AI API çağrıları ve yanıtları
- Kalite kontrol sonuçları
- Hata ve istisnalar
```

## 7. Uygulama Adımları

### Faz 1: Temel Altyapı (1-2 hafta)
1. Veritabanı şeması genişletme
2. Başlık puanlaması sistemi
3. Sınıflandırma sistemi
4. Kalite metrikleri hesaplama

### Faz 2: Gelişmiş Özellikler (2-3 hafta)
1. Araştırma sistemi
2. Dinamik prompt oluşturma
3. Model seçimi optimizasyonu
4. Paralel işleme

### Faz 3: Optimizasyon (1-2 hafta)
1. Performans tuning
2. Monitoring dashboard
3. A/B testing
4. Dokümantasyon ve training
