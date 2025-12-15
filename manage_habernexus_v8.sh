#!/bin/bash

################################################################################
# HaberNexus v8.0 - Advanced Management & Maintenance Script
# 
# Purpose: Comprehensive management, monitoring, and maintenance of HaberNexus
# Features:
#   - Service management (start, stop, restart, status)
#   - Health monitoring and diagnostics
#   - Database backup and restore
#   - User management
#   - Log viewing and analysis
#   - Performance monitoring
#   - Automatic maintenance tasks
#   - Troubleshooting tools
#
# Usage: bash manage_habernexus_v8.sh [COMMAND] [OPTIONS]
#
# Author: Salih TANRISEVEN
# Date: December 15, 2025
# Version: 8.0
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_VERSION="8.0"
readonly PROJECT_PATH="${PROJECT_PATH:-/opt/habernexus}"
readonly LOG_DIR="/var/log/habernexus"
readonly BACKUP_DIR="${PROJECT_PATH}/.backups"
readonly COMPOSE_FILE="${PROJECT_PATH}/docker-compose.yml"

# ============================================================================
# COLORS & SYMBOLS
# ============================================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

readonly CHECK="✓"
readonly CROSS="✗"
readonly WARNING="⚠"
readonly INFO="ℹ"
readonly ARROW="→"
readonly BULLET="•"
readonly GEAR="⚙"
readonly ROCKET="🚀"
readonly DATABASE="🗄"
readonly CLOCK="🕐"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}$*${NC}$(printf '%*s' $((66 - ${#1})) '')${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${MAGENTA}${ARROW} ${BOLD}$*${NC}"
    echo -e "${GRAY}$(printf '─%.0s' $(seq 1 60))${NC}"
}

log_success() {
    echo -e "${GREEN}[${CHECK}]${NC} $*"
}

log_error() {
    echo -e "${RED}[${CROSS}]${NC} $*"
}

log_info() {
    echo -e "${BLUE}[${INFO}]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[${WARNING}]${NC} $*"
}

check_project() {
    if [[ ! -d "$PROJECT_PATH" ]]; then
        log_error "Proje dizini bulunamadı: $PROJECT_PATH"
        log_info "Kurulum için: sudo bash install_v8.sh"
        exit 1
    fi
    
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "docker-compose.yml bulunamadı"
        exit 1
    fi
}

# ============================================================================
# SERVICE MANAGEMENT
# ============================================================================

cmd_status() {
    print_header "${GEAR} Servis Durumu"
    
    check_project
    cd "$PROJECT_PATH"
    
    print_section "Docker Container'ları"
    docker-compose ps
    
    echo ""
    print_section "Servis Sağlığı"
    
    local services=("postgres" "redis" "app" "caddy" "celery" "celery_beat" "flower" "cloudflared")
    
    for service in "${services[@]}"; do
        local status=$(docker-compose ps "$service" 2>/dev/null | grep -E "Up|running" | wc -l || echo "0")
        
        if [[ $status -gt 0 ]]; then
            local health=$(docker-compose ps "$service" 2>/dev/null | grep -o "(healthy)" || echo "")
            log_success "$service çalışıyor $health"
        else
            log_error "$service çalışmıyor"
        fi
    done
    
    echo ""
    print_section "Kaynak Kullanımı"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null | head -10 || true
}

cmd_start() {
    print_header "${ROCKET} Servisleri Başlat"
    
    check_project
    cd "$PROJECT_PATH"
    
    log_info "Servisler başlatılıyor..."
    
    if docker-compose up -d; then
        log_success "Tüm servisler başlatıldı"
        sleep 3
        cmd_status
    else
        log_error "Servisler başlatılamadı"
        exit 1
    fi
}

cmd_stop() {
    print_header "Servisleri Durdur"
    
    check_project
    cd "$PROJECT_PATH"
    
    log_info "Servisler durduruluyor..."
    
    if docker-compose down; then
        log_success "Tüm servisler durduruldu"
    else
        log_error "Servisler durdurulamadı"
        exit 1
    fi
}

cmd_restart() {
    local service="${1:-}"
    
    check_project
    cd "$PROJECT_PATH"
    
    if [[ -n "$service" ]]; then
        print_header "Servisi Yeniden Başlat: $service"
        log_info "$service yeniden başlatılıyor..."
        docker-compose restart "$service"
        log_success "$service yeniden başlatıldı"
    else
        print_header "Tüm Servisleri Yeniden Başlat"
        log_info "Tüm servisler yeniden başlatılıyor..."
        docker-compose restart
        log_success "Tüm servisler yeniden başlatıldı"
    fi
    
    sleep 3
    cmd_status
}

# ============================================================================
# HEALTH & MONITORING
# ============================================================================

cmd_health() {
    print_header "Sistem Sağlık Kontrolü"
    
    check_project
    cd "$PROJECT_PATH"
    
    local checks_passed=0
    local checks_failed=0
    
    print_section "Container Durumu"
    local running=$(docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l)
    local total=$(docker-compose config --services 2>/dev/null | wc -l)
    
    if [[ $running -ge $((total - 1)) ]]; then
        log_success "Container'lar: $running/$total çalışıyor"
        ((checks_passed++))
    else
        log_warning "Container'lar: $running/$total çalışıyor"
    fi
    
    print_section "Veritabanı Bağlantısı"
    if docker-compose exec -T postgres pg_isready -U habernexus > /dev/null 2>&1; then
        log_success "PostgreSQL bağlantısı aktif"
        ((checks_passed++))
    else
        log_error "PostgreSQL bağlantısı yok"
        ((checks_failed++))
    fi
    
    print_section "Redis Bağlantısı"
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        log_success "Redis bağlantısı aktif"
        ((checks_passed++))
    else
        log_error "Redis bağlantısı yok"
        ((checks_failed++))
    fi
    
    print_section "Uygulama Durumu"
    if docker-compose exec -T app python manage.py check > /dev/null 2>&1; then
        log_success "Django uygulaması sağlıklı"
        ((checks_passed++))
    else
        log_warning "Django kontrolü başarısız"
    fi
    
    print_section "Disk Kullanımı"
    local disk_usage=$(df -h "$PROJECT_PATH" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -lt 80 ]]; then
        log_success "Disk kullanımı: ${disk_usage}%"
        ((checks_passed++))
    elif [[ $disk_usage -lt 90 ]]; then
        log_warning "Disk kullanımı yüksek: ${disk_usage}%"
    else
        log_error "Disk kullanımı kritik: ${disk_usage}%"
        ((checks_failed++))
    fi
    
    echo ""
    print_section "Özet"
    echo -e "${GREEN}Başarılı:${NC} $checks_passed  ${RED}Başarısız:${NC} $checks_failed"
    
    if [[ $checks_failed -eq 0 ]]; then
        echo ""
        log_success "Sistem sağlıklı!"
    else
        echo ""
        log_warning "Bazı kontroller başarısız oldu"
    fi
}

cmd_logs() {
    local service="${1:-app}"
    local lines="${2:-100}"
    
    print_header "Loglar: $service (son $lines satır)"
    
    check_project
    cd "$PROJECT_PATH"
    
    docker-compose logs --tail="$lines" -f "$service"
}

# ============================================================================
# DATABASE MANAGEMENT
# ============================================================================

cmd_backup_db() {
    print_header "${DATABASE} Veritabanı Yedeği"
    
    check_project
    cd "$PROJECT_PATH"
    
    mkdir -p "$BACKUP_DIR"
    
    local backup_file="${BACKUP_DIR}/db_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    log_info "Veritabanı yedekleniyor..."
    
    if docker-compose exec -T postgres pg_dump -U habernexus habernexus > "$backup_file"; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "Yedek oluşturuldu: $backup_file ($size)"
    else
        log_error "Yedekleme başarısız"
        exit 1
    fi
}

cmd_restore_db() {
    local backup_file="${1:-}"
    
    if [[ -z "$backup_file" ]]; then
        print_header "Mevcut Yedekler"
        
        if [[ -d "$BACKUP_DIR" ]]; then
            ls -lh "$BACKUP_DIR"/*.sql 2>/dev/null || log_info "Yedek bulunamadı"
        fi
        
        echo ""
        log_info "Kullanım: $0 restore-db <yedek_dosyası>"
        return
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Yedek dosyası bulunamadı: $backup_file"
        exit 1
    fi
    
    print_header "Veritabanı Geri Yükleme"
    
    log_warning "Bu işlem mevcut veritabanının üzerine yazacak!"
    read -p "Devam etmek istiyor musunuz? (evet/hayır): " confirm
    
    if [[ "$confirm" != "evet" ]]; then
        log_info "İşlem iptal edildi"
        return
    fi
    
    check_project
    cd "$PROJECT_PATH"
    
    log_info "Veritabanı geri yükleniyor..."
    
    if docker-compose exec -T postgres psql -U habernexus habernexus < "$backup_file"; then
        log_success "Veritabanı geri yüklendi"
    else
        log_error "Geri yükleme başarısız"
        exit 1
    fi
}

cmd_migrate() {
    print_header "Veritabanı Migrasyonları"
    
    check_project
    cd "$PROJECT_PATH"
    
    log_info "Migrasyonlar çalıştırılıyor..."
    
    if docker-compose exec -T app python manage.py migrate; then
        log_success "Migrasyonlar tamamlandı"
    else
        log_error "Migrasyon hatası"
        exit 1
    fi
}

# ============================================================================
# USER MANAGEMENT
# ============================================================================

cmd_create_user() {
    local username="${1:-}"
    local email="${2:-}"
    local password="${3:-}"
    
    if [[ -z "$username" || -z "$email" ]]; then
        log_info "Kullanım: $0 create-user <kullanıcı_adı> <email> [şifre]"
        return
    fi
    
    print_header "Admin Kullanıcısı Oluştur"
    
    check_project
    cd "$PROJECT_PATH"
    
    if [[ -z "$password" ]]; then
        password=$(python3 -c 'import secrets; print(secrets.token_urlsafe(12))')
        log_info "Otomatik şifre: $password"
    fi
    
    log_info "Kullanıcı oluşturuluyor: $username"
    
    docker-compose exec -T app python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()

if User.objects.filter(username='$username').exists():
    print("Kullanıcı zaten mevcut")
else:
    User.objects.create_superuser('$username', '$email', '$password')
    print("Kullanıcı oluşturuldu")
EOF
    
    log_success "İşlem tamamlandı"
}

cmd_change_password() {
    local username="${1:-}"
    local new_password="${2:-}"
    
    if [[ -z "$username" ]]; then
        log_info "Kullanım: $0 change-password <kullanıcı_adı> [yeni_şifre]"
        return
    fi
    
    print_header "Şifre Değiştir: $username"
    
    check_project
    cd "$PROJECT_PATH"
    
    if [[ -z "$new_password" ]]; then
        new_password=$(python3 -c 'import secrets; print(secrets.token_urlsafe(12))')
        log_info "Yeni şifre: $new_password"
    fi
    
    docker-compose exec -T app python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()

try:
    user = User.objects.get(username='$username')
    user.set_password('$new_password')
    user.save()
    print("Şifre değiştirildi")
except User.DoesNotExist:
    print("Kullanıcı bulunamadı")
EOF
    
    log_success "İşlem tamamlandı"
}

cmd_list_users() {
    print_header "Kullanıcı Listesi"
    
    check_project
    cd "$PROJECT_PATH"
    
    docker-compose exec -T app python manage.py shell << 'EOF'
from django.contrib.auth import get_user_model
User = get_user_model()

print(f"{'Kullanıcı':<20} {'E-posta':<30} {'Admin':<8} {'Aktif':<8}")
print("-" * 70)

for user in User.objects.all():
    print(f"{user.username:<20} {user.email:<30} {'Evet' if user.is_superuser else 'Hayır':<8} {'Evet' if user.is_active else 'Hayır':<8}")
EOF
}

# ============================================================================
# MAINTENANCE
# ============================================================================

cmd_cleanup() {
    print_header "Sistem Temizliği"
    
    check_project
    cd "$PROJECT_PATH"
    
    print_section "Docker Temizliği"
    log_info "Kullanılmayan Docker kaynakları temizleniyor..."
    docker system prune -f
    log_success "Docker temizliği tamamlandı"
    
    print_section "Eski Loglar"
    log_info "30 günden eski loglar temizleniyor..."
    find "$LOG_DIR" -name "*.log" -type f -mtime +30 -delete 2>/dev/null || true
    log_success "Eski loglar temizlendi"
    
    print_section "Eski Yedekler"
    log_info "30 günden eski yedekler temizleniyor..."
    find "$BACKUP_DIR" -name "*.sql" -type f -mtime +30 -delete 2>/dev/null || true
    log_success "Eski yedekler temizlendi"
    
    log_success "Temizlik tamamlandı"
}

cmd_update() {
    print_header "Sistem Güncelleme"
    
    check_project
    cd "$PROJECT_PATH"
    
    print_section "Kod Güncelleme"
    log_info "En son değişiklikler alınıyor..."
    git fetch origin
    git pull origin main
    log_success "Kod güncellendi"
    
    print_section "Docker İmajları"
    log_info "İmajlar yeniden oluşturuluyor..."
    docker-compose build
    log_success "İmajlar güncellendi"
    
    print_section "Servisleri Yeniden Başlat"
    docker-compose up -d
    log_success "Servisler yeniden başlatıldı"
    
    print_section "Migrasyonlar"
    docker-compose exec -T app python manage.py migrate --noinput
    log_success "Migrasyonlar tamamlandı"
    
    log_success "Güncelleme tamamlandı!"
}

cmd_full_backup() {
    print_header "Tam Sistem Yedeği"
    
    check_project
    cd "$PROJECT_PATH"
    
    local backup_name="full_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    mkdir -p "$backup_path"
    
    print_section "Veritabanı Yedeği"
    docker-compose exec -T postgres pg_dump -U habernexus habernexus > "${backup_path}/database.sql"
    log_success "Veritabanı yedeklendi"
    
    print_section "Yapılandırma Dosyaları"
    cp "${PROJECT_PATH}/.env" "${backup_path}/" 2>/dev/null || true
    cp "${PROJECT_PATH}/docker-compose.yml" "${backup_path}/" 2>/dev/null || true
    log_success "Yapılandırma yedeklendi"
    
    print_section "Arşiv Oluşturma"
    tar -czf "${BACKUP_DIR}/${backup_name}.tar.gz" -C "$BACKUP_DIR" "$backup_name"
    rm -rf "$backup_path"
    
    local size=$(du -h "${BACKUP_DIR}/${backup_name}.tar.gz" | cut -f1)
    log_success "Tam yedek oluşturuldu: ${BACKUP_DIR}/${backup_name}.tar.gz ($size)"
}

# ============================================================================
# TROUBLESHOOTING
# ============================================================================

cmd_troubleshoot() {
    print_header "Sorun Giderme Tanılaması"
    
    check_project
    cd "$PROJECT_PATH"
    
    print_section "Sistem Bilgisi"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Kernel: $(uname -r)"
    echo "Docker: $(docker --version 2>/dev/null || echo 'Kurulu değil')"
    
    print_section "Disk Kullanımı"
    df -h "$PROJECT_PATH"
    
    print_section "Bellek Kullanımı"
    free -h
    
    print_section "Container Durumu"
    docker-compose ps
    
    print_section "Son Hatalar (app)"
    docker-compose logs --tail=20 app 2>/dev/null | grep -i "error\|exception\|failed" || echo "Hata bulunamadı"
    
    print_section "Son Hatalar (postgres)"
    docker-compose logs --tail=10 postgres 2>/dev/null | grep -i "error\|fatal" || echo "Hata bulunamadı"
    
    print_section "Ağ Durumu"
    docker network ls | grep habernexus || echo "Ağ bulunamadı"
    
    print_section "Volume Durumu"
    docker volume ls | grep habernexus || echo "Volume bulunamadı"
}

# ============================================================================
# HELP
# ============================================================================

cmd_help() {
    cat << EOF

${CYAN}${BOLD}HaberNexus v${SCRIPT_VERSION} - Yönetim Scripti${NC}

${WHITE}Kullanım:${NC}
  bash manage_habernexus_v8.sh [KOMUT] [SEÇENEKLER]

${WHITE}Servis Yönetimi:${NC}
  ${GREEN}status${NC}              Servis durumunu göster
  ${GREEN}start${NC}               Tüm servisleri başlat
  ${GREEN}stop${NC}                Tüm servisleri durdur
  ${GREEN}restart${NC} [servis]    Servisleri yeniden başlat

${WHITE}Sağlık & İzleme:${NC}
  ${GREEN}health${NC}              Sistem sağlık kontrolü
  ${GREEN}logs${NC} [servis] [n]   Logları görüntüle (varsayılan: app, 100 satır)
  ${GREEN}troubleshoot${NC}        Sorun giderme tanılaması

${WHITE}Veritabanı:${NC}
  ${GREEN}backup-db${NC}           Veritabanı yedeği al
  ${GREEN}restore-db${NC} <dosya>  Veritabanını geri yükle
  ${GREEN}migrate${NC}             Migrasyonları çalıştır

${WHITE}Kullanıcı Yönetimi:${NC}
  ${GREEN}create-user${NC} <ad> <email> [şifre]   Admin kullanıcısı oluştur
  ${GREEN}change-password${NC} <ad> [şifre]      Şifre değiştir
  ${GREEN}list-users${NC}                        Kullanıcıları listele

${WHITE}Bakım:${NC}
  ${GREEN}cleanup${NC}             Sistem temizliği
  ${GREEN}update${NC}              Sistemi güncelle
  ${GREEN}full-backup${NC}         Tam sistem yedeği

${WHITE}Örnekler:${NC}
  ${GRAY}# Servis durumunu kontrol et${NC}
  bash manage_habernexus_v8.sh status

  ${GRAY}# Uygulama loglarını görüntüle${NC}
  bash manage_habernexus_v8.sh logs app 50

  ${GRAY}# Yeni admin oluştur${NC}
  bash manage_habernexus_v8.sh create-user admin admin@example.com

EOF
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        status)
            cmd_status
            ;;
        start)
            cmd_start
            ;;
        stop)
            cmd_stop
            ;;
        restart)
            cmd_restart "$@"
            ;;
        health)
            cmd_health
            ;;
        logs)
            cmd_logs "$@"
            ;;
        backup-db)
            cmd_backup_db
            ;;
        restore-db)
            cmd_restore_db "$@"
            ;;
        migrate)
            cmd_migrate
            ;;
        create-user)
            cmd_create_user "$@"
            ;;
        change-password)
            cmd_change_password "$@"
            ;;
        list-users)
            cmd_list_users
            ;;
        cleanup)
            cmd_cleanup
            ;;
        update)
            cmd_update
            ;;
        full-backup)
            cmd_full_backup
            ;;
        troubleshoot)
            cmd_troubleshoot
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            log_error "Bilinmeyen komut: $command"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
