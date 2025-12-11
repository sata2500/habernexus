# Haber Nexus - Kurulum Rehberi

Bu rehber, Haber Nexus projesini farklı ortamlarda (Docker, yerel geliştirme, production) nasıl kuracağınızı detaylı olarak açıklar.

---

## İçindekiler

1. [Docker ile Kurulum (Önerilen)](#docker-ile-kurulum-önerilen)
2. [Yerel Geliştirme Ortamı Kurulumu](#yerel-geliştirme-ortamı-kurulumu)
3. [Production Ortamı Kurulumu](#production-ortamı-kurulumu)
4. [Yapılandırma](#yapılandırma)
5. [Sorun Giderme](#sorun-giderme)

---

## Docker ile Kurulum (Önerilen)

Bu yöntem, tüm bağımlılıkları izole konteynerlerde çalıştırdığı için en kolay ve en güvenilir olanıdır.

### Gereksinimler

- Docker ve Docker Compose
- Git

### Adımlar

1.  **Projeyi klonlayın:**
    ```bash
    git clone https://github.com/sata2500/habernexus.git
    cd habernexus
    ```

2.  **`.env` dosyasını oluşturun:**
    ```bash
    cp .env.example .env
    ```

3.  **`.env` dosyasını düzenleyin:**
    `SECRET_KEY` ve `GOOGLE_API_KEY` gibi gerekli alanları doldurun.

4.  **Konteynerleri başlatın:**
    ```bash
    docker-compose up -d --build
    ```

5.  **Veritabanını migrate edin:**
    ```bash
    docker-compose exec app python manage.py migrate
    ```

6.  **Yönetici oluşturun:**
    ```bash
    docker-compose exec app python manage.py createsuperuser
    ```

7.  **Tarayıcıdan erişin:**
    - Ana Sayfa: `http://localhost`
    - Admin Paneli: `http://localhost/admin/`

---

## Yerel Geliştirme Ortamı Kurulumu

Bu yöntem, Docker kullanmadan doğrudan kendi makinenizde geliştirme yapmak isteyenler içindir.

### Gereksinimler

- Python 3.11+
- PostgreSQL 14+
- Redis 6+
- Git

### Adımlar

1.  **PostgreSQL ve Redis Kurulumu:**
    İşletim sisteminize uygun şekilde PostgreSQL ve Redis sunucularını kurun ve çalıştırın.

2.  **Veritabanı Oluşturma:**
    `habernexus` adında bir veritabanı ve bu veritabanına erişim yetkisi olan bir kullanıcı oluşturun.

3.  **Projeyi klonlayın ve sanal ortam oluşturun:**
    ```bash
    git clone https://github.com/sata2500/habernexus.git
    cd habernexus
    python3 -m venv venv
    source venv/bin/activate
    ```

4.  **Bağımlılıkları yükleyin:**
    ```bash
    pip install -r requirements.txt
    ```

5.  **`.env` dosyasını yapılandırın:**
    `.env.example` dosyasını kopyalayın ve veritabanı bağlantı bilgilerinizi (`DB_HOST=localhost` vb.) ve diğer ayarları güncelleyin.

6.  **Veritabanını migrate edin ve yönetici oluşturun:**
    ```bash
    python manage.py migrate
    python manage.py createsuperuser
    ```

7.  **Celery ve Django sunucusunu başlatın:**
    İki ayrı terminal açın:

    - **Terminal 1 (Celery):**
      ```bash
      celery -A habernexus_config worker -l info
      ```
    - **Terminal 2 (Django):**
      ```bash
      python manage.py runserver
      ```

8.  **Tarayıcıdan erişin:** `http://127.0.0.1:8000`

---

## Production Ortamı Kurulumu

Production ortamı için **Docker** kullanılması şiddetle tavsiye edilir. Aşağıdaki adımlar, production için optimize edilmiş Docker Compose yapılandırmasını kullanır.

### Gereksinimler

- Docker ve Docker Compose yüklü bir sunucu (Ubuntu 22.04 önerilir)
- Bir alan adı (domain)
- SSL sertifikası (Let\'s Encrypt önerilir)

### Adımlar

1.  **Sunucuya bağlanın ve projeyi klonlayın.**

2.  **`docker-compose.prod.yml` dosyasını kullanın:**
    Bu dosya, Gunicorn, Nginx ve production için optimize edilmiş diğer ayarları içerir.

3.  **`.env` dosyasını production için yapılandırın:**
    - `DEBUG=False` olarak ayarlayın.
    - `ALLOWED_HOSTS` değişkenine alan adınızı ekleyin.
    - Veritabanı ve diğer gizli bilgileri güvenli bir şekilde ayarlayın.

4.  **Nginx yapılandırmasını düzenleyin:**
    `config/nginx.conf` dosyasını açın ve `server_name` direktifini kendi alan adınızla değiştirin. SSL sertifikası ayarlarını yapın.

5.  **Production konteynerlerini başlatın:**
    ```bash
    docker-compose -f docker-compose.prod.yml up -d --build
    ```

6.  **Statik dosyaları toplayın:**
    ```bash
    docker-compose -f docker-compose.prod.yml exec app python manage.py collectstatic --noinput
    ```

7.  **DNS ayarlarınızı yapın:**
    Alan adınızın A kaydını sunucunuzun IP adresine yönlendirin.

Detaylı adımlar ve güvenlik önerileri için **[Dağıtım Rehberi](DEPLOYMENT.md)**'ne bakın.

---

## Yapılandırma

Tüm yapılandırma seçenekleri ve açıklamaları için **[Yapılandırma Rehberi](CONFIGURATION.md)**'ne bakın.

---

## Sorun Giderme

Kurulum sırasında karşılaşılan yaygın sorunlar ve çözümleri için **[Sorun Giderme Rehberi](TROUBLESHOOTING.md)**'ne bakın.
