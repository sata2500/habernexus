# Haber Nexus - Geliştirme Kılavuzu

Bu belge, Haber Nexus projesini yerel ortamda geliştirmek için gereken adımları açıklamaktadır.

## Ön Gereksinimler

- Docker ve Docker Compose kurulu
- Git kurulu
- Python 3.11+ (yerel geliştirme için)
- Node.js 16+ (Tailwind CSS için)

## Kurulum Adımları

### 1. Repoyu Klonla

```bash
git clone https://github.com/sata2500/habernexus.git
cd habernexus
```

### 2. Ortam Değişkenlerini Ayarla

```bash
cp .env.example .env
```

`.env` dosyasını açıp gerekli değerleri düzenle:

```env
DEBUG=True
DJANGO_SECRET_KEY=your-development-secret-key
ALLOWED_HOSTS=localhost,127.0.0.1,habernexus.local
GOOGLE_API_KEY=your-google-api-key-here
```

### 3. Docker ile Başlat

```bash
docker-compose up -d
```

Bu komut şu servisleri başlatacaktır:
- **Nginx**: http://localhost:80
- **Django**: http://localhost:8000 (Nginx arkasında)
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **Celery**: Arka planda çalışır
- **Celery Beat**: Periyodik görevleri çalıştırır

### 4. Veritabanı Migrasyonlarını Çalıştır

```bash
docker-compose exec app python manage.py migrate
```

### 5. Süper Kullanıcı Oluştur

```bash
docker-compose exec app python manage.py createsuperuser
```

Sorulara cevap ver:
- Kullanıcı adı: `admin`
- E-posta: `admin@habernexus.com`
- Şifre: Güçlü bir şifre gir

### 6. Django Admin Paneline Erişim

Tarayıcıda açıp admin paneline gir:
```
http://localhost/admin
```

Oluşturduğun kullanıcı adı ve şifre ile giriş yap.

## Geliştirme Sırasında Kullanışlı Komutlar

### Logları Görüntüle

```bash
# Django uygulaması
docker-compose logs -f app

# Celery worker
docker-compose logs -f celery

# Celery Beat
docker-compose logs -f celery_beat

# Nginx
docker-compose logs -f nginx
```

### Veritabanı Migrasyonları

```bash
# Yeni migrasyonlar oluştur
docker-compose exec app python manage.py makemigrations

# Migrasyonları uygula
docker-compose exec app python manage.py migrate

# Migrasyonları geri al
docker-compose exec app python manage.py migrate app_name 0001
```

### Django Shell

```bash
docker-compose exec app python manage.py shell
```

### Statik Dosyaları Topla

```bash
docker-compose exec app python manage.py collectstatic --noinput
```

### Celery Görevini Test Et

```bash
# Django shell'de
from news.tasks import fetch_rss_feeds
fetch_rss_feeds.delay()
```

## Proje Yapısı

```
habernexus/
├── habernexus_config/     # Django proje yapılandırması
│   ├── settings.py        # Ayarlar
│   ├── urls.py            # URL yönlendirmeleri
│   ├── celery.py          # Celery yapılandırması
│   └── wsgi.py            # WSGI uygulaması
├── core/                  # Çekirdek uygulaması
│   ├── models.py          # Setting, SystemLog modelleri
│   ├── admin.py           # Admin paneli yapılandırması
│   └── tasks.py           # Celery görevleri
├── news/                  # Haber uygulaması
│   ├── models.py          # Article, RssSource modelleri
│   ├── admin.py           # Admin paneli yapılandırması
│   └── tasks.py           # RSS tarama, AI içerik üretimi
├── authors/               # Yazarlar uygulaması
│   ├── models.py          # Author modeli
│   └── admin.py           # Admin paneli yapılandırması
├── config/                # Yapılandırma dosyaları
│   └── nginx.conf         # Nginx yapılandırması
├── media/                 # Yüklenen dosyalar (görseller, videolar)
├── static/                # Statik dosyalar (CSS, JS)
├── staticfiles/           # Toplanan statik dosyalar (üretim)
├── templates/             # Django şablonları
├── Dockerfile             # Docker imajı tanımı
├── docker-compose.yml     # Docker Compose yapılandırması
├── requirements.txt       # Python bağımlılıkları
└── manage.py              # Django yönetim aracı
```

## Yeni Bir Özellik Geliştirme

### 1. Model Oluştur

`news/models.py` veya ilgili uygulamada modeli tanımla.

### 2. Migrasyonlar Oluştur

```bash
docker-compose exec app python manage.py makemigrations
docker-compose exec app python manage.py migrate
```

### 3. Admin Paneline Ekle

`news/admin.py` veya ilgili uygulamada admin kaydını yap.

### 4. Celery Görevleri (Gerekirse)

`news/tasks.py` veya ilgili uygulamada görevleri tanımla.

### 5. Views ve Templates (Gerekirse)

`news/views.py` ve `templates/` klasöründe dosyalar oluştur.

### 6. Test Et

Değişiklikleri test et ve hata denetimini yap.

### 7. Commit ve Push

```bash
git add .
git commit -m "Açıklayıcı commit mesajı"
git push origin main
```

## Hata Giderme

### PostgreSQL Bağlantı Hatası

```bash
docker-compose down
docker-compose up -d db
sleep 5
docker-compose up -d
```

### Redis Bağlantı Hatası

```bash
docker-compose restart redis
```

### Celery Görevleri Çalışmıyor

```bash
# Celery worker'ı yeniden başlat
docker-compose restart celery

# Logları kontrol et
docker-compose logs -f celery
```

### Statik Dosyalar Yüklenmedi

```bash
docker-compose exec app python manage.py collectstatic --noinput
docker-compose restart nginx
```

## Üretim Dağıtımı

Üretim ortamına dağıtmak için:

1. `.env` dosyasını güncelle (güvenli değerler)
2. `DEBUG=False` yap
3. `SECURE_SSL_REDIRECT=True` yap
4. SSL sertifikası ekle (`config/ssl/`)
5. `docker-compose up -d` çalıştır

Daha detaylı bilgi için `docs/DEPLOYMENT.md` dosyasına bakınız.

## İletişim ve Destek

Sorularınız için: salihtanriseven25@gmail.com
