#!/bin/bash

#############################################################################
# Haber Nexus - Sistem Sağlığı Kontrol Scripti v1.0
# Docker, servisler ve sistem kaynaklarını kontrol eder.
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
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_step() { echo -e "\n${BLUE}==>${NC} $1"; }

# Hata Yakalama
trap \'log_error "Satır $LINENO: Komut başarısız oldu: $BASH_COMMAND"\' ERR

log_step "Haber Nexus Sistem Sağlığı Kontrolü"

# Docker Container Durumu
log_step "Docker Container Durumu"
docker-compose -f docker-compose.prod.yml ps

# Servis Durumları
log_step "Servis Durumları"
for service in web postgres redis celery celery_beat nginx; do
    status=$(docker-compose -f docker-compose.prod.yml ps -q $service | xargs docker inspect --format='{{.State.Status}}')
    if [ "$status" == "running" ]; then
        log_info "$service: $status"
    else
        log_error "$service: $status"
    fi
done

# Veritabanı Bağlantısı
log_step "Veritabanı Bağlantısı"
if docker-compose -f docker-compose.prod.yml exec -T postgres pg_isready -U habernexus_user &>/dev/null; then
    log_info "PostgreSQL bağlantısı başarılı."
else
    log_error "PostgreSQL bağlantısı başarısız."
fi

# Redis Bağlantısı
log_step "Redis Bağlantısı"
if docker-compose -f docker-compose.prod.yml exec -T redis redis-cli PING | grep -q PONG; then
    log_info "Redis bağlantısı başarılı."
else
    log_error "Redis bağlantısı başarısız."
fi

# Web Arayüzü
log_step "Web Arayüzü"
if curl -s --head http://localhost | head -n 1 | grep "200 OK" > /dev/null; then
    log_info "Web arayüzü çalışıyor."
else
    log_error "Web arayüzü çalışmıyor."
fi

# Sistem Kaynakları
log_step "Sistem Kaynakları"
log_info "Disk Kullanımı:"
df -h /
log_info "RAM Kullanımı:"
free -h

log_info "✅ Sistem sağlığı kontrolü tamamlandı."
