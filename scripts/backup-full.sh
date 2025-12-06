#!/bin/bash

################################################################################
# Haber Nexus - Kapsamlı Yedekleme Scripti
# Veritabanı, dosyalar, konfigürasyon ve tüm sistem verilerini yedekler
# Geliştirici: Salih TANRISEVEN
# Tarih: 2025-12-06
################################################################################

set -e

# ============================================================================
# RENKLER VE FONKSIYONLAR
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_step() { echo -e "\n${BLUE}==>${NC} $1"; }
log_section() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${CYAN}$1${NC}\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# ============================================================================
# BANNER
# ============================================================================

clear
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                  🔐 HABER NEXUS - KAPSAMLI YEDEKLEME 🔐                    ║
║                                                                              ║
║                    Tüm Sistem Verilerinin Yedeklemesi                        ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF

# ============================================================================
# AYARLAR
# ============================================================================

log_section "Yedekleme Ayarları"

# Proje dizini
PROJECT_PATH="${1:-.}"
if [ ! -f "$PROJECT_PATH/manage.py" ]; then
    log_error "Proje dizini geçersiz. Lütfen proje kök dizininde çalıştırın."
fi

# Yedekleme dizini
BACKUP_BASE_DIR="${PROJECT_PATH}/.backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="habernexus_backup_${TIMESTAMP}"
BACKUP_DIR="${BACKUP_BASE_DIR}/${BACKUP_NAME}"

# Veritabanı bilgileri (.env'den oku)
if [ -f "$PROJECT_PATH/.env" ]; then
    export $(grep -v '^#' "$PROJECT_PATH/.env" | xargs)
fi

DB_ENGINE="${DB_ENGINE:-django.db.backends.sqlite3}"
DB_NAME="${DB_NAME:-db.sqlite3}"
DB_USER="${DB_USER:-habernexus_user}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

log_info "Proje Dizini: $PROJECT_PATH"
log_info "Yedekleme Dizini: $BACKUP_DIR"
log_info "Veritabanı Tipi: $DB_ENGINE"
log_info "Yedekleme Adı: $BACKUP_NAME"

# ============================================================================
# ADIM 1: YEDEKLEMEDİZİNİ OLUŞTUR
# ============================================================================

log_section "Adım 1: Yedekleme Dizini Oluşturuluyor"

log_step "Dizin oluşturuluyor..."
mkdir -p "$BACKUP_DIR"
log_info "Yedekleme dizini oluşturuldu."

# ============================================================================
# ADIM 2: VERİTABANINI YEDEKLE
# ============================================================================

log_section "Adım 2: Veritabanı Yedekleniyor"

if [ "$DB_ENGINE" = "django.db.backends.sqlite3" ]; then
    log_step "SQLite veritabanı yedekleniyor..."
    if [ -f "$PROJECT_PATH/$DB_NAME" ]; then
        cp "$PROJECT_PATH/$DB_NAME" "$BACKUP_DIR/database.sqlite3"
        log_info "SQLite veritabanı yedeklendi."
    else
        log_warning "SQLite veritabanı dosyası bulunamadı."
    fi
elif [ "$DB_ENGINE" = "django.db.backends.postgresql" ]; then
    log_step "PostgreSQL veritabanı yedekleniyor..."
    PGPASSWORD="$DB_PASSWORD" pg_dump \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        "$DB_NAME" | gzip > "$BACKUP_DIR/database.sql.gz"
    log_info "PostgreSQL veritabanı yedeklendi."
else
    log_warning "Bilinmeyen veritabanı türü: $DB_ENGINE"
fi

# ============================================================================
# ADIM 3: ORTAM DEĞİŞKENLERİNİ YEDEKLE
# ============================================================================

log_section "Adım 3: Ortam Değişkenleri Yedekleniyor"

log_step ".env dosyası yedekleniyor..."
if [ -f "$PROJECT_PATH/.env" ]; then
    cp "$PROJECT_PATH/.env" "$BACKUP_DIR/.env.backup"
    log_info ".env dosyası yedeklendi."
