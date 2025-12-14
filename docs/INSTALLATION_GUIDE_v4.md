# HaberNexus Kurulum Rehberi v4.0

## İçindekiler
1. [Sistem Gereksinimleri](#sistem-gereksinimleri)
2. [Kurulum Seçenekleri](#kurulum-seçenekleri)
3. [Adım Adım Kurulum](#adım-adım-kurulum)
4. [Cloudflare Tunnel Kurulumu](#cloudflare-tunnel-kurulumu)
5. [Nginx Proxy Manager Kurulumu](#nginx-proxy-manager-kurulumu)
6. [Sorun Giderme](#sorun-giderme)
7. [Sonraki Adımlar](#sonraki-adımlar)

---

## Sistem Gereksinimleri

### Minimum Gereksinimler
- **İşletim Sistemi**: Ubuntu 22.04 LTS veya 24.04 LTS
- **RAM**: 4 GB (8 GB önerilen)
- **Disk**: 20 GB boş alan
- **CPU**: 2 çekirdek (4 çekirdek önerilen)
- **İnternet**: Sabit bağlantı

### Yazılım Gereksinimleri
- Docker (otomatik kurulur)
- Docker Compose v2 (otomatik kurulur)
- Git (otomatik kurulur)
- Bash 4.0+

### Ağ Gereksinimleri
- **Cloudflare Tunnel + NPM**: Port 81 açık (admin panel)
- **Cloudflare Tunnel + Direct**: Hiçbir port açmaya gerek yok
- **Direct Port Forwarding**: Portlar 80 ve 443 açık olmalı

---

## Kurulum Seçenekleri

### Seçenek 1: Cloudflare Tunnel + Nginx Proxy Manager (Önerilen) ⭐

**Avantajları:**
- ✅ Port açmaya gerek yok
- ✅ Dinamik IP desteği
- ✅ GUI tabanlı yönetim
- ✅ Otomatik SSL sertifikası
- ✅ Kolay subdomain yönetimi
- ✅ Ücretsiz

**Dezavantajları:**
- ❌ Ek container gerektirir
- ❌ Cloudflare'ye bağımlılık

**Kimler için:**
- Dinamik IP'si olanlar
- Port açamayan kullanıcılar
- GUI arayüz isteyenler

---

### Seçenek 2: Cloudflare Tunnel + Direct Nginx

**Avantajları:**
- ✅ Port açmaya gerek yok
- ✅ Basit kurulum
- ✅ Daha az kaynak kullanımı

**Dezavantajları:**
- ❌ CLI tabanlı yönetim
- ❌ Subdomain yönetimi zor

**Kimler için:**
- Basit kurulum isteyenler
- Kaynak kısıtlı sistemler

---

### Seçenek 3: Direct Port Forwarding

**Avantajları:**
- ✅ Basit kurulum
- ✅ Doğrudan kontrol
- ✅ Cloudflare'ye bağımlı değil

**Dezavantajları:**
- ❌ Port açmaya gerek
- ❌ Statik IP gerekli
- ❌ SSL sertifikası manuel yönetim

**Kimler için:**
- Statik IP'si olanlar
- Port açabilen kullanıcılar
- Gelişmiş kullanıcılar

---

## Adım Adım Kurulum

### 1. Sunucuya Bağlan

```bash
ssh root@your-server-ip
```

### 2. Installer'ı İndir ve Çalıştır

```bash
# Installer'ı indir
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v4.sh

# Çalıştırılabilir yap
chmod +x install_v4.sh

# Root olarak çalıştır
sudo bash install_v4.sh
```

### 3. Ana Menüyü Seç

Installer başladığında ana menü görünecek:

```
┌─────────────────────────────────────────┐
│   HaberNexus Installer v4.0             │
├─────────────────────────────────────────┤
│ 1. Fresh Installation (Recommended)     │
│ 2. Smart Migration                      │
│ 3. Update System                        │
│ 4. Health Check                         │
│ 5. Exit                                 │
└─────────────────────────────────────────┘
```

**Seç: 1 (Fresh Installation)**

### 4. Kurulum Türünü Seç

```
┌─────────────────────────────────────────┐
│ Select Installation Type:               │
├─────────────────────────────────────────┤
│ 1. Cloudflare Tunnel + Nginx Proxy Mgr  │
│ 2. Cloudflare Tunnel + Direct Nginx     │
│ 3. Direct Port Forwarding               │
└─────────────────────────────────────────┘
```

**Seç: 1 (Önerilen)**

### 5. Konfigürasyon Bilgilerini Gir

Installer aşağıdaki bilgileri isteyecek:

#### Domain Adı
```
Enter your domain name (e.g., habernexus.com):
```
**Örnek:** `habernexus.com`

#### Admin Email
```
Enter admin email:
```
**Örnek:** `admin@habernexus.com`

#### Admin Kullanıcı Adı
```
Enter admin username:
```
**Örnek:** `admin`

#### Admin Şifresi
```
Set Admin Password (min 12 chars):
```
**Gereksinimler:**
- Minimum 12 karakter
- Büyük harf içermeli
- Sayı içermeli
- Özel karakter içermeli

**Örnek:** `MySecure@Pass123`

#### Veritabanı Şifresi
```
Set Database Password (min 12 chars):
```
**Gereksinimler:** Admin şifresi ile aynı

### 6. Cloudflare Tunnel Token'ı Gir

Installer rehberlik gösterecek:

```
HOW TO GET YOUR CLOUDFLARE TUNNEL TOKEN:

1. Go to https://one.dash.cloudflare.com
2. Navigate to Networks > Tunnels
3. Click 'Create a Tunnel' → Select 'Cloudflared'
4. Name it (e.g., 'habernexus') and Save
5. Copy the token from 'Install and run a connector' section
   (It looks like: eyJhIjoi...)
6. Paste it below when prompted
```

**Adımlar:**
1. https://one.dash.cloudflare.com adresine git
2. **Networks > Tunnels** seçeneğine tıkla
3. **Create a Tunnel** düğmesine tıkla
4. **Cloudflared** seçeneğini seç
5. Tunnel adını gir (örn: `habernexus`)
6. **Save tunnel** düğmesine tıkla
7. **Install and run a connector** bölümünden token'ı kopyala
8. Installer'a yapıştır

### 7. Cloudflare API Token'ı Gir

Installer rehberlik gösterecek:

```
HOW TO GET YOUR CLOUDFLARE API TOKEN:

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click 'Create Token'
3. Use 'Edit zone DNS' template
4. Under Zone Resources, select your domain
5. Create and copy the token

This token is used for automatic SSL certificate renewal.
```

**Adımlar:**
1. https://dash.cloudflare.com/profile/api-tokens adresine git
2. **Create Token** düğmesine tıkla
3. **Edit zone DNS** şablonunu seç
4. **Zone Resources** altında domain'ini seç
5. **Create Token** düğmesine tıkla
6. Token'ı kopyala ve Installer'a yapıştır

### 8. NPM Veritabanı Türünü Seç

```
Select database type:
1. SQLite (Simple, Recommended)
2. PostgreSQL (Advanced)
```

**Seç: 1 (SQLite - Basit ve önerilen)**

### 9. Kurulumun Tamamlanmasını Bekle

Installer otomatik olarak:
- Docker image'ları indir
- Container'ları başlat
- Veritabanı migrasyonlarını çalıştır
- Admin kullanıcısını oluştur
- Health check'leri çalıştır

### 10. Kurulum Özeti

Kurulum tamamlandığında özet bilgiler gösterilecek:

```
╔════════════════════════════════════════╗
║  Installation Summary                  ║
╠════════════════════════════════════════╣
║ Status: ✓ Successful                   ║
║ Installation Type: Tunnel + NPM        ║
║ Domain: habernexus.com                 ║
║ Project Path: /opt/habernexus          ║
║                                        ║
║ Access URLs:                           ║
║ • Main Site: https://habernexus.com    ║
║ • Admin Panel: https://habernexus.com/admin ║
║ • NPM Panel: http://localhost:81       ║
║                                        ║
║ Next Steps:                            ║
║ 1. Configure Cloudflare DNS            ║
║ 2. Setup NPM proxy hosts               ║
║ 3. Configure HaberNexus settings       ║
║ 4. Start content generation            ║
╚════════════════════════════════════════╝
```

---

## Cloudflare Tunnel Kurulumu

### DNS Kayıtlarını Yapılandır

Cloudflare Dashboard'da:

1. **DNS** sekmesine git
2. **Add Record** düğmesine tıkla
3. Aşağıdaki kayıtları ekle:

#### Ana Domain
```
Type: CNAME
Name: habernexus.com
Target: <tunnel-id>.cfargotunnel.com
Proxied: Yes (Turuncu bulut)
```

#### Wildcard (Subdomainler için)
```
Type: CNAME
Name: *.habernexus.com
Target: <tunnel-id>.cfargotunnel.com
Proxied: Yes (Turuncu bulut)
```

#### www Subdomain (Opsiyonel)
```
Type: CNAME
Name: www
Target: <tunnel-id>.cfargotunnel.com
Proxied: Yes (Turuncu bulut)
```

### Public Hostname'leri Yapılandır

Cloudflare Dashboard'da:

1. **Networks > Tunnels** seçeneğine git
2. Tunnel'ını seç
3. **Public Hostnames** sekmesine tıkla
4. **Add a public hostname** düğmesine tıkla

#### Ana Domain
```
Subdomain: (boş bırak)
Domain: habernexus.com
Path: (boş bırak)
Service Type: HTTP
URL: http://nginx_proxy_manager:81
```

#### Wildcard
```
Subdomain: *
Domain: habernexus.com
Path: (boş bırak)
Service Type: HTTP
URL: http://nginx_proxy_manager:81
```

---

## Nginx Proxy Manager Kurulumu

### Admin Panel'e Erişim

1. Browser'da aç: `http://your-server-ip:81`
2. Default login:
   - **Email:** `admin@example.com`
   - **Password:** `changeme`

### Admin Şifresini Değiştir

1. Sağ üst köşedeki profil ikonuna tıkla
2. **Settings** seçeneğine tıkla
3. **Change Password** düğmesine tıkla
4. Yeni şifre gir ve kaydet

### Proxy Host Oluştur

1. **Proxy Hosts** sekmesine tıkla
2. **Add Proxy Host** düğmesine tıkla

#### Konfigürasyon
```
Domain Names: habernexus.com, www.habernexus.com
Scheme: http
Forward Hostname/IP: app
Forward Port: 8000
Block Common Exploits: ON
Websockets Support: ON
```

3. **SSL** sekmesine tıkla
4. **Request a new SSL Certificate** seçeneğini seç
5. **Use a DNS Challenge** seçeneğini işaretle
6. **DNS Provider:** Cloudflare seçeneğini seç
7. Cloudflare API Token'ını gir
8. **Save** düğmesine tıkla

---

## Sorun Giderme

### Problem: "Connection refused" hatası

**Çözüm:**
```bash
# Container'ları kontrol et
docker compose ps

# Logs'ları kontrol et
docker compose logs app
docker compose logs nginx_proxy_manager

# Container'ları yeniden başlat
docker compose restart
```

### Problem: Cloudflare Tunnel bağlantısı kesildi

**Çözüm:**
```bash
# Tunnel container'ını kontrol et
docker logs habernexus_cloudflared

# Container'ı yeniden başlat
docker restart habernexus_cloudflared

# Token'ı kontrol et
echo $CLOUDFLARE_TUNNEL_TOKEN
```

### Problem: SSL sertifikası hatası

**Çözüm:**
1. NPM Dashboard'a git
2. **SSL Certificates** sekmesine tıkla
3. Sertifikayı sil
4. Yeni sertifika oluştur (DNS Challenge ile)

### Problem: Database bağlantı hatası

**Çözüm:**
```bash
# Database container'ını kontrol et
docker compose logs postgres

# Database'i reset et
docker compose down -v
docker compose up -d
```

### Problem: Admin panel erişilemez

**Çözüm:**
```bash
# NPM container'ını kontrol et
docker logs habernexus_npm

# Port'u kontrol et
ss -tuln | grep 81

# Container'ı yeniden başlat
docker restart habernexus_npm
```

---

## Sonraki Adımlar

### 1. HaberNexus Ayarlarını Yapılandır

1. https://habernexus.com/admin adresine git
2. Admin paneline giriş yap
3. **Settings** sekmesine tıkla
4. Aşağıdaki ayarları yapılandır:
   - Site başlığı
   - Site açıklaması
   - Logo ve favicon
   - Google Gemini API anahtarı
   - RSS feed kaynakları

### 2. RSS Feed'leri Ekle

1. Admin panelde **RSS Feeds** sekmesine tıkla
2. **Add Feed** düğmesine tıkla
3. Feed URL'sini gir
4. **Save** düğmesine tıkla

### 3. Content Generation'ı Başlat

1. Admin panelde **Content Generation** sekmesine tıkla
2. **Start Generation** düğmesine tıkla
3. Sistem otomatik olarak haber oluşturmaya başlayacak

### 4. Monitoring'i Ayarla

1. Grafana'ya erişim: `https://habernexus.com:3000`
2. Default login:
   - **Username:** `admin`
   - **Password:** `admin`
3. Dashboard'ları yapılandır

### 5. Backup'ları Ayarla

```bash
# Günlük backup'ı schedule et
crontab -e

# Aşağıdaki satırı ekle (her gün saat 2'de):
0 2 * * * /opt/habernexus/scripts/backup.sh
```

---

## Faydalı Komutlar

### Container Yönetimi
```bash
# Tüm container'ları göster
docker compose ps

# Container'ları başlat
docker compose up -d

# Container'ları durdur
docker compose down

# Container'ları yeniden başlat
docker compose restart

# Logs'ları görüntüle
docker compose logs -f app

# Belirli container'ın logs'unu görüntüle
docker compose logs -f nginx_proxy_manager
```

### Veritabanı Yönetimi
```bash
# Database'e bağlan
docker compose exec postgres psql -U habernexus_user -d habernexus

# Database'i backup et
docker compose exec postgres pg_dump -U habernexus_user habernexus > backup.sql

# Database'i restore et
cat backup.sql | docker compose exec -T postgres psql -U habernexus_user -d habernexus
```

### Django Yönetimi
```bash
# Migrations'ı çalıştır
docker compose exec app python manage.py migrate

# Static files'ları topla
docker compose exec app python manage.py collectstatic --noinput

# Django shell'i aç
docker compose exec app python manage.py shell

# Superuser oluştur
docker compose exec app python manage.py createsuperuser
```

---

## İletişim ve Destek

- **GitHub:** https://github.com/sata2500/habernexus
- **Email:** salihtanriseven25@gmail.com
- **Issues:** https://github.com/sata2500/habernexus/issues

---

## Sürüm Geçmişi

### v4.0 (December 2024)
- ✨ Nginx Proxy Manager entegrasyonu
- ✨ Cloudflare Tunnel desteği
- ✨ GUI tabanlı kurulum
- ✨ Geliştirilmiş hata yönetimi
- ✨ Health check fonksiyonları
- ✨ Modüler script yapısı

### v3.1 (Previous)
- TUI tabanlı installer
- Cloudflare Tunnel desteği
- Smart migration

---

## Lisans

Bu proje proprietary yazılımdır. Detaylar için LICENSE dosyasına bakınız.

**Geliştirici:** Salih TANRISEVEN  
**Email:** salihtanriseven25@gmail.com
