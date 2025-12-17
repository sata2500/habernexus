# HaberNexus v7.0 - Kurulum Rehberi

> **Tam Otomatik Kurulum • Kullanıcı Dostu • Sorunsuz Deneyim**

## 📋 İçindekiler

1. [Sistem Gereksinimleri](#sistem-gereksinimleri)
2. [Hızlı Başlangıç](#hızlı-başlangıç)
3. [Kurulum Modları](#kurulum-modları)
4. [Adım Adım Kurulum](#adım-adım-kurulum)
5. [Kurulum Sonrası](#kurulum-sonrası)
6. [Sorun Giderme](#sorun-giderme)
7. [Yönetim Komutları](#yönetim-komutları)

---

## Sistem Gereksinimleri

### Donanım
- **CPU**: 2+ çekirdek (4+ önerilir)
- **RAM**: 4GB minimum (8GB+ önerilir)
- **Disk**: 20GB+ boş alan
- **İnternet**: Stabil bağlantı

### İşletim Sistemi
- Ubuntu 20.04 LTS ✓
- Ubuntu 22.04 LTS ✓
- Ubuntu 24.04 LTS ✓

### Yazılım Bağımlılıkları
Script otomatik olarak kurar:
- Docker
- Docker Compose
- Git
- Python 3
- curl/wget

---

## Hızlı Başlangıç

### 1️⃣ En Hızlı Yol (Önerilen)

```bash
# Repo'yu klonla
git clone https://github.com/sata2500/habernexus.git
cd habernexus

# Hızlı kurulum yap
sudo bash install_v7.sh --quick
```

**Süre**: ~5-10 dakika  
**Uygun**: Üretim ortamı, standart kurulum

### 2️⃣ Özel Yapılandırma

```bash
sudo bash install_v7.sh --custom
```

**Süre**: ~10-15 dakika  
**Uygun**: Özel gereksinimler, manuel yapılandırma

### 3️⃣ Geliştirme Modu

```bash
sudo bash install_v7.sh --dev --debug
```

**Süre**: ~10-15 dakika  
**Uygun**: Geliştirme, test ortamı, hata ayıklama

---

## Kurulum Modları

### 🚀 Quick Mode (Hızlı)

**Özellikler:**
- Önceden tanımlanmış değerler
- Minimum etkileşim
- Üretim için hazır
- Önerilen seçenek

**Kullanım:**
```bash
sudo bash install_v7.sh --quick
```

**Varsayılan Değerler:**
- Domain: `habernexus.local`
- Admin: `admin`
- Database: Otomatik şifre

### ⚙️ Custom Mode (Özel)

**Özellikler:**
- İnteraktif yapılandırma
- Tam kontrol
- Adım adım rehberlik
- Doğrulama kontrolleri

**Kullanım:**
```bash
sudo bash install_v7.sh --custom
```

**Sorular:**
1. Domain adı
2. Admin e-posta
3. Admin kullanıcı adı
4. Admin şifresi
5. Cloudflare API Token
6. Cloudflare Tunnel Token

### 🔧 Development Mode (Geliştirme)

**Özellikler:**
- Debug modu etkin
- Detaylı logging
- Geliştirme ayarları
- Test için uygun

**Kullanım:**
```bash
sudo bash install_v7.sh --dev --debug
```

---

## Adım Adım Kurulum

### Adım 1: Sistem Hazırlığı

```bash
# Sistem güncellemeleri
sudo apt-get update
sudo apt-get upgrade -y

# Git klonla
git clone https://github.com/sata2500/habernexus.git
cd habernexus
```

### Adım 2: Kurulum Script'ini Çalıştır

```bash
# Hızlı kurulum (önerilen)
sudo bash install_v7.sh --quick

# VEYA özel kurulum
sudo bash install_v7.sh --custom
```

### Adım 3: Kurulum İzle

Script otomatik olarak:
- ✓ Sistem kontrollerini çalıştırır
- ✓ Bağımlılıkları kurar
- ✓ Docker imajlarını oluşturur
- ✓ Servisleri başlatır
- ✓ Veritabanını başlatır
- ✓ Admin kullanıcısını oluşturur

### Adım 4: Kurulum Tamamlandı

Script başarılı olduğunda:
- ✅ Başarı mesajı gösterilir
- ✅ Erişim bilgileri gösterilir
- ✅ Sonraki adımlar listelenir

---

## Kurulum Sonrası

### 🌐 Uygulamaya Erişim

```
Admin Paneli:  https://habernexus.local/admin
Ana Sayfa:     https://habernexus.local
API:           https://habernexus.local/api
```

### 👤 Admin Giriş

```
Kullanıcı Adı: admin
Şifre:         (kurulum sırasında belirlediğiniz)
```

### 📝 İlk Yapılandırma

1. Admin paneline giriş yap
2. RSS kaynakları ekle
3. İçerik ayarlarını yapılandır
4. Celery görevlerini etkinleştir
5. Sistem sağlığını kontrol et

### 🔐 Güvenlik Önerileri

1. **Şifreyi Değiştir**
   ```bash
   bash manage_habernexus.sh change-password admin yeni_sifre
   ```

2. **Yeni Admin Kullanıcı Oluştur**
   ```bash
   bash manage_habernexus.sh create-user yeni_admin email@example.com sifre
   ```

3. **SSL Sertifikasını Kontrol Et**
   ```bash
   curl -I https://habernexus.local
   ```

4. **Firewall Kuralları Ayarla**
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

---

## Sorun Giderme

### ❌ Servisler Başlamıyor

**Kontrol et:**
```bash
bash manage_habernexus.sh status
bash manage_habernexus.sh logs app
```

**Çözüm:**
```bash
# Servisleri yeniden başlat
bash manage_habernexus.sh restart

# Tüm Docker kaynaklarını temizle
bash manage_habernexus.sh cleanup-docker

# Yeniden başlat
bash manage_habernexus.sh start
```

### ❌ Veritabanı Bağlantı Hatası

**Kontrol et:**
```bash
bash manage_habernexus.sh health
```

**Çözüm:**
```bash
# PostgreSQL loglarını kontrol et
bash manage_habernexus.sh logs postgres

# Veritabanını yeniden başlat
bash manage_habernexus.sh restart postgres

# Migrasyonları çalıştır
bash manage_habernexus.sh migrate
```

### ❌ Port Zaten Kullanımda

**Kontrol et:**
```bash
sudo lsof -i :80
sudo lsof -i :443
```

**Çözüm:**
```bash
# Mevcut servisleri durdur
bash manage_habernexus.sh stop

# Portları boşalt
sudo systemctl stop nginx  # veya başka servis
sudo systemctl stop apache2

# Yeniden başlat
bash manage_habernexus.sh start
```

### ❌ SSL Sertifikası Sorunu

**Kontrol et:**
```bash
bash manage_habernexus.sh logs caddy
```

**Çözüm:**
```bash
# Caddy'yi yeniden başlat
bash manage_habernexus.sh restart caddy

# Sertifikaları temizle ve yeniden oluştur
docker-compose exec -T caddy rm -rf /data/caddy
bash manage_habernexus.sh restart caddy
```

### ❌ Cloudflare Tunnel Bağlantısı Başarısız

**Kontrol et:**
```bash
bash manage_habernexus.sh logs cloudflared
```

**Çözüm:**
1. Token'ı kontrol et
2. .env dosyasını güncelle
3. Servisleri yeniden başlat

```bash
# .env dosyasını düzenle
nano /opt/habernexus/.env

# Servisleri yeniden başlat
bash manage_habernexus.sh restart cloudflared
```

### 📊 Sistem Tanılaması

```bash
# Tam sistem kontrolü
bash manage_habernexus.sh troubleshoot

# Disk kullanımı
df -h

# Bellek kullanımı
free -h

# Docker sistem bilgisi
docker system df
```

---

## Yönetim Komutları

### 📊 Durum & İzleme

```bash
# Servis durumunu göster
bash manage_habernexus.sh status

# Logları görüntüle
bash manage_habernexus.sh logs app
bash manage_habernexus.sh logs postgres
bash manage_habernexus.sh logs -f  # Canlı izle

# Sistem sağlığını kontrol et
bash manage_habernexus.sh health

# Sorun giderme
bash manage_habernexus.sh troubleshoot
```

### 🔄 Servis Yönetimi

```bash
# Tüm servisleri başlat
bash manage_habernexus.sh start

# Tüm servisleri durdur
bash manage_habernexus.sh stop

# Tüm servisleri yeniden başlat
bash manage_habernexus.sh restart

# Belirli servisi yeniden başlat
bash manage_habernexus.sh restart postgres
bash manage_habernexus.sh restart app
bash manage_habernexus.sh restart caddy
```

### 💾 Veritabanı

```bash
# Veritabanını yedekle
bash manage_habernexus.sh backup-db

# Veritabanını geri yükle
bash manage_habernexus.sh restore-db /path/to/backup.sql

# Migrasyonları çalıştır
bash manage_habernexus.sh migrate
```

### 👤 Kullanıcı Yönetimi

```bash
# Admin kullanıcı oluştur
bash manage_habernexus.sh create-user admin admin@example.com sifre

# Şifreyi değiştir
bash manage_habernexus.sh change-password admin yeni_sifre

# Tüm kullanıcıları listele
bash manage_habernexus.sh list-users
```

### 🧹 Bakım

```bash
# Eski logları sil
bash manage_habernexus.sh cleanup-logs

# Docker kaynaklarını temizle
bash manage_habernexus.sh cleanup-docker

# Projeyi güncelle
bash manage_habernexus.sh update
```

### 💾 Yedekleme

```bash
# Tam yedekleme yap
bash manage_habernexus.sh full-backup

# Mevcut yedeklemeleri listele
bash manage_habernexus.sh list-backups
```

---

## 🆘 Destek & Yardım

### 📚 Kaynaklar

- **Dokümantasyon**: https://docs.habernexus.com
- **GitHub Repo**: https://github.com/sata2500/habernexus
- **Sorunlar**: https://github.com/sata2500/habernexus/issues
- **Tartışmalar**: https://github.com/sata2500/habernexus/discussions

### 📧 İletişim

- **E-posta**: salihtanriseven25@gmail.com
- **GitHub**: @sata2500

### 🐛 Hata Bildirme

Bir sorunla karşılaşırsa:

1. Logları kontrol et:
   ```bash
   bash manage_habernexus.sh troubleshoot
   ```

2. Sistem bilgisini topla:
   ```bash
   uname -a
   docker --version
   docker-compose --version
   ```

3. GitHub'da issue aç:
   - Hata mesajını ekle
   - Logları ekle
   - Sistem bilgisini ekle
   - Yeniden üretme adımlarını ekle

---

## 📝 Notlar

### Kurulum Günlükleri

Kurulum günlükleri şu konumlarda saklanır:
- **Kurulum Günlüğü**: `/var/log/habernexus/install_v7_*.log`
- **Yapılandırma**: `/var/log/habernexus/installation_config_*.conf`
- **Servis Günlükleri**: `docker-compose logs`

### Yedeklemeler

Yedeklemeler şu konumda saklanır:
- **Yedekleme Dizini**: `/opt/habernexus/.backups/`
- **Veritabanı Yedekleri**: `.sql` dosyaları
- **Tam Yedeklemeler**: `.tar.gz` arşivleri

### Yapılandırma Dosyaları

- **Ortam Değişkenleri**: `/opt/habernexus/.env`
- **Docker Compose**: `/opt/habernexus/docker-compose.yml`
- **Caddy Yapılandırması**: `/opt/habernexus/caddy/Caddyfile`

---

## ✅ Kontrol Listesi

Kurulum sonrası kontrol et:

- [ ] Servisler çalışıyor mu? (`bash manage_habernexus.sh status`)
- [ ] Admin paneline giriş yapabiliyor musun?
- [ ] SSL sertifikası geçerli mi?
- [ ] Veritabanı bağlantısı çalışıyor mu?
- [ ] Redis bağlantısı çalışıyor mu?
- [ ] Cloudflare Tunnel bağlı mı?
- [ ] Yedekleme yapıldı mı?
- [ ] Firewall kuralları ayarlandı mı?

---

## 🎉 Tebrikler!

HaberNexus v7.0 başarıyla kuruldu! 

Şimdi:
1. Admin paneline giriş yap
2. RSS kaynakları ekle
3. İçerik ayarlarını yapılandır
4. Sistem sağlığını izle

**Mutlu haber agregasyonu! 📰**

---

*Son güncelleme: 15 Aralık 2025*  
*Sürüm: 7.0*  
*Yazar: Salih TANRISEVEN*
