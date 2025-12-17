# HaberNexus v7.0 - Kurulum Script'leri

> **Tam Otomatik • Kullanıcı Dostu • Sorunsuz Deneyim**

Bu dizin HaberNexus'u kurmak, yönetmek ve bakımını yapmak için gerekli tüm script'leri içerir.

---

## 📦 Script'ler

### 1. 🚀 `install_v7.sh` - Ana Kurulum Script'i

**Amaç**: HaberNexus'u tam otomatik olarak kurmak

**Özellikler**:
- ✅ Sistem kontrolü ve doğrulama
- ✅ Otomatik bağımlılık kurulumu
- ✅ Docker imajlarını oluşturma
- ✅ Veritabanı başlatma
- ✅ Admin kullanıcı oluşturma
- ✅ SSL sertifikası yapılandırması
- ✅ Detaylı hata yönetimi
- ✅ Renkli, kullanıcı dostu arayüz

**Kullanım**:

```bash
# Hızlı kurulum (önerilen)
sudo bash install_v7.sh --quick

# Özel yapılandırma
sudo bash install_v7.sh --custom

# Geliştirme modu
sudo bash install_v7.sh --dev --debug

# Yardım
bash install_v7.sh --help
```

**Kurulum Modları**:

| Mode | Açıklama | Süre | Uygun |
|------|----------|------|-------|
| `--quick` | Varsayılan değerlerle hızlı kurulum | 5-10 dk | Üretim |
| `--custom` | İnteraktif yapılandırma | 10-15 dk | Özel gereksinimler |
| `--dev` | Geliştirme modu, debug etkin | 10-15 dk | Geliştirme |

**Seçenekler**:

```bash
--quick              # Hızlı kurulum (varsayılan değerler)
--custom             # Özel yapılandırma (interaktif)
--dev                # Geliştirme modu
--force              # Mevcut kurulumu yedekle ve yeniden kur
--skip-docker-check  # Docker kurulumu kontrolünü atla
--debug              # Debug logging etkinleştir
--help               # Yardım mesajını göster
```

**Çıktı**:
- ✅ Kurulum günlüğü: `/var/log/habernexus/install_v7_*.log`
- ✅ Yapılandırma: `/var/log/habernexus/installation_config_*.conf`
- ✅ Ortam dosyası: `/opt/habernexus/.env`

---

### 2. 🔧 `manage_habernexus.sh` - Yönetim Script'i

**Amaç**: Kurulumdan sonra HaberNexus'u yönetmek ve bakımını yapmak

**Özellikler**:
- 📊 Servis durumunu izleme
- 🔄 Servis başlatma/durdurma/yeniden başlatma
- 💾 Veritabanı yedekleme/geri yükleme
- 👤 Kullanıcı yönetimi
- 🧹 Sistem temizliği
- 📝 Log yönetimi
- 🐛 Sorun giderme

**Kullanım**:

```bash
bash manage_habernexus.sh [COMMAND] [OPTIONS]
```

**Komutlar**:

#### Durum & İzleme
```bash
bash manage_habernexus.sh status          # Servis durumunu göster
bash manage_habernexus.sh logs [SERVICE] # Logları görüntüle
bash manage_habernexus.sh health         # Sistem sağlığını kontrol et
bash manage_habernexus.sh troubleshoot   # Sorun giderme tanılaması
```

#### Servis Yönetimi
```bash
bash manage_habernexus.sh start           # Tüm servisleri başlat
bash manage_habernexus.sh stop            # Tüm servisleri durdur
bash manage_habernexus.sh restart         # Tüm servisleri yeniden başlat
bash manage_habernexus.sh restart [SVC]   # Belirli servisi yeniden başlat
```

#### Veritabanı
```bash
bash manage_habernexus.sh backup-db       # Veritabanını yedekle
bash manage_habernexus.sh restore-db FILE # Veritabanını geri yükle
bash manage_habernexus.sh migrate         # Migrasyonları çalıştır
```

#### Kullanıcı Yönetimi
```bash
bash manage_habernexus.sh create-user U E P  # Admin kullanıcı oluştur
bash manage_habernexus.sh change-password U P # Şifreyi değiştir
bash manage_habernexus.sh list-users        # Tüm kullanıcıları listele
```

#### Bakım
```bash
bash manage_habernexus.sh cleanup-logs    # Eski logları sil
bash manage_habernexus.sh cleanup-docker  # Docker kaynaklarını temizle
bash manage_habernexus.sh update          # Projeyi güncelle
```

#### Yedekleme
```bash
bash manage_habernexus.sh full-backup     # Tam yedekleme yap
bash manage_habernexus.sh list-backups    # Yedeklemeleri listele
```

**Örnekler**:

```bash
# Servis durumunu kontrol et
bash manage_habernexus.sh status

# Uygulama loglarını izle
bash manage_habernexus.sh logs app

# Veritabanını yedekle
bash manage_habernexus.sh backup-db

# Admin kullanıcı oluştur
bash manage_habernexus.sh create-user admin admin@example.com sifre123

# Sistem sağlığını kontrol et
bash manage_habernexus.sh health
```

---

### 3. ✅ `pre_install_check.sh` - Ön Kurulum Kontrol Script'i

**Amaç**: Kurulumdan önce sistem uyumluluğunu doğrulamak

**Kontroller**:
- ✅ Root ayrıcalıkları
- ✅ İşletim sistemi uyumluluğu
- ✅ CPU çekirdek sayısı
- ✅ RAM belleği
- ✅ Disk alanı
- ✅ İnternet bağlantısı
- ✅ Gerekli komutlar (curl, wget, git, python3)
- ✅ Docker kurulumu
- ✅ Port kullanılabilirliği
- ✅ Dosya izinleri
- ✅ Firewall durumu
- ✅ SELinux durumu

