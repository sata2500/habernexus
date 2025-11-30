# Haber Nexus - Yapıy Zeka Destekli Otomatik Haber Ajansı

![Haber Nexus](https://img.shields.io/badge/Django-5.0-green) ![Python](https://img.shields.io/badge/Python-3.11-blue) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-12+-blue) ![Redis](https://img.shields.io/badge/Redis-6+-red) ![Celery](https://img.shields.io/badge/Celery-5.3-green) ![Nginx](https://img.shields.io/badge/Nginx-1.18-green)

**Haber Nexus**, Google Gemini ve Imagen API'lerini kullanarak tam otomatik, profesyonel haber içeriği üretim, 7/24 kesintisiz çalışan bir haber ajansı uygulamadır.

## 🌟 Özellikleri

### ✨ Temel Özellikleri
- **Tam Otomatik İçerik Üretimi**: Google Gemini API ile profesyonel haber yazıları
- **Otomatik Görsel Oluşturma**: Google Imagen API ile ilgili görseller
- **RSS Kaynakları**: Birden fazla RSS kaynagından otomatik haber taraması
- **Profesyonel Yazarlar**: Sistem tarafından oluşturulan yazar profilleri
- **7/24 Çalışma**: Celery ile periyodik görevler
- **SEO Optimizasyonu**: Sitemap, robots.txt, yapılandırılmış veriler

### 🔧 Teknik Özellikleri
- **Django 5.0**: Modern Python web framework
- **PostgreSQL**: Güvenilir veritabanı
- **Redis**: Cache ve message broker
- **Celery**: Asenkron görev işleme
- **Nginx**: Yüksek performanslı web server
- **Tailwind CSS**: Modern responsive tasarım
- **Docker**: Kolay dağıtım

### 🛡️ Güvenlik
- CSRF koruması
- SQL injection koruması
- XSS koruması
- HTTPS/SSL
- Güvenli API anahtarı yönetimi
- Hata günlüğü ve monitoring

## 📋 Sistem Gereksinimleri

- **OS**: Ubuntu 20.04 LTS veya üstü
- **Python**: 3.9+
- **PostgreSQL**: 12+
- **Redis**: 6+
- **Nginx**: 1.18+
- **Node.js**: 14+ (Tailwind CSS için)

## 🚀 Hızlı Başlangıç

### Yerel Geliştirme Ortamı

```bash
# Proje klonla
git clone https://github.com/sata2500/habernexus.git
cd habernexus

# Virtual environment oluştur
python3 -m venv venv
source venv/bin/activate

# Bağımlılıkları yükle
pip install -r requirements.txt

# Ortam değişkenlerini ayarla
cp .env.example .env

# Migrasyonları uygula
python manage.py migrate

# Superuser oluştur
python manage.py createsuperuser

# Development server'ı başlat
python manage.py runserver
```

### Production Dağıtımı

Detaylı deployment rehberi için `docs/DEPLOYMENT.md` dosyasını okuyun.

Otomatik deployment script:

```bash
chmod +x scripts/deploy.sh
sudo ./scripts/deploy.sh
```

## 📚 Dokümantasyon

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Sistem mimarisi ve bileşenler
- **[DEVELOPMENT.md](docs/DEVELOPMENT.md)** - Geliştirme rehberi
- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Production dağıtım rehberi

## 🔐 API Anahtarı Yapılandırması

Admin panelinden (`/admin/api-settings/`) aşağıdaki API anahtarını ekleyin:

1. **Google Gemini API**: Haber içeriği üretimi için
2. **Google Imagen API**: Görsel üretimi için (opsiyonel)

## 📁 Proje Yapısı

```
habernexus/
├─ habernexus_config/       # Django ayarları
├─ news/                    # Haberler uygulaması
├─ authors/                 # Yazarlar uygulaması
├─ core/                    # Çekirdek uygulaması
├─ templates/               # HTML şablonları
├─ config/                  # Yapılandırma dosyaları
├─ scripts/                 # Yardımcı scriptler
├─ docs/                    # Dokümantasyon
├─ requirements.txt         # Python bağımlılıkları
├─ manage.py               # Django yönetim komutu
└─ docker-compose.yml      # Docker Compose yapılandırması
```

## 🔄 İş Akışı

### RSS Tarama Süreci
1. Celery Beat periyodik olarak `fetch_rss_feeds` görevini tetikler
2. RSS kaynakları taranır ve yeni haberler algılanır
3. Her haber için `generate_ai_content` görevi tetiklenir
4. Google Gemini API haber içeriğini oluşturur
5. Google Imagen API (opsiyonel) görsel oluşturur
6. Haber yayınlanır ve veritabanına kaydedilir

## 👥 Geliştirici

Salih TANRISEVEN (salihtanriseven25@gmail.com)

## 📄 Lisans

Tüm hakları saklıdır.
