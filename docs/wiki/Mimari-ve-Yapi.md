## HaberNexus Mimarisi ve Proje Yapısı

Bu doküman, HaberNexus projesinin teknik mimarisini, kullanılan teknolojileri ve klasör yapısını detaylandırmaktadır.

---

### Teknolojiler

| Kategori | Teknoloji | Açıklama |
|---|---|---|
| **Backend** | Python 3.11, Django 5.1 | Ana uygulama çerçevesi. |
| **Frontend** | Tailwind CSS, Django Templates | Modern ve hızlı arayüz geliştirme. |
| **Veritabanı** | PostgreSQL | Güvenilir ve ölçeklenebilir birincil veritabanı. |
| **Asenkron Görevler** | Celery, Redis | Arka plan görevleri (RSS çekme, AI işlemleri) için kuyruk sistemi. |
| **Arama** | Elasticsearch | Gelişmiş ve hızlı metin tabanlı arama. |
| **AI & Makine Öğrenmesi** | Google Gemini, Spacy | İçerik üretimi, özetleme ve doğal dil işleme. |
| **Deployment** | Docker, Caddy, Cloudflare Tunnel | Konteynerleştirme, otomatik HTTPS ve güvenli erişim. |
| **CI/CD** | GitHub Actions | Otomatik test, kod kalitesi kontrolü ve dağıtım. |

---

### Sistem Mimarisi Diyagramı

Aşağıdaki diyagram, HaberNexus'un genel sistem mimarisini göstermektedir:

```mermaid
flowchart TB
    subgraph Internet["🌐 İnternet"]
        User["👤 Kullanıcı"]
        RSSFeeds["📰 RSS Kaynakları"]
    end

    subgraph CloudflareLayer["☁️ Cloudflare"]
        CF["Cloudflare CDN & WAF"]
        Tunnel["Cloudflare Tunnel"]
    end

    subgraph Server["🖥️ Sunucu (Docker)"]
        subgraph ReverseProxy["Reverse Proxy"]
            Caddy["🔒 Caddy\n(Auto HTTPS)"]
        end

        subgraph AppLayer["Uygulama Katmanı"]
            Django["🐍 Django App\n(Gunicorn)"]
            Celery["⚙️ Celery Worker"]
            CeleryBeat["⏰ Celery Beat"]
        end

        subgraph DataLayer["Veri Katmanı"]
            PostgreSQL["🐘 PostgreSQL"]
            Redis["🔴 Redis"]
            Elasticsearch["🔍 Elasticsearch"]
        end

        subgraph AILayer["AI Katmanı"]
            Gemini["🤖 Google Gemini"]
            Imagen["🎨 Google Imagen"]
        end
    end

    User -->|HTTPS| CF
    CF -->|Secure| Tunnel
    Tunnel -->|Internal| Caddy
    Caddy -->|Proxy| Django

    Django -->|ORM| PostgreSQL
    Django -->|Cache/Queue| Redis
    Django -->|Search| Elasticsearch

    Celery -->|Tasks| Redis
    CeleryBeat -->|Schedule| Redis
    Celery -->|Fetch| RSSFeeds
    Celery -->|AI Request| Gemini
    Celery -->|Image Gen| Imagen

    Celery -->|Store| PostgreSQL
```

---

### İstek Akışı Diyagramı

Bir kullanıcı isteğinin sistemde nasıl işlendiğini gösteren akış:

```mermaid
sequenceDiagram
    participant U as 👤 Kullanıcı
    participant CF as ☁️ Cloudflare
    participant C as 🔒 Caddy
    participant D as 🐍 Django
    participant R as 🔴 Redis
    participant P as 🐘 PostgreSQL
    participant E as 🔍 Elasticsearch

    U->>CF: HTTPS İsteği
    CF->>C: Tunnel üzerinden
    C->>D: Proxy (8000)
    
    alt Önbellekte Var
        D->>R: Cache Kontrolü
        R-->>D: Önbellek Verisi
        D-->>C: JSON/HTML Yanıt
    else Önbellekte Yok
        D->>P: Veritabanı Sorgusu
        P-->>D: Veri
        D->>R: Önbelleğe Al
        D-->>C: JSON/HTML Yanıt
    end
    
    C-->>CF: Yanıt
    CF-->>U: Sıkıştırılmış Yanıt
```

---

### Haber İşleme Pipeline'ı

RSS kaynaklarından haberlerin nasıl işlendiğini gösteren akış:

```mermaid
flowchart LR
    subgraph Input["📥 Girdi"]
        RSS["RSS Feeds"]
    end

    subgraph Processing["⚙️ İşleme"]
        Fetch["1️⃣ RSS Çekme\n(Celery)"]
        Parse["2️⃣ İçerik Ayrıştırma"]
        Duplicate["3️⃣ Tekrar Kontrolü"]
        AI["4️⃣ AI İşleme\n(Gemini)"]
        Quality["5️⃣ Kalite Kontrolü"]
    end

    subgraph Output["📤 Çıktı"]
        DB["PostgreSQL"]
        Index["Elasticsearch\nIndex"]
        Publish["Yayınla"]
    end

    RSS --> Fetch
    Fetch --> Parse
    Parse --> Duplicate
    Duplicate -->|Yeni| AI
    Duplicate -->|Tekrar| Discard["🗑️ Atla"]
    AI --> Quality
    Quality -->|Geçti| DB
    Quality -->|Başarısız| Review["📝 İnceleme"]
    DB --> Index
    Index --> Publish
```

