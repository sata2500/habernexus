# HaberNexus Kurulum Sistemi Tasarım Dokümanı

**Versiyon:** 11.0.0  
**Tarih:** 18 Aralık 2025  
**Geliştirici:** Salih TANRISEVEN

---

## 1. Genel Bakış

Bu doküman, HaberNexus projesi için profesyonel, idempotent ve kullanıcı dostu bir kurulum sistemi tasarımını içerir.

### 1.1 Hedefler

1. **Tek komutla kurulum:** Yeni kullanıcılar için en basit deneyim
2. **Manuel kurulum:** İleri düzey kullanıcılar için tam kontrol
3. **Geliştirici kurulumu:** Hızlı geliştirme ortamı
4. **Idempotent:** Tekrar çalıştırılabilir, güvenli
5. **Yedekleme/Geri yükleme:** Veri güvenliği
6. **Temizleme/Sıfırlama:** Sorunsuz yeniden kurulum

---

## 2. Kurulum Modları

### 2.1 Otomatik Kurulum (Önerilen)

```bash
# Tek komutla kurulum
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/install.sh | sudo bash

# Parametrelerle kurulum
curl -fsSL ... | sudo bash -s -- --domain habernexus.com --email admin@example.com

# Hızlı kurulum (varsayılan değerlerle)
curl -fsSL ... | sudo bash -s -- --quick

# Geliştirici kurulumu
curl -fsSL ... | sudo bash -s -- --dev

# Tam sıfırlama ile kurulum
curl -fsSL ... | sudo bash -s -- --reset
```

### 2.2 Manuel Kurulum

```bash
# Script'i indir
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/install.sh -o install.sh

# Manuel mod ile çalıştır
sudo bash install.sh --manual
```

---

## 3. Komut Satırı Parametreleri

| Parametre | Kısa | Açıklama | Varsayılan |
|-----------|------|----------|------------|
| `--domain` | `-d` | Domain adı | localhost |
| `--email` | `-e` | Admin e-posta | admin@localhost |
| `--username` | `-u` | Admin kullanıcı adı | admin |
| `--password` | `-p` | Admin şifresi | (otomatik) |
| `--quick` | `-q` | Hızlı kurulum | false |
| `--dev` | | Geliştirici modu | false |
| `--manual` | `-m` | Manuel kurulum | false |
| `--reset` | | Tam sıfırlama | false |
| `--backup` | `-b` | Sadece yedek al | false |
| `--restore` | `-r` | Yedekten geri yükle | - |
| `--list-backups` | | Yedekleri listele | false |
| `--uninstall` | | Tamamen kaldır | false |
| `--dry-run` | | Simülasyon modu | false |
| `--no-tui` | | TUI'yi devre dışı bırak | false |
| `--config` | `-c` | Config dosyası | - |
| `--help` | `-h` | Yardım | - |
| `--version` | `-v` | Versiyon | - |

---

## 4. Kurulum Adımları

### 4.1 Otomatik Kurulum Akışı