**Kullanım**:

```bash
# Kontrolleri çalıştır
bash pre_install_check.sh

# Root olarak çalıştır (önerilen)
sudo bash pre_install_check.sh
```

**Çıktı**:
- ✅ Geçen kontroller (yeşil)
- ⚠️ Uyarılar (sarı)
- ❌ Başarısız kontroller (kırmızı)
- 📊 Özet raporu

**Örnek Çıktı**:

```
════════════════════════════════════════════════════════════════
  HaberNexus Pre-Installation Check
════════════════════════════════════════════════════════════════

→ Root Privileges
  [✓] Running as root

→ Operating System
  [✓] Ubuntu detected: 22.04
  [✓] Supported Ubuntu version

→ CPU Cores
  [✓] 4 cores (recommended: 4+)

→ RAM Memory
  [✓] 8GB RAM (recommended: 8+)

→ Disk Space
  [✓] 100GB available (required: 20+)

→ Internet Connectivity
  [✓] Connected to https://github.com

...

════════════════════════════════════════════════════════════════
  Check Summary
════════════════════════════════════════════════════════════════

Passed:   12
Warnings: 1
Failed:   0

✓ System is ready for installation!

Next steps:
  1. Run: sudo bash install_v7.sh --quick
  2. Or:  sudo bash install_v7.sh --custom
```

---

## 🚀 Hızlı Başlangıç

### Adım 1: Ön Kontrol

```bash
# Sistem uyumluluğunu kontrol et
sudo bash pre_install_check.sh
```

### Adım 2: Kurulum

```bash
# Hızlı kurulum (önerilen)
sudo bash install_v7.sh --quick

# VEYA özel yapılandırma
sudo bash install_v7.sh --custom
```

### Adım 3: Kurulum Sonrası

```bash
# Servis durumunu kontrol et
bash manage_habernexus.sh status

# Admin paneline erişim
# https://habernexus.local/admin
```

---

## 📋 Kurulum Akışı

```
pre_install_check.sh
        ↓
   [Kontroller Geçti]
        ↓
install_v7.sh --quick
        ↓
   [Sistem Hazırlığı]
   [Bağımlılık Kurulumu]
   [Docker Kurulumu]
   [Repository Klonlama]
   [Yapılandırma]
   [Docker İmajları Oluşturma]
   [Servis Başlatma]
   [Veritabanı Başlatma]
   [Admin Kullanıcı Oluşturma]
        ↓
   [Kurulum Tamamlandı]
        ↓
manage_habernexus.sh
   [Yönetim & Bakım]
```

---

## 🔍 Sorun Giderme

### Kurulum Başlamıyor

```bash
# Ön kontrolleri çalıştır
sudo bash pre_install_check.sh

# Sorunları düzelt ve yeniden dene
sudo bash install_v7.sh --quick
```

### Servisler Çalışmıyor

```bash
# Durumu kontrol et
bash manage_habernexus.sh status

# Logları görüntüle
bash manage_habernexus.sh logs app

# Yeniden başlat
bash manage_habernexus.sh restart
```

### Veritabanı Sorunları

```bash
# Sağlığı kontrol et
bash manage_habernexus.sh health

# PostgreSQL loglarını görüntüle
bash manage_habernexus.sh logs postgres

# Yeniden başlat
bash manage_habernexus.sh restart postgres
```

---

## 📚 Detaylı Rehberler

Daha fazla bilgi için bkz:
- **Kurulum Rehberi**: `INSTALLATION_GUIDE_v7.md`
- **GitHub Repo**: https://github.com/sata2500/habernexus
- **Dokümantasyon**: https://docs.habernexus.com

---

## 🎯 Sistem Gereksinimleri

| Gereksinim | Minimum | Önerilen |
|-----------|---------|----------|
| CPU | 2 çekirdek | 4+ çekirdek |
| RAM | 4 GB | 8+ GB |
| Disk | 20 GB | 50+ GB |
| İşletim Sistemi | Ubuntu 20.04 | Ubuntu 22.04+ |
| İnternet | Stabil bağlantı | 10+ Mbps |

---

## 📝 Dosya Konumları

| Dosya | Konum |
|------|--------|
| Kurulum Günlüğü | `/var/log/habernexus/install_v7_*.log` |
| Yapılandırma | `/var/log/habernexus/installation_config_*.conf` |
| Ortam Dosyası | `/opt/habernexus/.env` |
| Yedeklemeler | `/opt/habernexus/.backups/` |
| Proje Dizini | `/opt/habernexus/` |

---

## 🆘 Destek

- **GitHub Issues**: https://github.com/sata2500/habernexus/issues
- **E-posta**: salihtanriseven25@gmail.com
- **Dokümantasyon**: https://docs.habernexus.com

---

## 📄 Lisans

MIT License - Detaylar için `LICENSE` dosyasına bakın

---

## 👨‍💻 Geliştirici

**Salih TANRISEVEN**
- GitHub: [@sata2500](https://github.com/sata2500)
- E-posta: salihtanriseven25@gmail.com

---

## 🎉 Başarılı Kurulum!

Tebrikler! HaberNexus v7.0 başarıyla kuruldu.

Şimdi:
1. Admin paneline giriş yap
2. RSS kaynakları ekle
3. İçerik ayarlarını yapılandır
4. Sistem sağlığını izle

**Mutlu haber agregasyonu! 📰**

---

*Son güncelleme: 15 Aralık 2025*  
*Sürüm: 7.0*
