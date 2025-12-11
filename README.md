# Haber Nexus - AI Destekli Otomatik Haber Ajansı

![Haber Nexus](https://img.shields.io/badge/Django-5.0-green) ![Python](https://img.shields.io/badge/Python-3.11-blue) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue) ![Redis](https://img.shields.io/badge/Redis-7-red) ![Celery](https://img.shields.io/badge/Celery-5.4-green) ![Docker](https://img.shields.io/badge/Docker-Ready-blue)

**Haber Nexus**, Google Gemini AI kullanarak RSS kaynaklarından tam otomatik, profesyonel ve SEO uyumlu haber içeriği üreten, 7/24 kesintisiz çalışan yeni nesil bir haber ajansı platformudur.

---

## 🚀 Hızlı Başlangıç

### Docker ile Kurulum (Önerilen)

1.  **Projeyi klonlayın:**
    ```bash
    git clone https://github.com/sata2500/habernexus.git
    cd habernexus
    ```

2.  **Ortam değişkenlerini ayarlayın:**
    ```bash
    cp .env.example .env
    nano .env # Gerekli alanları (SECRET_KEY, GOOGLE_API_KEY) doldurun
    ```

3.  **Docker Compose ile başlatın:**
    ```bash
    docker-compose up -d --build
    ```

4.  **Admin kullanıcısı oluşturun:**
    ```bash
    docker-compose exec app python manage.py createsuperuser
    ```

5.  **Tarayıcıdan açın:** `http://localhost`

Detaylı kurulum ve diğer seçenekler için **[Kurulum Rehberi](docs/INSTALLATION.md)**'ni inceleyin.

---

## 🌟 Temel Özellikler

| Özellik | Açıklama | Durum |
|---|---|---|
| **Otomatik İçerik Üretimi** | Google Gemini AI ile SEO uyumlu, profesyonel haber metinleri | ✅ |
| **Akıllı İçerik Sistemi** | Başlık puanlama, sınıflandırma ve kalite kontrolü | ✅ |
| **RSS Entegrasyonu** | Çoklu RSS kaynağından otomatik haber tarama ve işleme | ✅ |
| **Asenkron Görevler** | Celery ile 7/24 kesintisiz, performanslı görev işleme | ✅ |
| **Görsel Optimizasyonu** | İndirilen görselleri WebP formatına dönüştürme ve optimize etme | ✅ |
| **Docker Desteği** | Docker Compose ile tek komutla kolay kurulum ve deployment | ✅ |
| **CI/CD Pipeline** | GitHub Actions ile otomatik test, kod kalitesi ve güvenlik kontrolü | ✅ |
| **Kapsamlı Testler** | %71+ test coverage ile güvenilir kod tabanı | ✅ |
| **Admin Paneli** | Django admin üzerinden tam kontrol (API ayarları, kaynaklar, yazarlar) | ✅ |
| **SEO Optimizasyonu** | Sitemap, robots.txt, slug-based URL, meta etiketler | ✅ |

---

## 🛠️ Teknoloji Stack

- **Backend:** Django 5.0, Gunicorn
- **Veritabanı:** PostgreSQL 16
- **Cache & Broker:** Redis 7
- **Task Queue:** Celery 5.4, Celery Beat
- **AI Engine:** Google Gemini 1.5 Flash
- **Containerization:** Docker, Docker Compose
- **Frontend:** Tailwind CSS
- **Web Server:** Nginx

---

## 📚 Dokümantasyon

Tüm dokümantasyon `docs/` klasörü altında toplanmıştır. Her dosya, projenin belirli bir yönünü detaylı olarak açıklamaktadır.

| Dosya | Açıklama |
|---|---|
| **[QUICK_START.md](docs/QUICK_START.md)** | 5 dakikada hızlı başlangıç rehberi. |
| **[INSTALLATION.md](docs/INSTALLATION.md)** | Yerel, Docker ve Production ortamları için detaylı kurulum adımları. |
| **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** | Production ortamına dağıtım, CI/CD, yedekleme ve bakım. |
| **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** | Sistem mimarisi, bileşenler ve veri akışı. |
| **[CONTENT_SYSTEM.md](docs/CONTENT_SYSTEM.md)** | Gelişmiş içerik üretim sisteminin mimarisi ve işleyişi. |
| **[DEVELOPMENT.md](docs/DEVELOPMENT.md)** | Geliştirme süreçleri, kod standartları ve en iyi pratikler. |
| **[CONFIGURATION.md](docs/CONFIGURATION.md)** | Ortam değişkenleri ve servis yapılandırmaları. |
| **[CONTRIBUTING.md](docs/CONTRIBUTING.md)** | Projeye katkıda bulunma rehberi. |
| **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** | Sık karşılaşılan sorunlar ve çözümleri. |
| **[CHANGELOG.md](CHANGELOG.md)** | Projenin versiyon geçmişi ve yapılan değişiklikler. |

---

## 📂 Proje Yapısı

```
habernexus/
├── docs/                  # Tüm proje dokümantasyonu
├── habernexus_config/     # Django ayarları, Celery, WSGI
├── core/                  # Sistem ayarları, loglama, temel modeller
├── news/                  # Haber, RSS, kategori ve etiket yönetimi
├── authors/               # Yazar profilleri ve yönetimi
├── templates/             # HTML şablonları (Tailwind CSS)
├── scripts/               # Kurulum ve bakım scriptleri
├── docker-compose.yml     # Docker Compose yapılandırması
└── requirements.txt       # Python bağımlılıkları
```

---

## 🤝 Katkıda Bulunma

Katkılarınız projenin gelişimi için çok değerlidir. Lütfen **[Katkıda Bulunma Rehberi](docs/CONTRIBUTING.md)**'ni inceleyerek sürece dahil olun.

1.  Projeyi fork edin.
2.  Yeni bir branch oluşturun: `git checkout -b feature/yeni-ozellik`
3.  Değişikliklerinizi yapın ve commit edin: `git commit -m 'feat: Yeni özellik eklendi'`
4.  Fork ettiğiniz repoya push edin: `git push origin feature/yeni-ozellik`
5.  Bir Pull Request (PR) oluşturun.

---

## 👥 Geliştirici

- **Salih TANRISEVEN**
- **Email:** salihtanriseven25@gmail.com

---

## 📄 Lisans

Copyright (c) 2026 Haber Nexus. Tüm hakları saklıdır.

Bu proje tescilli (proprietary) lisans altındadır. Daha fazla bilgi için [LICENSE](LICENSE) dosyasına bakınız.
