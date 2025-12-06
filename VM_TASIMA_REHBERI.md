# Haber Nexus - VM Taşıma Rehberi

**Tarih:** 6 Aralık 2025  
**Geliştirici:** Salih TANRISEVEN  
**Email:** salihtanriseven25@gmail.com

---

## 📋 İçindekiler

1. [Genel Bakış](#genel-bakış)
2. [Taşıma Yöntemleri](#taşıma-yöntemleri)
3. [Yedekleme Oluşturma](#yedekleme-oluşturma)
4. [Yeni VM'ye Kurulum](#yeni-vme-kurulum)
5. [Yedeklemeden Geri Yükleme](#yedeklemeden-geri-yükleme)
6. [Doğrulama ve Test](#doğrulama-ve-test)
7. [Sorun Giderme](#sorun-giderme)

---

## 🎯 Genel Bakış

Bu rehber, Haber Nexus uygulamasını bir VM'den başka bir VM'ye taşımanız için adım adım talimatlar sağlar. Taşıma işlemi şunları içerir:

- **Veritabanı:** Tüm haber, yazar, kategori ve ayar verilerini taşır
- **Dosyalar:** Medya dosyaları, statik dosyalar ve proje dosyalarını taşır
- **Konfigürasyon:** .env dosyası ve tüm ayarları taşır
- **Sistem:** Systemd servisleri, Nginx yapılandırması vb.

### Taşıma Süresi
- **Yedekleme:** 5-10 dakika
- **Kurulum:** 10-20 dakika
- **Geri Yükleme:** 5-10 dakika
- **Toplam:** 20-40 dakika

---

## 🔄 Taşıma Yöntemleri

### Yöntem 1: Yedekleme + Geri Yükleme (Önerilen)

**Avantajları:**
- ✅ Orijinal VM'yi etkilemez
- ✅ Yedekleme dosyasını saklayabilirsiniz
- ✅ Hata durumunda geri dönüş yapabilirsiniz
- ✅ Birden fazla VM'ye taşıyabilirsiniz

**Dezavantajları:**
- ❌ Daha uzun sürüyor
- ❌ Daha fazla disk alanı gerekiyor

### Yöntem 2: Doğrudan Taşıma (rsync)

**Avantajları:**
- ✅ Daha hızlı
- ✅ Daha az disk alanı

**Dezavantajları:**
- ❌ Orijinal VM'yi etkileyebilir
- ❌ Yedekleme yapılmaz

---

## 📦 Yedekleme Oluşturma

### Adım 1: Orijinal VM'de Yedekleme Oluştur

SSH ile orijinal VM'ye bağlanın:

```bash
ssh -i ~/.ssh/habernexus_key ubuntu@ORIGINAL_VM_IP
```

Yedekleme scriptini çalıştırın:

```bash
cd /opt/habernexus
sudo bash scripts/backup-full.sh /opt/habernexus
```

Script aşağıdaki dosyaları oluşturacak:

```
/opt/habernexus/.backups/
└── habernexus_backup_YYYYMMDD_HHMMSS/
    ├── database.sqlite3 (veya database.sql.gz)
    ├── .env.backup
    ├── staticfiles.tar.gz
    ├── project.tar.gz
    ├── backup.info
    ├── checksums.md5
    └── habernexus_backup_YYYYMMDD_HHMMSS.tar.gz
```

### Adım 2: Yedekleme Dosyasını İndir

Yedekleme arşivini yerel bilgisayarınıza indirin:

```bash
scp -i ~/.ssh/habernexus_key \
    ubuntu@ORIGINAL_VM_IP:/opt/habernexus/.backups/habernexus_backup_*.tar.gz \
    ~/habernexus_backup.tar.gz
```

### Adım 3: Yedekleme Dosyasını Yeni VM'ye Yükle

Yedekleme dosyasını yeni VM'ye yükleyin:

```bash
scp -i ~/.ssh/new_vm_key \
    ~/habernexus_backup.tar.gz \
    ubuntu@NEW_VM_IP:/tmp/
```

---

## 🚀 Yeni VM'ye Kurulum

### Adım 1: Yeni VM Oluştur

Google Cloud Console'da yeni bir VM oluşturun (bkz. [VM_KURULUM_REHBERI.md](VM_KURULUM_REHBERI.md))

### Adım 2: Yeni VM'ye Bağlan

```bash
ssh -i ~/.ssh/new_vm_key ubuntu@NEW_VM_IP
```

### Adım 3: Projeyi Klonla

```bash
git clone https://github.com/sata2500/habernexus.git
cd habernexus
```

### Adım 4: Kurulum Scriptini Çalıştır

```bash
sudo bash scripts/setup.sh
```

Kurulum sırasında:
- **Kurulum Yöntemi:** 1 (Docker Compose)
- **Domain:** Yeni domain adınız
- **Email:** Admin email
- **PostgreSQL Şifresi:** Yeni şifre
- **SSL:** 1 (Let's Encrypt) veya 2 (Self-signed)

### Adım 5: Kurulumun Tamamlanmasını Bekle

Kurulum ~15-20 dakika sürecektir.

---

## 🔄 Yedeklemeden Geri Yükleme

### Adım 1: Yedekleme Dosyasını Çıkar

Yeni VM'de yedekleme dosyasını çıkartın:

```bash
cd /opt/habernexus
sudo tar -xzf /tmp/habernexus_backup.tar.gz -C /tmp/
```

### Adım 2: Geri Yükleme Scriptini Çalıştır

```bash
sudo bash scripts/restore-full.sh /tmp/habernexus_backup_YYYYMMDD_HHMMSS /opt/habernexus
```

Script soracak:
```
Bu yedeklemeyi geri yüklemek istediğinize emin misiniz? (y/n): y
```

`y` yazıp Enter tuşuna basın.

### Adım 3: Geri Yüklemenin Tamamlanmasını Bekle

Geri yükleme ~5-10 dakika sürecektir.

---

## ✅ Doğrulama ve Test

### Adım 1: Servisleri Kontrol Et

```bash
# Docker Compose kullanıyorsanız
docker-compose -f /opt/habernexus/docker-compose.prod.yml ps

# Traditional kullanıyorsanız
sudo systemctl status habernexus habernexus-celery habernexus-celery-beat
```

### Adım 2: Veritabanını Kontrol Et

```bash
# Docker Compose
docker-compose -f /opt/habernexus/docker-compose.prod.yml exec app python manage.py shell

# Traditional
cd /opt/habernexus
source venv/bin/activate
python manage.py shell
```

Django shell'de:

```python
from django.contrib.auth.models import User
print(f"Toplam kullanıcı: {User.objects.count()}")

from news.models import Article
print(f"Toplam makale: {Article.objects.count()}")

from news.models import RSSSource
print(f"Toplam RSS kaynağı: {RSSSource.objects.count()}")

exit()
```

### Adım 3: Web Sitesini Test Et

Tarayıcıda açın:

```
https://NEW_DOMAIN/
https://NEW_DOMAIN/admin/
```

Admin paneline giriş yapın:
- **Kullanıcı:** admin
- **Şifre:** Orijinal admin şifresi

### Adım 4: Logları Kontrol Et

```bash
# Docker Compose
docker-compose -f /opt/habernexus/docker-compose.prod.yml logs -f app

# Traditional
sudo journalctl -u habernexus -f
```

---

## 🔍 Sorun Giderme

### Sorun: "Permission denied" hatası

**Çözüm:**
```bash
sudo chown -R ubuntu:ubuntu /opt/habernexus
sudo chmod -R 755 /opt/habernexus
sudo chmod 600 /opt/habernexus/.env
```

### Sorun: Veritabanı bağlantı hatası

**Çözüm:**
```bash
# Veritabanı dosyasının var olduğunu kontrol et
ls -lh /opt/habernexus/db.sqlite3

# İzinleri kontrol et
sudo chmod 644 /opt/habernexus/db.sqlite3
```

### Sorun: Statik dosyalar yüklenmedi

**Çözüm:**
```bash
# Docker Compose
docker-compose -f /opt/habernexus/docker-compose.prod.yml exec app python manage.py collectstatic

# Traditional
cd /opt/habernexus
source venv/bin/activate
python manage.py collectstatic
```

### Sorun: Admin şifresi unutuldu

**Çözüm:**
```bash
# Docker Compose
docker-compose -f /opt/habernexus/docker-compose.prod.yml exec app python manage.py changepassword admin

# Traditional
cd /opt/habernexus
source venv/bin/activate
python manage.py changepassword admin
```

---

## 📋 Hızlı Taşıma Kontrol Listesi

### Orijinal VM'de:
- [ ] Yedekleme scriptini çalıştır
- [ ] Yedekleme dosyasını doğrula
- [ ] Yedekleme dosyasını indir

### Yeni VM'de:
- [ ] Yeni VM oluştur
- [ ] SSH anahtarını ayarla
- [ ] Projeyi klonla
- [ ] Kurulum scriptini çalıştır
- [ ] Yedekleme dosyasını yükle
- [ ] Geri yükleme scriptini çalıştır
- [ ] Servisleri kontrol et
- [ ] Veritabanını doğrula
- [ ] Web sitesini test et
- [ ] Logları kontrol et

### Taşıma Sonrası:
- [ ] DNS'i güncelle (yeni domain için)
- [ ] SSL sertifikasını kontrol et
- [ ] Email ayarlarını kontrol et
- [ ] Backup cron job'unu kontrol et
- [ ] Monitoring'i kontrol et

---

## 🔐 Güvenlik Notları

### Yedekleme Dosyasını Güvenle Saklayın

Yedekleme dosyası tüm veritabanı ve konfigürasyon verilerini içerir. Güvenli bir yerde saklayın:

```bash
# Yedekleme dosyasını şifrele
gpg --symmetric habernexus_backup.tar.gz

# Şifrelenmiş dosyayı kopyala
cp habernexus_backup.tar.gz.gpg /secure/location/

# Orijinal dosyayı sil
rm habernexus_backup.tar.gz
```

### .env Dosyasını Kontrol Edin

Geri yükleme sonrası .env dosyasını kontrol edin:

```bash
cat /opt/habernexus/.env
```

Aşağıdaki değerleri güncelleyin:
- `DOMAIN` - Yeni domain adı
- `ALLOWED_HOSTS` - Yeni IP/domain
- `DB_PASSWORD` - Yeni veritabanı şifresi (PostgreSQL kullanıyorsanız)
- `GOOGLE_API_KEY` - API key (gerekirse)

### DNS Ayarlarını Güncelleyin

Yeni VM'nin IP adresine işaret etmek için DNS kayıtlarını güncelleyin:

```
A Record: habernexus.com -> NEW_VM_IP
```

---

## 📞 Yardım

Sorun yaşarsanız:

1. **Logları kontrol edin:**
   ```bash
   sudo tail -f /var/log/habernexus/gunicorn-error.log
   ```

2. **Veritabanını doğrulayın:**
   ```bash
   python manage.py check
   ```

3. **Servisleri yeniden başlatın:**
   ```bash
   sudo systemctl restart habernexus
   ```

4. **GitHub Issues:** https://github.com/sata2500/habernexus/issues

5. **Email:** salihtanriseven25@gmail.com

---

## 📌 Hızlı Komutlar

```bash
# Yedekleme oluştur
sudo bash scripts/backup-full.sh /opt/habernexus

# Yedeklemeyi geri yükle
sudo bash scripts/restore-full.sh /tmp/habernexus_backup_YYYYMMDD_HHMMSS /opt/habernexus

# Servisleri yeniden başlat
sudo systemctl restart habernexus habernexus-celery habernexus-celery-beat

# Logları göster
sudo journalctl -u habernexus -f

# Veritabanını doğrula
python manage.py check

# Admin şifresi değiştir
python manage.py changepassword admin
```

---

**Taşıma işlemi başarıyla tamamlandı! 🎉**

Artık Haber Nexus uygulamanız yeni VM'de çalışıyor. Herhangi bir sorun yaşarsanız, yukarıdaki sorun giderme bölümüne bakın.
