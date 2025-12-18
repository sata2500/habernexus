# HaberNexus

<div align="center">

![HaberNexus Logo](https://img.shields.io/badge/HaberNexus-v10.7-blue?style=for-the-badge&logo=newspaper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/Python-3.10%2B-green?style=for-the-badge&logo=python)](https://python.org)
[![Django](https://img.shields.io/badge/Django-5.1-green?style=for-the-badge&logo=django)](https://djangoproject.com)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?style=for-the-badge&logo=docker)](https://docker.com)
[![CI/CD](https://img.shields.io/github/actions/workflow/status/sata2500/habernexus/ci.yml?style=for-the-badge&label=CI%2FCD)](https://github.com/sata2500/habernexus/actions)
[![Release](https://img.shields.io/github/v/release/sata2500/habernexus?style=for-the-badge)](https://github.com/sata2500/habernexus/releases)

**Modern, AI-Destekli, Tam Otomatik Haber Agregasyon Platformu**

[Hızlı Kurulum](#-hızlı-kurulum) • [Özellikler](#-özellikler) • [API](#-rest-api) • [Dökümanlar](#-dökümanlar) • [Destek](#-destek)

</div>

---

## ✨ v10.7 Yenilikleri

### 🔄 Gelişmiş Kurulum Sistemi
- **Tam Sıfırlama:** `--reset` parametresi ile tüm eski kurulumu temizleme (Docker, Caddy, Cloudflare vs.)
- **Akıllı Yedekleme:** Sadece veritabanı ve yapılandırma dosyası yedekleniyor
- **Güvenli Yedek Konumu:** Yedekler `/var/backups/habernexus` dizininde saklanıyor
- **Kolay Geri Yükleme:** `--restore` parametresi ile tek komutla geri yükleme
- **Pipe Desteği:** `curl | bash` ile çalıştırıldığında bile interaktif girdi alabilme

### 🤖 Google Gen AI SDK Güncellemeleri
- **Gelişmiş ThinkingConfig Desteği:** Gemini 2.5 ve 3 serisi için optimize edilmiş
- **Geriye Uyumluluk:** Eski API'ler otomatik olarak yeni formata dönüştürülüyor

### 🛡️ Güçlendirilmiş CI/CD Pipeline
- **Otomatik Release:** Versiyon güncellendiğinde otomatik GitHub Release oluşturma
- **Otomatik Issue Oluşturma:** Pipeline hatalarında otomatik issue açma
- **Güvenlik Taraması:** Bandit ve Trivy ile SARIF formatında raporlama

---

## 🚀 Hızlı Kurulum

### ⚡ Tek Komutla Kurulum (Önerilen)

```bash
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/get-habernexus.sh | sudo bash
```

### 🔧 Kurulum Seçenekleri

```bash
# Domain ve email ile kurulum
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/get-habernexus.sh | \
  sudo bash -s -- --domain example.com --email admin@example.com

# Hızlı kurulum (varsayılan değerlerle)
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/get-habernexus.sh | \
  sudo bash -s -- --quick

# Tam sıfırlama ile yeniden kurulum
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/get-habernexus.sh | \
  sudo bash -s -- --reset
```

### 💾 Yedekleme ve Geri Yükleme

```bash
# Manuel yedek alma
sudo bash get-habernexus.sh --backup

# Mevcut yedekleri listeleme
sudo bash get-habernexus.sh --list-backups

# Yedekten geri yükleme
sudo bash get-habernexus.sh --restore backup_20251218_013128
```

### 🐳 Docker ile Kurulum

```bash
# Production ortamı
docker compose -f docker-compose.prod.yml up -d

# Development ortamı
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
- **Google Gemini AI:** Otomatik haber özetleme ve içerik üretimi
- **ThinkingConfig:** Gelişmiş reasoning desteği
- **Akıllı Kategori Sınıflandırma:** Otomatik kategorize
- **Duygu Analizi:** Haber metinlerinin analizi
- **Görsel Üretimi:** Google Imagen 4.0 ile AI görsel oluşturma

### 📰 Haber Agregasyonu
- **100+ Haber Kaynağı:** Geniş RSS/Atom feed desteği
- **Gerçek Zamanlı Güncelleme:** Celery ile periyodik içerik çekme
- **İçerik Kalite Kontrolü:** Otomatik kalite değerlendirme
- **Duplicate Detection:** Tekrar eden içeriklerin tespiti

### 🚀 REST API
- **Kapsamlı Endpoints:** Haberler, yazarlar, kategoriler için API
- **Güvenlik:** Rate limiting, CORS ve JWT yetkilendirme
- **Dokümantasyon:** Swagger/ReDoc ile otomatik API docs
- **Pagination:** Cursor-based ve offset pagination

### 📧 Newsletter Sistemi
- **E-posta Aboneliği:** Kullanıcı bülten aboneliği
- **Otomatik Gönderim:** Celery Beat ile periyodik gönderim
- **Template Desteği:** Özelleştirilebilir şablonlar

### 🔒 Güvenlik
- **Cloudflare Tunnel:** Port açmadan güvenli erişim
- **SSL/TLS:** Otomatik sertifika yönetimi
- **Rate Limiting:** API isteklerini sınırlama
- **CORS:** Cross-origin güvenliği

---

## 📚 Proje Yönetimi ve Dokümantasyon

Bu proje, tüm geliştiricilerin katılımını teşvik eden şeffaf ve merkezi bir yönetim sistemi kullanır. Katkıda bulunmadan önce lütfen aşağıdaki belgeleri inceleyin.

| Belge | Açıklama |
|---|---|
| [**Geliştirme Yol Haritası (DEVELOPMENT_ROADMAP.md)**](DEVELOPMENT_ROADMAP.md) | Projenin gelecek hedeflerini, anlık öncelikleri ve görev durumlarını içerir. | 
| [**Katkıda Bulunma Rehberi (CONTRIBUTING.md)**](CONTRIBUTING.md) | Kodlama standartları, commit formatı ve PR süreci gibi tüm katkı kurallarını tanımlar. |
| [**Geliştirici Rehberi (DEVELOPER_GUIDE.md)**](DEVELOPER_GUIDE.md) | Projenin teknik mimarisi, kurulumu ve geliştirme ortamı hakkında detaylı bilgi verir. |
| [**Bilinen Hatalar (KNOWN_ISSUES.md)**](KNOWN_ISSUES.md) | Mevcut hataları, geçici çözümleri ve hata raporlama sürecini açıklar. |

---

## 🛠️ Geliştirme

### Yerel Geliştirme Ortamı

```bash
# Repoyu klonlayın
git clone https://github.com/sata2500/habernexus.git
cd habernexus

# Virtual environment oluşturun
python -m venv venv
source venv/bin/activate

# Bağımlılıkları kurun
pip install -r requirements.txt

# Geliştirme sunucusunu başlatın
python manage.py runserver
```

### Test Çalıştırma

```bash
# Tüm testleri çalıştır
pytest

# Coverage ile
pytest --cov=. --cov-report=html
```

---

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen [CONTRIBUTING.md](CONTRIBUTING.md) dosyasını okuyun.

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'feat: Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

---

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

---

## 👨‍💻 Geliştirici

**Salih TANRISEVEN**
- Email: salihtanriseven25@gmail.com
- GitHub: [@sata2500](https://github.com/sata2500)

---

<div align="center">

**⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!**

</div>
