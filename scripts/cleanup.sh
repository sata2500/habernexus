#!/bin/bash
# =============================================================================
# HaberNexus - Cleanup & Reset System v11.0.0
# =============================================================================
#
# Kurulumu temizleme ve sıfırlama sistemi.
#
# KULLANIM:
#   Servisleri durdur:
#     sudo bash scripts/cleanup.sh --stop
#
#   Container'ları temizle (volume'ları koru):
#     sudo bash scripts/cleanup.sh --soft
#
#   Tam temizlik (volume'lar dahil):
#     sudo bash scripts/cleanup.sh --hard
#
#   Tamamen kaldır:
#     sudo bash scripts/cleanup.sh --uninstall
#
# Geliştirici: Salih TANRISEVEN
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly SCRIPT_VERSION="11.0.0"
readonly INSTALL_DIR="${INSTALL_DIR:-/opt/habernexus}"
readonly BACKUP_DIR="${BACKUP_DIR:-/var/backups/habernexus}"
readonly LOG_DIR="/var/log/habernexus"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# LOGGING
# =============================================================================

info() { echo -e "${BLUE}•${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }
fatal() { error "$*"; exit 1; }
step() { echo -e "\n${CYAN}==>${NC} ${BOLD}$*${NC}"; }

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

check_root() {
    [[ $EUID -eq 0 ]] || fatal "Bu script root yetkisi gerektirir."
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    if [[ "$default" == "y" ]]; then
        echo -n -e "$prompt [E/h]: "
    else
        echo -n -e "$prompt [e/H]: "
    fi
    read -r response
    
    [[ "$response" =~ ^[eEyY]$ ]]
}

get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$(cd -P "$(dirname "$source")/.." && pwd)"
}

find_install_dir() {
    local script_dir
    script_dir=$(get_script_dir)
    
    if [[ -f "$script_dir/docker-compose.prod.yml" ]]; then
        echo "$script_dir"
    elif [[ -f "$INSTALL_DIR/docker-compose.prod.yml" ]]; then
        echo "$INSTALL_DIR"
    elif [[ -f "./docker-compose.prod.yml" ]]; then
        echo "$(pwd)"
    else
        echo ""
    fi
}

# =============================================================================
# CLEANUP FUNCTIONS
# =============================================================================

stop_services() {
    step "Servisler durduruluyor"
    
    local install_dir
    install_dir=$(find_install_dir)
    
    if [[ -n "$install_dir" ]]; then
        cd "$install_dir"
        
        # Docker Compose ile durdur
        if [[ -f "docker-compose.prod.yml" ]]; then
            docker compose -f docker-compose.prod.yml down 2>/dev/null || true
        fi
        if [[ -f "docker-compose.yml" ]]; then
            docker compose down 2>/dev/null || true
        fi
        if [[ -f "docker-compose.override.yml" ]]; then
            docker compose -f docker-compose.prod.yml -f docker-compose.override.yml down 2>/dev/null || true
        fi
    fi
    
    # Tek tek container'ları durdur
    local containers=$(docker ps -a --filter "name=habernexus" --format '{{.Names}}' 2>/dev/null || true)
    for container in $containers; do
        info "Durduruluyor: $container"
        docker stop "$container" 2>/dev/null || true
    done
    
    # İlgili diğer container'ları da durdur
    for container in cloudflared caddy postgres redis; do
        if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
            info "Durduruluyor: $container"
            docker stop "$container" 2>/dev/null || true
        fi
    done
    
    success "Servisler durduruldu"
}

remove_containers() {
    step "Container'lar siliniyor"
    
    # HaberNexus container'ları
    local containers=$(docker ps -a --filter "name=habernexus" --format '{{.Names}}' 2>/dev/null || true)
    for container in $containers; do
        info "Siliniyor: $container"
        docker rm -f "$container" 2>/dev/null || true
    done
    
    # İlgili diğer container'lar
    for container in cloudflared caddy postgres redis; do
        if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
            info "Siliniyor: $container"
            docker rm -f "$container" 2>/dev/null || true
        fi
    done
    
    success "Container'lar silindi"
}

