# Haber Nexus - Dağıtım Rehberi

Bu rehber, Haber Nexus projesini production ortamına nasıl dağıtacağınızı, bakımını nasıl yapacağınızı ve güvenliğini nasıl sağlayacağınızı açıklar.

---

## İçindekiler

1. [Ön Koşullar](#ön-koşullar)
2. [Production için Docker Compose Kullanımı](#production-için-docker-compose-kullanımı)
3. [Nginx ve SSL Yapılandırması](#nginx-ve-ssl-yapılandırması)
4. [Güvenlik En İyi Pratikleri](#güvenlik-en-iyi-pratikleri)
5. [Yedekleme ve Geri Yükleme](#yedekleme-ve-geri-yükleme)
6. [Güncelleme ve Bakım](#güncelleme-ve-bakım)
7. [CI/CD Pipeline](#cicd-pipeline)

---

## Ön Koşullar

- Ubuntu 22.04 LTS veya üstü bir sunucu
- Docker ve Docker Compose
- Bir alan adı (domain)
- Sunucuya SSH erişimi

---

## Production için Docker Compose Kullanımı

Production ortamı için `docker-compose.prod.yml` dosyası kullanılır. Bu dosya, `docker-compose.yml` dosyasını genişletir ve production için optimize edilmiş ayarlar ekler.

### Adımlar

1.  **Sunucuya bağlanın ve projeyi klonlayın.**

2.  **`.env` dosyasını production için yapılandırın:**
    ```env
    DEBUG=False
    ALLOWED_HOSTS=habernexus.com,www.habernexus.com
    # Diğer gizli bilgileri güvenli bir şekilde ayarlayın
    ```

3.  **Production konteynerlerini başlatın:**
    ```bash
    docker-compose -f docker-compose.prod.yml up -d --build
    ```

4.  **Veritabanını hazırlayın ve yönetici oluşturun:**
    ```bash
    docker-compose -f docker-compose.prod.yml exec app python manage.py migrate
    docker-compose -f docker-compose.prod.yml exec app python manage.py createsuperuser
    ```

5.  **Statik dosyaları toplayın:**
    ```bash
    docker-compose -f docker-compose.prod.yml exec app python manage.py collectstatic --noinput
    ```

---

## Nginx ve SSL Yapılandırması

### Let\'s Encrypt ile SSL Sertifikası Alma

1.  **Certbot Kurulumu:**
    ```bash
    sudo apt update
    sudo apt install certbot python3-certbot-nginx
    ```

2.  **Nginx Yapılandırması:**
    `config/nginx.conf` dosyasını düzenleyerek `server_name` direktifini alan adınızla değiştirin.

3.  **Certbot Çalıştırma:**
    ```bash
    sudo certbot --nginx -d habernexus.com -d www.habernexus.com
    ```
    Certbot, Nginx yapılandırmanızı otomatik olarak güncelleyecek ve sertifikaları alacaktır.

4.  **Sertifika Yenileme:**
    Let\'s Encrypt sertifikaları 90 gün geçerlidir. Certbot, otomatik yenileme için bir cron job oluşturur. `sudo certbot renew --dry-run` komutu ile yenileme işlemini test edebilirsiniz.

---

## Güvenlik En İyi Pratikleri

- **`.env` Dosyasını Güvende Tutun:** Asla versiyon kontrol sistemine eklemeyin.
- **Güçlü Şifreler Kullanın:** Veritabanı, admin paneli ve diğer servisler için güçlü ve benzersiz şifreler kullanın.
- **Sunucuyu Güncel Tutun:** `sudo apt update && sudo apt upgrade` komutları ile sunucunuzu düzenli olarak güncelleyin.
- **Firewall Kullanın:** `ufw` gibi bir firewall ile sadece gerekli portlara (80, 443, 22) izin verin.
- **SSH Erişimini Kısıtlayın:** Şifre ile SSH erişimini devre dışı bırakıp sadece SSH anahtarı ile erişime izin verin.

---

## Yedekleme ve Geri Yükleme

### Veritabanı Yedekleme

```bash
docker-compose -f docker-compose.prod.yml exec db pg_dump -U habernexus -d habernexus > backup_$(date +%F).sql
```

### Medya Dosyalarını Yedekleme

```bash
tar -czf media_backup_$(date +%F).tar.gz ./media
```

### Otomatik Yedekleme

Bu komutları bir cron job olarak ayarlayarak yedekleme işlemini otomatikleştirebilirsiniz.

### Geri Yükleme

- **Veritabanı:**
  ```bash
  cat backup.sql | docker-compose -f docker-compose.prod.yml exec -T db psql -U habernexus -d habernexus
  ```
- **Medya Dosyaları:**
  ```bash
  tar -xzf media_backup.tar.gz
  ```

---

## Güncelleme ve Bakım

### Projeyi Güncelleme

1.  **En son kodu çekin:**
    ```bash
    git pull origin main
    ```

2.  **Yeni imajları oluşturun:**
    ```bash
    docker-compose -f docker-compose.prod.yml build
    ```

3.  **Servisleri yeniden başlatın:**
    ```bash
    docker-compose -f docker-compose.prod.yml up -d
    ```

4.  **Veritabanı değişikliklerini uygulayın:**
    ```bash
    docker-compose -f docker-compose.prod.yml exec app python manage.py migrate
    ```

### Bakım Modu

Bakım sırasında sitenin erişimini geçici olarak kapatmak için Nginx yapılandırmanıza aşağıdaki gibi bir kural ekleyebilirsiniz:

```nginx
location / {
    if (-f /path/to/maintenance.flag) {
        return 503;
    }
    # ... diğer kurallar
}
```

---

## CI/CD Pipeline

Proje, GitHub Actions kullanarak bir CI/CD pipeline içerir. Bu pipeline, her `push` işleminde aşağıdaki adımları otomatik olarak çalıştırır:

- **Test:** `pytest` ile tüm testleri çalıştırır.
- **Kod Kalitesi:** `flake8`, `black` ve `isort` ile kod standartlarını kontrol eder.
- **Güvenlik Taraması:** `bandit` ile potansiyel güvenlik açıklarını tarar.
- **Docker İmajı Oluşturma:** Yeni bir Docker imajı oluşturur ve Docker Hub\a push eder (isteğe bağlı).
- **Sunucuya Dağıtım:** SSH üzerinden sunucuya bağlanır ve `docker-compose pull && docker-compose up -d` komutlarını çalıştırır (isteğe bağlı).

Detaylar için `.github/workflows/` klasöründeki dosyalara bakın.
