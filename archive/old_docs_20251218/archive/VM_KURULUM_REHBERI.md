# Haber Nexus - VM Kurulum Rehberi

**Tarih:** 6 Aralık 2025  
**Geliştirici:** Salih TANRISEVEN  
**Email:** salihtanriseven25@gmail.com  
**Domain:** habernexus.com

---

## 📋 İçindekiler

1. [Genel Bakış](#genel-bakış)
2. [Ön Gereksinimler](#ön-gereksinimler)
3. [VM Hazırlığı](#vm-hazırlığı)
4. [Kurulum Adımları](#kurulum-adımları)
5. [Kurulum Sonrası](#kurulum-sonrası)
6. [Sorun Giderme](#sorun-giderme)
7. [Yönetim Komutları](#yönetim-komutları)

---

## 🎯 Genel Bakış

Bu rehber, **Haber Nexus** uygulamasını Ubuntu 22.04 veya 24.04 LTS çalıştıran bir Google Cloud VM'e kurmanız için adım adım talimatlar sağlar.

**Kurulum Yöntemleri:**
- **Docker Compose** (Önerilen) - Daha kolay yönetim ve ölçekleme
- **Traditional** - Sistemde doğrudan kurulum

### Kurulum Süresi
- Docker Compose: ~10-15 dakika
- Traditional: ~15-20 dakika

---

## ✅ Ön Gereksinimler

### VM Gereksinimleri
- **İşletim Sistemi:** Ubuntu 22.04 LTS veya 24.04 LTS
- **CPU:** Minimum 2 core (4 core önerilir)
- **RAM:** Minimum 4 GB (8 GB önerilir)
- **Disk:** Minimum 20 GB (50 GB önerilir)
- **Network:** İnternet bağlantısı

### Bilgisayarınızda Gerekli Olanlar
- SSH istemcisi (Windows: PuTTY veya WSL, macOS/Linux: Terminal)
- VM'nin SSH anahtarı (`.pem` dosyası)
- VM'nin IP adresi veya domain adı

### Gerekli Bilgiler
Kurulum sırasında aşağıdaki bilgileri hazır bulundurun:
- Domain adı (örn: habernexus.com) - Opsiyonel
- Admin email adresi
- PostgreSQL veritabanı şifresi (güçlü şifre)
- Google Gemini API Key

---

## 🔧 VM Hazırlığı

### Adım 1: VM Oluştur (Google Cloud Console)

1. **Google Cloud Console'a git:** https://console.cloud.google.com/
2. **Compute Engine > VM Instances** seçin
3. **Create Instance** butonuna tıklayın
4. Aşağıdaki ayarları yapın:

```
Name: habernexus-vm
Region: europe-west1 (veya tercih ettiğiniz region)
Zone: europe-west1-b
Machine Type: e2-standard-2 (2 vCPU, 8 GB RAM)
Boot Disk: Ubuntu 24.04 LTS, 50 GB
Firewall: Allow HTTP traffic, Allow HTTPS traffic
```

5. **Create** butonuna tıklayın ve VM'nin başlamasını bekleyin.

### Adım 2: SSH Anahtarı Oluştur

**Windows (PowerShell):**
```powershell
# SSH anahtarı oluştur
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\habernexus_key -N ""

# Anahtarı göster
Get-Content $env:USERPROFILE\.ssh\habernexus_key.pub
```

**macOS/Linux:**
```bash
# SSH anahtarı oluştur
ssh-keygen -t rsa -b 4096 -f ~/.ssh/habernexus_key -N ""

# Anahtarı göster
cat ~/.ssh/habernexus_key.pub
```

### Adım 3: SSH Anahtarını VM'ye Ekle

1. Google Cloud Console'da VM'yi seçin
2. **Edit** butonuna tıklayın
3. **SSH Keys** bölümüne gidin
4. **Add Item** tıklayın
5. Oluşturduğunuz public key'i yapıştırın
6. **Save** butonuna tıklayın

### Adım 4: VM'ye Bağlan

**Windows (PowerShell):**
```powershell
ssh -i $env:USERPROFILE\.ssh\habernexus_key ubuntu@<VM_IP>
```

**macOS/Linux:**
```bash
ssh -i ~/.ssh/habernexus_key ubuntu@<VM_IP>
```

> **Not:** `<VM_IP>` yerine VM'nin harici IP adresini yazın.

---

## 🚀 Kurulum Adımları

### Adım 1: VM'ye Bağlan

SSH ile VM'ye bağlandığınızda, aşağıdaki komut satırını göreceksiniz:

```
ubuntu@habernexus-vm:~$
```

### Adım 2: Projeyi Klonla

```bash
# Projeyi klonla
git clone https://github.com/sata2500/habernexus.git

# Proje dizinine git
cd habernexus
```

### Adım 3: Kurulum Scriptini Çalıştır

```bash
# Kurulum scriptini çalıştır (sudo gerekli)
sudo bash scripts/setup.sh
```

### Adım 4: Kurulum Sorularını Cevapla

Script aşağıdaki soruları soracak:

#### 1. Kurulum Yöntemi
```
Kurulum yöntemi seçin:
  1) Docker Compose (Önerilen - Daha kolay yönetim)
  2) Traditional (Sistemde doğrudan kurulum)

Seçim (1 veya 2) [1]: 
```
**Önerilen:** `1` (Docker Compose)

#### 2. Proje Dizini
```
Proje dizini [/opt/habernexus]: 
```
**Önerilen:** Varsayılan değeri kullanın (Enter tuşuna basın)

#### 3. Sistem Kullanıcısı
```
Sistem kullanıcısı [habernexus]: 
```
**Önerilen:** Varsayılan değeri kullanın

#### 4. Domain Adı
```
Domain adınız (örn: habernexus.com) [localhost]: habernexus.com
```
**Önemli:** Gerçek domain adınızı girin

#### 5. Admin Email
```
Admin email adresi: salihtanriseven25@gmail.com
```
**Önemli:** Geçerli bir email adresi girin

#### 6. PostgreSQL Şifresi
```
PostgreSQL şifresi (en az 12 karakter, özel karakter içermemeli): 
```
**Önemli:** Güçlü bir şifre girin (örn: `MySecurePass2025`)

Şifreyi tekrar girin:
```
PostgreSQL şifresi (tekrar): 
```

#### 7. Google Gemini API Key
```
Google Gemini API Key: 
```
**Opsiyonel:** API key'inizi girin veya boş bırakın

#### 8. SSL Sertifikası
```
SSL/TLS Sertifikası:
  1) Let's Encrypt (Üretim - Önerilen)
  2) Self-signed (Geliştirme)
  3) Şimdilik kurma

Seçim (1, 2 veya 3) [1]: 
```
**Önerilen:** `1` (Let's Encrypt)

#### 9. Onay
```
Devam etmek istiyor musunuz? (y/n): y
```

### Adım 5: Kurulumun Tamamlanmasını Bekle

Script otomatik olarak:
- Sistem paketlerini güncelleyecek
- Docker/PostgreSQL/Redis/Nginx kuracak
- Projeyi klonlayacak
- Veritabanını oluşturacak
- Servisleri başlatacak
- SSL sertifikasını kuracak

Kurulum sırasında aşağıdaki gibi mesajlar göreceksiniz:

```
[✓] Root yetkisi kontrol edildi.
[✓] Ubuntu 24.04 tespit edildi.
[✓] İnternet bağlantısı kontrol edildi.

==> Sistem Hazırlığı
==> Adım 1: Sistem Hazırlığı
[✓] Sistem paketleri güncellendi.
[✓] Temel paketler kuruldu.
[✓] Docker ve Docker Compose kuruldu.

... (daha fazla adım)

🎉 KURULUM BAŞARIYLA TAMAMLANDI! 🎉
```

---

## 📝 Kurulum Sonrası

### Adım 1: Admin Kullanıcısı Oluştur

Kurulum tamamlandıktan sonra, admin kullanıcısını oluşturun:

**Docker Compose kullanıyorsanız:**
```bash
cd /opt/habernexus
docker-compose -f docker-compose.prod.yml exec app python manage.py createsuperuser
```

**Traditional kullanıyorsanız:**
```bash
cd /opt/habernexus
sudo -u habernexus ./venv/bin/python manage.py createsuperuser
```

Aşağıdaki bilgileri girin:
```
Username: admin
Email address: salihtanriseven25@gmail.com
Password: (güçlü bir şifre girin)
Password (again): (şifreyi tekrar girin)
```

### Adım 2: Web Sitesine Erişim

Tarayıcınızda aşağıdaki URL'lere gidin:

```
Web Sitesi: https://habernexus.com
Admin Paneli: https://habernexus.com/admin/
```

Admin paneline giriş yapın:
- **Kullanıcı Adı:** admin
- **Şifre:** Oluşturduğunuz şifre

### Adım 3: Google Gemini API Key Ayarla

1. Admin paneline gidin
2. **Settings** bölümüne gidin
3. `GOOGLE_API_KEY` ayarını bulun
4. API key'inizi girin

### Adım 4: RSS Kaynakları Ekle

1. Admin panelinde **News > RSS Sources** seçin
2. **Add RSS Source** butonuna tıklayın
3. RSS feed URL'sini girin (örn: https://feeds.bbc.com/news/rss.xml)
4. Kategori seçin
5. **Save** butonuna tıklayın

### Adım 5: Haber Taramasını Başlat

Admin panelinde aşağıdaki komutları çalıştırın:

**Docker Compose:**
```bash
docker-compose -f /opt/habernexus/docker-compose.prod.yml exec app python manage.py shell
```

**Traditional:**
```bash
sudo -u habernexus /opt/habernexus/venv/bin/python /opt/habernexus/manage.py shell
```

Django shell'de:
```python
from news.tasks import fetch_all_rss
fetch_all_rss.delay()
```

---

## 🔍 Sorun Giderme

### Sorun: "Connection refused" hatası

**Çözüm:**
```bash
# Docker Compose kullanıyorsanız
docker-compose -f /opt/habernexus/docker-compose.prod.yml restart

# Traditional kullanıyorsanız
sudo systemctl restart habernexus habernexus-celery habernexus-celery-beat
```

### Sorun: SSL sertifikası hatası

**Çözüm:**
```bash
# Let's Encrypt sertifikasını yenile
sudo certbot renew

# Self-signed sertifikası oluştur
sudo openssl req -x509 -newkey rsa:4096 \
    -keyout /opt/habernexus/nginx/ssl/privkey.pem \
    -out /opt/habernexus/nginx/ssl/fullchain.pem \
    -days 365 -nodes -subj "/CN=habernexus.com"
```

### Sorun: Veritabanı bağlantı hatası

**Çözüm:**
```bash
# Docker Compose kullanıyorsanız
docker-compose -f /opt/habernexus/docker-compose.prod.yml logs db

# Traditional kullanıyorsanız
sudo systemctl status postgresql
sudo sudo -u postgres psql -c "SELECT version();"
```

### Sorun: Celery görevleri çalışmıyor

**Çözüm:**
```bash
# Docker Compose kullanıyorsanız
docker-compose -f /opt/habernexus/docker-compose.prod.yml logs celery

# Traditional kullanıyorsanız
sudo systemctl status habernexus-celery
sudo tail -f /var/log/habernexus/celery-worker.log
```

### Sorun: Disk alanı yetersiz

**Çözüm:**
```bash
# Disk kullanımını kontrol et
df -h

# Eski logları temizle
sudo journalctl --vacuum=30d

# Docker temizliği (Docker Compose kullanıyorsanız)
docker system prune -a
```

---

## 📊 Yönetim Komutları

### Servis Yönetimi

**Docker Compose:**
```bash
# Servisleri başlat
docker-compose -f /opt/habernexus/docker-compose.prod.yml up -d

# Servisleri durdur
docker-compose -f /opt/habernexus/docker-compose.prod.yml down

# Servisleri yeniden başlat
docker-compose -f /opt/habernexus/docker-compose.prod.yml restart

# Servis durumlarını göster
docker-compose -f /opt/habernexus/docker-compose.prod.yml ps

# Logları göster
docker-compose -f /opt/habernexus/docker-compose.prod.yml logs -f app
```

**Traditional:**
```bash
# Django uygulamasını başlat
sudo systemctl start habernexus

# Django uygulamasını durdur
sudo systemctl stop habernexus

# Django uygulamasını yeniden başlat
sudo systemctl restart habernexus

# Servis durumunu kontrol et
sudo systemctl status habernexus

# Logları göster
sudo journalctl -u habernexus -f
```

### Veritabanı Yönetimi

**Docker Compose:**
```bash
# PostgreSQL shell'e gir
docker-compose -f /opt/habernexus/docker-compose.prod.yml exec db psql -U habernexus_user -d habernexus

# Veritabanı yedekle
docker-compose -f /opt/habernexus/docker-compose.prod.yml exec db pg_dump -U habernexus_user habernexus > backup.sql

# Veritabanını geri yükle
docker-compose -f /opt/habernexus/docker-compose.prod.yml exec db psql -U habernexus_user habernexus < backup.sql
```

**Traditional:**
```bash
# PostgreSQL shell'e gir
sudo -u postgres psql -d habernexus

# Veritabanı yedekle
pg_dump -U habernexus_user -h localhost habernexus > backup.sql

# Veritabanını geri yükle
psql -U habernexus_user -h localhost habernexus < backup.sql
```

### Django Yönetimi

**Docker Compose:**
```bash
# Migrasyonları çalıştır
docker-compose -f /opt/habernexus/docker-compose.prod.yml exec app python manage.py migrate

# Statik dosyaları topla
docker-compose -f /opt/habernexus/docker-compose.prod.yml exec app python manage.py collectstatic

# Django shell'e gir
docker-compose -f /opt/habernexus/docker-compose.prod.yml exec app python manage.py shell
```

**Traditional:**
```bash
# Migrasyonları çalıştır
sudo -u habernexus /opt/habernexus/venv/bin/python /opt/habernexus/manage.py migrate

# Statik dosyaları topla
sudo -u habernexus /opt/habernexus/venv/bin/python /opt/habernexus/manage.py collectstatic

# Django shell'e gir
sudo -u habernexus /opt/habernexus/venv/bin/python /opt/habernexus/manage.py shell
```

### Monitoring ve Loglar

```bash
# Health check çalıştır
/usr/local/bin/habernexus-health-check

# Sistem loglarını göster
sudo journalctl -u habernexus -n 100

# Celery loglarını göster
sudo tail -f /var/log/habernexus/celery-worker.log

# Nginx loglarını göster
sudo tail -f /var/log/nginx/access.log

# Disk kullanımını kontrol et
df -h

# RAM kullanımını kontrol et
free -h

# Çalışan prosesleri göster
ps aux | grep habernexus
```

### Yedekleme

```bash
# Manuel yedekleme
cd /opt/habernexus
sudo bash scripts/backup.sh

# Yedekleri listele
ls -lh /var/backups/habernexus/

# Yedekten geri yükle
sudo bash scripts/restore.sh /var/backups/habernexus/habernexus_backup_20251206_120000
```

---

## 🔐 Güvenlik Önerileri

### 1. Firewall Kuralları

```bash
# SSH erişimini sınırla
sudo ufw allow from YOUR_IP/32 to any port 22

# HTTP/HTTPS erişimini aç
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Firewall'ı etkinleştir
sudo ufw enable
```

### 2. SSL/TLS Sertifikası

```bash
# Let's Encrypt sertifikasını yenile
sudo certbot renew

# Otomatik yenileme kontrol et
sudo systemctl status certbot.timer
```

### 3. Düzenli Yedekleme

```bash
# Günlük yedekleme cron job'u
sudo crontab -e

# Aşağıdaki satırı ekle (günde bir kez saat 02:00'de)
0 2 * * * cd /opt/habernexus && sudo bash scripts/backup.sh
```

### 4. Sistem Güncellemeleri

```bash
# Sistem paketlerini güncelle
sudo apt-get update
sudo apt-get upgrade -y

# Otomatik güncellemeleri etkinleştir
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

---

## 📞 Yardım ve Destek

- **GitHub:** https://github.com/sata2500/habernexus
- **Email:** salihtanriseven25@gmail.com
- **Documentation:** Proje içindeki `docs/` klasörü

---

## 📌 Hızlı Referans

| Görev | Komut |
|---|---|
| VM'ye bağlan | `ssh -i ~/.ssh/habernexus_key ubuntu@<VM_IP>` |
| Kurulumu başlat | `sudo bash scripts/setup.sh` |
| Servisleri yeniden başlat | `docker-compose -f /opt/habernexus/docker-compose.prod.yml restart` |
| Logları göster | `docker-compose -f /opt/habernexus/docker-compose.prod.yml logs -f` |
| Admin paneline gir | `https://<DOMAIN>/admin/` |
| Yedekleme yap | `cd /opt/habernexus && sudo bash scripts/backup.sh` |
| Health check | `/usr/local/bin/habernexus-health-check` |

---

**Kurulum Başarıyla Tamamlandı! 🎉**

Artık Haber Nexus uygulamanız Ubuntu 24 VM'de çalışıyor. Admin paneline giderek RSS kaynakları ekleyebilir ve otomatik haber taramasını başlatabilirsiniz.
