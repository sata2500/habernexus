# 🚀 HaberNexus v10.1

<div align="center">

![HaberNexus Logo](https://img.shields.io/badge/HaberNexus-v10.1-blue?style=for-the-badge&logo=newspaper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/Python-3.11+-green?style=for-the-badge&logo=python)](https://python.org)
[![Django](https://img.shields.io/badge/Django-5.1-green?style=for-the-badge&logo=django)](https://djangoproject.com)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?style=for-the-badge&logo=docker)](https://docker.com)

**Modern, AI-Destekli, Tam Otomatik Haber Agregasyon Platformu**

[Hızlı Kurulum](#-hızlı-kurulum) • [Özellikler](#-özellikler) • [Dökümanlar](#-dökümanlar) • [Destek](#-destek)

</div>

---

## ✨ v10.1'de Yenilikler

### 🎯 CI/CD ve Hata Ayıklama
- **Güçlendirilmiş CI/CD Pipeline:** GitHub Actions workflow'u güvenlik ve performans için optimize edildi.
- **Kapsamlı Testler:** Python 3.10, 3.11 ve 3.12 için test matrix eklendi.
- **Güvenlik Taramaları:** Bandit, Safety ve Trivy ile otomatik güvenlik taramaları.
- **Kod Kalitesi:** Black, isort, flake8 ve ruff ile otomatik kod kalitesi kontrolü.
- **Hata Düzeltmeleri:** `ATOMIC_REQUESTS` ve `AuthorSerializer` hataları giderildi.

### 🛡️ Gelişmiş Hata Yakalama
- **Özel Exception Sınıfları:** `core/exceptions.py` ile daha yönetilebilir hata sınıfları.
- **Gelişmiş Logging:** `core/logging_config.py` ile yapılandırılmış JSON log formatı.
- **Middleware'ler:** `core/middleware.py` ile global hata yakalama, performans izleme ve güvenlik başlıkları.
- **Health Check Endpoint'leri:** `/core/health/` altında detaylı sistem sağlık durumu.

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

---

## 💻 Sistem Gereksinimleri

| Bileşen | Minimum | Önerilen |
|---------|---------|----------|
| CPU | 2 çekirdek | 4+ çekirdek |
| RAM | 2 GB | 4+ GB |
| Disk | 15 GB | 50+ GB SSD |
| OS | Ubuntu 20.04 | Ubuntu 22.04/24.04 |

---

## ✨ Özellikler

### 🤖 AI-Destekli İçerik
- **Google Gemini AI:** Otomatik haber özetleme ve görsel üretimi (Gemini 2.5 Flash & Imagen 4.0).
- **Akıllı Kategori Sınıflandırma:** İçeriklerin otomatik olarak kategorize edilmesi.
- **Duygu Analizi:** Haber metinlerinin duygu analizinin yapılması.

### 📰 Haber Agregasyonu
- **100+ Haber Kaynağı:** Geniş RSS/Atom feed desteği.
- **Gerçek Zamanlı Güncelleme:** Celery ile periyodik içerik çekme.

### 🚀 REST API
- **Kapsamlı Endpoints:** Haberler, yazarlar, kategoriler ve daha fazlası için API.
- **Güvenlik:** Rate limiting, CORS ve yetkilendirme.
- **Dokümantasyon:** drf-spectacular ile otomatik Swagger/ReDoc.

### 📧 Newsletter Sistemi
- **E-posta Aboneliği:** Kullanıcıların bültenlere abone olması.
- **Otomatik Gönderim:** Celery Beat ile periyodik bülten gönderimi.

### 🔒 Güvenlik
- **Cloudflare Tunnel:** Port açmadan güvenli erişim.
- **Otomatik SSL:** Let's Encrypt ile otomatik SSL sertifikası.
- **Gelişmiş Hata Yakalama:** Kapsamlı logging ve hata yönetimi.

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
```

---

## 🎯 Erişim Adresleri

| Servis | URL | Açıklama |
|--------|-----|----------|
| Ana Site | https://your-domain.com | Haber portalı |
| Admin Panel | https://your-domain.com/admin | Yönetim paneli |
| API | https://your-domain.com/api/v1/ | REST API |
| API Docs | https://your-domain.com/api/v1/schema/swagger-ui/ | Swagger UI |
| Flower | https://your-domain.com/flower | Celery izleme |

---

## 📁 Proje Yapısı

```
habernexus/
├── 📄 .github/workflows/ci.yml   # Gelişmiş CI/CD Pipeline
├── 📄 docker-compose.yml         # Docker yapılandırması
├── 📄 Dockerfile                 # Uygulama imajı
├── 📄 requirements.txt           # Python bağımlılıkları
├── 📁 habernexus_config/         # Django ayarları
├── 📁 core/                      # Çekirdek uygulama (hata yakalama, logging)
├── 📁 news/                      # Haber modülü (AI, RSS, API)
├── 📁 users/                     # Kullanıcı modülü
├── 📁 api/                       # REST API
├── 📁 templates/                 # HTML şablonları
├── 📁 static/                    # Statik dosyalar
└── 📁 docs/                      # Dökümanlar
```

---

## 📚 Dökümanlar

| Döküman | Açıklama |
|---------|----------|
| [INSTALLATION.md](docs/INSTALLATION.md) | Detaylı kurulum kılavuzu |
| [QUICK_START.md](docs/QUICK_START.md) | Hızlı başlangıç |
| [API.md](docs/API.md) | API referansı |
| [CONFIGURATION.md](docs/CONFIGURATION.md) | Yapılandırma seçenekleri |

---

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz!

1. Repoyu fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'i push edin (`git push origin feature/amazing`)
5. Pull Request açın

---

## 📞 Destek

- **GitHub Issues**: [Issues](https://github.com/sata2500/habernexus/issues)
- **E-posta**: salihtanriseven25@gmail.com
- **Geliştirici**: Salih TANRISEVEN

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.

---

## 📈 Yol Haritası

- [x] REST API Modülü
- [x] Newsletter Sistemi
- [x] Gelişmiş Hata Yakalama
- [x] Güçlendirilmiş CI/CD
- [ ] Çoklu dil desteği
- [ ] Mobil uygulama
- [ ] Plugin sistemi
- [ ] Gelişmiş analitik

---

<div align="center">

**HaberNexus v10.1** - Modern, Otomatik, Güvenli

**Geliştirici:** Salih TANRISEVEN | Aralık 2025

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!

</div>
