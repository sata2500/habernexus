# Setup Script - Özet ve Özellikler

**Dosya:** `scripts/setup.sh`  
**Boyut:** ~30 KB  
**Uyumlu Sistemler:** Ubuntu 22.04 LTS, Ubuntu 24.04 LTS  
**Geliştirici:** Salih TANRISEVEN  
**Tarih:** 6 Aralık 2025

---

## 📋 Genel Bakış

`setup.sh` scripti, Haber Nexus uygulamasını Ubuntu VM'ye tamamen otomatik olarak kuran kapsamlı bir kurulum aracıdır. Script, mevcut tüm kurulum scriptlerini birleştirerek tek, interaktif ve kullanıcı dostu bir deneyim sağlar.

---

## ✨ Ana Özellikler

### 1. **Interaktif Kurulum**
- Kullanıcıdan gerekli bilgileri adım adım sorar
- Varsayılan değerler sağlar (Enter tuşu ile kullanılabilir)
- Giriş validasyonu ve hata kontrolü

### 2. **Çift Kurulum Yöntemi**
- **Docker Compose** - Önerilen, kolay yönetim
- **Traditional** - Sistemde doğrudan kurulum

### 3. **Kapsamlı Sistem Kurulumu**
- Sistem paketlerini günceller
- Docker/Docker Compose kurar (Docker Compose seçilirse)
- PostgreSQL veritabanını oluşturur
- Redis cache sunucusunu kurar
- Nginx web sunucusunu yapılandırır

### 4. **Uygulama Kurulumu**
- GitHub deposundan projeyi klonlar
- Python sanal ortamını oluşturur
- Bağımlılıkları yükler
- Django migrasyonlarını çalıştırır
- Statik dosyaları toplar

### 5. **Servis Yönetimi**
- Systemd servisleri oluşturur (Traditional için)
- Servisleri otomatik başlatmaya ayarlar
- Health check mekanizması

### 6. **SSL/TLS Sertifikası**
- Let's Encrypt entegrasyonu (Üretim)
- Self-signed sertifika oluşturma (Geliştirme)
- Otomatik sertifika yenileme

### 7. **Monitoring ve Yedekleme**
- Health check scripti oluşturur
- Otomatik yedekleme cron job'u ayarlar
- Log rotation yapılandırması

### 8. **Güvenlik**
- Root yetkisi kontrolü
- OS doğrulaması
- İnternet bağlantısı kontrolü
- Firewall yapılandırması
- Güvenli şifre yönetimi

### 9. **Renkli Çıktı**
- Renk kodlu mesajlar (başarı, uyarı, hata)
- Adım adım ilerleme göstergesi
- Detaylı kurulum özeti

### 10. **Hata Yönetimi**
- Hataları yakalar ve rapor eder
- Kurulum başarısızlığında çıkar
- Mevcut kurulumları kontrol eder

---

## 🚀 Kullanım

### Temel Kullanım

```bash
# Projeyi klonla
git clone https://github.com/sata2500/habernexus.git
cd habernexus

# Kurulum scriptini çalıştır
sudo bash scripts/setup.sh
```

### Kurulum Süreci

1. **Ön Kontroller** (~1 dakika)
   - Root yetkisi
   - OS doğrulaması
   - İnternet bağlantısı

2. **Kurulum Ayarları** (~1 dakika)
   - Kurulum yöntemi seçimi
   - Proje dizini
   - Sistem kullanıcısı

3. **Gerekli Bilgileri Alma** (~2 dakika)
   - Domain adı
   - Admin email
   - PostgreSQL şifresi
   - Google API Key
   - SSL tipi

4. **Sistem Hazırlığı** (~5 dakika)
   - Paket güncellemeleri
   - Temel araçlar kurulumu
   - Docker kurulumu (Docker Compose seçilirse)

5. **Kullanıcı ve Dizinler** (~1 dakika)
   - Sistem kullanıcısı oluşturma
   - Gerekli dizinleri oluşturma

