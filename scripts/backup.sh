#!/bin/bash

#############################################################################
# Haber Nexus Backup Script
# Backs up PostgreSQL database, Redis data, and media files
#############################################################################

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-.backup}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="habernexus_backup_${TIMESTAMP}"
FULL_BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
log_info "Creating backup directory: ${FULL_BACKUP_PATH}"
mkdir -p "${FULL_BACKUP_PATH}"

# Backup PostgreSQL database
log_info "Backing up PostgreSQL database..."
docker-compose -f docker-compose.prod.yml exec -T postgres pg_dump \
    -U ${DB_USER:-habernexus_user} \
    ${DB_NAME:-habernexus} | gzip > "${FULL_BACKUP_PATH}/database.sql.gz"

if [ $? -eq 0 ]; then
    log_info "✅ Database backup completed"
else
    log_error "Database backup failed"
    exit 1
fi

# Backup Redis data
log_info "Backing up Redis data..."
docker-compose -f docker-compose.prod.yml exec -T redis redis-cli \
    --rdb /data/dump.rdb
docker cp habernexus-redis:/data/dump.rdb "${FULL_BACKUP_PATH}/redis_dump.rdb"

if [ $? -eq 0 ]; then
    log_info "✅ Redis backup completed"
else
    log_warn "Redis backup skipped (optional)"
fi

# Backup media files
log_info "Backing up media files..."
if [ -d "media" ]; then
    tar -czf "${FULL_BACKUP_PATH}/media.tar.gz" media/
    log_info "✅ Media files backup completed"
else
    log_warn "No media directory found"
fi

# Backup environment file
log_info "Backing up environment configuration..."
if [ -f ".env" ]; then
    cp .env "${FULL_BACKUP_PATH}/.env.backup"
    log_info "✅ Environment backup completed"
else
    log_warn "No .env file found"
fi

# Create backup metadata
log_info "Creating backup metadata..."
cat > "${FULL_BACKUP_PATH}/backup.info" << EOF
Backup Information
==================
Date: $(date)
Hostname: $(hostname)
Database: ${DB_NAME:-habernexus}
Database User: ${DB_USER:-habernexus_user}

Files included:
- database.sql.gz: PostgreSQL database dump
- redis_dump.rdb: Redis data snapshot
- media.tar.gz: Media files
- .env.backup: Environment configuration

To restore this backup, use:
./scripts/restore.sh ${FULL_BACKUP_PATH}
EOF

# Create compressed backup archive
log_info "Creating compressed backup archive..."
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C "${BACKUP_DIR}" "${BACKUP_NAME}"

# Calculate backup size
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)

log_info "✅ Backup completed successfully!"
log_info "Backup location: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
log_info "Backup size: ${BACKUP_SIZE}"

# Optional: Upload to cloud storage
if [ ! -z "$BACKUP_UPLOAD_ENABLED" ] && [ "$BACKUP_UPLOAD_ENABLED" = "true" ]; then
    log_info "Uploading backup to cloud storage..."
    # Add your cloud upload logic here (e.g., gsutil, aws s3, etc.)
fi

# Optional: Cleanup old backups (keep last 7 days)
if [ ! -z "$BACKUP_RETENTION_DAYS" ]; then
    log_info "Cleaning up old backups (older than ${BACKUP_RETENTION_DAYS} days)..."
    find "${BACKUP_DIR}" -name "habernexus_backup_*.tar.gz" -mtime +${BACKUP_RETENTION_DAYS} -delete
fi

log_info "Done!"
