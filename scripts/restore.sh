#!/bin/bash

#############################################################################
# Haber Nexus Restore Script
# Restores PostgreSQL database, Redis data, and media files from backup
#############################################################################

set -e

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

# Check arguments
if [ -z "$1" ]; then
    log_error "Usage: $0 <backup_path>"
    log_info "Example: $0 .backup/habernexus_backup_20231206_120000"
    exit 1
fi

BACKUP_PATH="$1"

# Check if backup exists
if [ ! -d "$BACKUP_PATH" ]; then
    log_error "Backup directory not found: $BACKUP_PATH"
    exit 1
fi

log_info "Starting restore from: $BACKUP_PATH"

# Confirm restore operation
log_warn "⚠️  WARNING: This will overwrite the current database and files!"
read -p "Are you sure you want to restore? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    log_info "Restore cancelled"
    exit 0
fi

# Stop containers
log_info "Stopping containers..."
docker-compose -f docker-compose.prod.yml down || true

# Restore PostgreSQL database
if [ -f "${BACKUP_PATH}/database.sql.gz" ]; then
    log_info "Restoring PostgreSQL database..."
    
    # Start postgres container
    docker-compose -f docker-compose.prod.yml up -d postgres
    sleep 10
    
    # Restore database
    gunzip -c "${BACKUP_PATH}/database.sql.gz" | \
    docker-compose -f docker-compose.prod.yml exec -T postgres psql \
        -U ${DB_USER:-habernexus_user} \
        -d ${DB_NAME:-habernexus}
    
    if [ $? -eq 0 ]; then
        log_info "✅ Database restored successfully"
    else
        log_error "Database restore failed"
        exit 1
    fi
else
    log_error "Database backup file not found: ${BACKUP_PATH}/database.sql.gz"
    exit 1
fi

# Restore Redis data
if [ -f "${BACKUP_PATH}/redis_dump.rdb" ]; then
    log_info "Restoring Redis data..."
    
    docker-compose -f docker-compose.prod.yml up -d redis
    sleep 5
    
    docker cp "${BACKUP_PATH}/redis_dump.rdb" habernexus-redis:/data/dump.rdb
    docker-compose -f docker-compose.prod.yml exec -T redis redis-cli SHUTDOWN
    sleep 2
    docker-compose -f docker-compose.prod.yml up -d redis
    
    log_info "✅ Redis data restored"
else
    log_warn "Redis backup file not found - skipping Redis restore"
fi

# Restore media files
if [ -f "${BACKUP_PATH}/media.tar.gz" ]; then
    log_info "Restoring media files..."
    
    # Remove old media
    rm -rf media/
    
    # Extract media
    tar -xzf "${BACKUP_PATH}/media.tar.gz"
    
    log_info "✅ Media files restored"
else
    log_warn "Media backup file not found - skipping media restore"
fi

# Restore environment file
if [ -f "${BACKUP_PATH}/.env.backup" ]; then
    log_info "Restoring environment configuration..."
    cp "${BACKUP_PATH}/.env.backup" .env
    log_info "✅ Environment configuration restored"
else
    log_warn "Environment backup file not found - skipping .env restore"
fi

# Start all containers
log_info "Starting all containers..."
docker-compose -f docker-compose.prod.yml up -d

# Wait for containers to be ready
log_info "Waiting for containers to be ready..."
sleep 15

# Run migrations
log_info "Running database migrations..."
docker-compose -f docker-compose.prod.yml exec -T web python manage.py migrate

# Collect static files
log_info "Collecting static files..."
docker-compose -f docker-compose.prod.yml exec -T web python manage.py collectstatic --noinput

# Health check
log_info "Performing health check..."
for i in {1..30}; do
    if curl -f http://localhost:8000/health/ > /dev/null 2>&1; then
        log_info "✅ Application is healthy!"
        break
    fi
    echo "Waiting for application... ($i/30)"
    sleep 2
done

log_info "✅ Restore completed successfully!"
log_info "Application is running and ready to use"
