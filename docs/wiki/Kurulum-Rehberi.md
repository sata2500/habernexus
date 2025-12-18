## HaberNexus Kurulum Rehberi

Bu rehber, HaberNexus platformunu farklı ortamlarda kurmanız için gerekli adımları içerir.

---

### ⚡ Tek Komutla Kurulum (Önerilen Yöntem)

En hızlı ve en kolay kurulum yöntemi, `get-habernexus.sh` betiğini kullanmaktır. Bu betik, gerekli tüm bağımlılıkları (Docker, Caddy, Cloudflare Tunnel) kurar, sistemi yapılandırır ve uygulamayı başlatır.

**Gereksinimler:**
- Ubuntu 22.04 veya 24.04
- `sudo` yetkilerine sahip bir kullanıcı
- Cloudflare hesabınız ve bir domain

**Kurulum Adımı:**

```bash
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/get-habernexus.sh | sudo bash
```

Betik çalıştırıldığında sizden domain, e-posta adresi ve Cloudflare API token gibi bilgileri girmenizi isteyecektir.

#### Gelişmiş Kurulum Seçenekleri

```bash
# Domain ve e-posta adresini parametre olarak vererek kurulum
sudo bash get-habernexus.sh -- --domain habernexus.com --email salihtanriseven25@gmail.com

# Hızlı kurulum (interaktif girdi olmadan, varsayılan değerlerle)
sudo bash get-habernexus.sh -- --quick

# Mevcut kurulumu tamamen sıfırlayarak yeniden kurma
sudo bash get-habernexus.sh -- --reset
```

### 🐳 Docker ile Kurulum

Projeyi Docker Compose ile production veya development ortamında çalıştırabilirsiniz.

**Gereksinimler:**
- Docker ve Docker Compose

**Adımlar:**

1.  **Projeyi Klonlayın:**
    ```bash
    git clone https://github.com/sata2500/habernexus.git
    cd habernexus
    ```

2.  **Yapılandırma Dosyasını Oluşturun:**
    `.env.example` dosyasını kopyalayarak `.env` adında yeni bir dosya oluşturun ve içindeki değerleri kendi yapılandırmanıza göre düzenleyin.
    ```bash
    cp .env.example .env
    ```

3.  **Uygulamayı Başlatın:**

    -   **Production Ortamı İçin:**
        Bu komut, Caddy, Cloudflare Tunnel ve Gunicorn ile optimize edilmiş bir şekilde uygulamayı başlatır.
        ```bash
        docker compose -f docker-compose.prod.yml up -d
        ```

    -   **Development Ortamı İçin:**
        Bu komut, Django'nun dahili geliştirme sunucusu ile uygulamayı başlatır ve kod değişikliklerini anında yansıtır.
        ```bash
        docker compose up -d
        ```

4.  **Logları İzleme:**
    ```bash
    docker compose logs -f
    ```

### 💻 Yerel Geliştirme Ortamı Kurulumu

Projeyi Docker olmadan, doğrudan kendi makinenizde geliştirmek için aşağıdaki adımları izleyebilirsiniz.

**Gereksinimler:**
- Python 3.11+
- PostgreSQL (veya SQLite)
- Redis

**Adımlar:**

1.  **Projeyi Klonlayın:**
    ```bash
    git clone https://github.com/sata2500/habernexus.git
    cd habernexus
    ```

2.  **Sanal Ortam (Virtual Environment) Oluşturun:**
    ```bash
    python -m venv venv
    source venv/bin/activate  # Linux/macOS
    # venv\Scripts\activate  # Windows
    ```

3.  **Bağımlılıkları Kurun:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Veritabanı Kurulumu ve Migration:**
    `.env` dosyanızda veritabanı bağlantı bilgilerinizi ayarladıktan sonra veritabanını oluşturun.
    ```bash
    python manage.py migrate
    ```

5.  **Geliştirme Sunucusunu Başlatın:**
    ```bash
    python manage.py runserver
    ```
    Uygulama artık `http://127.0.0.1:8000` adresinde çalışıyor olacaktır.

6.  **Celery Worker'ı Başlatın (Ayrı bir terminalde):**
    Arka plan görevlerinin (RSS çekme, içerik üretme vb.) çalışması için Celery worker'ı başlatmanız gerekir.
    ```bash
    celery -A habernexus_config worker -l info
    ```

7.  **Celery Beat'i Başlatın (Ayrı bir terminalde):**
    Periyodik görevlerin zamanlanması için Celery Beat'i başlatın.
    ```bash
    celery -A habernexus_config beat -l info
    ```