```
┌─────────────────────────────────────────────────────────────┐
│                    KURULUM BAŞLANGICI                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. ÖN KONTROLLER                                             │
│    • Root yetkisi kontrolü                                   │
│    • İşletim sistemi kontrolü (Ubuntu 20.04/22.04/24.04)    │
│    • Bellek kontrolü (min 2GB)                               │
│    • Disk alanı kontrolü (min 15GB)                          │
│    • İnternet bağlantısı kontrolü                            │
│    • Port kontrolü (80, 443)                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. MEVCUT KURULUM TESPİTİ                                    │
│    • /opt/habernexus dizini var mı?                          │
│    • Docker container'ları çalışıyor mu?                     │
│    • Yedek alınacak mı? (kullanıcıya sor)                   │
│    • Temizlik gerekli mi?                                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. BAĞIMLILIKLAR                                             │
│    • Sistem paketleri güncelleme                             │
│    • Temel paketler (curl, wget, git, jq)                   │
│    • Docker kurulumu                                         │
│    • Docker Compose kontrolü                                 │
│    • Whiptail (TUI için)                                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. YAPILANDIRMA TOPLAMA                                      │
│    • TUI varsa: whiptail dialog'ları                        │
│    • TUI yoksa: CLI prompt'ları                              │
│    • Domain adı                                              │
│    • Admin bilgileri                                         │
│    • Cloudflare Tunnel (opsiyonel)                          │
│    • Google AI API Key (opsiyonel)                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. PROJE KURULUMU                                            │
│    • GitHub'dan klonlama                                     │
│    • .env dosyası oluşturma                                  │
│    • Caddyfile yapılandırma                                  │
│    • Docker Compose override (Cloudflare için)              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. SERVİSLERİ BAŞLATMA                                       │
│    • Docker imajları build                                   │
│    • Container'ları başlat                                   │
│    • Database migration                                      │
│    • Static dosyaları topla                                  │
│    • Admin kullanıcı oluştur                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. DOĞRULAMA                                                 │
│    • Health check endpoint kontrolü                          │
│    • Database bağlantı kontrolü                              │
│    • Redis bağlantı kontrolü                                 │
│    • Web sunucu erişim kontrolü                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. TAMAMLAMA                                                 │
│    • Giriş bilgilerini göster                                │
│    • CREDENTIALS.txt dosyası oluştur                         │
│    • Sonraki adımları göster                                 │
│    • Log dosyası konumunu göster                             │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Manuel Kurulum Adımları

1. **Sistem Hazırlığı**
   - Sistem gereksinimlerini kontrol et
   - Gerekli paketleri kur
   - Docker'ı kur

2. **Proje Kurulumu**
   - Repository'yi klonla
   - Dizin yapısını oluştur

3. **Yapılandırma**
   - .env dosyasını düzenle
   - Caddyfile'ı yapılandır
   - Docker Compose'u özelleştir

4. **Veritabanı**
   - PostgreSQL'i başlat
   - Migration'ları çalıştır
   - Admin kullanıcı oluştur

5. **Servisleri Başlat**
   - Tüm container'ları başlat
   - Logları kontrol et

6. **Doğrulama**
   - Health check
   - Web arayüzü kontrolü

---

## 5. Yedekleme Sistemi

### 5.1 Yedeklenen Veriler

| Veri | Dosya | Açıklama |
|------|-------|----------|
| PostgreSQL | database.sql.gz | Tüm veritabanı dump'ı |
| Redis | redis_dump.rdb | Redis snapshot |
| Yapılandırma | .env.backup | Environment değişkenleri |
| Media | media.tar.gz | Yüklenen dosyalar |
| Metadata | backup.info | Yedek bilgileri |

### 5.2 Yedekleme Komutları

```bash
# Manuel yedek alma
sudo bash install.sh --backup

# Yedekleri listeleme
sudo bash install.sh --list-backups

# Yedekten geri yükleme
sudo bash install.sh --restore backup_20251218_120000

# Otomatik eski yedek temizleme (7 günden eski)
# Yedekleme sırasında otomatik çalışır
```

### 5.3 Yedek Dizin Yapısı

```
/var/backups/habernexus/
├── backup_20251218_120000/
│   ├── database.sql.gz
│   ├── redis_dump.rdb
│   ├── .env.backup
│   ├── media.tar.gz
│   └── backup.info
└── backup_20251218_140000.tar.gz
```

---

## 6. Temizleme/Sıfırlama Sistemi

### 6.1 Temizleme Seviyeleri

| Seviye | Açıklama | Komut |
|--------|----------|-------|
| Soft | Container'ları durdur | `--stop` |
| Medium | Container ve volume'ları sil | `--clean` |
| Hard | Tüm kurulumu sil | `--reset` |
| Full | Yedekler dahil her şeyi sil | `--uninstall` |

### 6.2 Temizlenen Kaynaklar

- Docker container'ları (habernexus-*)
- Docker volume'ları (postgres_data, redis_data, static_files, media_files)
- Docker network'leri (habernexus-network)
- Kurulum dizini (/opt/habernexus)
- Systemd servisleri
- Caddy yapılandırması
- Cloudflare yapılandırması

---

## 7. Geliştirici Modu

### 7.1 Özellikler

- DEBUG=True
- Hot reload aktif
- SQLite veritabanı (opsiyonel)
- Minimal Docker yapılandırması
- Hızlı başlangıç

### 7.2 Kullanım

```bash
# Geliştirici kurulumu
sudo bash install.sh --dev

