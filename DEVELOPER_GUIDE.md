# HaberNexus - Kapsamlı Geliştirici Rehberi

**Son Güncelleme:** 18 Aralık 2025

---

Bu rehber, HaberNexus projesinin teknik mimarisini, yerel geliştirme ortamının kurulumunu ve proje standartlarını detaylı bir şekilde açıklamaktadır. Projeye yeni katılan veya katkıda bulunmak isteyen tüm geliştiriciler için bir başlangıç noktasıdır.

## 1. 🏛️ Proje Mimarisi

HaberNexus, ölçeklenebilir ve modüler bir yapı üzerine kurulmuş, Django tabanlı bir web uygulamasıdır. Sistem, birkaç ana bileşenden oluşur:

| Bileşen | Teknoloji | Açıklama |
|---|---|---|
| **Web Sunucusu** | Nginx | Gelen istekleri karşılayan ve statik dosyaları sunan reverse proxy. |
| **Uygulama Sunucusu**| Gunicorn | Django uygulamasını çalıştıran WSGI sunucusu. |
| **Core Framework** | Django 5.1 | Projenin ana iş mantığını barındıran web çatısı. |
| **Veritabanı** | PostgreSQL | Tüm verilerin (haberler, kullanıcılar, vb.) saklandığı ilişkisel veritabanı. |
| **Asenkron Görevler**| Celery & Redis | Uzun süren işlemleri (RSS çekme, AI içerik üretimi) arka planda yürüten görev kuyruğu. Redis, mesaj broker olarak kullanılır. |
| **AI Motoru** | Google Gen AI SDK | Haber özetleme, kategori belirleme ve içerik üretimi için Gemini modellerini kullanır. |
| **Arama Motoru** | Elasticsearch | Gelişmiş metin arama ve filtreleme yetenekleri sağlar. |
| **Önbellekleme** | Redis | Sık erişilen verileri önbelleğe alarak performansı artırır. |
| **Konteynerizasyon**| Docker & Docker Compose| Tüm servislerin izole ortamlarda tutarlı bir şekilde çalışmasını sağlar. |
| **CI/CD** | GitHub Actions | Kod kalitesi kontrolü, test ve dağıtım süreçlerini otomatikleştirir. |

### 📁 Proje Dizin Yapısı

```
habernexus/
├── .github/              # GitHub Actions ve issue şablonları
├── api/                  # REST API uygulaması (DRF)
├── authors/              # Yazar yönetimi uygulaması
├── core/                 # Çekirdek uygulama (ayarlar, loglama, temel modeller)
├── news/                 # Haber yönetimi uygulaması (ana iş mantığı)
├── habernexus_config/    # Django proje ayarları (settings.py, urls.py)
├── static/               # Statik dosyalar (CSS, JS, imajlar)
├── templates/            # Django şablonları
├── docs/                 # Güncel olmayan, arşivlenmiş dokümanlar
├── archive/              # Arşivlenmiş eski dokümanlar ve script'ler
├── scripts/              # Yardımcı betikler (backup, restore)
├── tests/                # Entegrasyon testleri
├── Dockerfile            # Ana uygulama için Docker imajı
├── docker-compose.yml    # Geliştirme ortamı için Docker Compose
├── requirements.txt      # Python bağımlılıkları
├── pyproject.toml        # Proje ve araç yapılandırması (Ruff, Pytest)
└── manage.py             # Django yönetim aracı
```

---

## 2. 🛠️ Yerel Geliştirme Ortamı Kurulumu

### Ön Gereksinimler

- Git
- Docker ve Docker Compose
- GitHub hesabınıza fork'lanmış HaberNexus reposu

### Kurulum Adımları

1.  **Projeyi Klonlayın:**

    ```bash
    git clone https://github.com/<YOUR_USERNAME>/habernexus.git
    cd habernexus
    git remote add upstream https://github.com/sata2500/habernexus.git
    ```

2.  **Ortam Değişkenlerini Ayarlayın:**

    `.env.example` dosyasını kopyalayarak `.env` dosyasını oluşturun ve gerekli alanları doldurun.

    ```bash
    cp .env.example .env
    ```

    **Önemli `.env` Değişkenleri:**

    - `DEBUG=True`
    - `DJANGO_SECRET_KEY`: Geliştirme için benzersiz bir anahtar oluşturun.
    - `ALLOWED_HOSTS=localhost,127.0.0.1`
    - `GOOGLE_API_KEY`: Kendi Google AI API anahtarınız.

3.  **Docker Servislerini Başlatın:**

    ```bash
    docker-compose up -d
    ```

4.  **Veritabanı Migrasyonlarını Çalıştırın:**

    ```bash
    docker-compose exec app python manage.py migrate
    ```

5.  **Süper Kullanıcı Oluşturun:**

    ```bash
    docker-compose exec app python manage.py createsuperuser
    ```

6.  **Sisteme Erişin:**

    - **Uygulama:** `http://localhost`
    - **Django Admin:** `http://localhost/admin`

---

## 3. ✅ Kod Kalitesi ve Test

Proje, yüksek kod kalitesini korumak için `Ruff` ve `Bandit` gibi araçları kullanır.

### Kod Analizi

Değişikliklerinizi commit'lemeden önce aşağıdaki komutları çalıştırın:

```bash
# Ruff ile formatlama ve linting hatalarını kontrol et
ruff check .

# Ruff ile otomatik formatlama
ruff format .

# Bandit ile güvenlik taraması
bandit -r . -x ./venv,./.git
```

### Testler

Tüm testlerin başarılı olduğundan emin olun.

```bash
# Tüm testleri çalıştır
pytest

# Test kapsamını (coverage) raporla
pytest --cov=.
```

**Test Hedefleri:**

- **Minimum Kapsam:** %70
- **Hedef Kapsam:** %85+
- Kritik iş akışları için %100 test kapsamı hedeflenmelidir.

---

## 4. 🚀 Katkı ve Geliştirme Süreci

Tüm geliştirme süreci [Geliştirme Yol Haritası (DEVELOPMENT_ROADMAP.md)](DEVELOPMENT_ROADMAP.md) ve [Katkıda Bulunma Rehberi (CONTRIBUTING.md)](CONTRIBUTING.md) dosyaları üzerinden yürütülür. Lütfen bu belgeleri dikkatlice inceleyin.

### Genel Akış

1.  Yol haritasından bir görev seçin.
2.  Görevi üstlenmek için PR açın.
3.  Yeni bir `feature` veya `fix` dalı oluşturun.
4.  Değişikliklerinizi yapın.
5.  Testleri ve kod kalitesi kontrollerini çalıştırın.
6.  Commit mesajınızı [Conventional Commits](https://www.conventionalcommits.org/) standardına uygun yazın.
7.  Pull Request açın ve inceleme sürecini bekleyin.

---

## 5. 🗄️ Dokümantasyon Yönetimi

- **Güncel Dokümanlar:** Projenin ana dizininde yer alır (`README.md`, `DEVELOPMENT_ROADMAP.md`, vb.).
- **Arşiv:** Artık geçerli olmayan veya güncelliğini yitirmiş tüm dokümanlar `archive/` dizinine taşınır. Lütfen `docs/` dizinindeki belgelere itibar etmeyin, bunlar eski sürümlere aittir.

Yeni bir doküman oluştururken veya mevcut olanı güncellerken, lütfen açık, anlaşılır ve teknik olarak doğru bilgiler verdiğinizden emin olun.