else
    log_warning ".env dosyası bulunamadı."
fi

# ============================================================================
# ADIM 4: MEDYA DOSYALARINI YEDEKLE
# ============================================================================

log_section "Adım 4: Medya Dosyaları Yedekleniyor"

log_step "Medya dosyaları sıkıştırılıyor..."
if [ -d "$PROJECT_PATH/media" ] && [ "$(ls -A $PROJECT_PATH/media)" ]; then
    tar -czf "$BACKUP_DIR/media.tar.gz" -C "$PROJECT_PATH" media/
    MEDIA_SIZE=$(du -sh "$BACKUP_DIR/media.tar.gz" | cut -f1)
    log_info "Medya dosyaları yedeklendi ($MEDIA_SIZE)."
else
    log_warning "Medya dizini boş veya bulunamadı."
fi

# ============================================================================
# ADIM 5: STATİK DOSYALARI YEDEKLE
# ============================================================================

log_section "Adım 5: Statik Dosyalar Yedekleniyor"

log_step "Statik dosyalar sıkıştırılıyor..."
if [ -d "$PROJECT_PATH/staticfiles" ] && [ "$(ls -A $PROJECT_PATH/staticfiles)" ]; then
    tar -czf "$BACKUP_DIR/staticfiles.tar.gz" -C "$PROJECT_PATH" staticfiles/
    STATIC_SIZE=$(du -sh "$BACKUP_DIR/staticfiles.tar.gz" | cut -f1)
    log_info "Statik dosyalar yedeklendi ($STATIC_SIZE)."
else
    log_warning "Statik dosyalar dizini boş veya bulunamadı."
fi

# ============================================================================
# ADIM 6: PROJE DOSYALARINI YEDEKLE
# ============================================================================

log_section "Adım 6: Proje Dosyaları Yedekleniyor"

log_step "Proje dosyaları sıkıştırılıyor..."
tar -czf "$BACKUP_DIR/project.tar.gz" \
    --exclude='.git' \
    --exclude='venv' \
    --exclude='__pycache__' \
    --exclude='.pytest_cache' \
    --exclude='.coverage' \
    --exclude='*.pyc' \
    --exclude='db.sqlite3' \
    --exclude='media' \
    --exclude='staticfiles' \
    --exclude='.backups' \
    -C "$PROJECT_PATH/.." habernexus/

PROJECT_SIZE=$(du -sh "$BACKUP_DIR/project.tar.gz" | cut -f1)
log_info "Proje dosyaları yedeklendi ($PROJECT_SIZE)."

# ============================================================================
# ADIM 7: SISTEM BİLGİSİNİ KAYDET
# ============================================================================

log_section "Adım 7: Sistem Bilgileri Kaydediliyor"

log_step "Yedekleme metadata'sı oluşturuluyor..."

cat > "$BACKUP_DIR/backup.info" <<EOF
╔════════════════════════════════════════════════════════════════════════════╗
║                    HABER NEXUS YEDEKLEME BİLGİSİ                          ║
╚════════════════════════════════════════════════════════════════════════════╝

Yedekleme Tarihi: $(date)
Yedekleme Adı: $BACKUP_NAME
Yedekleme Dizini: $BACKUP_DIR

SİSTEM BİLGİSİ
═══════════════════════════════════════════════════════════════════════════
İşletim Sistemi: $(uname -s)
Hostname: $(hostname)
Kernel: $(uname -r)
Python Sürümü: $(python3 --version 2>&1)
Django Sürümü: $(grep -oP 'Django==\K[^"]+' "$PROJECT_PATH/requirements.txt" 2>/dev/null || echo "Bilinmiyor")

VERİTABANI BİLGİSİ
═══════════════════════════════════════════════════════════════════════════
Veritabanı Tipi: $DB_ENGINE
Veritabanı Adı: $DB_NAME
Veritabanı Kullanıcısı: $DB_USER
Veritabanı Host: $DB_HOST
Veritabanı Port: $DB_PORT

