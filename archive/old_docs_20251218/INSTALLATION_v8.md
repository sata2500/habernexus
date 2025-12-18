# HaberNexus v8.0 - Kurulum Kılavuzu

## 🚀 Hızlı Başlangıç

HaberNexus'u kurmak için tek bir komut yeterli:

```bash
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/one_click_install.sh | sudo bash
```

Bu komut:
- Tüm bağımlılıkları otomatik yükler
- Docker ve Docker Compose kurar
- İnteraktif yapılandırma sihirbazını başlatır
- Sistemi tam otomatik olarak kurar

---

## 📋 İçindekiler

1. [Sistem Gereksinimleri](#sistem-gereksinimleri)
2. [Kurulum Seçenekleri](#kurulum-seçenekleri)
3. [Adım Adım Kurulum](#adım-adım-kurulum)
4. [Yapılandırma](#yapılandırma)
5. [Cloudflare Ayarları](#cloudflare-ayarları)
6. [Kurulum Sonrası](#kurulum-sonrası)
7. [Sorun Giderme](#sorun-giderme)
8. [Yönetim Komutları](#yönetim-komutları)

---

## 💻 Sistem Gereksinimleri

### Minimum Gereksinimler

| Bileşen | Minimum | Önerilen |
|---------|---------|----------|
| CPU | 2 çekirdek | 4+ çekirdek |
| RAM | 2 GB | 4+ GB |
| Disk | 15 GB | 50+ GB SSD |
| OS | Ubuntu 20.04 | Ubuntu 22.04/24.04 |

### Desteklenen İşletim Sistemleri

- ✅ Ubuntu 22.04 LTS (Önerilen)
- ✅ Ubuntu 24.04 LTS
- ✅ Ubuntu 20.04 LTS
- ⚠️ Debian 11/12 (Sınırlı destek)

### Gerekli Portlar

| Port | Servis | Açıklama |
|------|--------|----------|
| 80 | HTTP | Web trafiği |
| 443 | HTTPS | Güvenli web trafiği |
| 5432 | PostgreSQL | Veritabanı (dahili) |
| 6379 | Redis | Cache (dahili) |
| 8000 | Django | Uygulama (dahili) |

---

## 🔧 Kurulum Seçenekleri

### Seçenek 1: One-Click Kurulum (Önerilen)

En basit yöntem - tek komutla kurulum:

```bash
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/one_click_install.sh | sudo bash
```

### Seçenek 2: İnteraktif Kurulum

Adım adım rehberli kurulum:

```bash
git clone https://github.com/sata2500/habernexus.git
cd habernexus
sudo bash install_v8.sh --auto
```

### Seçenek 3: Hızlı Kurulum

Varsayılan değerlerle hızlı kurulum:

```bash
sudo bash install_v8.sh --quick
```

### Seçenek 4: Yapılandırma Dosyası ile Kurulum

Önceden hazırlanmış yapılandırma ile kurulum:

```bash
# Yapılandırma dosyasını düzenleyin
cp install_config.example.yml install_config.yml
nano install_config.yml

# Kurulumu başlatın
sudo bash install_v8.sh --config install_config.yml
```

### Seçenek 5: Web Wizard ile Kurulum

Tarayıcı tabanlı görsel kurulum:

```bash
sudo bash install_v8.sh --wizard
```

---

## 📝 Adım Adım Kurulum

### 1. Sistem Kontrolü

Kurulum öncesi sisteminizi kontrol edin:

```bash
sudo bash pre_install_check_v8.sh
```

Bu script şunları kontrol eder:
- İşletim sistemi uyumluluğu
- CPU ve RAM yeterliliği
- Disk alanı
- İnternet bağlantısı
- Port durumu
- Docker kurulumu

### 2. Kurulumu Başlatın

```bash
sudo bash install_v8.sh --auto
```

### 3. Bilgileri Girin

Kurulum sihirbazı şu bilgileri soracak:

1. **Domain Adı**: Sitenizin adresi (örn: habernexus.com)
2. **Admin E-posta**: Yönetici e-posta adresi
3. **Admin Kullanıcı Adı**: Admin panel giriş adı
4. **Admin Şifresi**: Güçlü bir şifre (veya otomatik oluşturulsun)
5. **Cloudflare API Token**: DNS yönetimi için
6. **Cloudflare Tunnel Token**: Güvenli bağlantı için

### 4. Kurulumu Bekleyin

Kurulum otomatik olarak:
- Docker ve bağımlılıkları yükler
- Veritabanını oluşturur
- Uygulamayı derler
- Servisleri başlatır
- SSL sertifikası alır

Tipik kurulum süresi: **5-15 dakika**

### 5. Kurulum Tamamlandı

Kurulum tamamlandığında şunları göreceksiniz:
- Site adresi
- Admin panel adresi
- Giriş bilgileri
- Yönetim komutları

---

## ⚙️ Yapılandırma

### Ortam Değişkenleri

Kurulum sonrası yapılandırma `/opt/habernexus/.env` dosyasındadır:

```bash
# Dosyayı düzenleyin
sudo nano /opt/habernexus/.env

# Değişiklikleri uygulayın
cd /opt/habernexus
sudo docker-compose restart
```

### Önemli Ayarlar

| Değişken | Açıklama |
|----------|----------|
| `DOMAIN` | Site domain adresi |
| `DEBUG` | Hata ayıklama modu (production'da False) |
| `SECRET_KEY` | Django güvenlik anahtarı |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API erişimi |
| `CLOUDFLARE_TUNNEL_TOKEN` | Cloudflare Tunnel bağlantısı |
| `GOOGLE_API_KEY` | Google AI API anahtarı |

---

## ☁️ Cloudflare Ayarları

### Cloudflare API Token Oluşturma

1. [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens) adresine gidin
2. **Create Token** butonuna tıklayın
3. **Edit zone DNS** template'ini seçin
4. Zone Resources bölümünde domain'inizi seçin
5. Token'ı oluşturun ve kopyalayın

### Cloudflare Tunnel Oluşturma

1. [Cloudflare Zero Trust](https://one.dash.cloudflare.com) adresine gidin
2. **Networks** → **Tunnels** bölümüne gidin
3. **Create a Tunnel** butonuna tıklayın
4. Tunnel adını girin (örn: habernexus-tunnel)
5. **Cloudflared** seçeneğini seçin
6. Token'ı kopyalayın

### DNS Ayarları

Cloudflare DNS'te şu kayıtları ekleyin:

| Tip | Ad | İçerik | Proxy |
|-----|-----|--------|-------|
| CNAME | @ | tunnel-id.cfargotunnel.com | ✅ |
| CNAME | www | @ | ✅ |

---

## 🎉 Kurulum Sonrası

### Erişim Adresleri

- **Ana Site**: `https://yourdomain.com`
- **Admin Panel**: `https://yourdomain.com/admin`
- **API**: `https://yourdomain.com/api`
- **Flower (Celery)**: `https://yourdomain.com/flower`

### İlk Adımlar

1. Admin paneline giriş yapın
2. Site ayarlarını yapılandırın
3. Haber kaynaklarını ekleyin
4. Kategorileri düzenleyin
5. İlk haberleri çekin

### Servis Durumu Kontrolü

```bash
# Tüm servislerin durumu
bash /opt/habernexus/manage_habernexus_v8.sh status

# Sağlık kontrolü
bash /opt/habernexus/manage_habernexus_v8.sh health

# Logları görüntüle
bash /opt/habernexus/manage_habernexus_v8.sh logs app
```

---

## 🔧 Sorun Giderme

### Yaygın Sorunlar

#### Kurulum Başlamıyor

```bash
# Root yetkisi ile çalıştırın
sudo bash install_v8.sh --auto

# Sistem kontrolü yapın
sudo bash pre_install_check_v8.sh
```

#### Docker Başlamıyor

```bash
# Docker servisini başlatın
sudo systemctl start docker
sudo systemctl enable docker

# Docker durumunu kontrol edin
sudo systemctl status docker
```

#### Servisler Çalışmıyor

```bash
# Container durumunu kontrol edin
cd /opt/habernexus
sudo docker-compose ps

# Logları inceleyin
sudo docker-compose logs app
sudo docker-compose logs postgres
```

#### Veritabanı Bağlantı Hatası

```bash
# PostgreSQL durumunu kontrol edin
sudo docker-compose exec postgres pg_isready -U habernexus

# Veritabanını yeniden başlatın
sudo docker-compose restart postgres
```

#### SSL Sertifika Sorunu

```bash
# Caddy loglarını kontrol edin
sudo docker-compose logs caddy

# DNS ayarlarını doğrulayın
nslookup yourdomain.com
```

### Tanılama Komutu

Kapsamlı sorun giderme için:

```bash
bash /opt/habernexus/manage_habernexus_v8.sh troubleshoot
```

### Log Dosyaları

- Kurulum logları: `/var/log/habernexus/install_v8_*.log`
- Uygulama logları: `docker-compose logs app`
- Veritabanı logları: `docker-compose logs postgres`

---

## 📚 Yönetim Komutları

### Servis Yönetimi

```bash
# Servisleri başlat
bash manage_habernexus_v8.sh start

# Servisleri durdur
bash manage_habernexus_v8.sh stop

# Servisleri yeniden başlat
bash manage_habernexus_v8.sh restart

# Belirli servisi yeniden başlat
bash manage_habernexus_v8.sh restart app
```

### Veritabanı İşlemleri

```bash
# Yedek al
bash manage_habernexus_v8.sh backup-db

# Yedekten geri yükle
bash manage_habernexus_v8.sh restore-db /path/to/backup.sql

# Migrasyonları çalıştır
bash manage_habernexus_v8.sh migrate
```

### Kullanıcı Yönetimi

```bash
# Yeni admin oluştur
bash manage_habernexus_v8.sh create-user admin admin@example.com

# Şifre değiştir
bash manage_habernexus_v8.sh change-password admin

# Kullanıcıları listele
bash manage_habernexus_v8.sh list-users
```

### Bakım İşlemleri

```bash
# Sistem temizliği
bash manage_habernexus_v8.sh cleanup

# Sistemi güncelle
bash manage_habernexus_v8.sh update

# Tam yedek al
bash manage_habernexus_v8.sh full-backup
```

---

## 📞 Destek

- **GitHub Issues**: [github.com/sata2500/habernexus/issues](https://github.com/sata2500/habernexus/issues)
- **E-posta**: salihtanriseven25@gmail.com
- **Dökümanlar**: [docs/](./docs/)

---

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](../LICENSE) dosyasına bakın.

---

**HaberNexus v8.0** - Modern, Otomatik, Güvenli

*Geliştirici: Salih TANRISEVEN*
*Tarih: Aralık 2025*
