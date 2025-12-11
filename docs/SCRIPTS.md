# Haber Nexus - Script Dokümantasyonu

Bu rehber, projedeki script\lerin kullanımını ve işlevlerini açıklar.

---

## İçindekiler

1. [Kurulum Script\leri](#kurulum-scriptleri)
   - [setup.sh](#setupsh)
   - [setup-dev.sh](#setup-devsh)
2. [Yedekleme ve Geri Yükleme](#yedekleme-ve-geri-yükleme)
   - [backup.sh](#backupsh)
   - [restore.sh](#restoresh)
3. [Yardımcı Script\ler](#yardımcı-scriptler)
   - [health-check.sh](#health-checksh)

---

## Kurulum Script\leri

### setup.sh

**Amaç:** Production ortamına Docker tabanlı tam otomatik kurulum yapar.

**Kullanım:**
```bash
sudo bash scripts/setup.sh
```

**Özellikler:**
- Ubuntu 22.04/24.04 LTS desteği
- Docker ve Docker Compose kurulumu
- İnteraktif kurulum (domain, şifreler, API key)
- Otomatik .env dosyası oluşturma
- Docker container\larını başlatma
- SSL sertifikası (Let\'s Encrypt) kurulumu
- Detaylı loglama (`/var/log/habernexus_setup_*.log`)

### setup-dev.sh

**Amaç:** Geliştirme ortamını hızlıca kurar.

**Kullanım:**
```bash
bash scripts/setup-dev.sh
```

**Özellikler:**
- Python sanal ortamı oluşturma
- Gerekli bağımlılıkları yükleme
- SQLite veritabanı kullanımı
- Otomatik .env dosyası oluşturma
- Admin kullanıcısı oluşturma
- Testleri çalıştırma

---

## Yedekleme ve Geri Yükleme

### backup.sh

**Amaç:** Projenin tam yedeğini alır.

**Kullanım:**
```bash
sudo bash scripts/backup.sh
```

**Yedeklenenler:**
- PostgreSQL veritabanı
- Redis verisi
- Medya dosyaları
- .env dosyası

**Özellikler:**
- Yedekleri `/var/backups/habernexus` dizinine kaydeder.
- Otomatik olarak eski yedekleri (7 günden eski) siler.

### restore.sh

**Amaç:** Yedekten geri yükleme yapar.

**Kullanım:**
```bash
sudo bash scripts/restore.sh <yedek_dosyasi.tar.gz>
```

**Özellikler:**
- İnteraktif onay mekanizması
- Servisleri otomatik durdurma ve başlatma
- Veritabanı, Redis ve medya dosyalarını geri yükleme

---

## Yardımcı Script\ler

### health-check.sh

**Amaç:** Sistemin genel sağlık durumunu kontrol eder.

**Kullanım:**
```bash
sudo bash scripts/health-check.sh
```

**Kontroller:**
- Docker container durumları
- Servislerin çalışıp çalışmadığı
- Veritabanı ve Redis bağlantısı
- Web arayüzünün erişilebilirliği
- Sistem kaynakları (disk, RAM)