---

### Veritabanı Şeması (ER Diyagramı)

Ana veritabanı tablolarının ilişkilerini gösteren diyagram:

```mermaid
erDiagram
    AUTHOR ||--o{ ARTICLE : writes
    RSS_SOURCE ||--o{ ARTICLE : provides
    ARTICLE ||--o| CONTENT_QUALITY : has

    AUTHOR {
        int id PK
        string name
        string slug UK
        text bio
        string avatar
        string expertise
        boolean is_active
        datetime created_at
    }

    RSS_SOURCE {
        int id PK
        string name
        string url UK
        string category
        int frequency_minutes
        boolean is_active
        datetime last_checked
    }

    ARTICLE {
        int id PK
        string title
        string slug UK
        text content
        text excerpt
        string featured_image
        string category
        string tags
        int author_id FK
        int rss_source_id FK
        string status
        boolean is_ai_generated
        int views_count
        datetime published_at
    }

    CONTENT_QUALITY {
        int id PK
        int article_id FK
        float readability_score
        int word_count
        int sentence_count
        float keyword_density
        float overall_quality_score
    }
```

---

### Docker Servis Yapısı

Docker Compose ile çalışan servislerin yapısı:

```mermaid
graph TB
    subgraph DockerNetwork["🐳 habernexus_network"]
        subgraph Frontend["Frontend Tier"]
            caddy["caddy\n:80, :443"]
            cloudflared["cloudflared"]
        end

        subgraph Application["Application Tier"]
            app["app (Django)\n:8000"]
            celery["celery"]
            celery_beat["celery-beat"]
            flower["flower\n:5555"]
        end

        subgraph Data["Data Tier"]
            postgres["postgres\n:5432"]
            redis["redis\n:6379"]
            elasticsearch["elasticsearch\n:9200"]
        end

        subgraph Monitoring["Monitoring"]
            prometheus["prometheus\n:9090"]
            grafana["grafana\n:3000"]
        end
    end

    cloudflared --> caddy
    caddy --> app
    app --> postgres
    app --> redis
    app --> elasticsearch
    celery --> redis
    celery --> postgres
    celery_beat --> redis
    flower --> celery
    prometheus --> app
    grafana --> prometheus
```

---

### Proje Klasör Yapısı

Proje, Django'nun "apps" konseptine uygun olarak modüler bir şekilde düzenlenmiştir.

```
/habernexus
├── api/                  # REST API ile ilgili tüm kodlar (views, serializers, urls)
├── authors/              # Yazar yönetimi uygulaması (models, admin)
├── core/                 # Projenin temel bileşenleri (middleware, management commands, settings)
├── habernexus_config/    # Projenin ana yapılandırma dosyaları (settings.py, urls.py, celery.py)
├── news/                 # Haber yönetimi uygulaması (models, views, tasks, admin)
├── static/               # Statik dosyalar (CSS, JS, resimler)
├── templates/            # Django HTML şablonları
├── tests/                # Otomatik testler
├── .github/              # GitHub Actions (CI/CD) ve issue şablonları
├── caddy/                # Caddy yapılandırma dosyaları
├── cloudflared/          # Cloudflare Tunnel yapılandırma dosyaları
├── docker-compose.yml    # Geliştirme ortamı için Docker Compose dosyası
├── docker-compose.prod.yml # Production ortamı için Docker Compose dosyası
├── Dockerfile            # Django uygulamasının Docker imajını oluşturmak için
├── manage.py             # Django yönetim betiği
├── requirements.txt      # Python bağımlılıkları
└── README.md             # Proje ana sayfası
```

### Uygulama (App) Açıklamaları

-   **`api`**: Dış dünyaya sunulan REST API'nin mantığını içerir. `views.py` içinde endpoint'ler, `serializers.py` içinde veri modelleri bulunur.
-   **`authors`**: Yazarları ve onlarla ilgili bilgileri yöneten Django app'i.
-   **`core`**: Projenin genelinde kullanılan yardımcı fonksiyonlar, özel middleware katmanları, yönetim komutları ve temel modeller gibi çapraz kesen bileşenleri barındırır.
-   **`habernexus_config`**: Django projesinin ana yapılandırma merkezidir. `settings.py` ile tüm ayarlar, `urls.py` ile ana URL yönlendirmeleri ve `celery.py` ile asenkron görev yapılandırması burada yer alır.
-   **`news`**: Projenin kalbidir. Haber (`Article`), RSS Kaynağı (`RssSource`) gibi ana modelleri, haberlerin listelendiği ve detaylarının gösterildiği `views.py`'ı ve en önemlisi, RSS kaynaklarını tarayan, AI ile içerik üreten `tasks.py` dosyasını içerir.