YEDEKLENMİŞ DOSYALAR
═══════════════════════════════════════════════════════════════════════════
EOF

if [ -f "$BACKUP_DIR/database.sqlite3" ]; then
    echo "✓ database.sqlite3 - SQLite veritabanı" >> "$BACKUP_DIR/backup.info"
elif [ -f "$BACKUP_DIR/database.sql.gz" ]; then
    echo "✓ database.sql.gz - PostgreSQL veritabanı" >> "$BACKUP_DIR/backup.info"
fi

[ -f "$BACKUP_DIR/.env.backup" ] && echo "✓ .env.backup - Ortam değişkenleri" >> "$BACKUP_DIR/backup.info"
[ -f "$BACKUP_DIR/media.tar.gz" ] && echo "✓ media.tar.gz - Medya dosyaları" >> "$BACKUP_DIR/backup.info"
[ -f "$BACKUP_DIR/staticfiles.tar.gz" ] && echo "✓ staticfiles.tar.gz - Statik dosyalar" >> "$BACKUP_DIR/backup.info"
[ -f "$BACKUP_DIR/project.tar.gz" ] && echo "✓ project.tar.gz - Proje dosyaları" >> "$BACKUP_DIR/backup.info"

cat >> "$BACKUP_DIR/backup.info" <<EOF

GERI YÜKLEME TALİMATLARı
═══════════════════════════════════════════════════════════════════════════
Bu yedeklemeyi geri yüklemek için:

  bash scripts/restore-full.sh $BACKUP_DIR

YEDEKLEME BOYUTU
═══════════════════════════════════════════════════════════════════════════
EOF

echo "Toplam Boyut: $(du -sh "$BACKUP_DIR" | cut -f1)" >> "$BACKUP_DIR/backup.info"

log_info "Yedekleme metadata'sı kaydedildi."

# ============================================================================
# ADIM 8: YEDEKLEME ARŞİVİ OLUŞTUR
# ============================================================================

log_section "Adım 8: Yedekleme Arşivi Oluşturuluyor"

log_step "Yedekleme arşivi sıkıştırılıyor..."
cd "$BACKUP_BASE_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
ARCHIVE_SIZE=$(du -sh "${BACKUP_NAME}.tar.gz" | cut -f1)
log_info "Yedekleme arşivi oluşturuldu ($ARCHIVE_SIZE)."

# ============================================================================
# ADIM 9: İNTEGRİTE KONTROLÜ
# ============================================================================

log_section "Adım 9: İntegriteKontrolü"

log_step "Yedekleme dosyaları kontrol ediliyor..."
FILE_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)
log_info "Yedeklenen dosya sayısı: $FILE_COUNT"

# MD5 checksum oluştur
md5sum "$BACKUP_DIR"/* > "$BACKUP_DIR/checksums.md5" 2>/dev/null || true
log_info "MD5 checksums oluşturuldu."

# ============================================================================
# YEDEKLEME TAMAMLANDI
# ============================================================================

log_section "🎉 YEDEKLEME BAŞARIYLA TAMAMLANDI! 🎉"

echo ""
echo "Yedekleme Bilgileri:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Yedekleme Adı: $BACKUP_NAME"
echo "  Yedekleme Dizini: $BACKUP_DIR"
echo "  Arşiv Dosyası: ${BACKUP_NAME}.tar.gz ($ARCHIVE_SIZE)"
echo "  Yedeklenen Dosya Sayısı: $FILE_COUNT"
echo "  Yedekleme Tarihi: $(date)"
echo ""

echo "Yedekleme Dosyaları:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh "$BACKUP_DIR" | tail -n +2 | awk '{printf "  %-30s %10s\n", $9, $5}'
echo ""

echo "Geri Yükleme:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  bash scripts/restore-full.sh $BACKUP_DIR"
echo ""

log_info "Yedekleme tamamlandı! Yedekleme bilgileri $BACKUP_DIR/backup.info dosyasında kaydedildi."
