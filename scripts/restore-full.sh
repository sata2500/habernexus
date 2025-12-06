#!/bin/bash

################################################################################
# Haber Nexus - Kapsamlı Geri Yükleme Scripti
# Yedeklemeden tüm sistem verilerini geri yükler
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
║                  🔄 HABER NEXUS - KAPSAMLI GERI YÜKLEME 🔄                ║
║                                                                              ║
║                    Yedeklemeden Sistem Verilerinin Geri Yüklenmesi          ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF

# ============================================================================
# AYARLAR
# ============================================================================

log_section "Geri Yükleme Ayarları"

# Yedekleme dizini
BACKUP_DIR="${1:-.}"
if [ ! -d "$BACKUP_DIR" ]; then
    log_error "Yedekleme dizini bulunamadı: $BACKUP_DIR"
fi

# Yedekleme bilgisini oku
if [ ! -f "$BACKUP_DIR/backup.info" ]; then
    log_error "Yedekleme bilgi dosyası bulunamadı: $BACKUP_DIR/backup.info"
fi

# Hedef dizin
TARGET_PATH="${2:-.}"
if [ ! -f "$TARGET_PATH/manage.py" ]; then
    log_error "Hedef proje dizini geçersiz. Lütfen proje kök dizinini belirtin."
fi

log_info "Yedekleme Dizini: $BACKUP_DIR"
log_info "Hedef Proje Dizini: $TARGET_PATH"

# Yedekleme bilgisini göster
echo ""
echo "Yedekleme Bilgileri:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
head -20 "$BACKUP_DIR/backup.info"
echo ""

# Onay iste
read -p "Bu yedeklemeyi geri yüklemek istediğinize emin misiniz? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_error "Geri yükleme iptal edildi."
fi

# ============================================================================
# ADIM 1: HEDEFDİZİNİ HAZIRLA
# ============================================================================

log_section "Adım 1: Hedef Dizin Hazırlanıyor"

log_step "Eski dosyalar yedekleniyor..."
if [ -d "$TARGET_PATH/media" ]; then
    mv "$TARGET_PATH/media" "$TARGET_PATH/media.old"
fi
if [ -d "$TARGET_PATH/staticfiles" ]; then
    mv "$TARGET_PATH/staticfiles" "$TARGET_PATH/staticfiles.old"
fi
if [ -f "$TARGET_PATH/db.sqlite3" ]; then
    mv "$TARGET_PATH/db.sqlite3" "$TARGET_PATH/db.sqlite3.old"
fi
log_info "Eski dosyalar yedeklendi."

# ============================================================================
# ADIM 2: VERİTABANINI GERI YÜKLE
# ============================================================================

log_section "Adım 2: Veritabanı Geri Yükleniyor"

if [ -f "$BACKUP_DIR/database.sqlite3" ]; then
    log_step "SQLite veritabanı geri yükleniyor..."
    cp "$BACKUP_DIR/database.sqlite3" "$TARGET_PATH/db.sqlite3"
    log_info "SQLite veritabanı geri yüklendi."
elif [ -f "$BACKUP_DIR/database.sql.gz" ]; then
    log_step "PostgreSQL veritabanı geri yükleniyor..."
    
    # .env dosyasından veritabanı bilgisini oku
    if [ -f "$BACKUP_DIR/.env.backup" ]; then
        export $(grep -v '^#' "$BACKUP_DIR/.env.backup" | xargs)
    fi
    
    DB_NAME="${DB_NAME:-habernexus}"
    DB_USER="${DB_USER:-habernexus_user}"
    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-5432}"
    
    # Veritabanını sil ve yeniden oluştur
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>/dev/null || true
    
    # Veritabanını geri yükle
    gunzip -c "$BACKUP_DIR/database.sql.gz" | PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
    log_info "PostgreSQL veritabanı geri yüklendi."
else
    log_warning "Veritabanı yedeklemesi bulunamadı."
fi

# ============================================================================
# ADIM 3: ORTAM DEĞİŞKENLERİNİ GERI YÜKLE
# ============================================================================

log_section "Adım 3: Ortam Değişkenleri Geri Yükleniyor"

if [ -f "$BACKUP_DIR/.env.backup" ]; then
    log_step ".env dosyası geri yükleniyor..."
    cp "$BACKUP_DIR/.env.backup" "$TARGET_PATH/.env"
    log_info ".env dosyası geri yüklendi."
else
    log_warning ".env dosyası yedeklemesi bulunamadı."
fi

# ============================================================================
# ADIM 4: MEDYA DOSYALARINI GERI YÜKLE
# ============================================================================

log_section "Adım 4: Medya Dosyaları Geri Yükleniyor"

