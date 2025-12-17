# HaberNexus v10.0 Geliştirme Planı

**Tarih:** 16 Aralık 2025  
**Hazırlayan:** Salih TANRISEVEN (Manus AI ile)  
**Proje:** HaberNexus - AI Destekli Otomatik Haber Ajansı

---

## 📋 Genel Bakış

Bu plan, HaberNexus projesinin v9.0'dan v10.0'a yükseltilmesi için gerekli tüm geliştirmeleri kapsamaktadır. Araştırmalar sonucunda tespit edilen kritik güncellemeler, iyileştirmeler ve yeni özellikler bu planda detaylandırılmıştır.

---

## 🎯 Hedefler

| Öncelik | Hedef | Durum | Tahmini Süre |
|---------|-------|-------|--------------|
| 🔴 Kritik | Google Gen AI SDK Geçişi | ⏳ Yapılacak | 2-3 saat |
| 🔴 Kritik | REST API Modülü | ⏳ Yapılacak | 4-5 saat |
| 🟠 Önemli | Newsletter Sistemi | ⏳ Yapılacak | 2-3 saat |
| 🟠 Önemli | SEO İyileştirmeleri | ⏳ Yapılacak | 2-3 saat |
| 🟡 Normal | Performans Optimizasyonu | ⏳ Yapılacak | 2-3 saat |
| 🟡 Normal | Güvenlik Güncellemeleri | ⏳ Yapılacak | 1-2 saat |
| 🟢 İsteğe Bağlı | Dark Mode | ⏳ Yapılacak | 1-2 saat |

**Toplam Tahmini Süre:** 14-21 saat

---

## 📂 Geliştirme Aşamaları

### Aşama 1: Google Gen AI SDK Geçişi (KRİTİK)

**Problem:** Mevcut `google-generativeai` paketi deprecated, yeni `google-genai` SDK'ya geçiş gerekli.

**Yapılacaklar:**

1. **requirements.txt Güncelleme:**
   ```
   # Eski
   google-generativeai==0.8.3
   
   # Yeni
   google-genai>=1.0.0
   ```

2. **news/tasks.py Güncelleme:**
   - Import değişiklikleri
   - Client oluşturma yöntemi
   - API çağrı yapısı

3. **Yeni SDK Kullanımı:**
   ```python
   from google import genai
   from google.genai import types
   
   client = genai.Client(api_key=api_key)
   
   response = client.models.generate_content(
       model='gemini-2.5-flash',
       contents=prompt,
       config=types.GenerateContentConfig(
           temperature=0.7,
           top_p=0.95,
       )
   )
   ```

4. **Imagen 4 Güncelleme:**
   ```python
   response = client.models.generate_images(
       model='imagen-4.0-generate-001',
       prompt=image_prompt,
       config=types.GenerateImagesConfig(
           number_of_images=1,
           aspect_ratio='16:9',
       ),
   )
   ```

**Dosyalar:**
- `requirements.txt`
- `news/tasks.py`
- `core/models.py` (AI model seçenekleri)

---

### Aşama 2: REST API Modülü Oluşturma (KRİTİK)

**Problem:** Proje REST API endpoint'lerine sahip değil, sadece template-based views var.

**Yapılacaklar:**

1. **API App Oluşturma:**
   ```
   api/
   ├── __init__.py
   ├── apps.py
   ├── urls.py
   ├── views.py
   ├── serializers.py
   ├── permissions.py
   └── pagination.py
   ```

2. **Serializers:**
   - ArticleSerializer
   - ArticleListSerializer
   - AuthorSerializer
   - CategorySerializer
   - RssSourceSerializer

3. **ViewSets:**
   - ArticleViewSet (CRUD)
   - AuthorViewSet (Read-only)
   - CategoryViewSet (Read-only)
   - RssSourceViewSet (Admin only)
   - SettingViewSet (Admin only)

4. **API Endpoints:**
   ```
   /api/v1/articles/           GET, POST
   /api/v1/articles/{id}/      GET, PUT, DELETE
   /api/v1/articles/featured/  GET
   /api/v1/articles/search/    GET
   /api/v1/authors/            GET
   /api/v1/authors/{slug}/     GET
   /api/v1/categories/         GET
   /api/v1/rss-sources/        GET, POST (admin)
   /api/v1/settings/           GET, POST (admin)
   ```

5. **Authentication:**
   - Token Authentication
   - API Key Authentication
   - Rate Limiting

**Dosyalar:**
- `api/` (yeni klasör)
- `habernexus_config/settings.py`
- `habernexus_config/urls.py`

---

### Aşama 3: Newsletter Sistemi (ÖNEMLİ)

**Problem:** Newsletter formu mevcut ancak işlevsel değil.

