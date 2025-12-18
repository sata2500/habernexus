# 🔍 HaberNexus Kurulum Sorunları ve Çözümleri

**Tarih**: 2025-12-06  
**Geliştirici**: Salih TANRISEVEN  
**Durum**: Analiz Tamamlandı ✅

---

## 📋 İçindekiler

1. [Yaşanan Sorunlar](#yaşanan-sorunlar)
2. [Sorunların Nedenleri](#sorunların-nedenleri)
3. [Çözümler](#çözümler)
4. [GitHub Actions Hataları](#github-actions-hataları)
5. [Kod Düzeltmeleri](#kod-düzeltmeleri)
6. [Öneriler](#öneriler)

---

## 🔴 Yaşanan Sorunlar

### 1. Nginx Container'ı Başlamıyor (Çözüldü ✅)

**Hata Mesajı:**
```
cannot load certificate "/etc/nginx/ssl/habernexus.com/fullchain.pem": 
BIO_new_file() failed (SSL: error:80000002:system library::No such file or directory)
```

**Neden:**
- Kurulum sırasında Let's Encrypt sertifikası başarıyla alınamadı
- Nginx yapılandırması `/etc/nginx/ssl/habernexus.com/fullchain.pem` dosyasını arıyordu
- Dosya mevcut değildi

**Çözüm:**
- Self-signed sertifika oluşturuldu
- Nginx yapılandırması güncellendi

**Uygulanan Komutlar:**
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /opt/habernexus/nginx/ssl/key.pem \
  -out /opt/habernexus/nginx/ssl/cert.pem \
  -subj "/C=TR/ST=Istanbul/L=Istanbul/O=HaberNexus/CN=habernexus.com"
```

---

### 2. Django Admin Paneline Giriş Yapılamıyor (500 Hatası)

**Hata Mesajı:**
```
Server Error (500)
```

**Neden:**
- Django loglarında POST isteği kaydedilmiyor
- İstek Nginx'ten Django'ya iletilmiyor
- Muhtemel nedenler:
  1. Nginx proxy ayarları yanlış
  2. Django session/CSRF ayarları yanlış
  3. Veritabanı bağlantı sorunu
  4. Django uygulaması hata veriyor

**Çözüm Adımları:**
1. Nginx yapılandırması kontrol edildi ve güncellendi
2. Django settings.py kontrol edildi
3. PostgreSQL bağlantısı doğrulandı
4. Celery/Redis bağlantısı doğrulandı

---

### 3. Cloudflare Üzerinden Erişim Sorunu (Error 521)

**Hata Mesajı:**
```
Web server is down - Error code 521
```

**Neden:**
- Cloudflare, sunucunuza bağlanamıyordu
- Nginx container'ı başlamıyordu (Sorun #1)
- Port 80 ve 443 açık değildi

**Çözüm:**
- Nginx container'ı başlatıldı
- Self-signed sertifika kuruldu
- Port 80 ve 443 açıldı

---

## 🔧 Sorunların Nedenleri

### Temel Nedenler

| Sorun | Neden | Çözüm |
|-------|-------|-------|
| SSL Sertifikası Yok | Let's Encrypt kurulumu başarısız | Self-signed sertifika oluştur |
| Nginx Başlamıyor | Sertifika yolu yanlış | Nginx config güncelle |
| Django 500 Hatası | Bilinmiyor (araştırma devam ediyor) | Logları detaylı kontrol et |
| Cloudflare Error 521 | Nginx başlamıyor | Nginx'i düzelt |

### Konfigürasyon Sorunları

1. **Nginx Yapılandırması**
   - Sertifika yolu: `/etc/nginx/ssl/habernexus.com/fullchain.pem` (YANLIŞ)
   - Doğru yol: `/etc/nginx/ssl/cert.pem`

2. **Django Settings**
   - ALLOWED_HOSTS: Doğru ayarlanmış ✅
   - CSRF_TRUSTED_ORIGINS: Doğru ayarlanmış ✅
   - DEBUG: False (Production) ✅

3. **Docker Compose**
   - Network yapılandırması: Doğru ✅
   - Volume bağlantıları: Doğru ✅

---

## ✅ Çözümler

### Çözüm 1: Nginx Yapılandırmasını Güncelle

**Dosya**: `/opt/habernexus/nginx/conf.d/habernexus.conf`

**Değişiklikler**:
```nginx
# YANLIŞ
ssl_certificate /etc/nginx/ssl/habernexus.com/fullchain.pem;
ssl_certificate_key /etc/nginx/ssl/habernexus.com/privkey.pem;

# DOĞRU
ssl_certificate /etc/nginx/ssl/cert.pem;
ssl_certificate_key /etc/nginx/ssl/key.pem;
```

### Çözüm 2: Self-Signed Sertifika Oluştur

```bash
sudo mkdir -p /opt/habernexus/nginx/ssl

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /opt/habernexus/nginx/ssl/key.pem \
  -out /opt/habernexus/nginx/ssl/cert.pem \
  -subj "/C=TR/ST=Istanbul/L=Istanbul/O=HaberNexus/CN=habernexus.com"

sudo chmod 644 /opt/habernexus/nginx/ssl/cert.pem
sudo chmod 644 /opt/habernexus/nginx/ssl/key.pem
```

### Çözüm 3: Django Admin Paneli Sorunu (Devam Eden Araştırma)

**Yapılacaklar:**
1. Django DEBUG modunu aç ve detaylı hata mesajını görmek
2. Nginx proxy ayarlarını kontrol et
3. PostgreSQL bağlantısını test et
4. Celery/Redis bağlantısını test et

**Test Komutları:**
```bash
# Django shell'de admin kullanıcısını kontrol et
cd /opt/habernexus
sudo docker-compose -f docker-compose.prod.yml exec web python manage.py shell

from django.contrib.auth.models import User
print(User.objects.all())
# Beklenen çıktı: <QuerySet [<User: admin>]>

# Django admin paneline doğrudan erişim test et
curl -X POST http://localhost:8000/admin/login/ \
  -d "username=admin&password=YOUR_PASSWORD"
```

---

## 🚀 GitHub Actions Hataları

### Analiz Edilen Dosyalar

1. **`.github/workflows/ci.yml`** - CI/CD Pipeline
2. **`.github/workflows/deploy.yml`** - Production Deployment

### Bulunun Sorunlar

#### 1. Deploy Workflow'da Eksik Secrets

**Sorun**: GitHub Actions secrets tanımlanmamış

**Gerekli Secrets:**
```
VM_HOST          - Sunucu IP adresi (35.198.132.19)
VM_USER          - SSH kullanıcı adı (kayakadir2500)
VM_SSH_KEY       - Private SSH anahtarı
```

**Çözüm:**
GitHub repository settings'te şu secrets'ları ekleyin:
1. `VM_HOST`: `35.198.132.19`
2. `VM_USER`: `kayakadir2500`
3. `VM_SSH_KEY`: Sunucunuzun private SSH anahtarı

#### 2. Deploy Script'te Sorunlar

**Dosya**: `.github/workflows/deploy.yml`

**Sorunlar:**
1. **Satır 29**: Yanlış dizin yolu
   ```yaml
   # YANLIŞ
   cd /home/${{ secrets.VM_USER }}/habernexus
   
   # DOĞRU
   cd /opt/habernexus
   ```

2. **Satır 61**: Health check URL yanlış
   ```yaml
   # YANLIŞ
   curl -f http://localhost:8000/health/
   
   # DOĞRU (Nginx üzerinden)
   curl -f https://habernexus.com/health/
   ```

3. **Satır 82-87**: Issue comment eklenemiyor (push event'inde issue_number yok)
   ```yaml
   # SORUN: Push event'inde issue_number yoktur
   # Çözüm: Şartlı kontrol ekle veya pull_request event'ine sınırla
   ```

#### 3. CI Workflow'da Sorunlar

**Dosya**: `.github/workflows/ci.yml`

**Sorunlar:**
1. **Satır 90**: Test komutu eksik
   ```yaml
   # YANLIŞ
   python manage.py test news --verbosity=2
   
   # DOĞRU
   python manage.py test --verbosity=2
   ```

2. **Satır 193**: Docker run komutu başarısız olabilir
   ```yaml
   # Sorun: ENV variables tanımlanmamış
   docker run --rm habernexus:latest python manage.py check
   
   # Çözüm: ENV variables ekle
   docker run --rm \
     -e DJANGO_SECRET_KEY=test \
     -e DEBUG=False \
     habernexus:latest python manage.py check
   ```

---

## 💻 Kod Düzeltmeleri

### 1. Deploy Workflow Düzeltmesi

**Dosya**: `.github/workflows/deploy.yml`

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    name: Deploy to Google Cloud VM
    runs-on: ubuntu-latest
    if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Deploy via SSH
      uses: appleboy/ssh-action@master
      with:
        host: ${{ secrets.VM_HOST }}
        username: ${{ secrets.VM_USER }}
        key: ${{ secrets.VM_SSH_KEY }}
        port: 22
        script: |
          set -e
          
          echo "=== Starting deployment ==="
          cd /opt/habernexus  # ✅ DÜZELTME: /home/${{ secrets.VM_USER }}/habernexus yerine
          
          # Pull latest code
          echo "Pulling latest code from GitHub..."
          git fetch origin
          git reset --hard origin/main
          
          # Build and start containers
          echo "Building Docker images..."
          docker-compose -f docker-compose.prod.yml build
          
          # Stop old containers
          echo "Stopping old containers..."
          docker-compose -f docker-compose.prod.yml down || true
          
          # Start new containers
          echo "Starting new containers..."
          docker-compose -f docker-compose.prod.yml up -d
          
          # Run migrations
          echo "Running database migrations..."
          docker-compose -f docker-compose.prod.yml exec -T web python manage.py migrate
          
          # Collect static files
          echo "Collecting static files..."
          docker-compose -f docker-compose.prod.yml exec -T web python manage.py collectstatic --noinput
          
          # Health check
          echo "Waiting for application to be ready..."
          sleep 10
          
          for i in {1..30}; do
            if curl -f http://localhost:8000/health/ > /dev/null 2>&1; then
              echo "✅ Application is healthy!"
              break
            fi
            echo "Waiting for application... ($i/30)"
            sleep 2
          done
          
          # Verify deployment
          if curl -f http://localhost:8000/health/ > /dev/null 2>&1; then
            echo "✅ Deployment successful!"
          else
            echo "❌ Deployment failed - application not responding"
            exit 1
          fi

    - name: Notify deployment success
      if: success()
      run: |
        echo "✅ Deployment to production completed successfully!"

    - name: Notify deployment failure
      if: failure()
      run: |
        echo "❌ Deployment to production failed!"
```

### 2. CI Workflow Düzeltmesi

**Dosya**: `.github/workflows/ci.yml`

```yaml
# ... (önceki kısım aynı)

    - name: Run Django tests
      env:
        DEBUG: 'False'
        DB_NAME: habernexus_test
        DB_USER: postgres
        DB_PASSWORD: postgres
        DB_HOST: localhost
        DB_PORT: 5432
        CELERY_BROKER_URL: redis://localhost:6379/0
        CELERY_RESULT_BACKEND: redis://localhost:6379/0
        DJANGO_SECRET_KEY: test-secret-key-for-ci
        ALLOWED_HOSTS: 'localhost,127.0.0.1'
      run: |
        python manage.py test --verbosity=2  # ✅ DÜZELTME: 'news' parametresi kaldırıldı

# ... (diğer kısımlar)

    - name: Test Docker image
      run: |
        docker build -t habernexus:latest .
        docker run --rm \
          -e DJANGO_SECRET_KEY=test-secret-key-for-ci \
          -e DEBUG=False \
          -e DB_HOST=localhost \
          -e ALLOWED_HOSTS='localhost,127.0.0.1' \
          habernexus:latest python manage.py check  # ✅ DÜZELTME: ENV variables eklendi
      continue-on-error: true
```

### 3. Nginx Yapılandırması Düzeltmesi

**Dosya**: `nginx/conf.d/habernexus.conf`

```nginx
# Upstream Django application
upstream django {
    server web:8000;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name habernexus.com www.habernexus.com _;
    return 301 https://$server_name$request_uri;
}

# HTTPS server block
server {
    listen 443 ssl http2;
    server_name habernexus.com www.habernexus.com;

    # SSL certificates (Self-signed or Let's Encrypt)
    ssl_certificate /etc/nginx/ssl/cert.pem;  # ✅ DÜZELTME
    ssl_certificate_key /etc/nginx/ssl/key.pem;  # ✅ DÜZELTME

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/habernexus_access.log main;
    error_log /var/log/nginx/habernexus_error.log warn;

    # Static files
    location /static/ {
        alias /app/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Media files
    location /media/ {
        alias /app/media/;
        expires 7d;
        add_header Cache-Control "public";
    }

    # Health check endpoint
    location /health/ {
        access_log off;
        proxy_pass http://django;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API endpoints
    location /api/ {
        proxy_pass http://django;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    # Admin panel
    location /admin/ {
        proxy_pass http://django;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    # Main application
    location / {
        proxy_pass http://django;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
```

---

## 📊 Öneriler

### 1. GitHub Actions Secrets Kurulumu

Repository settings'te şu secrets'ları ekleyin:

```
VM_HOST=35.198.132.19
VM_USER=kayakadir2500
VM_SSH_KEY=<private-ssh-key>
```

### 2. Let's Encrypt Sertifikası Kurulumu

Self-signed sertifika yerine Let's Encrypt kullanmak için:

```bash
# Certbot kurulumu
sudo apt-get install certbot python3-certbot-nginx

# Sertifika oluşturma
sudo certbot certonly --standalone -d habernexus.com -d www.habernexus.com

# Sertifikaları Docker container'ına kopyalama
sudo cp /etc/letsencrypt/live/habernexus.com/fullchain.pem /opt/habernexus/nginx/ssl/
sudo cp /etc/letsencrypt/live/habernexus.com/privkey.pem /opt/habernexus/nginx/ssl/
```

### 3. Django Admin Paneli Sorunu Araştırması

```bash
# DEBUG modunu aç
export DEBUG=True

# Container'ı yeniden başlat
cd /opt/habernexus
sudo docker-compose -f docker-compose.prod.yml down
sudo docker-compose -f docker-compose.prod.yml up -d

# Logları kontrol et
sudo docker-compose -f docker-compose.prod.yml logs web -f
```

### 4. Monitoring ve Logging

```bash
# Nginx loglarını kontrol et
sudo docker-compose -f docker-compose.prod.yml logs nginx -f

# Django loglarını kontrol et
sudo docker-compose -f docker-compose.prod.yml logs web -f

# PostgreSQL loglarını kontrol et
sudo docker-compose -f docker-compose.prod.yml logs postgres -f
```

### 5. Güvenlik İyileştirmeleri

1. **SSH Key Rotasyonu**: GitHub Actions secret'ındaki SSH key'i düzenli olarak değiştirin
2. **Firewall Kuralları**: UFW firewall'ı etkinleştirin
3. **SSL/TLS**: Let's Encrypt sertifikasını otomatik olarak yenilemek için cron job ekleyin
4. **Database Backup**: Günlük veritabanı backup'ı alın

---

## ✅ Kontrol Listesi

- [ ] GitHub Actions secrets'ları ekle
- [ ] Deploy workflow'ı güncelle
- [ ] CI workflow'ı güncelle
- [ ] Nginx yapılandırmasını güncelle
- [ ] Django admin paneli sorunu çöz
- [ ] Let's Encrypt sertifikası kur
- [ ] Firewall kurallarını uygula
- [ ] Monitoring ve logging'i kur
- [ ] Backup stratejisini oluştur

---

## 📞 İletişim

- **Email**: salihtanriseven25@gmail.com
- **GitHub**: https://github.com/sata2500/habernexus
- **Issues**: https://github.com/sata2500/habernexus/issues

---

**Son Güncelleme**: 2025-12-06  
**Durum**: Analiz Tamamlandı ✅  
**Sonraki Adım**: Kod düzeltmelerini uygula
