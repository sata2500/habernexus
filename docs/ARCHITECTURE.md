# Haber Nexus - Sistem Mimarisi

Bu belge, Haber Nexus projesinin teknik mimarisini ve bileşenlerini açıklamaktadır.

## Genel Mimari

```
┌─────────────────────────────────────────────────────────────┐
│                      İnternet                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Nginx (Reverse Proxy)                    │
│  • SSL/TLS Sonlandırması                                    │
│  • Statik Dosyaları Servis Etme                             │
│  • Gzip Sıkıştırması                                        │
│  • Load Balancing (İsteğe Bağlı)                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Django Uygulaması (Gunicorn)                   │
│  • Web Arayüzü (Admin Panel)                                │
│  • REST API (İsteğe Bağlı)                                  │
│  • Ziyaretçi Arayüzü                                        │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
    ┌────────────┐       ┌────────────┐      ┌────────────┐
    │ PostgreSQL │       │   Redis    │      │   Celery   │
    │ Veritabanı │       │   Cache    │      │   Worker   │
    │            │       │   Broker   │      │            │
    └────────────┘       └────────────┘      └────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │  Celery Beat        │
                    │  (Zamanlayıcı)      │
                    └─────────────────────┘
```

## Bileşenler

### 1. Nginx (Web Sunucusu / Reverse Proxy)

**Görev:**
- Gelen HTTP/HTTPS isteklerini karşılar
- Django uygulamasına proxy'ler
- Statik dosyaları (CSS, JS, görseller) doğrudan servis eder
- SSL/TLS şifrelemesini yönetir
- Gzip sıkıştırması ile bant genişliğini azaltır

**Yapılandırma:** `config/nginx.conf`

**Port:** 80 (HTTP), 443 (HTTPS)

### 2. Django Uygulaması (Gunicorn)

**Görev:**
- Web arayüzü (yönetim paneli, ziyaretçi sayfaları)
- İş mantığı ve veri işleme
- Veritabanı işlemleri

**Bileşenler:**
- `habernexus_config/`: Proje yapılandırması
- `core/`: Sistem ayarları ve günlükleme
- `news/`: Haber yönetimi
- `authors/`: Yazar yönetimi

**Port:** 8000 (Nginx arkasında, dışarıya kapalı)

### 3. PostgreSQL (Veritabanı)

**Görev:**
- Tüm uygulama verilerini saklar
- İlişkisel veri yönetimi

**Tablolar:**
- `core_setting`: Sistem ayarları
- `core_systemlog`: Hata ve olay günlükleri
- `news_article`: Haberler
- `news_rsssource`: RSS kaynakları
- `authors_author`: Yazarlar
- `django_celery_beat_*`: Celery Beat zamanlamaları

**Port:** 5432

### 4. Redis (Cache / Message Broker)

**Görev:**
- Celery görevlerinin kuyruğunu yönetir (Broker)
- Görev sonuçlarını saklar (Result Backend)
- Uygulamada cache olarak kullanılabilir

**Port:** 6379

### 5. Celery (Asenkron Görev Yürütücü)

**Görev:**
- Arka planda uzun süren görevleri çalıştırır
- Django uygulamasını bloke etmez
- Görevleri kuyruklara ayırır

**Görevler:**
- `fetch_rss_feeds`: RSS kaynaklarını tarar
- `generate_ai_content`: AI ile haber içeriği oluşturur
- `process_video_content`: Video işleme (izole kuyruk)
- `cleanup_old_logs`: Eski günlükleri temizler

**Kuyruklar:**
- `default`: Genel görevler
- `video_processing`: Video işleme (concurrency=1, izole)

### 6. Celery Beat (Zamanlayıcı)

**Görev:**
- Periyodik görevleri belirli zamanlarda çalıştırır
- Veritabanı tabanlı zamanlama

**Zamanlanmış Görevler:**
- RSS tarama: Her 15 dakikada bir
- Eski günlükleri temizle: Haftada bir (Pazartesi 02:00)

## Veri Akışı

### RSS'den İçerik Üretimi Süreci

```
1. Celery Beat (Her 15 dakikada bir)
   │
   ▼
2. fetch_rss_feeds() Görevi Tetiklenir
   │
   ├─ RSS kaynağını indir
   ├─ Yeni haberleri parse et
   ├─ Veritabanına ham veri olarak kaydet
   │
   ▼
3. generate_ai_content() Görevi Tetiklenir (Her haber için)
   │
   ├─ Google AI API'ye bağlan
   ├─ Prompt oluştur (yazar profili + haber verisi)
   ├─ AI'dan özgün içerik al
   ├─ Görseli indir ve optimize et (WebP)
   ├─ Veritabanına kaydet
   │
   ▼
4. Haber Yayınlandı
   │
   ├─ Ziyaretçiler tarafından görülebilir
   ├─ SEO indexing için hazır
   │
   ▼
5. Hata Oluşursa
   │
   └─ SystemLog'a kaydedilir
      (Yönetici tarafından kontrol edilebilir)
```

## Veritabanı Şeması (Basitleştirilmiş)