remove_volumes() {
    step "Docker volume'ları siliniyor"
    
    # İsimle eşleşen volume'lar
    local volumes=$(docker volume ls -q --filter "name=habernexus" 2>/dev/null || true)
    for volume in $volumes; do
        info "Siliniyor: $volume"
        docker volume rm "$volume" 2>/dev/null || true
    done
    
    # Bilinen volume isimleri
    for volume in postgres_data redis_data static_files media_files caddy_data caddy_config; do
        if docker volume ls -q 2>/dev/null | grep -q "^${volume}$"; then
            info "Siliniyor: $volume"
            docker volume rm "$volume" 2>/dev/null || true
        fi
    done
    
    success "Volume'lar silindi"
}

remove_networks() {
    step "Docker network'leri siliniyor"
    
    # HaberNexus network'leri
    local networks=$(docker network ls -q --filter "name=habernexus" 2>/dev/null || true)
    for network in $networks; do
        info "Siliniyor: $network"
        docker network rm "$network" 2>/dev/null || true
    done
    
    success "Network'ler silindi"
}

remove_images() {
    step "Docker imajları siliniyor"
    
    # HaberNexus imajları
    local images=$(docker images --filter "reference=*habernexus*" -q 2>/dev/null || true)
    for image in $images; do
        info "Siliniyor: $image"
        docker rmi -f "$image" 2>/dev/null || true
    done
    
    success "İmajlar silindi"
}

remove_install_dir() {
    step "Kurulum dizini siliniyor"
    
    local install_dir
    install_dir=$(find_install_dir)
    
    if [[ -n "$install_dir" ]] && [[ -d "$install_dir" ]]; then
        info "Siliniyor: $install_dir"
        rm -rf "$install_dir"
        success "Kurulum dizini silindi"
    else
        info "Kurulum dizini bulunamadı"
    fi
}

remove_logs() {
    step "Log dosyaları siliniyor"
    
    if [[ -d "$LOG_DIR" ]]; then
        info "Siliniyor: $LOG_DIR"
        rm -rf "$LOG_DIR"
        success "Log dosyaları silindi"
    else
        info "Log dizini bulunamadı"
    fi
}

remove_backups() {
    step "Yedek dosyaları siliniyor"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        info "Siliniyor: $BACKUP_DIR"
        rm -rf "$BACKUP_DIR"
        success "Yedek dosyaları silindi"
    else
        info "Yedek dizini bulunamadı"
    fi
}

remove_systemd_services() {
    step "Systemd servisleri kaldırılıyor"
    
    for service in habernexus caddy cloudflared; do
        if [[ -f "/etc/systemd/system/${service}.service" ]]; then
            info "Kaldırılıyor: ${service}.service"
            systemctl stop "$service" 2>/dev/null || true
            systemctl disable "$service" 2>/dev/null || true
            rm -f "/etc/systemd/system/${service}.service"
        fi
    done
    
    systemctl daemon-reload 2>/dev/null || true
    success "Systemd servisleri kaldırıldı"
}

prune_docker() {
    step "Docker temizliği yapılıyor"
    
    docker system prune -f 2>/dev/null || true
    success "Docker temizliği tamamlandı"
}

# =============================================================================
# CLEANUP LEVELS
# =============================================================================

cleanup_stop() {
    echo ""
    echo -e "${CYAN}${BOLD}HaberNexus - Servisleri Durdurma${NC}"
    echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
    echo ""
    
    info "Bu işlem tüm HaberNexus servislerini durduracak."
    info "Veriler ve yapılandırma korunacak."
    echo ""
    
    if ! confirm "Devam etmek istiyor musunuz?"; then
        info "İşlem iptal edildi"
        return 0
    fi
    
    stop_services
    
    echo ""
    success "Servisler başarıyla durduruldu!"
    echo ""
    echo "Yeniden başlatmak için:"
    echo "  cd $INSTALL_DIR && docker compose -f docker-compose.prod.yml up -d"
    echo ""
}