**Yapılacaklar:**

1. **Newsletter Model:**
   ```python
   class NewsletterSubscriber(models.Model):
       email = models.EmailField(unique=True)
       is_active = models.BooleanField(default=True)
       subscribed_at = models.DateTimeField(auto_now_add=True)
       unsubscribed_at = models.DateTimeField(null=True, blank=True)
       token = models.UUIDField(default=uuid.uuid4, unique=True)
   ```

2. **Newsletter Views:**
   - Subscribe endpoint
   - Unsubscribe endpoint
   - Confirmation email

3. **Celery Task:**
   - Günlük/haftalık haber özeti gönderimi
   - Email template'leri

**Dosyalar:**
- `news/models.py`
- `news/views.py`
- `news/tasks.py`
- `templates/emails/`

---

### Aşama 4: SEO İyileştirmeleri (ÖNEMLİ)

**Yapılacaklar:**

1. **Structured Data (JSON-LD):**
   - Article schema
   - Organization schema
   - BreadcrumbList schema

2. **Meta Tags İyileştirmeleri:**
   - Open Graph tags
   - Twitter Cards
   - Canonical URLs

3. **Sitemap Güncellemesi:**
   - News sitemap
   - Image sitemap

4. **robots.txt Güncelleme**

**Dosyalar:**
- `templates/base.html`
- `templates/article_detail.html`
- `news/sitemaps.py`
- `robots.txt`

---

### Aşama 5: Performans Optimizasyonu (NORMAL)

**Yapılacaklar:**

1. **Database Query Optimizasyonu:**
   - select_related kullanımı
   - prefetch_related kullanımı
   - Database indexleri

2. **Caching Stratejisi:**
   - View caching
   - Template fragment caching
   - API response caching

3. **Static Files Optimizasyonu:**
   - CSS/JS minification
   - Image lazy loading
   - WebP format kullanımı

**Dosyalar:**
- `news/views.py`
- `news/models.py`
- `habernexus_config/settings.py`

---

### Aşama 6: Güvenlik Güncellemeleri (NORMAL)

**Yapılacaklar:**

1. **Rate Limiting:**
   - django-ratelimit entegrasyonu
   - API endpoint koruması

2. **Security Headers:**
   - Content-Security-Policy
   - X-Content-Type-Options
   - Referrer-Policy

3. **Input Validation:**
   - Form validation
   - API input sanitization

**Dosyalar:**
- `habernexus_config/settings.py`
- `habernexus_config/middleware.py`

---

### Aşama 7: Dark Mode (İSTEĞE BAĞLI)

**Yapılacaklar:**

1. **CSS Variables:**
   - Light theme colors
   - Dark theme colors

2. **Theme Toggle:**
   - JavaScript toggle
   - LocalStorage persistence

3. **Template Updates:**
   - base.html güncelleme
   - Component styling

**Dosyalar:**
- `templates/base.html`
- `static/css/theme.css`

---

## 📊 Dosya Değişiklikleri Özeti

| Dosya | İşlem | Açıklama |
|-------|-------|----------|
| `requirements.txt` | Güncelle | SDK değişikliği |
| `news/tasks.py` | Güncelle | Yeni SDK kullanımı |
| `core/models.py` | Güncelle | Model seçenekleri |
| `api/` | Oluştur | Yeni API modülü |
| `news/models.py` | Güncelle | Newsletter model |
| `news/views.py` | Güncelle | Newsletter views |
| `templates/base.html` | Güncelle | SEO, Dark mode |
| `templates/article_detail.html` | Güncelle | Structured data |
| `habernexus_config/settings.py` | Güncelle | API, Cache ayarları |
| `habernexus_config/urls.py` | Güncelle | API routes |

---

## ✅ Başarı Kriterleri

1. **Fonksiyonel:** Tüm özellikler çalışır durumda
2. **Test:** Unit testler geçiyor
3. **Güvenlik:** Güvenlik taraması temiz
4. **Performans:** Sayfa yükleme < 3 saniye
5. **SEO:** Lighthouse SEO skoru > 90

---

## 🚀 Uygulama Sırası

1. ✅ Proje analizi
2. ✅ Araştırma
3. ⏳ Google Gen AI SDK geçişi
4. ⏳ API modülü oluşturma
5. ⏳ Newsletter sistemi
6. ⏳ SEO iyileştirmeleri
7. ⏳ Performans optimizasyonu
8. ⏳ Güvenlik güncellemeleri
9. ⏳ Dark mode
10. ⏳ Test ve kalite kontrol
11. ⏳ GitHub push

---

**Durum:** ✅ Plan Hazır - Geliştirmeye Başlanıyor