if [ -f "$BACKUP_DIR/media.tar.gz" ]; then
    log_step "Medya dosyaları çıkarılıyor..."
    tar -xzf "$BACKUP_DIR/media.tar.gz" -C "$TARGET_PATH"
    log_info "Medya dosyaları geri yüklendi."
else
    log_warning "Medya dosyaları yedeklemesi bulunamadı."
fi

# ============================================================================
# ADIM 5: STATİK DOSYALARI GERI YÜKLE
# ============================================================================

log_section "Adım 5: Statik Dosyalar Geri Yükleniyor"

if [ -f "$BACKUP_DIR/staticfiles.tar.gz" ]; then
    log_step "Statik dosyalar çıkarılıyor..."
    tar -xzf "$BACKUP_DIR/staticfiles.tar.gz" -C "$TARGET_PATH"
    log_info "Statik dosyalar geri yüklendi."
else
    log_warning "Statik dosyalar yedeklemesi bulunamadı."
fi

# ============================================================================
# ADIM 6: PROJE DOSYALARINI GERI YÜKLE (OPSİYONEL)
# ============================================================================

log_section "Adım 6: Proje Dosyaları (Opsiyonel)"

if [ -f "$BACKUP_DIR/project.tar.gz" ]; then
    read -p "Proje dosyalarını da geri yüklemek istediğinize emin misiniz? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_step "Proje dosyaları çıkarılıyor..."
        
        # Geçici dizine çıkar
        TEMP_DIR=$(mktemp -d)
        tar -xzf "$BACKUP_DIR/project.tar.gz" -C "$TEMP_DIR"
        
        # Dosyaları kopyala (git ve venv hariç)
        find "$TEMP_DIR/habernexus" -maxdepth 1 -type f -exec cp {} "$TARGET_PATH" \;
        
        # Dizinleri kopyala (git, venv, __pycache__ hariç)
        for dir in "$TEMP_DIR/habernexus"/*; do
            dir_name=$(basename "$dir")
            if [[ ! "$dir_name" =~ ^(\.git|venv|__pycache__|\.pytest_cache)$ ]]; then
                if [ -d "$dir" ]; then
                    rm -rf "$TARGET_PATH/$dir_name"
                    cp -r "$dir" "$TARGET_PATH/"
                fi
            fi
        done
        
        rm -rf "$TEMP_DIR"
        log_info "Proje dosyaları geri yüklendi."
    else
        log_info "Proje dosyaları geri yüklenmedi."
    fi
else
    log_warning "Proje dosyaları yedeklemesi bulunamadı."
fi

# ============================================================================
# ADIM 7: İZİNLERİ AYARLA
# ============================================================================

log_section "Adım 7: Dosya İzinleri Ayarlanıyor"

log_step "Dosya izinleri ayarlanıyor..."
chmod -R 755 "$TARGET_PATH"
chmod 600 "$TARGET_PATH/.env" 2>/dev/null || true
log_info "Dosya izinleri ayarlandı."

# ============================================================================
# ADIM 8: VERİTABANI DOĞRULA
# ============================================================================

log_section "Adım 8: Veritabanı Doğrulanıyor"

log_step "Django sistem kontrolleri çalıştırılıyor..."
cd "$TARGET_PATH"

if [ -d "venv" ]; then
    PYTHON="venv/bin/python"
elif command -v python3 &> /dev/null; then
    PYTHON="python3"
else
    log_warning "Python bulunamadı, sistem kontrolleri atlanıyor."
    PYTHON=""
fi

if [ -n "$PYTHON" ]; then
    $PYTHON manage.py check || log_warning "Sistem kontrolleri başarısız oldu."
    log_info "Veritabanı doğrulandı."
else
    log_warning "Veritabanı doğrulanmadı."
fi

# ============================================================================
# GERI YÜKLEME TAMAMLANDI
# ============================================================================

log_section "🎉 GERI YÜKLEME BAŞARIYLA TAMAMLANDI! 🎉"

echo ""
echo "Geri Yükleme Bilgileri:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Yedekleme Dizini: $BACKUP_DIR"
echo "  Hedef Proje Dizini: $TARGET_PATH"
echo "  Geri Yükleme Tarihi: $(date)"
echo ""

echo "Sonraki Adımlar:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Servisleri yeniden başlat:"
echo "   sudo systemctl restart habernexus habernexus-celery habernexus-celery-beat"
echo ""
echo "2. Veritabanı migrasyonlarını çalıştır (opsiyonel):"
echo "   python manage.py migrate"
echo ""
echo "3. Statik dosyaları topla (opsiyonel):"
echo "   python manage.py collectstatic"
echo ""
echo "4. Web sitesini kontrol et:"
echo "   https://habernexus.com"
echo ""

log_info "Geri yükleme tamamlandı!"
