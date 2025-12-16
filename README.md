# 🚀 HaberNexus v9.0

<div align="center">

![HaberNexus Logo](https://img.shields.io/badge/HaberNexus-v9.0-blue?style=for-the-badge&logo=newspaper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/Python-3.11+-green?style=for-the-badge&logo=python)](https://python.org)
[![Django](https://img.shields.io/badge/Django-5.1-green?style=for-the-badge&logo=django)](https://djangoproject.com)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?style=for-the-badge&logo=docker)](https://docker.com)

**Modern, AI-Destekli, Tam Otomatik Haber Agregasyon Platformu**

[Hızlı Kurulum](#-hızlı-kurulum) • [Özellikler](#-özellikler) • [Dökümanlar](#-dökümanlar) • [Destek](#-destek)

</div>

---

## ✨ v9.0'da Yenilikler

### 🎯 Ultimate Kurulum Sistemi
- **One-Click Kurulum** - Tek komutla tam otomatik kurulum
- **Web Wizard** - Tarayıcı tabanlı görsel kurulum sihirbazı
- **YAML Yapılandırma** - Dosya ile otomatik kurulum
- **Akıllı Validasyon** - Cloudflare API, domain, email doğrulaması
- **Gerçek Zamanlı İlerleme** - Animasyonlu progress bar
- **Rollback Mekanizması** - Hata durumunda otomatik geri alma

### 🛡️ Gelişmiş Güvenlik
- **Cloudflare Tunnel** - Port açmaya gerek yok
- **Otomatik SSL** - Let's Encrypt sertifikaları
- **API Token Doğrulama** - Kurulum öncesi kontrol
- **Güvenli Şifre Üretimi** - Otomatik güçlü şifreler

### 📊 Kapsamlı Yönetim
- **25+ Yönetim Komutu** - Tam kontrol
- **Sağlık İzleme** - Gerçek zamanlı durum
- **Otomatik Yedekleme** - Zamanlanmış backuplar
- **Sorun Giderme** - Entegre tanılama araçları

---

## 🚀 Hızlı Kurulum

### One-Click Kurulum (Önerilen)

Tek komutla tam otomatik kurulum:

```bash
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/install_v9.sh | sudo bash -s -- --quick
```

### Manuel Kurulum

```bash
# Repoyu klonlayın
git clone https://github.com/sata2500/habernexus.git
cd habernexus

# İnteraktif kurulum (Whiptail dialog'ları ile)
sudo bash install_v9.sh

# Hızlı kurulum (varsayılan değerlerle)
sudo bash install_v9.sh --quick

# Parametreli kurulum
sudo bash install_v9.sh --domain example.com --email admin@example.com

# Config dosyası ile kurulum
sudo bash install_v9.sh --config install_config.yml
```

### Kurulum Öncesi Kontrol

```bash
sudo bash pre_install_check_v8.sh
```

### Dry Run (Simülasyon)

```bash
sudo bash install_v9.sh --dry-run --quick
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
- Google Gemini AI ile otomatik haber özetleme
- Akıllı kategori sınıflandırma
- Duygu analizi ve trend tespiti

### 📰 Haber Agregasyonu
- 100+ haber kaynağı desteği
- RSS/Atom feed entegrasyonu
- Gerçek zamanlı güncelleme
- Otomatik içerik çekme

### 🎨 Modern Arayüz
- Responsive tasarım
- Karanlık/Aydınlık tema
- PWA desteği
- Mobil uyumlu

### 🔒 Güvenlik
- Cloudflare Tunnel entegrasyonu
- Otomatik SSL sertifikası
- Rate limiting
- CSRF/XSS koruması

### ⚡ Performans
- Redis cache
- Celery task queue
- PostgreSQL veritabanı
- Docker optimizasyonu

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
| Task Queue | Celery | 5.3+ |
| Reverse Proxy | Caddy | 2.7+ |
| Tunnel | Cloudflare Tunnel | Latest |
| Container | Docker | 24+ |
| AI | Google Gemini | Latest |

---

## 📊 Yönetim Komutları

```bash
# Kurulum dizinine git
cd /opt/habernexus

# Servis durumu
docker compose ps

# Logları görüntüle
docker compose logs -f

# Servisleri yeniden başlat
docker compose restart

# Servisleri durdur
docker compose down

# Servisleri başlat
docker compose up -d

# Yönetim scripti ile
bash manage_habernexus_v8.sh status
bash manage_habernexus_v8.sh health
bash manage_habernexus_v8.sh logs app
bash manage_habernexus_v8.sh backup-db
bash manage_habernexus_v8.sh help
```

---

## 🎯 Erişim Adresleri

| Servis | URL | Açıklama |
|--------|-----|----------|
| Ana Site | https://your-domain.com | Haber portalı |
| Admin Panel | https://your-domain.com/admin | Yönetim paneli |
| API | https://your-domain.com/api | REST API |
| Flower | https://your-domain.com/flower | Celery izleme |

---

## 📁 Proje Yapısı

```
habernexus/
├── 📄 install_v9.sh              # Ana kurulum scripti (Whiptail + Fallback)
├── 📄 install_v8.sh              # Alternatif kurulum scripti
├── 📄 one_click_install.sh       # Tek tıkla kurulum
├── 📄 pre_install_check_v8.sh    # Sistem kontrol scripti
├── 📄 manage_habernexus_v8.sh    # Yönetim scripti
├── 📄 docker-compose.yml         # Docker yapılandırması
├── 📄 Dockerfile                 # Uygulama imajı
├── 📄 requirements.txt           # Python bağımlılıkları
├── 📄 install_config.example.yml # Yapılandırma şablonu
├── 📁 habernexus_config/         # Django ayarları
├── 📁 core/                      # Çekirdek uygulama
├── 📁 news/                      # Haber modülü
├── 📁 users/                     # Kullanıcı modülü
├── 📁 api/                       # REST API
├── 📁 templates/                 # HTML şablonları
├── 📁 static/                    # Statik dosyalar
├── 📁 caddy/                     # Caddy yapılandırması
├── 📁 cloudflared/               # Tunnel yapılandırması
└── 📁 docs/                      # Dökümanlar
```

---

## 📚 Dökümanlar

| Döküman | Açıklama |
|---------|----------|
| [INSTALLATION_v8.md](docs/INSTALLATION_v8.md) | Detaylı kurulum kılavuzu |
| [QUICK_START.md](docs/QUICK_START.md) | Hızlı başlangıç |
| [API.md](docs/API.md) | API referansı |
| [CONFIGURATION.md](docs/CONFIGURATION.md) | Yapılandırma seçenekleri |

---

## 🐛 Sorun Giderme

### Kurulum Sorunları

```bash
# Sistem kontrolü
sudo bash pre_install_check_v8.sh

# Log dosyalarını incele
tail -f /var/log/habernexus/install_v8_*.log
```

### Çalışma Zamanı Sorunları

```bash
# Servis durumu
bash manage_habernexus_v8.sh status

# Sağlık kontrolü
bash manage_habernexus_v8.sh health

# Tanılama
bash manage_habernexus_v8.sh troubleshoot
```

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

- [x] Web tabanlı kurulum wizard
- [x] YAML yapılandırma desteği
- [x] Otomatik rollback mekanizması
- [x] Gelişmiş validasyon
- [ ] Çoklu dil desteği
- [ ] Mobil uygulama
- [ ] Plugin sistemi
- [ ] Gelişmiş analitik

---

<div align="center">

**HaberNexus v9.0** - Modern, Otomatik, Güvenli

Geliştirici: **Salih TANRISEVEN** | Aralık 2025

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!

</div>
