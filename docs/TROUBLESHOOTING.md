# Haber Nexus - Sorun Giderme Rehberi

Bu rehber, kurulum veya kullanım sırasında karşılaşabileceğiniz yaygın sorunları ve çözümlerini içerir.

---

## ✅ Kurulum Sonrası Kontrol Listesi

Kurulumun başarılı olduğundan emin olmak için aşağıdaki kontrolleri yapın:

1.  **Servis Durumları:** Tüm servislerin `active (running)` olduğundan emin olun.
    ```bash
    sudo systemctl status habernexus habernexus-celery habernexus-celery-beat nginx postgresql redis-server
    ```

2.  **Web Sitesi Erişimi:** Tarayıcınızdan `http://[VM_IP_ADRESINIZ]` adresine gidin.

3.  **Admin Paneli:** `http://[VM_IP_ADRESINIZ]/admin/` adresine gidin ve giriş yapın.

4.  **Veritabanı Bağlantısı:** `sudo -u postgres psql -d habernexus -c "\dt"` komutu Django tablolarını listelemelidir.

5.  **Redis Bağlantısı:** `redis-cli ping` komutu `PONG` cevabını vermelidir.

---

## 🐛 Sık Karşılaşılan Sorunlar ve Çözümleri

### Sorun 1: 502 Bad Gateway

**Belirtiler:** Tarayıcıda "502 Bad Gateway" hatası.

**Olası Neden:** Gunicorn servisi çalışmıyor.

**Çözüm:**

```bash
# 1. Gunicorn servisini kontrol et
sudo systemctl status habernexus

# 2. Eğer failed durumundaysa, logları incele
sudo journalctl -u habernexus -n 100 --no-pager

# 3. Manuel olarak başlatmayı dene
sudo systemctl restart habernexus
```

### Sorun 2: Statik Dosyalar Yüklenmiyor (CSS/JS)

**Belirtiler:** Sayfa açılıyor ancak tasarımı bozuk.

**Olası Neden:** Statik dosyalar toplanamamış veya Nginx yolu yanlış.

**Çözüm:**

```bash
# 1. Statik dosyaları yeniden topla
sudo -u habernexus_user /var/www/habernexus/venv/bin/python manage.py collectstatic --noinput

# 2. Dosya izinlerini kontrol et
sudo chown -R habernexus_user:habernexus_user /var/www/habernexus/staticfiles/

# 3. Nginx\\'i yeniden başlat
sudo systemctl restart nginx
```

### Sorun 3: Celery Görevleri Çalışmıyor

**Belirtiler:** RSS kaynaklarından haber çekilmiyor.

**Olası Neden:** Celery worker veya beat servisi çalışmıyor, Redis bağlantısı yok.

**Çözüm:**

```bash
# 1. Celery servislerini kontrol et
sudo systemctl status habernexus-celery habernexus-celery-beat

# 2. Redis bağlantısını test et
redis-cli ping

# 3. Celery loglarını incele
sudo tail -f /var/log/habernexus/celery-worker.log

# 4. Servisleri yeniden başlat
sudo systemctl restart habernexus-celery habernexus-celery-beat
```

### Sorun 4: SSL Sertifikası Hatası (Certbot)

**Belirtiler:** `sudo certbot` komutu hata veriyor.

**Olası Neden:** Domain DNS kaydı doğru ayarlanmamış veya firewall engelliyor.

**Çözüm:**

```bash
# 1. DNS kaydını kontrol et
nslookup sizin-domain.com
# Cevap, VM IP adresiniz olmalı

# 2. Firewall kontrolü (80 ve 443 portları ALLOW olmalı)
sudo ufw status

# 3. Nginx\\'in çalıştığını kontrol et
sudo systemctl status nginx
```

---

## 🔍 Log Dosyaları ve İzleme

Sorunları teşhis etmek için log dosyaları en iyi dostunuzdur.

- **Gunicorn (Django):** `sudo tail -f /var/log/habernexus/gunicorn-error.log`
- **Celery Worker:** `sudo tail -f /var/log/habernexus/celery-worker.log`
- **Celery Beat:** `sudo tail -f /var/log/habernexus/celery-beat.log`
- **Nginx:** `sudo tail -f /var/log/nginx/error.log`
- **Systemd Journal:** `sudo journalctl -u habernexus -f`

---

## 📞 Destek

Sorun yaşamaya devam ediyorsanız, lütfen GitHub Issues üzerinden bir kayıt oluşturun:

[https://github.com/sata2500/habernexus/issues](https://github.com/sata2500/habernexus/issues)