6. **Proje Klonlama** (~2 dakika)
   - GitHub deposundan klonlama
   - Mevcut kurulumları güncelleme

7. **Ortam Değişkenleri** (~1 dakika)
   - .env dosyası oluşturma
   - Secret key üretme

8. **Uygulama Kurulumu** (~5-10 dakika)
   - Docker Compose veya Traditional kurulum
   - Veritabanı migrasyonları
   - Statik dosyaları toplama

9. **Servis Yapılandırması** (~2 dakika)
   - Systemd servisleri oluşturma
   - Servisleri başlatma

10. **Nginx Yapılandırması** (~1 dakika)
    - Reverse proxy ayarları
    - SSL yapılandırması

11. **SSL/TLS Sertifikası** (~2-5 dakika)
    - Let's Encrypt veya Self-signed

12. **Monitoring ve Yedekleme** (~1 dakika)
    - Health check kurulumu
    - Yedekleme cron job'u

**Toplam Süre:** 10-20 dakika

---

## 📊 Kurulum Yöntemlerinin Karşılaştırması

| Özellik | Docker Compose | Traditional |
|---|---|---|
| **Kurulum Süresi** | 10-15 dakika | 15-20 dakika |
| **Karmaşıklık** | Düşük | Orta |
| **Yönetim** | Kolay | Daha karmaşık |
| **Ölçekleme** | Kolay | Zor |
| **Sistem Kaynakları** | Biraz daha fazla | Daha az |
| **Güncellemeler** | Kolay | Manuel |
| **Yedekleme** | Docker komutları | SQL komutları |
| **Önerilen** | ✅ Evet | Deneyimli kullanıcılar |

---

## 🔧 Teknik Detaylar

### Kurulum Sırasında Oluşturulan Dosyalar

```
/opt/habernexus/
├── .env                          # Ortam değişkenleri
├── docker-compose.prod.yml       # Docker Compose yapılandırması
├── Dockerfile                    # Docker image tanımı
├── manage.py                     # Django yönetim scripti
├── requirements.txt              # Python bağımlılıkları
├── venv/                         # Python sanal ortamı (Traditional)
├── staticfiles/                  # Toplu statik dosyalar
├── media/                        # Kullanıcı yüklenen dosyalar
├── logs/                         # Uygulama logları
└── ...

/etc/systemd/system/
├── habernexus.service           # Django uygulaması servisi
├── habernexus-celery.service    # Celery worker servisi
└── habernexus-celery-beat.service # Celery Beat servisi

/etc/nginx/sites-available/
└── habernexus                   # Nginx yapılandırması

/var/log/habernexus/
├── gunicorn-access.log          # Gunicorn erişim logları
├── gunicorn-error.log           # Gunicorn hata logları
├── celery-worker.log            # Celery worker logları
└── celery-beat.log              # Celery Beat logları

/var/backups/habernexus/
└── backup_*.sql.gz              # Otomatik yedeklemeler

/usr/local/bin/
└── habernexus-health-check      # Health check scripti

/etc/cron.d/
├── habernexus-backup            # Günlük yedekleme
└── habernexus-health-check      # Health check cron job
```

### Oluşturulan Kullanıcı ve Gruplar

```bash
# Sistem kullanıcısı
habernexus:habernexus

# Dizin izinleri
/opt/habernexus          -> habernexus:habernexus (755)
/var/log/habernexus      -> habernexus:habernexus (755)
/var/backups/habernexus  -> habernexus:habernexus (755)
```

### Açılan Portlar

```
80   -> HTTP (Nginx)
443  -> HTTPS (Nginx)
5432 -> PostgreSQL (Docker: db container)
6379 -> Redis (Docker: redis container)
8000 -> Django (Docker: app container, localhost only)
```

---

## 📝 Kurulum Sırasında Sorulan Sorular

### 1. Kurulum Yöntemi
```
Kurulum yöntemi seçin:
  1) Docker Compose (Önerilen - Daha kolay yönetim)
  2) Traditional (Sistemde doğrudan kurulum)

Seçim (1 veya 2) [1]:
```
**Varsayılan:** 1 (Docker Compose)

