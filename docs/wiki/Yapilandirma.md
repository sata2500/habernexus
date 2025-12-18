## HaberNexus Yapılandırma Rehberi

Bu rehber, HaberNexus uygulamasının temel yapılandırma ayarlarını ve bu ayarların nasıl yönetileceğini açıklar. Yapılandırma, temel olarak çevre değişkenleri (environment variables) aracılığıyla yönetilir ve `.env` dosyası içinde saklanır.

---

### `.env` Dosyası

Projenin ana dizininde bulunan `.env` dosyası, tüm hassas bilgileri ve ortama özgü ayarları içerir. Bu dosya **kesinlikle Git repolarına dahil edilmemelidir** (`.gitignore` dosyasında listelenmiştir).

Kurulum sırasında `install.sh` betiği veya manuel olarak `.env.example` dosyasını kopyalayarak kendi `.env` dosyanızı oluşturmanız gerekir.

```bash
cp .env.example .env
```

#### Temel Yapılandırma Değişkenleri

| Değişken | Açıklama | Örnek Değer |
|---|---|---|
| `SECRET_KEY` | Django uygulamasının güvenlik anahtarı. **Çok gizlidir.** | `django-insecure-!@#...` |
| `DEBUG` | Hata ayıklama modunu açar veya kapatır. **Production'da `False` olmalıdır.** | `False` |
| `ALLOWED_HOSTS` | Uygulamanın hizmet vereceği domain adresleri. | `habernexus.com,www.habernexus.com` |
| `DOMAIN_NAME` | Projenin ana domain adı. | `habernexus.com` |
| `ADMIN_EMAIL` | Yönetici e-posta adresi. | `salihtanriseven25@gmail.com` |

#### Veritabanı Yapılandırması (PostgreSQL)

| Değişken | Açıklama | Örnek Değer |
|---|---|---|
| `DB_ENGINE` | Django veritabanı motoru. | `django.db.backends.postgresql` |
| `DB_NAME` | Veritabanı adı. | `habernexus` |
| `DB_USER` | Veritabanı kullanıcısı. | `habernexus_user` |
| `DB_PASSWORD` | Veritabanı şifresi. | `GucluBirSifre123` |
| `DB_HOST` | Veritabanı sunucusunun adresi. | `postgres` (Docker içinde) veya `localhost` |
| `DB_PORT` | Veritabanı portu. | `5432` |

#### Redis Yapılandırması

| Değişken | Açıklama | Örnek Değer |
|---|---|---|
| `REDIS_HOST` | Redis sunucusunun adresi. | `redis` (Docker içinde) veya `localhost` |
| `REDIS_PORT` | Redis portu. | `6379` |

#### Cloudflare Yapılandırması

| Değişken | Açıklama | Örnek Değer |
|---|---|---|
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token'ı (DNS yönetimi için). | `...` |
| `CLOUDFLARE_TUNNEL_TOKEN` | Cloudflare Tunnel token'ı (güvenli bağlantı için). | `...` |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare hesap ID'niz. | `...` |
| `CLOUDFLARE_ZONE_ID` | Domain'inizin bulunduğu Cloudflare Zone ID'si. | `...` |

#### AI ve API Anahtarları

Bu ayarlar, Django admin panelindeki **Çekirdek > API Ayarları** bölümünden dinamik olarak yönetilebilir, ancak `.env` dosyasına da eklenebilir.

| Değişken | Açıklama | Örnek Değer |
|---|---|---|
| `GOOGLE_GEMINI_API_KEY` | Google Gemini AI içerik üretimi için API anahtarı. | `AIza...` |
| `GOOGLE_IMAGEN_API_KEY` | Google Imagen görsel üretimi için API anahtarı. | `AIza...` |

---

### Django Admin Panelinden Yapılandırma

Bazı operasyonel ayarlar, kod değişikliği yapmadan doğrudan yönetici panelinden değiştirilebilir. Bu, esneklik sağlar ve yeniden dağıtım (re-deployment) gerektirmez.

**Yönetim Paneli Adresi:** `/admin/`

#### API Ayarları

-   **Konum:** `Çekirdek > API Ayarları` (`/admin/core/settings/`)
-   **Yönetilebilen Ayarlar:**
    -   **Google Gemini API Anahtarı:** AI metin üretimi için kullanılır.
    -   **Google Imagen API Anahtarı:** AI görsel üretimi için kullanılır.
    -   **RSS Tarama Sıklığı:** RSS kaynaklarının kaç dakikada bir taranacağını belirler.
    -   **İçerik Üretim Sıklığı:** Yapay zekanın ne sıklıkla yeni içerik üreteceğini belirler.

Bu panel üzerinden yapılan değişiklikler veritabanına kaydedilir ve Celery Beat tarafından çalıştırılan periyodik görevlerin zamanlamasını anında günceller.

#### RSS Kaynakları Yönetimi

-   **Konum:** `Haberler > RSS Kaynakları`
-   **Yönetilebilen Ayarlar:**
    -   Yeni RSS kaynakları ekleyebilir, mevcutları düzenleyebilir veya silebilirsiniz.
    -   Her bir kaynağın `kategori`, `tarama sıklığı` ve `aktif olup olmadığı` gibi özelliklerini yönetebilirsiniz.
