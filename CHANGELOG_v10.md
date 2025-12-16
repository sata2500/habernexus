# HaberNexus v10.0 Changelog

**Tarih:** 16 Aralık 2025  
**Geliştirici:** Salih TANRISEVEN  
**E-posta:** salihtanriseven25@gmail.com  
**Domain:** habernexus.com

---

## 🎯 Genel Bakış

HaberNexus v10.0, projenin en kapsamlı güncellemesidir. Bu sürümde Google AI SDK geçişi, tam işlevsel REST API, newsletter sistemi ve birçok SEO/performans iyileştirmesi yapılmıştır.

---

## 🚀 Yeni Özellikler

### 1. Google Gen AI SDK Geçişi

**Eski SDK:** `google-generativeai` (deprecated)  
**Yeni SDK:** `google-genai` (önerilen)

**Değişiklikler:**
- `requirements.txt` güncellendi
- `news/tasks.py` yeni SDK kullanımına uyarlandı
- Gemini 2.5 Flash ve Imagen 4.0 desteği eklendi
- Daha iyi hata yönetimi ve retry mekanizması

**Yeni Kullanım:**
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

### 2. REST API Modülü

**Endpoint:** `/api/v1/`

**Yeni Dosyalar:**
- `api/__init__.py`
- `api/apps.py`
- `api/urls.py`
- `api/views.py`
- `api/serializers.py`
- `api/pagination.py`
- `api/permissions.py`
- `api/tests.py`

**API Endpoints:**

| Endpoint | Method | Açıklama |
|----------|--------|----------|
| `/api/v1/articles/` | GET | Haber listesi |
| `/api/v1/articles/{slug}/` | GET | Haber detayı |
| `/api/v1/articles/featured/` | GET | Öne çıkan haberler |
| `/api/v1/articles/latest/` | GET | Son haberler |
| `/api/v1/articles/search/` | GET | Haber arama |
| `/api/v1/articles/by_category/` | GET | Kategoriye göre |
| `/api/v1/authors/` | GET | Yazar listesi |
| `/api/v1/authors/{slug}/` | GET | Yazar detayı |
| `/api/v1/authors/{slug}/articles/` | GET | Yazarın haberleri |
| `/api/v1/rss-sources/` | GET/POST | RSS kaynakları (admin) |
| `/api/v1/categories/` | GET | Kategori listesi |
| `/api/v1/stats/` | GET | Site istatistikleri |
| `/api/v1/health/` | GET | API sağlık kontrolü |

**Özellikler:**
- Pagination (sayfalama)
- Filtering (filtreleme)
- Search (arama)
- Ordering (sıralama)
- Rate limiting (hız sınırlama)
- CORS desteği

### 3. Newsletter Sistemi

**Yeni Dosyalar:**
- `news/models_newsletter.py`
- `news/views_newsletter.py`
- `news/tasks_newsletter.py`
- `news/admin_newsletter.py`
- `templates/newsletter/` (4 template)
- `templates/emails/` (2 template)

**Özellikler:**
- E-posta aboneliği
- E-posta doğrulama
- Abonelik iptali
- Tercih yönetimi
- Günlük/Haftalık bülten gönderimi
- Admin paneli entegrasyonu

**URL'ler:**
- `/newsletter/subscribe/` - Abone ol
- `/newsletter/verify/{token}/` - E-posta doğrula
- `/newsletter/unsubscribe/{token}/` - Abonelikten çık
- `/newsletter/preferences/{token}/` - Tercihleri yönet

---

## 🔧 İyileştirmeler

### SEO Optimizasyonları

**Değişiklikler:**
- `templates/base.html` - Gelişmiş meta tags
- `news/sitemaps.py` - Google News sitemap
- `static/robots.txt` - Yeni robots.txt

**Eklenen Meta Tags:**
- Open Graph (Facebook)
- Twitter Cards
- Canonical URL
- Structured Data (JSON-LD)
- NewsMediaOrganization schema