# Veya manuel
git clone https://github.com/sata2500/habernexus.git
cd habernexus
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python manage.py migrate
python manage.py runserver
```

---

## 8. Hata Yönetimi

### 8.1 Hata Kodları

| Kod | Açıklama |
|-----|----------|
| 0 | Başarılı |
| 1 | Genel hata |
| 2 | Root yetkisi gerekli |
| 3 | Desteklenmeyen işletim sistemi |
| 4 | Yetersiz sistem kaynağı |
| 5 | İnternet bağlantısı yok |
| 6 | Docker kurulum hatası |
| 7 | Git klonlama hatası |
| 8 | Docker Compose hatası |
| 9 | Migration hatası |
| 10 | Health check başarısız |

### 8.2 Hata Kurtarma

- Her adımda checkpoint kaydet
- Hata durumunda rollback seçeneği sun
- Detaylı log dosyası oluştur
- Kullanıcıya çözüm önerileri sun

---

## 9. Dosya Yapısı

```
/opt/habernexus/
├── .env                          # Ortam değişkenleri
├── .env.example                  # Örnek yapılandırma
├── docker-compose.yml            # Development
├── docker-compose.prod.yml       # Production
├── docker-compose.override.yml   # Cloudflare override
├── caddy/
│   ├── Caddyfile                 # Aktif yapılandırma
│   ├── Caddyfile.template        # Domain şablonu
│   └── Caddyfile.ip.template     # IP şablonu
├── scripts/
│   ├── backup.sh                 # Yedekleme
│   ├── restore.sh                # Geri yükleme
│   └── health-check.sh           # Sağlık kontrolü
├── CREDENTIALS.txt               # Giriş bilgileri (güvenli)
└── ...

/var/log/habernexus/
├── install_20251218_120000.log   # Kurulum logları
└── ...

/var/backups/habernexus/
├── backup_20251218_120000/       # Yedekler
└── ...
```

---

## 10. Güvenlik Önlemleri

1. **Şifre güvenliği:** Otomatik güçlü şifre oluşturma
2. **Secret key:** Kriptografik olarak güvenli
3. **Dosya izinleri:** .env ve CREDENTIALS.txt için 600
4. **Log güvenliği:** Hassas bilgiler maskelenir
5. **Token güvenliği:** Cloudflare token'ları güvenli saklanır

---

## 11. Uygulama Planı

### Faz 1: Otomatik Kurulum (install.sh)
- [x] Tasarım dokümanı
- [ ] Ana script yapısı
- [ ] Ön kontroller
- [ ] Bağımlılık kurulumu
- [ ] Yapılandırma toplama (TUI/CLI)
- [ ] Proje kurulumu
- [ ] Servis başlatma
- [ ] Doğrulama

### Faz 2: Manuel Kurulum
- [ ] Adım adım fonksiyonlar
- [ ] İnteraktif rehber
- [ ] Hata kurtarma

### Faz 3: Yedekleme/Geri Yükleme
- [ ] Yedekleme fonksiyonları
- [ ] Geri yükleme fonksiyonları
- [ ] Otomatik temizlik

### Faz 4: Temizleme/Sıfırlama
- [ ] Temizleme seviyeleri
- [ ] Güvenli silme
- [ ] Rollback

### Faz 5: Test ve Dokümantasyon
- [ ] Birim testleri
- [ ] Entegrasyon testleri
- [ ] Kullanıcı dokümantasyonu