cleanup_soft() {
    echo ""
    echo -e "${CYAN}${BOLD}HaberNexus - Yumuşak Temizlik${NC}"
    echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
    echo ""
    
    info "Bu işlem şunları yapacak:"
    echo "  • Container'ları durdurup silecek"
    echo "  • Network'leri silecek"
    echo ""
    info "Korunacaklar:"
    echo "  • Docker volume'ları (veritabanı, media)"
    echo "  • Kurulum dizini"
    echo "  • Yapılandırma dosyaları"
    echo ""
    
    if ! confirm "Devam etmek istiyor musunuz?"; then
        info "İşlem iptal edildi"
        return 0
    fi
    
    stop_services
    remove_containers
    remove_networks
    prune_docker
    
    echo ""
    success "Yumuşak temizlik tamamlandı!"
    echo ""
    echo "Yeniden kurmak için:"
    echo "  cd $INSTALL_DIR && docker compose -f docker-compose.prod.yml up -d"
    echo ""
}

cleanup_hard() {
    echo ""
    echo -e "${CYAN}${BOLD}HaberNexus - Sert Temizlik${NC}"
    echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
    echo ""
    
    echo -e "${YELLOW}${BOLD}⚠ DİKKAT: Bu işlem veritabanı dahil tüm verileri silecek!${NC}"
    echo ""
    info "Bu işlem şunları yapacak:"
    echo "  • Container'ları durdurup silecek"
    echo "  • Docker volume'larını silecek (VERİTABANI DAHİL)"
    echo "  • Network'leri silecek"
    echo "  • Docker imajlarını silecek"
    echo ""
    info "Korunacaklar:"
    echo "  • Kurulum dizini"
    echo "  • Yapılandırma dosyaları (.env)"
    echo "  • Yedek dosyaları"
    echo ""
    
    if ! confirm "Devam etmek istiyor musunuz?"; then
        info "İşlem iptal edildi"
        return 0
    fi
    
    echo ""
    echo -e "${RED}${BOLD}Son onay: Tüm veriler silinecek!${NC}"
    if ! confirm "Emin misiniz?"; then
        info "İşlem iptal edildi"
        return 0
    fi
    
    # Yedek teklifi
    echo ""
    if confirm "Önce yedek almak ister misiniz?" "y"; then
        local script_dir
        script_dir=$(get_script_dir)
        if [[ -f "$script_dir/scripts/backup.sh" ]]; then
            bash "$script_dir/scripts/backup.sh"
        elif [[ -f "./scripts/backup.sh" ]]; then
            bash "./scripts/backup.sh"
        else
            warning "Yedekleme script'i bulunamadı"
        fi
    fi
    
    stop_services
    remove_containers
    remove_volumes
    remove_networks
    remove_images
    prune_docker
    
    echo ""
    success "Sert temizlik tamamlandı!"
    echo ""
    echo "Yeniden kurmak için:"
    echo "  sudo bash setup.sh"
    echo ""
}

