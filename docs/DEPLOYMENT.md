# Haber Nexus - Deployment Rehberi

Bu rehber, Haber Nexus uygulamasını production ortamında Ubuntu sunucusuna dağıtmak için adım adım talimatlar içerir.

## Sistem Gereksinimleri

- **OS**: Ubuntu 20.04 LTS veya üzeri
- **Python**: 3.9+
- **PostgreSQL**: 12+
- **Redis**: 6+
- **Nginx**: 1.18+
- **Node.js**: 14+ (Tailwind CSS için)

## 1. Sunucu Hazırlığı

### 1.1 Sistem Güncellemesi

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y build-essential python3-dev python3-pip python3-venv
sudo apt install -y postgresql postgresql-contrib
sudo apt install -y redis-server
sudo apt install -y nginx
sudo apt install -y git curl wget
```

### 1.2 Kullanıcı Oluşturma

```bash
sudo useradd -m -s /bin/bash www-data
sudo usermod -aG sudo www-data
```

### 1.3 Dizin Yapısı

```bash
sudo mkdir -p /var/www/habernexus
sudo mkdir -p /var/log/habernexus
sudo mkdir -p /var/run/habernexus
sudo chown -R www-data:www-data /var/www/habernexus
sudo chown -R www-data:www-data /var/log/habernexus
sudo chown -R www-data:www-data /var/run/habernexus
```

## 2. Veritabanı Kurulumu

### 2.1 PostgreSQL Yapılandırması

```bash
sudo -u postgres psql <<EOF
CREATE USER habernexus WITH PASSWORD 'güçlü_şifre_buraya';
CREATE DATABASE habernexus OWNER habernexus;
ALTER ROLE habernexus SET client_encoding TO 'utf8';
ALTER ROLE habernexus SET default_transaction_isolation TO 'read committed';
ALTER ROLE habernexus SET default_transaction_deferrable TO on;
ALTER ROLE habernexus SET default_transaction_level TO 'read committed';
GRANT ALL PRIVILEGES ON DATABASE habernexus TO habernexus;
\q
EOF
```

### 2.2 Redis Yapılandırması

```bash
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

## 3. Uygulama Kurulumu

### 3.1 Proje Klonlama

```bash
cd /var/www
sudo git clone https://github.com/sata2500/habernexus.git
cd habernexus
sudo chown -R www-data:www-data .
```

### 3.2 Virtual Environment Oluşturma

```bash
sudo -u www-data python3 -m venv venv
sudo -u www-data venv/bin/pip install --upgrade pip setuptools wheel
sudo -u www-data venv/bin/pip install -r requirements.txt
sudo -u www-data venv/bin/pip install gunicorn
```

### 3.3 Ortam Değişkenleri

```bash
sudo nano /var/www/habernexus/.env
```

Aşağıdaki içeriği ekleyin:

```env
# Django
DEBUG=False
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=habernexus.com,www.habernexus.com

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=habernexus
DB_USER=habernexus
DB_PASSWORD=güçlü_şifre_buraya
DB_HOST=localhost
DB_PORT=5432

# Redis
REDIS_URL=redis://127.0.0.1:6379/1
CELERY_BROKER_URL=redis://127.0.0.1:6379/0
CELERY_RESULT_BACKEND=redis://127.0.0.1:6379/0

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password

# Google AI APIs
GOOGLE_GEMINI_API_KEY=your-api-key-here
GOOGLE_IMAGEN_API_KEY=your-api-key-here

# Gunicorn
GUNICORN_BIND=127.0.0.1:8000
GUNICORN_WORKERS=4
```

### 3.4 Django Migrasyonları

```bash
sudo -u www-data venv/bin/python manage.py migrate
sudo -u www-data venv/bin/python manage.py collectstatic --noinput
sudo -u www-data venv/bin/python manage.py createsuperuser
```

## 4. Systemd Servisleri

### 4.1 Django/Gunicorn Servisi

```bash
sudo cp /var/www/habernexus/config/habernexus.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable habernexus
sudo systemctl start habernexus
sudo systemctl status habernexus
```

### 4.2 Celery Worker Servisi

