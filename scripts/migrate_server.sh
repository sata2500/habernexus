#!/bin/bash

################################################################################
# Haber Nexus - Server Migration Utility
# Easily migrate your Haber Nexus instance to a new server.
# Features: Backup creation, Transfer (via scp/rsync), Restore
################################################################################

set -eo pipefail

# --- Configuration ---
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="habernexus_migration_${TIMESTAMP}.tar.gz"

# --- Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_step() { echo -e "\n${BLUE}==>${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Functions ---

create_backup() {
    log_step "Creating full system backup..."
    mkdir -p "$BACKUP_DIR"

    # 1. Backup Database
    log_info "Backing up database..."
    docker compose -f docker-compose.prod.yml exec -T postgres pg_dump -U habernexus_user habernexus > "$BACKUP_DIR/db_dump.sql"

    # 2. Backup Media Files
    log_info "Backing up media files..."
    tar -czf "$BACKUP_DIR/media.tar.gz" media/

    # 3. Backup Environment Variables
    log_info "Backing up configuration..."
    cp .env "$BACKUP_DIR/.env.backup"

    # 4. Create Final Archive
    log_info "Creating migration archive..."
    tar -czf "$ARCHIVE_NAME" -C "$BACKUP_DIR" db_dump.sql media.tar.gz .env.backup

    # Cleanup temp files
    rm "$BACKUP_DIR/db_dump.sql" "$BACKUP_DIR/media.tar.gz" "$BACKUP_DIR/.env.backup"

    log_info "Backup created: $ARCHIVE_NAME"
}

restore_backup() {
    local archive_path=$1
    
    if [ -z "$archive_path" ]; then
        log_error "Usage: ./migrate_server.sh restore <path_to_archive>"
    fi

    log_step "Restoring from backup: $archive_path"

    # 1. Extract Archive
    mkdir -p "$BACKUP_DIR/restore_temp"
    tar -xzf "$archive_path" -C "$BACKUP_DIR/restore_temp"

    # 2. Restore Environment
    if [ ! -f .env ]; then
        log_info "Restoring .env file..."
        cp "$BACKUP_DIR/restore_temp/.env.backup" .env
    else
        log_info ".env already exists. Skipping overwrite."
    fi

    # 3. Start Containers (if not running)
    log_info "Ensuring containers are running..."
    docker compose -f docker-compose.prod.yml up -d postgres
    sleep 5 # Wait for DB

    # 4. Restore Database
    log_info "Restoring database..."
    # Drop existing connections/db and recreate might be needed for clean restore, 
    # but for now we assume a fresh or compatible DB.
    cat "$BACKUP_DIR/restore_temp/db_dump.sql" | docker compose -f docker-compose.prod.yml exec -T postgres psql -U habernexus_user habernexus

    # 5. Restore Media
    log_info "Restoring media files..."
    tar -xzf "$BACKUP_DIR/restore_temp/media.tar.gz" -C .

    # Cleanup
    rm -rf "$BACKUP_DIR/restore_temp"

    log_info "Restore complete! Please restart your services: docker compose -f docker-compose.prod.yml up -d --build"
}

# --- Main ---

case "$1" in
    backup)
        create_backup
        ;;
    restore)
        restore_backup "$2"
        ;;
    *)
        echo "Usage: $0 {backup|restore <archive_path>}"
        exit 1
        ;;
esac