### Performans Optimizasyonları

**Değişiklikler:**
- `news/cache_utils.py` - Gelişmiş cache yönetimi
- API response caching
- Query optimization (select_related, prefetch_related)

### Güvenlik Güncellemeleri

**Yeni Paketler:**
- `django-filter==24.3`
- `django-ratelimit==4.1.0`

**Özellikler:**
- API rate limiting (100/saat anonim, 1000/saat kullanıcı)
- CORS yapılandırması
- API throttling

---

## 📁 Değiştirilen Dosyalar

| Dosya | İşlem | Açıklama |
|-------|-------|----------|
| `requirements.txt` | Güncellendi | Yeni SDK ve paketler |
| `news/tasks.py` | Güncellendi | Yeni Google AI SDK |
| `core/models.py` | Güncellendi | AI model seçenekleri |
| `habernexus_config/settings.py` | Güncellendi | API, CORS ayarları |
| `habernexus_config/urls.py` | Güncellendi | API routes |
| `news/urls.py` | Güncellendi | Newsletter routes |
| `news/admin.py` | Güncellendi | Newsletter admin |
| `news/sitemaps.py` | Güncellendi | Google News sitemap |
| `news/cache_utils.py` | Güncellendi | Cache iyileştirmeleri |
| `templates/base.html` | Güncellendi | SEO meta tags |
| `templates/home.html` | Güncellendi | Newsletter form |

---

## 📊 Yeni Dosyalar

```
api/
├── __init__.py
├── apps.py
├── pagination.py
├── permissions.py
├── serializers.py
├── tests.py
├── urls.py
└── views.py

news/
├── admin_newsletter.py
├── models_newsletter.py
├── tasks_newsletter.py
└── views_newsletter.py

templates/
├── emails/
│   ├── daily_newsletter.html
│   └── newsletter_verification.html
└── newsletter/
    ├── error.html
    ├── unsubscribe_confirm.html
    ├── unsubscribed.html
    └── verified.html

static/
└── robots.txt

DEVELOPMENT_PLAN_v10.md
RESEARCH_NOTES.md
CHANGELOG_v10.md
```

---

## 🔄 Migration Gereksinimleri

Newsletter modellerini kullanmak için migration oluşturulması gerekiyor:

```bash
python manage.py makemigrations news
python manage.py migrate
```

---

## ⚙️ Yapılandırma

### Yeni Ortam Değişkenleri

Newsletter için e-posta ayarları gerekli:

```env
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
DEFAULT_FROM_EMAIL=noreply@habernexus.com
```

### Celery Beat Görevleri

Newsletter görevleri için Celery Beat yapılandırması:

```python
CELERY_BEAT_SCHEDULE = {
    'send-daily-newsletter': {
        'task': 'news.tasks_newsletter.send_daily_newsletter',
        'schedule': crontab(hour=8, minute=0),
    },
    'send-weekly-newsletter': {
        'task': 'news.tasks_newsletter.send_weekly_newsletter',
        'schedule': crontab(hour=9, minute=0, day_of_week=1),
    },
    'cleanup-unverified-subscribers': {
        'task': 'news.tasks_newsletter.cleanup_unverified_subscribers',
        'schedule': crontab(hour=0, minute=0),
    },
}
```

---

## 📈 Sonraki Adımlar

1. **Dark Mode:** Tema desteği eklenebilir
2. **PWA:** Progressive Web App özellikleri
3. **Analytics:** Kullanıcı analitikleri
4. **Push Notifications:** Tarayıcı bildirimleri
5. **Social Login:** Sosyal medya ile giriş

---

## 🙏 Teşekkürler

Bu güncelleme Manus AI ile birlikte geliştirilmiştir.

**Commit:** `95230bf`  
**Branch:** `main`  
**Repository:** https://github.com/sata2500/habernexus
