#!/bin/bash

#############################################################################
# Haber Nexus - Gelişmiş Geri Yükleme Scripti v2.0
# PostgreSQL, Redis ve medya dosyalarını geri yükler.
# Geliştirici: Salih TANRISEVEN & Manus AI
#############################################################################

set -eo pipefail

# Renkler ve Loglama
RED=\'\033[0;31m\'
GREEN=\'\033[0;32m\'
YELLOW=\'\033[1;33m\'
BLUE=\'\033[0;34m\'
NC=\'\033[0m\'

log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_step() { echo -e "\n${BLUE}==>${NC} $1"; }

# Hata Yakalama
trap \'log_error "Satır $LINENO: Komut başarısız oldu: $BASH_COMMAND"\' ERR

# Argüman kontrolü
if [ -z "$1" ]; then
    log_error "Kullanım: $0 <yedek_dosyasi.tar.gz>"
    log_info "Örnek: $0 /var/backups/habernexus/habernexus_backup_20231206_120000.tar.gz"
    exit 1
fi

BACKUP_ARCHIVE="$1"

if [ ! -f "$BACKUP_ARCHIVE" ]; then
    log_error "Yedek dosyası bulunamadı: $BACKUP_ARCHIVE"
fi

# Onay
log_warning "Bu işlem mevcut verileri SİLECEK ve yedekten geri yükleyecektir."
read -p "Devam etmek istiyor musunuz? (y/n): " -n 1 -r
echo ""
[[ ! $REPLY =~ ^[Yy]$ ]] && log_error "Geri yükleme iptal edildi."

# Yedek dosyasını açma
TEMP_DIR="/tmp/habernexus_restore_$(date +%s)"
mkdir -p "$TEMP_DIR"
tar -xzf "$BACKUP_ARCHIVE" -C "$TEMP_DIR"
BACKUP_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d)

# .env dosyasını yükle
if [ -f .env ]; then
    export $(cat .env | sed \'s/#.*//g\' | xargs)
fi

DB_USER=${DB_USER:-habernexus_user}
DB_NAME=${DB_NAME:-habernexus}

# Servisleri durdurma
log_step "Servisler durduruluyor..."
docker-compose -f docker-compose.prod.yml down -v --remove-orphans 2>/dev/null || true
log_info "Servisler durduruldu."

# PostgreSQL geri yükleme
log_step "PostgreSQL veritabanı geri yükleniyor..."
docker-compose -f docker-compose.prod.yml up -d postgres
sleep 10 # PostgreSQL'in başlaması için bekle
docker-compose -f docker-compose.prod.yml exec -T postgres dropdb -U "$DB_USER" "$DB_NAME" --if-exists
docker-compose -f docker-compose.prod.yml exec -T postgres createdb -U "$DB_USER" "$DB_NAME"
gunzip -c "$BACKUP_DIR/database.sql.gz" | docker-compose -f docker-compose.prod.yml exec -T postgres psql -U "$DB_USER" -d "$DB_NAME"
log_info "Veritabanı geri yüklendi."

# Redis geri yükleme
log_step "Redis verisi geri yükleniyor..."
docker-compose -f docker-compose.prod.yml up -d redis
sleep 5
docker cp "$BACKUP_DIR/redis_dump.rdb" habernexus-redis:/data/dump.rdb
docker-compose -f docker-compose.prod.yml restart redis
log_info "Redis geri yüklendi."

# Medya dosyaları geri yükleme
log_step "Medya dosyaları geri yükleniyor..."
if [ -f "$BACKUP_DIR/media.tar.gz" ]; then
    rm -rf media/
    tar -xzf "$BACKUP_DIR/media.tar.gz"
    log_info "Medya dosyaları geri yüklendi."
else
    log_warning "Medya yedek dosyası bulunamadı."
fi

# .env dosyası geri yükleme
log_step ".env dosyası geri yükleniyor..."
if [ -f "$BACKUP_DIR/.env.backup" ]; then
    cp "$BACKUP_DIR/.env.backup" .env
    log_info ".env dosyası geri yüklendi."
else
    log_warning ".env yedek dosyası bulunamadı."
fi

# Servisleri başlatma
log_step "Tüm servisler başlatılıyor..."
docker-compose -f docker-compose.prod.yml up -d --remove-orphans
log_info "Servisler başlatıldı."

# Temizlik
rm -rf "$TEMP_DIR"

log_info "✅ Geri yükleme başarıyla tamamlandı!"
