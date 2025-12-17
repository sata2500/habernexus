# 🚀 HaberNexus v10.3

<div align="center">

![HaberNexus Logo](https://img.shields.io/badge/HaberNexus-v10.3-blue?style=for-the-badge&logo=newspaper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/Python-3.10%2B-green?style=for-the-badge&logo=python)](https://python.org)
[![Django](https://img.shields.io/badge/Django-5.1-green?style=for-the-badge&logo=django)](https://djangoproject.com)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?style=for-the-badge&logo=docker)](https://docker.com)
[![CI/CD](https://img.shields.io/github/actions/workflow/status/sata2500/habernexus/ci.yml?style=for-the-badge&label=CI%2FCD)](https://github.com/sata2500/habernexus/actions)

**Modern, AI-Destekli, Tam Otomatik Haber Agregasyon Platformu**

[Hızlı Kurulum](#-hızlı-kurulum) • [Özellikler](#-özellikler) • [API](#-rest-api) • [Dökümanlar](#-dökümanlar) • [Destek](#-destek)

</div>

---

## ✨ v10.3'te Yenilikler

### 🤖 Google Gen AI SDK Güncellemeleri
- **ThinkingLevel Enum Desteği:** `MINIMAL`, `LOW`, `MEDIUM`, `HIGH` seviyeleri ile thinking kontrolü.
- **ThinkingConfig İyileştirmeleri:** Daha esnek thinking_budget ve thinking_level yapılandırması.
- **Retry Mekanizması:** Exponential backoff ile gelişmiş hata yönetimi.
- **Batch Processing:** Toplu içerik üretimi için yeni task'lar.

### 🛡️ Güçlendirilmiş CI/CD Pipeline
- **CodeQL Entegrasyonu:** Gelişmiş güvenlik analizi ve kod taraması.
- **Dependency Review:** PR'larda otomatik bağımlılık güvenlik kontrolü.
- **Redis Service:** Test ortamında Redis desteği.
- **Haftalık Güvenlik Taraması:** Zamanlanmış güvenlik kontrolleri.
- **Test Timeout:** Uzun süren testler için timeout mekanizması.

### 🔒 Gelişmiş Hata Takibi
- **Sentry Entegrasyonu:** Kapsamlı hata izleme ve raporlama.
- **Error Context Manager:** Hata bağlamı yönetimi.
- **Breadcrumb Tracking:** İşlem geçmişi takibi.
- **Error Report Generator:** Detaylı hata raporları.

### 📁 Proje Organizasyonu
- **Arşiv Sistemi:** Eski dosyalar için sistematik arşivleme.
- **Temizlenmiş Kök Dizin:** Daha düzenli proje yapısı.
- **Güncellenmiş Dokümantasyon:** Tüm belgeler v10.3 için güncellendi.

---

## 🚀 Hızlı Kurulum

### One-Click Kurulum (Önerilen)

Tek komutla tam otomatik kurulum:

```bash
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/one_click_install.sh | sudo bash
```

### Manuel Kurulum

```bash
# Repoyu klonlayın
git clone https://github.com/sata2500/habernexus.git
cd habernexus

# İnteraktif kurulum
sudo bash install_v9.sh
```

### Docker ile Kurulum

```bash
# Docker Compose ile başlatma
docker compose up -d

# Logları izleme
docker compose logs -f
```

---

## 💻 Sistem Gereksinimleri

| Bileşen | Minimum | Önerilen |
|---------|---------|----------|
| CPU | 2 çekirdek | 4+ çekirdek |
| RAM | 2 GB | 4+ GB |
| Disk | 15 GB | 50+ GB SSD |
| OS | Ubuntu 20.04 | Ubuntu 22.04/24.04 |
| Python | 3.10+ | 3.11+ |

---

## ✨ Özellikler

### 🤖 AI-Destekli İçerik
- **Google Gemini AI:** Otomatik haber özetleme ve içerik üretimi (Gemini 2.5 Flash).
- **ThinkingConfig:** Gelişmiş reasoning için thinking_level ve thinking_budget desteği.
- **Akıllı Kategori Sınıflandırma:** İçeriklerin otomatik olarak kategorize edilmesi.
- **Duygu Analizi:** Haber metinlerinin duygu analizinin yapılması.
- **Görsel Üretimi:** Google Imagen 4.0 ile AI destekli görsel oluşturma.

### 📰 Haber Agregasyonu
- **100+ Haber Kaynağı:** Geniş RSS/Atom feed desteği.
- **Gerçek Zamanlı Güncelleme:** Celery ile periyodik içerik çekme.
- **İçerik Kalite Kontrolü:** Otomatik kalite değerlendirme ve filtreleme.
- **Duplicate Detection:** Tekrar eden içeriklerin otomatik tespiti.

### 🚀 REST API
- **Kapsamlı Endpoints:** Haberler, yazarlar, kategoriler ve daha fazlası için API.
- **Güvenlik:** Rate limiting, CORS ve JWT yetkilendirme.
- **Dokümantasyon:** drf-spectacular ile otomatik Swagger/ReDoc.
- **Pagination:** Cursor-based ve offset pagination desteği.

### 📧 Newsletter Sistemi
- **E-posta Aboneliği:** Kullanıcıların bültenlere abone olması.
- **Otomatik Gönderim:** Celery Beat ile periyodik bülten gönderimi.
- **Template Desteği:** Özelleştirilebilir e-posta şablonları.
- **Abonelik Yönetimi:** Kolay abonelik iptal ve tercih yönetimi.

### 🔒 Güvenlik
- **Cloudflare Tunnel:** Port açmadan güvenli erişim.
- **Otomatik SSL:** Let's Encrypt ile otomatik SSL sertifikası.
- **Rate Limiting:** DDoS koruması için istek sınırlama.
- **Security Headers:** Modern güvenlik başlıkları.
- **Sentry Entegrasyonu:** Kapsamlı hata takibi ve raporlama.

---

## 🏗️ Mimari

```
┌──────────────────────────────────────────┐
│         Cloudflare Tunnel                │
│  (DDoS Protection, No Port Forwarding)   │
└────────────────┬─────────────────────────┘
                 │
┌────────────────▼─────────────────────────┐
│    Caddy Reverse Proxy                   │
│  (Automatic HTTPS, Load Balancing)       │
└────────────────┬─────────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
┌───▼──┐  ┌─────▼────┐  ┌───▼────┐
│Django│  │ Celery   │  │Flower  │
│ App  │  │ Workers  │  │Monitor │
└───┬──┘  └─────┬────┘  └────────┘
    │           │
┌───▼───────────▼────┐
│PostgreSQL + Redis  │
│(Data & Cache)      │
└────────────────────┘
```

---

## 🛠️ Teknoloji Stack

| Bileşen | Teknoloji | Versiyon |
|---------|-----------|----------|
| Backend | Django | 5.1+ |
| Veritabanı | PostgreSQL | 16 |
| Cache | Redis | 7 |
| Task Queue | Celery | 5.4+ |
| Reverse Proxy | Caddy | 2.7+ |
| Tunnel | Cloudflare Tunnel | Latest |
| Container | Docker | 24+ |
| AI | Google Gemini | 2.5 Flash |
| Image AI | Google Imagen | 4.0 |
| API Framework | Django REST Framework | 3.15+ |
| API Docs | drf-spectacular | 0.28+ |
| Error Tracking | Sentry | 2.19+ |

---

## 📊 Yönetim Komutları

```bash
# Kurulum dizinine git
cd /opt/habernexus

# Servis durumu
docker compose ps

# Logları görüntüle
docker compose logs -f

# Yönetim scripti ile
bash manage_habernexus_v8.sh help

# Testleri çalıştır
docker compose exec web pytest -v

# Migration oluştur
docker compose exec web python manage.py makemigrations

# Migration uygula
docker compose exec web python manage.py migrate
```

---

## 🎯 Erişim Adresleri

| Servis | URL | Açıklama |
|--------|-----|----------|
| Ana Site | https://your-domain.com | Haber portalı |
| Admin Panel | https://your-domain.com/admin | Yönetim paneli |
| API | https://your-domain.com/api/v1/ | REST API |
| API Docs | https://your-domain.com/api/v1/schema/swagger-ui/ | Swagger UI |
| ReDoc | https://your-domain.com/api/v1/schema/redoc/ | ReDoc |
| Health Check | https://your-domain.com/core/health/ | Sistem sağlık durumu |
| Flower | https://your-domain.com/flower | Celery izleme |

---

## 📁 Proje Yapısı

```
habernexus/
├── 📄 .github/workflows/ci.yml   # Güçlendirilmiş CI/CD Pipeline
├── 📄 docker-compose.yml         # Docker yapılandırması
├── 📄 Dockerfile                 # Uygulama imajı
├── 📄 requirements.txt           # Python bağımlılıkları
├── 📁 habernexus_config/         # Django ayarları
│   ├── settings.py               # Ana ayarlar
│   ├── settings_test.py          # Test ayarları
│   └── celery.py                 # Celery yapılandırması
├── 📁 core/                      # Çekirdek uygulama
│   ├── exceptions.py             # Özel exception sınıfları
│   ├── error_tracking.py         # Sentry entegrasyonu
│   ├── middleware.py             # Güvenlik ve logging middleware
│   ├── logging_config.py         # Yapılandırılmış logging
│   └── health.py                 # Health check endpoints
├── 📁 news/                      # Haber modülü
│   ├── tasks.py                  # AI içerik üretimi (Gemini)
│   ├── models.py                 # Veri modelleri
│   └── views.py                  # View'lar
├── 📁 api/                       # REST API
│   ├── views.py                  # API view'ları
│   ├── serializers.py            # Serializer'lar
│   └── permissions.py            # Yetkilendirme
├── 📁 templates/                 # HTML şablonları
├── 📁 static/                    # Statik dosyalar
├── 📁 docs/                      # Güncel dökümanlar
└── 📁 archive/                   # Arşivlenmiş dosyalar
```

---

## 🔄 CI/CD Pipeline

GitHub Actions ile otomatik CI/CD:

```yaml
# Her push'ta çalışan job'lar:
- Test (Python 3.10, 3.11, 3.12)  # Paralel test matrix
- Code Quality                     # Black, isort, flake8, Ruff
- Security Checks                  # Bandit, pip-audit
- CodeQL Analysis                  # Gelişmiş güvenlik taraması
- Django Configuration Check       # System checks
- Dependency Review                # PR güvenlik kontrolü
- Build Docker Image               # Docker build (main branch)
- Pipeline Status                  # Durum bildirimi
```

---

## 📚 Dökümanlar

| Döküman | Açıklama |
|---------|----------|
| [INSTALLATION.md](docs/INSTALLATION.md) | Detaylı kurulum kılavuzu |
| [QUICK_START.md](docs/QUICK_START.md) | Hızlı başlangıç |
| [API.md](docs/API.md) | API referansı |
| [CONFIGURATION.md](docs/CONFIGURATION.md) | Yapılandırma seçenekleri |
| [CICD.md](docs/CICD.md) | CI/CD pipeline detayları |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Sorun giderme |
| [CHANGELOG.md](CHANGELOG.md) | Değişiklik günlüğü |

---

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz!

1. Repoyu fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'i push edin (`git push origin feature/amazing`)
5. Pull Request açın

### Kod Standartları

```bash
# Kod formatlama
black . --line-length=120

# Import sıralama
isort .

# Linting
flake8 . --max-line-length=120

# Testler
pytest -v
```

---

## 📞 Destek

- **GitHub Issues**: [Issues](https://github.com/sata2500/habernexus/issues)
- **E-posta**: salihtanriseven25@gmail.com
- **Geliştirici**: Salih TANRISEVEN
- **Domain**: [habernexus.com](https://habernexus.com)

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.

---

## 📈 Yol Haritası

### Tamamlanan
- [x] REST API Modülü
- [x] Newsletter Sistemi
- [x] Gelişmiş Hata Yakalama
- [x] Güçlendirilmiş CI/CD
- [x] Google Gen AI SDK Güncellemeleri
- [x] Rate Limiting Middleware
- [x] Security Headers
- [x] Sentry Entegrasyonu
- [x] CodeQL Analizi
- [x] Proje Organizasyonu

### Planlanan
- [ ] Çoklu dil desteği (i18n)
- [ ] Mobil uygulama (React Native)
- [ ] Plugin sistemi
- [ ] Gelişmiş analitik dashboard
- [ ] GraphQL API desteği
- [ ] WebSocket real-time updates

---

## 📊 Versiyon Geçmişi

| Versiyon | Tarih | Önemli Değişiklikler |
|----------|-------|---------------------|
| v10.3 | Aralık 2025 | ThinkingLevel enum, CodeQL, Sentry, proje organizasyonu |
| v10.2 | Aralık 2025 | Google Gen AI SDK güncellemeleri, CI/CD güçlendirme |
| v10.1 | Aralık 2025 | CI/CD düzeltmeleri, hata yakalama sistemi |
| v10.0 | Aralık 2025 | REST API, Newsletter, Google Gen AI SDK |
| v9.0 | Aralık 2025 | Whiptail kurulum sistemi |
| v8.0 | Aralık 2025 | Ultimate kurulum sistemi |

---

<div align="center">

**HaberNexus v10.3** - Modern, Otomatik, Güvenli

**Geliştirici:** Salih TANRISEVEN | Aralık 2025

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!

[![GitHub stars](https://img.shields.io/github/stars/sata2500/habernexus?style=social)](https://github.com/sata2500/habernexus)

</div>