### Article (Haberler)
```
- id (PK)
- title (Başlık)
- slug (URL slug)
- content (İçerik)
- excerpt (Özet)
- featured_image (Başlık görseli)
- author_id (FK → Author)
- category (Kategori)
- tags (Etiketler)
- rss_source_id (FK → RssSource)
- status (draft, published, archived)
- is_ai_generated (Boolean)
- is_ai_image (Boolean)
- views_count (Görüntülenme)
- published_at (Yayınlanma tarihi)
- created_at (Oluşturulma tarihi)
- updated_at (Güncelleme tarihi)
```

### Author (Yazarlar)
```
- id (PK)
- name (Ad)
- slug (URL slug)
- bio (Biyografi)
- expertise (Uzmanlık alanı)
- profile_image (Profil resmi)
- email (E-posta)
- website (Web sitesi)
- is_active (Aktif mi)
- created_at (Oluşturulma tarihi)
- updated_at (Güncelleme tarihi)
```

### RssSource (RSS Kaynakları)
```
- id (PK)
- name (Ad)
- url (RSS URL)
- category (Kategori)
- frequency_minutes (Tarama sıklığı)
- is_active (Aktif mi)
- last_checked (Son tarama zamanı)
- created_at (Oluşturulma tarihi)
- updated_at (Güncelleme tarihi)
```

### Setting (Sistem Ayarları)
```
- id (PK)
- key (Anahtar)
- value (Değer)
- description (Açıklama)
- is_secret (Gizli mi)
- created_at (Oluşturulma tarihi)
- updated_at (Güncelleme tarihi)
```

### SystemLog (Sistem Günlükleri)
```
- id (PK)
- level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- task_name (Görev adı)
- message (Mesaj)
- traceback (Stack trace)
- related_id (İlgili nesne ID)
- created_at (Oluşturulma tarihi)
```

## Güvenlik Mimarisi

### 1. Nginx Güvenliği
- SSL/TLS şifrelemesi
- Security headers (X-Frame-Options, X-Content-Type-Options vb.)
- Gzip sıkıştırması
- Rate limiting (İsteğe bağlı)

### 2. Django Güvenliği
- CSRF koruması
- SQL injection koruması (ORM kullanımı)
- XSS koruması (Template escaping)
- Şifre hashleme (Django Auth)
- Admin panel erişim kontrolü

### 3. Veri Güvenliği
- Gizli ayarlar (API anahtarları) `is_secret=True` ile maskelenir
- Ortam değişkenleri `.env` dosyasında saklanır
- `.env` dosyası `.gitignore`'da yer alır (repoya yüklenmez)

### 4. Video İşleme Güvenliği
- Video görevleri izole kuyruğa gönderilir
- Concurrency=1 ile aynı anda sadece bir video işlenir
- Sunucunun kilitlenmesi önlenir

## Ölçeklenebilirlik

### Yatay Ölçeklendirme (Horizontal Scaling)

```
┌──────────────┐
│   Nginx      │ (Load Balancer)
└──────────────┘
       │
    ┌──┴──┬──────┬──────┐
    ▼     ▼      ▼      ▼
  App1  App2   App3   App4 (Django Instances)
    │     │      │      │
    └─────┴──────┴──────┘
           │
        ┌──▼──┐
        │ DB  │ (PostgreSQL)
        └─────┘
```

### Dikey Ölçeklendirme (Vertical Scaling)

- Sunucu kaynaklarını artır (CPU, RAM)
- Gunicorn worker sayısını artır
- Celery worker sayısını artır

## Yedekleme Stratejisi

### Veritabanı Yedeklemesi
```bash
docker-compose exec db pg_dump -U postgres habernexus > backup.sql
```

### Medya Dosyaları Yedeklemesi
```bash
tar -czf media_backup.tar.gz media/
```

### Otomatik Yedekleme (Cron)
```bash
0 2 * * * docker-compose exec db pg_dump -U postgres habernexus > /backups/db_$(date +\%Y\%m\%d).sql
```

## Performans Optimizasyonları

1. **Veritabanı İndeksleri**: Sık sorgulanacak alanlara indeks eklendi
2. **Caching**: Redis ile sayfa cache'leme (İsteğe bağlı)
3. **Görsel Optimizasyonu**: WebP formatı, kalite ayarlaması
4. **Gzip Sıkıştırması**: Nginx'te etkinleştirildi
5. **CDN**: Statik dosyalar CDN'de barındırılabilir (İsteğe bağlı)

## Monitoring ve Logging

### Sistem Günlükleri
- `SystemLog` modeline kaydedilir
- Django Admin'de görüntülenebilir
- Filtreleme ve arama özelliği

### Celery Görev Günlükleri
```bash
docker-compose logs -f celery
```

### Nginx Erişim Günlükleri
```bash
docker-compose logs -f nginx
```

## Disaster Recovery

### Sunucu Arızası Durumunda
1. Yedeklenmiş veritabanını geri yükle
2. Medya dosyalarını geri yükle
3. Yeni sunucuda `docker-compose up -d` çalıştır

### Veri Kaybı Durumunda
1. Son yedekten geri yükle
2. Kayıp veriler için RSS kaynaklarını yeniden tara

## İleride Yapılacaklar

- [ ] Elasticsearch entegrasyonu (Gelişmiş arama)
- [ ] CDN entegrasyonu (Statik dosyalar)
- [ ] Monitoring araçları (Prometheus, Grafana)
- [ ] Backup otomasyonu
- [ ] Multi-region deployment
- [ ] Kubernetes migration
