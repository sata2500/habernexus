# Haber Nexus - AI Destekli Otomatik Haber Ajansı

![Haber Nexus](https://img.shields.io/badge/Django-5.0-green) ![Python](https://img.shields.io/badge/Python-3.11-blue) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue) ![Redis](https://img.shields.io/badge/Redis-7-red) ![Celery](https://img.shields.io/badge/Celery-5.4-green) ![Docker](https://img.shields.io/badge/Docker-Ready-blue)

**Haber Nexus**, Google Gemini AI kullanarak RSS kaynaklarından tam otomatik, profesyonel haber içeriği üreten, 7/24 kesintisiz çalışan bir haber ajansı platformudur.

---

## 🚀 Hızlı Başlangıç (Otomatik Kurulum)

### Docker ile (Önerilen)

1.  **Projeyi klonlayın:**
    ```bash
    git clone https://github.com/sata2500/habernexus.git
    cd habernexus
    ```

2.  **Ortam değişkenlerini ayarlayın:**
    ```bash
    cp .env.example .env
    nano .env # Gerekli alanları doldurun (SECRET_KEY, GOOGLE_API_KEY)
    ```

3.  **Docker Compose ile başlatın:**
    ```bash
    docker-compose up -d --build
    ```

4.  **Admin kullanıcısı oluşturun:**
    ```bash
    docker-compose exec app python manage.py createsuperuser
    ```

5.  **Tarayıcıdan açın:** `http://localhost:80`

### Manuel Kurulum (Google Cloud VM / Ubuntu)

1.  **Kurulum scriptini indirin:**
    ```bash
    wget https://raw.githubusercontent.com/sata2500/habernexus/main/scripts/install.sh
    chmod +x install.sh
    ```

2.  **Scripti çalıştırın:**
    ```bash
    sudo bash install.sh
    ```

Script, size gerekli tüm bilgileri (domain, şifreler, API anahtarı) sorarak kurulumu otomatikleştirecektir.

---

## 🌟 Temel Özellikler

| Özellik | Açıklama | Durum |
|---|---|---|
| **Otomatik İçerik Üretimi** | Google Gemini AI ile SEO uyumlu, profesyonel haber metinleri | ✅ |
| **RSS Entegrasyonu** | Çoklu RSS kaynağından otomatik haber tarama ve işleme | ✅ |
| **Asenkron Görevler** | Celery ile 7/24 kesintisiz, performanslı görev işleme | ✅ |
| **Akıllı Kuyruk Sistemi** | Görevleri önceliklerine göre (high, default, low) ayırma | ✅ |
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

## 📂 Proje Yapısı

```
habernexus/
├── habernexus_config/  # Django ayarları, Celery, WSGI
├── core/               # Sistem ayarları, loglama, temel modeller
├── news/               # Haber, RSS, kategori ve etiket yönetimi
├── authors/            # Yazar profilleri ve yönetimi
├── templates/          # HTML şablonları (Tailwind CSS)
├── scripts/            # Kurulum ve bakım scriptleri
├── docs/               # Detaylı dokümantasyon
├── docker-compose.yml  # Docker Compose yapılandırması
└── requirements.txt    # Python bağımlılıkları
```

---

## 📚 Dokümantasyon

Detaylı bilgi için `docs` klasörünü inceleyin:

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md):** Sistem mimarisi ve bileşenler
- **[DEVELOPMENT.md](docs/DEVELOPMENT.md):** Geliştirme rehberi ve standartlar
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md):** Sık karşılaşılan sorunlar ve çözümleri
- **[CHANGELOG.md](docs/CHANGELOG.md):** Versiyon geçmişi ve değişiklikler

---

## 🤝 Katkıda Bulunma

Katkılarınız için teşekkürler! Lütfen aşağıdaki adımları izleyin:

1.  Projeyi fork edin.
2.  Yeni bir branch oluşturun: `git checkout -b feature/yeni-ozellik`
3.  Değişikliklerinizi yapın ve commit edin: `git commit -m 'feat: Yeni özellik eklendi'`
4.  Fork ettiğiniz repoya push edin: `git push origin feature/yeni-ozellik`
5.  Bir Pull Request (PR) oluşturun.

Lütfen kod standartları için `docs/DEVELOPMENT.md` dosyasını inceleyin.

---

## 👥 Geliştirici

- **Salih TANRISEVEN**
- **Email:** salihtanriseven25@gmail.com

---

## 📄 Lisans

Copyright (c) 2026 Haber Nexus. Tüm hakları saklıdır.

Bu proje tescilli (proprietary) lisans altındadır. Daha fazla bilgi için [LICENSE](LICENSE) dosyasına bakınız.