cleanup_uninstall() {
    echo ""
    echo -e "${RED}${BOLD}HaberNexus - Tamamen Kaldırma${NC}"
    echo -e "${RED}$(printf '%.0s─' {1..50})${NC}"
    echo ""
    
    echo -e "${RED}${BOLD}⚠ DİKKAT: Bu işlem HaberNexus'u tamamen kaldıracak!${NC}"
    echo ""
    info "Silinecekler:"
    echo "  • Tüm Docker container'ları"
    echo "  • Tüm Docker volume'ları (veritabanı dahil)"
    echo "  • Tüm Docker network'leri"
    echo "  • Tüm Docker imajları"
    echo "  • Kurulum dizini ($INSTALL_DIR)"
    echo "  • Log dosyaları ($LOG_DIR)"
    echo "  • Systemd servisleri"
    echo ""
    
    if ! confirm "Devam etmek istiyor musunuz?"; then
        info "İşlem iptal edildi"
        return 0
    fi
    
    echo ""
    echo -e "${RED}${BOLD}SON ONAY: Tüm HaberNexus verileri silinecek!${NC}"
    echo -n "Onaylamak için 'KALDIR' yazın: "
    read -r response
    
    if [[ "$response" != "KALDIR" ]]; then
        info "İşlem iptal edildi"
        return 0
    fi
    
    # Yedek teklifi
    echo ""
    if confirm "Önce yedek almak ister misiniz?" "y"; then
        local script_dir
        script_dir=$(get_script_dir)
        if [[ -f "$script_dir/scripts/backup.sh" ]]; then
            bash "$script_dir/scripts/backup.sh"
        fi
    fi
    
    stop_services
    remove_containers
    remove_volumes
    remove_networks
    remove_images
    remove_systemd_services
    remove_install_dir
    remove_logs
    prune_docker
    
    # Yedekleri de sil mi?
    echo ""
    if [[ -d "$BACKUP_DIR" ]]; then
        if confirm "Yedek dosyalarını da silmek ister misiniz?"; then
            remove_backups
        else
            info "Yedekler korundu: $BACKUP_DIR"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  ✓ HaberNexus Başarıyla Kaldırıldı${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════${NC}"
    echo ""
}

# =============================================================================
# STATUS
# =============================================================================

show_status() {
    echo ""
    echo -e "${CYAN}${BOLD}HaberNexus Durum Raporu${NC}"
    echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
    echo ""
    
    # Kurulum dizini
    local install_dir
    install_dir=$(find_install_dir)
    
    if [[ -n "$install_dir" ]]; then
        success "Kurulum dizini: $install_dir"
    else
        warning "Kurulum dizini bulunamadı"
    fi
    
    # Container'lar
    echo ""
    echo -e "${BOLD}Docker Container'ları:${NC}"
    local containers=$(docker ps -a --filter "name=habernexus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true)
    if [[ -n "$containers" ]]; then
        echo "$containers"
    else
        info "HaberNexus container'ı bulunamadı"
    fi
    
    # Volume'lar
    echo ""
    echo -e "${BOLD}Docker Volume'ları:${NC}"
    local volumes=$(docker volume ls --filter "name=habernexus" --format "table {{.Name}}\t{{.Driver}}" 2>/dev/null || true)
    if [[ -n "$volumes" ]]; then
        echo "$volumes"
    else
        info "HaberNexus volume'u bulunamadı"
    fi
    
    # Disk kullanımı
    echo ""
    echo -e "${BOLD}Disk Kullanımı:${NC}"
    if [[ -n "$install_dir" ]] && [[ -d "$install_dir" ]]; then
        local install_size=$(du -sh "$install_dir" 2>/dev/null | cut -f1)
        echo "  Kurulum: $install_size"
    fi
    if [[ -d "$BACKUP_DIR" ]]; then
        local backup_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        echo "  Yedekler: $backup_size"
    fi
    if [[ -d "$LOG_DIR" ]]; then
        local log_size=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
        echo "  Loglar: $log_size"
    fi
    
    echo ""
}

# =============================================================================
# HELP
# =============================================================================

show_help() {
    cat << EOF
HaberNexus Temizleme Sistemi v${SCRIPT_VERSION}

KULLANIM:
  sudo bash scripts/cleanup.sh [SEÇENEK]

SEÇENEKLER:
  --status            Mevcut durumu göster
  --stop              Servisleri durdur (veri korunur)
  --soft              Yumuşak temizlik (container'ları sil, volume'ları koru)
  --hard              Sert temizlik (volume'lar dahil her şeyi sil)
  --uninstall         Tamamen kaldır
  --help              Bu yardım mesajını göster

TEMİZLİK SEVİYELERİ:
  stop       → Sadece servisleri durdur
  soft       → Container ve network'leri sil
  hard       → Volume'lar dahil her şeyi sil (kurulum dizini hariç)
  uninstall  → Tamamen kaldır

ÖRNEKLER:
  # Durumu kontrol et
  sudo bash scripts/cleanup.sh --status

  # Servisleri durdur
  sudo bash scripts/cleanup.sh --stop

  # Yeniden kurulum için temizle
  sudo bash scripts/cleanup.sh --hard

  # Tamamen kaldır
  sudo bash scripts/cleanup.sh --uninstall

EOF
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    case "${1:-}" in
        --status)
            show_status
            ;;
        --stop)
            check_root
            cleanup_stop
            ;;
        --soft)
            check_root
            cleanup_soft
            ;;
        --hard)
            check_root
            cleanup_hard
            ;;
        --uninstall)
            check_root
            cleanup_uninstall
            ;;
        --help|-h)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            error "Bilinmeyen seçenek: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