### 2. Proje Dizini
```
Proje dizini [/opt/habernexus]:
```
**Varsayılan:** /opt/habernexus

### 3. Sistem Kullanıcısı
```
Sistem kullanıcısı [habernexus]:
```
**Varsayılan:** habernexus

### 4. Domain Adı
```
Domain adınız (örn: habernexus.com) [localhost]:
```
**Varsayılan:** localhost

### 5. Admin Email
```
Admin email adresi:
```
**Gerekli:** Boş olamaz

### 6. PostgreSQL Şifresi
```
PostgreSQL şifresi (en az 12 karakter, özel karakter içermemeli):
```
**Gerekli:** Minimum 12 karakter

### 7. Google Gemini API Key
```
Google Gemini API Key:
```
**Opsiyonel:** Boş bırakılabilir

### 8. SSL Sertifikası
```
SSL/TLS Sertifikası:
  1) Let's Encrypt (Üretim - Önerilen)
  2) Self-signed (Geliştirme)
  3) Şimdilik kurma

Seçim (1, 2 veya 3) [1]:
```
**Varsayılan:** 1 (Let's Encrypt)

### 9. Onay
```
Devam etmek istiyor musunuz? (y/n):
```
**Gerekli:** y veya n

---

## 🔍 Hata Ayıklama

### Kurulum Başarısız Olursa

1. **Logları kontrol et:**
   ```bash
   # Kurulum sırasında hata mesajını not et
   # Mesaj genellikle [✗] ile başlar
   ```

2. **Ön kontrolleri tekrar çalıştır:**
   ```bash
   # Root yetkisi
   sudo whoami
   
   # OS kontrolü
   cat /etc/os-release
   
   # İnternet bağlantısı
   ping 8.8.8.8
   ```

3. **Kurulumu temizle ve yeniden başla:**
   ```bash
   # Eski kurulumu sil (dikkatli olun!)
   sudo rm -rf /opt/habernexus
   
   # Kurulumu yeniden başla
   sudo bash scripts/setup.sh
   ```

### Yaygın Hatalar

| Hata | Çözüm |
|---|---|
| "This script must be run as root" | `sudo bash scripts/setup.sh` kullanın |
| "Ubuntu sistemi tespit edilemedi" | Ubuntu 22.04 veya 24.04 kullanın |
| "İnternet bağlantısı yok" | VM'nin internet erişimini kontrol edin |
| "PostgreSQL şifresi boş olamaz" | Güçlü bir şifre girin |
| "Nginx yapılandırma hatası" | Nginx loglarını kontrol edin |

---

## 🔄 Kurulum Sonrası Güncellemeler

### Script Güncelleme

```bash
# Projeyi güncelle
cd /opt/habernexus
git pull origin main

# Docker Compose kullanıyorsanız
docker-compose -f docker-compose.prod.yml up -d --build

# Traditional kullanıyorsanız
sudo systemctl restart habernexus
```

### Bağımlılıkları Güncelle

```bash
# Docker Compose
docker-compose -f /opt/habernexus/docker-compose.prod.yml exec app pip install --upgrade -r requirements.txt

# Traditional
sudo -u habernexus /opt/habernexus/venv/bin/pip install --upgrade -r /opt/habernexus/requirements.txt
```

---

## 📚 İlgili Belgeler

- **VM_KURULUM_REHBERI.md** - Detaylı VM kurulum rehberi
- **README.md** - Proje özeti
- **QUICK_START.md** - Hızlı başlangıç
- **docs/ARCHITECTURE.md** - Sistem mimarisi
- **docs/DEVELOPMENT.md** - Geliştirme rehberi

---

## 📞 Destek

- **GitHub:** https://github.com/sata2500/habernexus
- **Email:** salihtanriseven25@gmail.com

---

**Script Sürümü:** 1.0  
**Son Güncelleme:** 6 Aralık 2025  
**Durum:** ✅ Üretim Hazır
