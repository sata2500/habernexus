#!/bin/bash

#############################################################################
# Haber Nexus - Gelişmiş Yedekleme Scripti v2.0
# PostgreSQL, Redis ve medya dosyalarını yedekler.
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

# Yapılandırma
BACKUP_DIR="${BACKUP_DIR:-/var/backups/habernexus}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="habernexus_backup_${TIMESTAMP}"
FULL_BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# .env dosyasını yükle
if [ -f .env ]; then
    export $(cat .env | sed \'s/#.*//g\' | xargs)
fi

DB_USER=${DB_USER:-habernexus_user}
DB_NAME=${DB_NAME:-habernexus}

# Yedekleme dizini oluştur
log_step "Yedekleme dizini oluşturuluyor: ${FULL_BACKUP_PATH}"
mkdir -p "${FULL_BACKUP_PATH}"

# PostgreSQL yedekleme
log_step "PostgreSQL veritabanı yedekleniyor..."
docker-compose -f docker-compose.prod.yml exec -T postgres pg_dump -U "$DB_USER" -d "$DB_NAME" | gzip > "${FULL_BACKUP_PATH}/database.sql.gz"
log_info "Veritabanı yedeklemesi tamamlandı."

# Redis yedekleme
log_step "Redis verisi yedekleniyor..."
docker-compose -f docker-compose.prod.yml exec -T redis redis-cli SAVE
docker cp habernexus-redis:/data/dump.rdb "${FULL_BACKUP_PATH}/redis_dump.rdb"
log_info "Redis yedeklemesi tamamlandı."

# Medya dosyaları yedekleme
log_step "Medya dosyaları yedekleniyor..."
if [ -d "media" ]; then
    tar -czf "${FULL_BACKUP_PATH}/media.tar.gz" media/
    log_info "Medya dosyaları yedeklemesi tamamlandı."
else
    log_warning "Medya dizini bulunamadı."
fi

# .env dosyası yedekleme
log_step ".env dosyası yedekleniyor..."
if [ -f ".env" ]; then
    cp .env "${FULL_BACKUP_PATH}/.env.backup"
    log_info ".env dosyası yedeklemesi tamamlandı."
else
    log_warning ".env dosyası bulunamadı."
fi

# Yedekleme metadata oluşturma
log_step "Yedekleme metadata oluşturuluyor..."
cat > "${FULL_BACKUP_PATH}/backup.info" << EOF
Backup Information
==================
Date: $(date)
Hostname: $(hostname)
Database: $DB_NAME
Database User: $DB_USER

Files included:
- database.sql.gz
- redis_dump.rdb
- media.tar.gz
- .env.backup
EOF

# Sıkıştırılmış yedek arşivi oluşturma
log_step "Sıkıştırılmış yedek arşivi oluşturuluyor..."
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C "${BACKUP_DIR}" "${BACKUP_NAME}"
rm -rf "${FULL_BACKUP_PATH}"

BACKUP_SIZE=$(du -sh "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)

log_info "✅ Yedekleme başarıyla tamamlandı!"
log_info "Yedekleme konumu: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
log_info "Yedekleme boyutu: ${BACKUP_SIZE}"

# Eski yedeklemeleri temizleme (son 7 gün tutulur)
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}
log_step "Eski yedeklemeler temizleniyor (son ${BACKUP_RETENTION_DAYS} gün)..."
find "${BACKUP_DIR}" -name "habernexus_backup_*.tar.gz" -mtime +$BACKUP_RETENTION_DAYS -delete
log_info "Temizleme tamamlandı."

log_info "İşlem tamamlandı!"
