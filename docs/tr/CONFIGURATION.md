# Haber Nexus - Yapılandırma Rehberi

Bu rehber, Haber Nexus projesinin tüm yapılandırma seçeneklerini ve ortam değişkenlerini detaylı olarak açıklar.

---

## `.env` Dosyası

Projenin tüm yapılandırması, ana dizinde bulunan `.env` dosyası üzerinden yönetilir. `.env.example` dosyasını kopyalayarak kendi yapılandırmanızı oluşturmalısınız.

### Genel Ayarlar

| Değişken | Açıklama | Örnek Değer |
|---|---|---|
| `SECRET_KEY` | Django uygulamasının gizli anahtarı. **Mutlaka değiştirilmelidir.** | `django-insecure-your-secret-key` |
| `DEBUG` | Hata ayıklama modunu açar/kapatır. Production için `False` olmalıdır. | `True` veya `False` |
| `ALLOWED_HOSTS` | Uygulamanın hizmet vereceği alan adları (virgülle ayrılmış). | `localhost,127.0.0.1,habernexus.com` |

### Veritabanı Ayarları

| Değişken | Açıklama | Örnek Değer |
|---|---|---|
| `DB_ENGINE` | Veritabanı motoru. | `django.db.backends.postgresql` |
| `DB_NAME` | Veritabanı adı. | `habernexus` |
| `DB_USER` | Veritabanı kullanıcısı. | `habernexus` |
| `DB_PASSWORD` | Veritabanı şifresi. | `habernexus` |
| `DB_HOST` | Veritabanı sunucusunun adresi. | `db` (Docker için) veya `localhost` |
| `DB_PORT` | Veritabanı portu. | `5432` |

### Redis Ayarları

| Değişken | Açıklama | Örnek Değer |
|---|---|---|
| `REDIS_HOST` | Redis sunucusunun adresi. | `redis` (Docker için) veya `localhost` |
| `REDIS_PORT` | Redis portu. | `6379` |

### Celery Ayarları

| Değişken | Açıklama | Örnek Değer |
|---|---|---|
| `CELERY_BROKER_URL` | Celery\nin görev kuyruğu için kullanacağı Redis URL\si. | `redis://redis:6379/0` |
| `CELERY_RESULT_BACKEND` | Celery\nin görev sonuçlarını saklayacağı Redis URL\si. | `redis://redis:6379/0` |

### Google Gemini AI Ayarları

| Değişken | Açıklama | Örnek Değer |
|---|---|---|
| `GOOGLE_API_KEY` | Google Gemini API anahtarınız. | `your-google-api-key` |
| `GEMINI_MODEL` | Kullanılacak AI modeli. | `gemini-2.5-flash` |

### Email Ayarları (İsteğe Bağlı)

Django\nun hata raporlarını e-posta ile göndermesi için kullanılır.

| Değişken | Açıklama | Örnek Değer |
|---|---|---|
| `EMAIL_BACKEND` | E-posta gönderim backend\i. | `django.core.mail.backends.smtp.EmailBackend` |
| `EMAIL_HOST` | SMTP sunucusu. | `smtp.gmail.com` |
| `EMAIL_PORT` | SMTP portu. | `587` |
| `EMAIL_USE_TLS` | TLS kullanılacak mı? | `True` |
| `EMAIL_HOST_USER` | SMTP kullanıcı adı. | `your-email@gmail.com` |
| `EMAIL_HOST_PASSWORD` | SMTP şifresi. | `your-email-password` |

---

## Django Ayarları (`settings.py`)

Projenin temel Django ayarları `habernexus_config/settings.py` dosyasında bulunur. Bu dosya, `.env` dosyasındaki değişkenleri okuyarak yapılandırmayı tamamlar. Genellikle bu dosyayı doğrudan düzenlemeniz gerekmez.

---

## Celery Zamanlanmış Görevler (`celery.py`)

Periyodik olarak çalışacak görevler `habernexus_config/celery.py` dosyasındaki `beat_schedule` sözlüğünde tanımlanır.

```python
app.conf.beat_schedule = {
    # Her 15 dakikada bir RSS kaynaklarını tara
    \"fetch-rss-feeds\": {
        \"task\": \"news.tasks.fetch_rss_feeds\",
        \"schedule\": crontab(minute=\"/15\"),
    },
    # Her Pazartesi 02:00\de eski logları temizle
    \"cleanup-old-logs\": {
        \"task\": \"core.tasks.cleanup_old_logs\",
        \"schedule\": crontab(minute=0, hour=2, day_of_week=\"monday\"),
    },
}
```

Buradaki `crontab` ifadelerini değiştirerek görevlerin çalışma sıklığını ayarlayabilirsiniz.
