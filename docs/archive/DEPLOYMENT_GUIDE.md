'''
# Geliştirilmiş İçerik Üretim Sistemi - Kurulum ve Dağıtım Kılavuzu

**Tarih:** 06 Aralık 2025
**Hazırlayan:** Manus AI

## 1. Genel Bakış

Bu kılavuz, Haber Nexus projesine entegre edilen yeni nesil içerik üretim sisteminin kurulumu, yapılandırılması ve dağıtımı için gerekli adımları içermektedir. Bu sistem, RSS beslemelerinden akıllı başlık seçimi, yapay zeka destekli sınıflandırma, dinamik içerik üretimi ve kalite kontrol gibi gelişmiş özellikler sunar.

Sistemin ana bileşenleri şunlardır:

- **Başlık Puanlama Motoru:** RSS'lerden gelen başlıkları kalite metriklerine göre puanlar.
- **AI Sınıflandırma Modülü:** Başlıkları içerik türüne (haber, analiz vb.) göre sınıflandırır.
- **Dinamik İçerik Üretimi:** Her içerik türü için özelleştirilmiş prompt'lar kullanarak Gemini AI ile içerik oluşturur.
- **Kalite Kontrol Sistemi:** Üretilen içeriğin okunabilirlik, SEO ve yapısal kalitesini denetler.
- **İzleme ve Analitik:** Sistemin performansını ve sağlık durumunu izlemek için araçlar sunar.

## 2. Ön Gereksinimler

Sistemin çalışabilmesi için aşağıdaki yazılımların ve servislerin kurulu ve çalışır durumda olması gerekmektedir:

- **Python 3.11+**
- **PostgreSQL 14+**
- **Redis 6+**
- **Docker ve Docker Compose** (Önerilir)
- **Git**

## 3. Kurulum Adımları

### 3.1. Projeyi Klonlama

Projeyi GitHub'dan yerel makinenize klonlayın:

```bash
git clone https://github.com/sata2500/habernexus.git
cd habernexus
```

### 3.2. Python Sanal Ortamı ve Bağımlılıklar

Proje için bir sanal ortam oluşturun ve gerekli Python paketlerini yükleyin:

```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 3.3. Veritabanı Kurulumu

PostgreSQL'de proje için bir veritabanı ve kullanıcı oluşturun:

```sql
CREATE DATABASE habernexus;
CREATE USER habernexus_user WITH PASSWORD 'your_strong_password';
ALTER ROLE habernexus_user SET client_encoding TO 'utf8';
ALTER ROLE habernexus_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE habernexus_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE habernexus TO habernexus_user;
```

### 3.4. Ortam Değişkenleri (.env)

`.env.example` dosyasını kopyalayarak `.env` dosyasını oluşturun ve kendi ayarlarınızla güncelleyin:

```bash
cp .env.example .env
nano .env
```

Özellikle aşağıdaki değişkenleri doğru şekilde ayarladığınızdan emin olun:

```ini
DJANGO_SECRET_KEY=your_super_secret_key
DEBUG=True

DB_ENGINE=django.db.backends.postgresql
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=your_strong_password
DB_HOST=localhost
DB_PORT=5432

CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# Google Gemini API Anahtarı
GOOGLE_GEMINI_API_KEY=your_gemini_api_key
```

### 3.5. Veritabanı Geçişleri (Migrations)

Yeni modelleri veritabanına uygulamak için `migrate` komutunu çalıştırın:

```bash
python manage.py migrate
```

### 3.6. Yönetici (Superuser) Oluşturma

Django admin paneline erişmek için bir yönetici hesabı oluşturun:

```bash
python manage.py createsuperuser
```

## 4. Sistemi Çalıştırma

Sistemin tüm bileşenlerini (Django, Celery Worker, Celery Beat) çalıştırmanız gerekmektedir.

### 4.1. Django Geliştirme Sunucusu

```bash
python manage.py runserver
```

### 4.2. Celery Worker

Asenkron görevleri işlemek için Celery worker'ı ayrı bir terminalde başlatın:

```bash
celery -A habernexus_config worker -l info
```

### 4.3. Celery Beat (Zamanlayıcı)

Periyodik görevleri (RSS tarama, başlık puanlama vb.) tetiklemek için Celery Beat'i ayrı bir terminalde başlatın:

```bash
celery -A habernexus_config beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
```

## 5. Yeni Celery Görevleri ve Zamanlamaları

Yeni sistemle birlikte aşağıdaki periyodik görevler `habernexus_config/celery.py` dosyasında tanımlanmıştır:

| Görev | Zamanlama | Açıklama |
|---|---|---|
| `news.tasks_v2.fetch_rss_feeds_v2` | Her 15 dakikada bir | Aktif RSS kaynaklarını tarar ve yeni başlıkları veritabanına ekler. |
| `news.tasks_v2.score_headlines` | Her saat başında | Son 2 saatte eklenen başlıkları puanlar ve en iyi 10 tanesini sınıflandırmaya gönderir. |

Bu görevler, Celery Beat çalıştığı sürece otomatik olarak tetiklenecektir.

## 6. Yönetim Paneli ve İzleme

Yeni sistemin yönetimi ve izlenmesi Django admin paneli üzerinden gerçekleştirilebilir. `http://127.0.0.1:8000/admin/` adresine giderek aşağıdaki yeni bölümleri inceleyebilirsiniz:

- **Headline Scores:** Taranan tüm başlıkları, puanlarını ve işlenme durumlarını gösterir.
- **Article Classifications:** AI tarafından yapılan sınıflandırma sonuçlarını ve içerik özelliklerini listeler.
- **Content Quality Metrics:** Üretilen her makalenin detaylı kalite analizini sunar.
- **Content Generation Logs:** İçerik üretim sürecinin her aşamasını loglar ve olası hataların takibini kolaylaştırır.

## 7. CI/CD Pipeline

Projenin `.github/workflows/ci.yml` dosyasında tanımlanmış olan CI/CD pipeline'ı, yapılan her `push` ve `pull_request` işleminde otomatik olarak çalışır. Bu pipeline aşağıdaki adımları içerir:

1.  **Test:** Projenin tüm testlerini (unit ve integration) çalıştırır ve kod kapsamını (coverage) ölçer.
2.  **Lint:** Kod kalitesini `flake8`, `black`, `isort` ve `pylint` araçlarıyla denetler.
3.  **Security:** `safety` ve `bandit` araçlarıyla olası güvenlik zafiyetlerini tarar.
4.  **Build:** `main` branch'ine yapılan push işlemlerinde Docker imajı oluşturur.

Bu otomasyon, projenin kalitesini ve güvenliğini sürekli olarak yüksek tutmayı hedefler.
'''