```bash
sudo cp /var/www/habernexus/config/habernexus-celery.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable habernexus-celery
sudo systemctl start habernexus-celery
sudo systemctl status habernexus-celery
```

### 4.3 Celery Beat Servisi

```bash
sudo cp /var/www/habernexus/config/habernexus-celery-beat.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable habernexus-celery-beat
sudo systemctl start habernexus-celery-beat
sudo systemctl status habernexus-celery-beat
```

## 5. Nginx Yapılandırması

### 5.1 Nginx Sitesini Aktifleştir

```bash
sudo cp /var/www/habernexus/config/nginx_production.conf /etc/nginx/sites-available/habernexus
sudo ln -s /etc/nginx/sites-available/habernexus /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

## 6. SSL Sertifikası (Let's Encrypt)

### 6.1 Certbot Kurulumu

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### 6.2 Sertifika Oluşturma

```bash
sudo certbot certonly --webroot -w /var/www/certbot -d habernexus.com -d www.habernexus.com
```

### 6.3 Otomatik Yenileme

```bash
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

## 7. Monitoring ve Logging

### 7.1 Log Dosyalarını İzle

```bash
# Django logs
sudo tail -f /var/log/habernexus/django.log

# Celery logs
sudo tail -f /var/log/habernexus/celery-worker.log
sudo tail -f /var/log/habernexus/celery-beat.log

# Nginx logs
sudo tail -f /var/log/nginx/habernexus_access.log
sudo tail -f /var/log/nginx/habernexus_error.log
```

### 7.2 Systemd Journal

```bash
# Django
sudo journalctl -u habernexus -f

# Celery Worker
sudo journalctl -u habernexus-celery -f

# Celery Beat
sudo journalctl -u habernexus-celery-beat -f
```

## 8. Yedekleme

### 8.1 Veritabanı Yedeklemesi

```bash
sudo -u postgres pg_dump habernexus > /var/backups/habernexus_$(date +%Y%m%d_%H%M%S).sql
```

### 8.2 Otomatik Yedekleme (Cron)

```bash
sudo crontab -e
```

Aşağıdaki satırı ekleyin:

```cron
# Her gün saat 02:00'de veritabanı yedekle
0 2 * * * sudo -u postgres pg_dump habernexus > /var/backups/habernexus_$(date +\%Y\%m\%d).sql

# Her gün saat 03:00'te eski yedekleri sil (7 günden eski)
0 3 * * * find /var/backups -name "habernexus_*.sql" -mtime +7 -delete
```

## 9. Performans Optimizasyonları

### 9.1 PostgreSQL Tuning

```bash
sudo nano /etc/postgresql/12/main/postgresql.conf
```

Aşağıdaki parametreleri ayarla:

```
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
```

### 9.2 Redis Optimizasyonu

```bash
sudo nano /etc/redis/redis.conf
```

Aşağıdaki parametreleri ayarla:

```
maxmemory 512mb
maxmemory-policy allkeys-lru
```

## 10. Güvenlik

### 10.1 Firewall Yapılandırması

```bash
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 10.2 Fail2Ban Kurulumu

```bash
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## 11. Monitoring

### 11.1 Sağlık Kontrolü

```bash
curl https://habernexus.com/health/
```

### 11.2 Admin Paneli

```
https://habernexus.com/admin/
```

## Sorun Giderme

### Django Servisi Başlamıyor

```bash
sudo journalctl -u habernexus -n 50
sudo systemctl restart habernexus
```

### Celery Görevleri Çalışmıyor

```bash
sudo journalctl -u habernexus-celery -n 50
sudo systemctl restart habernexus-celery
```

### Nginx Hataları

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Güncelleme

Yeni sürüme güncellemek için:

```bash
cd /var/www/habernexus
sudo -u www-data git pull origin main
sudo -u www-data venv/bin/pip install -r requirements.txt
sudo -u www-data venv/bin/python manage.py migrate
sudo -u www-data venv/bin/python manage.py collectstatic --noinput
sudo systemctl restart habernexus
```

## İletişim ve Destek

Sorularınız veya sorunlarınız için lütfen GitHub issues sayfasını ziyaret edin:
https://github.com/sata2500/habernexus/issues
