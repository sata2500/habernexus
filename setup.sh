#!/bin/bash
# =============================================================================
# HaberNexus - Professional Installation System v11.0.0
# =============================================================================
#
# Tam otomatik ve manuel kurulum seçenekleri sunan profesyonel kurulum sistemi.
#
# KULLANIM:
#   Otomatik Kurulum (Önerilen):
#     curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/setup.sh | sudo bash
#
#   Parametrelerle Kurulum:
#     curl -fsSL ... | sudo bash -s -- --domain example.com --email admin@example.com
#
#   Manuel Kurulum:
#     sudo bash setup.sh --manual
#
#   Geliştirici Kurulumu:
#     sudo bash setup.sh --dev
#
# PARAMETRELER:
#   --domain, -d      Domain adı (varsayılan: localhost)
#   --email, -e       Admin e-posta adresi
#   --username, -u    Admin kullanıcı adı (varsayılan: admin)
#   --password, -p    Admin şifresi (boş ise otomatik)
#   --quick, -q       Varsayılan değerlerle hızlı kurulum
#   --dev             Geliştirici modu (DEBUG=True)
#   --manual, -m      Manuel kurulum modu
#   --reset           Mevcut kurulumu tamamen sıfırla
#   --backup, -b      Sadece yedek al
#   --restore, -r     Yedekten geri yükle
#   --list-backups    Mevcut yedekleri listele
#   --uninstall       Tamamen kaldır
#   --dry-run         Simülasyon modu
#   --no-tui          TUI'yi devre dışı bırak
#   --config, -c      YAML config dosyası
#   --help, -h        Yardım mesajını göster
#   --version, -v     Versiyon bilgisi
#
# GELİŞTİRİCİ: Salih TANRISEVEN
# E-POSTA: salihtanriseven25@gmail.com
# LİSANS: MIT
# =============================================================================

# Hata yönetimi - set -e kullanmıyoruz çünkü pipe'tan çalışırken sorun yaratıyor
# Bunun yerine kritik komutlarda manuel kontrol yapıyoruz
set +e

# Trap ile beklenmeyen hatalar için cleanup
trap 'handle_error $? $LINENO' ERR

handle_error() {
    local exit_code=$1
    local line_number=$2
    if [[ $exit_code -ne 0 ]]; then
        echo -e "\033[0;31m✗ Hata oluştu (kod: $exit_code, satır: $line_number)\033[0m" >&2
        echo "Log dosyasını kontrol edin: $LOG_FILE" >&2
    fi
}

# =============================================================================
# GLOBAL CONSTANTS
# =============================================================================

readonly SCRIPT_VERSION="11.0.0"
readonly SCRIPT_NAME="HaberNexus Professional Installer"
readonly GITHUB_REPO="sata2500/habernexus"
readonly GITHUB_RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main"
readonly INSTALL_DIR="/opt/habernexus"
readonly LOG_DIR="/var/log/habernexus"
readonly BACKUP_DIR="/var/backups/habernexus"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly MIN_MEMORY_MB=1024
readonly MIN_DISK_GB=10
readonly BACKUP_RETENTION_DAYS=7

# =============================================================================
# COLOR DEFINITIONS
# =============================================================================

setup_colors() {
    if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        BLUE='\033[0;34m'
        MAGENTA='\033[0;35m'
        CYAN='\033[0;36m'
        WHITE='\033[1;37m'
        BOLD='\033[1m'
        DIM='\033[2m'
        NC='\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' BOLD='' DIM='' NC=''
    fi
}

# =============================================================================
# UNICODE SYMBOLS
# =============================================================================

readonly CHECK="✓"
readonly CROSS="✗"
readonly ARROW="→"
readonly BULLET="•"
readonly STAR="★"
readonly ROCKET="🚀"
readonly PACKAGE="📦"
readonly GEAR="⚙️"
readonly LOCK="🔒"
readonly DATABASE="🗄️"
readonly SPARKLE="✨"

# =============================================================================
# GLOBAL VARIABLES
# =============================================================================

LOG_FILE=""
DOMAIN="localhost"
ADMIN_EMAIL=""
ADMIN_USERNAME="admin"
ADMIN_PASSWORD=""
DB_PASSWORD=""
SECRET_KEY=""
CLOUDFLARE_TUNNEL_TOKEN=""
GOOGLE_API_KEY=""

# Modes
QUICK_MODE=false
DEV_MODE=false
MANUAL_MODE=false
DRY_RUN=false
NO_TUI=false
FULL_RESET=false
BACKUP_ONLY=false
RESTORE_BACKUP=""
LIST_BACKUPS=false
UNINSTALL=false
USE_CLOUDFLARE=false
CONFIG_FILE=""
DIAGNOSE_MODE=false
DIAGNOSE_FIX=false

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

init_logging() {
    if [[ -d "$LOG_DIR" ]] || mkdir -p "$LOG_DIR" 2>/dev/null; then
        LOG_FILE="${LOG_DIR}/install_${TIMESTAMP}.log"
    else
        LOG_FILE="/tmp/habernexus_install_${TIMESTAMP}.log"
    fi
    touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/dev/null"
}

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
}

print_banner() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
  _   _       _               _   _                     
 | | | | __ _| |__   ___ _ __| \ | | _____  ___   _ ___ 
 | |_| |/ _` | '_ \ / _ \ '__|  \| |/ _ \ \/ / | | / __|
 |  _  | (_| | |_) |  __/ |  | |\  |  __/>  <| |_| \__ \
 |_| |_|\__,_|_.__/ \___|_|  |_| \_|\___/_/\_\\__,_|___/
                                                         
EOF
    echo -e "${NC}"
    echo -e "${DIM}Version ${SCRIPT_VERSION} | Professional Installation System${NC}"
    echo ""
}

info() {
    log "INFO" "$*"
    echo -e "${BLUE}${BULLET}${NC}  $*"
}

success() {
    log "SUCCESS" "$*"
    echo -e "${GREEN}${CHECK}${NC}  $*"
}

warning() {
    log "WARNING" "$*"
    echo -e "${YELLOW}⚠${NC}  $*"
}

error() {
    log "ERROR" "$*"
    echo -e "${RED}${CROSS}${NC}  $*" >&2
}

fatal() {
    log "FATAL" "$*"
    echo -e "${RED}${BOLD}FATAL:${NC} $*" >&2
    exit 1
}

step() {
    local step_num="$1"
    local step_msg="$2"
    echo ""
    echo -e "${MAGENTA}${BOLD}[$step_num]${NC} ${BOLD}$step_msg${NC}"
    echo -e "${DIM}$(printf '%.0s─' {1..60})${NC}"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

is_root() {
    [[ $EUID -eq 0 ]]
}

is_wsl() {
    grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null
}

is_container() {
    [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null
}

has_systemd() {
    [[ -d /run/systemd/system ]]
}

can_use_tui() {
    [[ "$NO_TUI" != true ]] && \
    [[ "$MANUAL_MODE" != true ]] && \
    [[ -t 0 ]] && \
    [[ -t 1 ]] && \
    command_exists whiptail
}

# /dev/tty üzerinden kullanıcı girdisi al
read_input() {
    local prompt="$1"
    local default="$2"
    local input=""
    
    if [[ -e /dev/tty ]]; then
        echo -n "$prompt" > /dev/tty
        read -r input < /dev/tty
    fi
    
    echo "${input:-$default}"
}

# Onay al
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    if [[ -e /dev/tty ]]; then
        if [[ "$default" == "y" ]]; then
            echo -n "$prompt [E/h]: " > /dev/tty
        else
            echo -n "$prompt [e/H]: " > /dev/tty
        fi
        read -r response < /dev/tty
    else
        response="$default"
    fi
    
    [[ "$response" =~ ^[eEyY]$ ]]
}

get_distribution() {
    local lsb_dist=""
    if [[ -r /etc/os-release ]]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
    fi
    echo "$lsb_dist" | tr '[:upper:]' '[:lower:]'
}

get_distribution_version() {
    local dist_version=""
    if [[ -r /etc/os-release ]]; then
        dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
    fi
    echo "$dist_version"
}

generate_password() {
    local length="${1:-16}"
    if command_exists openssl; then
        openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c "$length"
    elif command_exists python3; then
        python3 -c "import secrets, string; print(''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range($length)))"
    else
        head -c 100 /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c "$length"
    fi
}

generate_secret_key() {
    if command_exists python3; then
        python3 -c 'import secrets; print(secrets.token_urlsafe(50))'
    elif command_exists openssl; then
        openssl rand -base64 50 | tr -dc 'a-zA-Z0-9' | head -c 50
    else
        head -c 50 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 50
    fi
}

get_public_ip() {
    curl -fsSL --connect-timeout 5 https://api.ipify.org 2>/dev/null || \
    curl -fsSL --connect-timeout 5 https://ifconfig.me 2>/dev/null || \
    curl -fsSL --connect-timeout 5 https://icanhazip.com 2>/dev/null || \
    echo "unknown"
}

get_memory_mb() {
    awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo "0"
}

get_disk_gb() {
    df -BG / 2>/dev/null | awk 'NR==2 {gsub("G",""); print $4}' || echo "0"
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_domain() {
    local domain="$1"
    [[ -z "$domain" ]] && return 1
    [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]] && return 0
    [[ "$domain" == "localhost" || "$domain" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && return 0
    return 1
}

validate_email() {
    local email="$1"
    [[ -z "$email" ]] && return 1
    [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

# =============================================================================
# SYSTEM CHECKS
# =============================================================================

check_system_requirements() {
    step "1/8" "Sistem Gereksinimleri Kontrol Ediliyor"
    
    # Root kontrolü - pipe'tan çalıştırıldığında $0 geçerli olmayabilir
    if ! is_root; then
        fatal "Bu script root yetkisi gerektirir.\n\nLütfen şu şekilde çalıştırın:\n  curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/setup.sh | sudo bash"
    fi
    success "Root yetkisi: OK"
    
    # İşletim sistemi kontrolü
    local distro
    distro=$(get_distribution)
    local version
    version=$(get_distribution_version)
    
    case "$distro" in
        ubuntu)
            if [[ ! "$version" =~ ^(20\.04|22\.04|24\.04)$ ]]; then
                warning "Ubuntu $version test edilmemiş. 20.04, 22.04 veya 24.04 önerilir."
            fi
            ;;
        debian)
            if [[ ! "$version" =~ ^(11|12)$ ]]; then
                warning "Debian $version test edilmemiş. 11 veya 12 önerilir."
            fi
            ;;
        *)
            warning "Bu dağıtım ($distro) resmi olarak desteklenmiyor."
            ;;
    esac
    success "İşletim sistemi: $distro $version"
    
    # Bellek kontrolü
    local memory_mb
    memory_mb=$(get_memory_mb)
    if [[ "$memory_mb" -lt "$MIN_MEMORY_MB" ]]; then
        warning "Yetersiz bellek: ${memory_mb}MB. Minimum ${MIN_MEMORY_MB}MB önerilir."
    else
        success "Bellek: ${memory_mb}MB"
    fi
    
    # Disk kontrolü
    local disk_gb
    disk_gb=$(get_disk_gb)
    if [[ "$disk_gb" -lt "$MIN_DISK_GB" ]]; then
        warning "Yetersiz disk alanı: ${disk_gb}GB. Minimum ${MIN_DISK_GB}GB önerilir."
    else
        success "Disk alanı: ${disk_gb}GB boş"
    fi
    
    # Internet bağlantısı kontrolü
    if ! curl -fsSL --connect-timeout 5 https://github.com > /dev/null 2>&1; then
        fatal "Internet bağlantısı yok veya GitHub'a erişilemiyor."
    fi
    success "Internet bağlantısı: OK"
    
    # WSL kontrolü
    if is_wsl; then
        warning "WSL ortamı algılandı. Bazı özellikler sınırlı olabilir."
    fi
    
    # Container kontrolü
    if is_container; then
        warning "Container ortamı algılandı."
    fi
}

# =============================================================================
# EXISTING INSTALLATION CHECK
# =============================================================================

check_existing_installation() {
    step "2/8" "Mevcut Kurulum Kontrol Ediliyor"
    
    local has_installation=false
    local has_containers=false
    
    # Kurulum dizini kontrolü
    if [[ -d "$INSTALL_DIR" ]]; then
        has_installation=true
        info "Mevcut kurulum bulundu: $INSTALL_DIR"
    fi
    
    # Docker container kontrolü
    if command_exists docker; then
        if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q 'habernexus'; then
            has_containers=true
            info "HaberNexus container'ları bulundu"
        fi
    fi
    
    if [[ "$has_installation" == true ]] || [[ "$has_containers" == true ]]; then
        if [[ "$FULL_RESET" == true ]]; then
            warning "Tam sıfırlama modu aktif. Mevcut kurulum silinecek."
            
            # Yedek al
            if [[ "$DRY_RUN" != true ]]; then
                if confirm "Sıfırlamadan önce yedek almak ister misiniz?"; then
                    create_backup
                fi
            fi
            
            # Temizle
            full_cleanup
        else
            echo ""
            warning "Mevcut bir kurulum tespit edildi!"
            echo ""
            echo -e "  ${CYAN}Seçenekler:${NC}"
            echo -e "    ${BULLET} Yedek alıp devam etmek için: ${BOLD}E${NC}"
            echo -e "    ${BULLET} Tam sıfırlama için: ${BOLD}--reset${NC} parametresi kullanın"
            echo -e "    ${BULLET} İptal etmek için: ${BOLD}H${NC}"
            echo ""
            
            if confirm "Yedek alıp kuruluma devam etmek istiyor musunuz?"; then
                if [[ "$DRY_RUN" != true ]]; then
                    create_backup
                fi
                cleanup_for_reinstall
            else
                fatal "Kurulum iptal edildi."
            fi
        fi
    else
        success "Temiz sistem - yeni kurulum yapılacak"
    fi
}

# =============================================================================
# CLEANUP FUNCTIONS
# =============================================================================

full_cleanup() {
    info "Tam temizlik başlatılıyor..."
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Container'lar durdurulacak ve silinecek"
        info "[DRY-RUN] Volume'lar silinecek"
        info "[DRY-RUN] Network'ler silinecek"
        info "[DRY-RUN] Kurulum dizini silinecek"
        return 0
    fi
    
    # Docker container'ları durdur ve sil
    if command_exists docker; then
        info "Docker container'ları durduruluyor..."
        
        # HaberNexus container'ları
        docker ps -a --filter "name=habernexus" -q 2>/dev/null | xargs -r docker stop 2>/dev/null || true
        docker ps -a --filter "name=habernexus" -q 2>/dev/null | xargs -r docker rm -f 2>/dev/null || true
        
        # İlgili diğer container'lar
        for container in cloudflared caddy nginx postgres redis; do
            docker stop "$container" 2>/dev/null || true
            docker rm -f "$container" 2>/dev/null || true
        done
        
        success "Container'lar temizlendi"
        
        # Volume'ları sil
        info "Docker volume'ları temizleniyor..."
        docker volume ls -q --filter "name=habernexus" 2>/dev/null | xargs -r docker volume rm 2>/dev/null || true
        for volume in postgres_data redis_data static_files media_files caddy_data caddy_config; do
            docker volume rm "$volume" 2>/dev/null || true
        done
        success "Volume'lar temizlendi"
        
        # Network'leri sil
        info "Docker network'leri temizleniyor..."
        docker network ls -q --filter "name=habernexus" 2>/dev/null | xargs -r docker network rm 2>/dev/null || true
        success "Network'ler temizlendi"
        
        # Kullanılmayan kaynakları temizle
        docker system prune -f 2>/dev/null || true
    fi
    
    # Kurulum dizinini sil
    if [[ -d "$INSTALL_DIR" ]]; then
        info "Kurulum dizini siliniyor..."
        rm -rf "$INSTALL_DIR"
        success "Kurulum dizini silindi"
    fi
    
    # Systemd servislerini temizle
    if has_systemd; then
        for service in caddy cloudflared habernexus; do
            systemctl stop "$service" 2>/dev/null || true
            systemctl disable "$service" 2>/dev/null || true
            rm -f "/etc/systemd/system/${service}.service" 2>/dev/null || true
        done
        systemctl daemon-reload 2>/dev/null || true
    fi
    
    success "Tam temizlik tamamlandı"
}

cleanup_for_reinstall() {
    info "Yeniden kurulum için temizlik yapılıyor..."
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Container'lar durdurulacak"
        return 0
    fi
    
    # Sadece container'ları durdur (volume'ları koru)
    if command_exists docker && [[ -d "$INSTALL_DIR" ]]; then
        cd "$INSTALL_DIR" 2>/dev/null || true
        docker compose down --remove-orphans 2>/dev/null || true
        docker compose -f docker-compose.prod.yml down --remove-orphans 2>/dev/null || true
    fi
    
    success "Temizlik tamamlandı"
}

# =============================================================================
# BACKUP FUNCTIONS
# =============================================================================

create_backup() {
    info "Yedekleme başlatılıyor..."
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Yedek alınacak: $BACKUP_DIR/backup_$TIMESTAMP"
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    local backup_path="${BACKUP_DIR}/backup_${TIMESTAMP}"
    mkdir -p "$backup_path"
    
    # PostgreSQL yedekleme
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qE 'postgres|habernexus.*db'; then
        info "Veritabanı yedekleniyor..."
        local db_container
        db_container=$(docker ps --format '{{.Names}}' | grep -E 'postgres|habernexus.*db' | head -1)
        
        if [[ -n "$db_container" ]]; then
            local db_name="habernexus"
            local db_user="habernexus_user"
            
            if [[ -f "$INSTALL_DIR/.env" ]]; then
                db_name=$(grep -E '^DB_NAME=' "$INSTALL_DIR/.env" | cut -d'=' -f2 || echo "habernexus")
                db_user=$(grep -E '^DB_USER=' "$INSTALL_DIR/.env" | cut -d'=' -f2 || echo "habernexus_user")
            fi
            
            if docker exec "$db_container" pg_dump -U "$db_user" "$db_name" > "${backup_path}/database.sql" 2>/dev/null; then
                gzip "${backup_path}/database.sql"
                success "Veritabanı yedeği alındı"
            else
                warning "Veritabanı yedeği alınamadı"
            fi
        fi
    fi
    
    # Redis yedekleme
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qE 'redis|habernexus.*redis'; then
        info "Redis yedekleniyor..."
        local redis_container
        redis_container=$(docker ps --format '{{.Names}}' | grep -E 'redis|habernexus.*redis' | head -1)
        
        if [[ -n "$redis_container" ]]; then
            docker exec "$redis_container" redis-cli SAVE 2>/dev/null || true
            docker cp "${redis_container}:/data/dump.rdb" "${backup_path}/redis_dump.rdb" 2>/dev/null || true
            success "Redis yedeği alındı"
        fi
    fi
    
    # .env dosyası yedekleme
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        cp "$INSTALL_DIR/.env" "${backup_path}/.env.backup"
        success ".env dosyası yedeklendi"
    fi
    
    # Media dosyaları yedekleme
    if [[ -d "$INSTALL_DIR/media" ]]; then
        info "Media dosyaları yedekleniyor..."
        tar -czf "${backup_path}/media.tar.gz" -C "$INSTALL_DIR" media/ 2>/dev/null || true
        success "Media dosyaları yedeklendi"
    fi
    
    # Metadata oluştur
    cat > "${backup_path}/backup.info" << EOF
HaberNexus Backup Information
=============================
Date: $(date)
Hostname: $(hostname)
Script Version: $SCRIPT_VERSION
Install Directory: $INSTALL_DIR

Files:
$(ls -la "$backup_path" 2>/dev/null)
EOF
    
    # Arşivle
    tar -czf "${BACKUP_DIR}/backup_${TIMESTAMP}.tar.gz" -C "$BACKUP_DIR" "backup_${TIMESTAMP}"
    rm -rf "$backup_path"
    
    # Eski yedekleri temizle
    find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +$BACKUP_RETENTION_DAYS -delete 2>/dev/null || true
    
    success "Yedekleme tamamlandı: ${BACKUP_DIR}/backup_${TIMESTAMP}.tar.gz"
}

list_backups() {
    echo ""
    echo -e "${BOLD}Mevcut Yedekler:${NC}"
    echo -e "${DIM}$(printf '%.0s─' {1..60})${NC}"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        info "Henüz hiç yedek alınmamış."
        return 0
    fi
    
    local count=0
    for backup in "$BACKUP_DIR"/backup_*.tar.gz; do
        if [[ -f "$backup" ]]; then
            local backup_name
            backup_name=$(basename "$backup" .tar.gz)
            local backup_size
            backup_size=$(du -h "$backup" | cut -f1)
            local backup_date
            backup_date=$(echo "$backup_name" | sed 's/backup_//' | sed 's/_/ /')
            
            echo -e "  ${CYAN}$backup_name${NC}"
            echo -e "    Boyut: $backup_size"
            echo -e "    Tarih: $backup_date"
            echo ""
            ((count++))
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        info "Henüz hiç yedek alınmamış."
    else
        info "Toplam $count yedek bulundu."
        echo ""
        echo -e "${YELLOW}Geri yüklemek için:${NC}"
        echo "  sudo bash setup.sh --restore backup_YYYYMMDD_HHMMSS"
    fi
}

restore_backup() {
    local backup_name="$1"
    local backup_file="${BACKUP_DIR}/${backup_name}.tar.gz"
    
    if [[ ! -f "$backup_file" ]]; then
        fatal "Yedek dosyası bulunamadı: $backup_file"
    fi
    
    step "1/3" "Yedek Dosyası Açılıyor"
    
    local temp_dir="/tmp/habernexus_restore_$$"
    mkdir -p "$temp_dir"
    tar -xzf "$backup_file" -C "$temp_dir"
    local restore_dir
    restore_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -1)
    
    if [[ ! -d "$restore_dir" ]]; then
        rm -rf "$temp_dir"
        fatal "Yedek dosyası geçersiz"
    fi
    
    success "Yedek dosyası açıldı"
    
    step "2/3" "Veriler Geri Yükleniyor"
    
    # .env dosyasını geri yükle
    if [[ -f "${restore_dir}/.env.backup" ]]; then
        if confirm ".env dosyasını da geri yüklemek ister misiniz?"; then
            cp "${restore_dir}/.env.backup" "$INSTALL_DIR/.env"
            success ".env dosyası geri yüklendi"
        fi
    fi
    
    # Veritabanını geri yükle
    if [[ -f "${restore_dir}/database.sql.gz" ]]; then
        info "Veritabanı geri yükleniyor..."
        
        local db_container
        db_container=$(docker ps --format '{{.Names}}' | grep -E 'postgres|habernexus.*db' | head -1)
        
        if [[ -z "$db_container" ]]; then
            warning "Veritabanı container'ı çalışmıyor. Önce servisleri başlatın."
        else
            local db_name="habernexus"
            local db_user="habernexus_user"
            
            if [[ -f "$INSTALL_DIR/.env" ]]; then
                db_name=$(grep -E '^DB_NAME=' "$INSTALL_DIR/.env" | cut -d'=' -f2 || echo "habernexus")
                db_user=$(grep -E '^DB_USER=' "$INSTALL_DIR/.env" | cut -d'=' -f2 || echo "habernexus_user")
            fi
            
            gunzip -c "${restore_dir}/database.sql.gz" | docker exec -i "$db_container" psql -U "$db_user" "$db_name" 2>/dev/null
            success "Veritabanı geri yüklendi"
        fi
    fi
    
    # Media dosyalarını geri yükle
    if [[ -f "${restore_dir}/media.tar.gz" ]]; then
        info "Media dosyaları geri yükleniyor..."
        tar -xzf "${restore_dir}/media.tar.gz" -C "$INSTALL_DIR"
        success "Media dosyaları geri yüklendi"
    fi
    
    step "3/3" "Temizlik"
    rm -rf "$temp_dir"
    
    success "Geri yükleme tamamlandı!"
}


# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

install_dependencies() {
    step "3/8" "Bağımlılıklar Kuruluyor"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Paket listesi güncellenecek"
        info "[DRY-RUN] Temel paketler kurulacak"
        info "[DRY-RUN] Docker kurulacak"
        return 0
    fi
    
    info "Paket listesi güncelleniyor..."
    if ! apt-get update -qq 2>&1; then
        warning "Paket listesi güncellenemedi, devam ediliyor..."
    fi
    
    # Temel paketler
    local packages=(
        curl
        wget
        git
        ca-certificates
        gnupg
        lsb-release
        apt-transport-https
        software-properties-common
        jq
        net-tools
        whiptail
    )
    
    info "Temel paketler kuruluyor..."
    # Her paketi tek tek kur, hata olursa devam et
    local failed_packages=()
    for pkg in "${packages[@]}"; do
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$pkg" > /dev/null 2>&1; then
            failed_packages+=("$pkg")
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        warning "Bazı paketler kurulamadı: ${failed_packages[*]}"
    else
        success "Temel paketler kuruldu"
    fi
    
    # Docker kurulumu
    if ! command_exists docker; then
        info "Docker kuruluyor..."
        if curl -fsSL https://get.docker.com | sh > /dev/null 2>&1; then
            success "Docker kuruldu"
        else
            # Alternatif yöntem
            info "Alternatif Docker kurulum yöntemi deneniyor..."
            apt-get install -y -qq docker.io docker-compose-plugin > /dev/null 2>&1 || true
            if command_exists docker; then
                success "Docker kuruldu (apt ile)"
            else
                fatal "Docker kurulamadı. Lütfen manuel olarak kurun."
            fi
        fi
    else
        success "Docker zaten kurulu: $(docker --version 2>/dev/null | head -1)"
    fi
    
    # Docker Compose kontrolü
    if ! docker compose version > /dev/null 2>&1; then
        info "Docker Compose plugin kuruluyor..."
        apt-get install -y -qq docker-compose-plugin > /dev/null 2>&1 || true
    fi
    
    if docker compose version > /dev/null 2>&1; then
        success "Docker Compose: $(docker compose version 2>/dev/null | head -1)"
    else
        warning "Docker Compose kurulamadı, ancak devam ediliyor..."
    fi
    
    # Docker servisini başlat
    if has_systemd; then
        systemctl enable docker > /dev/null 2>&1 || true
        systemctl start docker > /dev/null 2>&1 || true
    fi
    
    # Docker'in çalıştığını doğrula
    if ! docker info > /dev/null 2>&1; then
        warning "Docker servisi başlatılamadı. Manuel olarak başlatmanız gerekebilir."
    fi
}

# =============================================================================
# CONFIGURATION COLLECTION - TUI
# =============================================================================

collect_config_tui() {
    info "Etkileşimli yapılandırma başlatılıyor..."
    
    # Hoşgeldin mesajı
    whiptail --title "HaberNexus Kurulum Sihirbazı v${SCRIPT_VERSION}" --msgbox \
        "HaberNexus Professional Installer'a hoş geldiniz!\n\nBu sihirbaz size kurulum sürecinde rehberlik edecektir.\n\n${ROCKET} Özellikler:\n• Tam otomatik kurulum\n• Cloudflare Tunnel desteği\n• Otomatik SSL sertifikası\n• Yedekleme ve geri yükleme\n\nDevam etmek için OK'a basın." \
        16 70
    
    # Kurulum modu seçimi
    local install_mode
    install_mode=$(whiptail --title "Kurulum Modu" --menu \
        "Kurulum modunu seçin:" 15 60 4 \
        "1" "Tam Kurulum (Önerilen) - Tüm bileşenler" \
        "2" "Hızlı Kurulum - Varsayılan değerlerle" \
        "3" "Geliştirici Kurulumu - DEBUG modu aktif" \
        "4" "Özel Kurulum - Tüm ayarları yapılandır" \
        3>&1 1>&2 2>&3) || install_mode="1"
    
    case "$install_mode" in
        "2") QUICK_MODE=true ;;
        "3") DEV_MODE=true ;;
    esac
    
    if [[ "$QUICK_MODE" == true ]]; then
        DOMAIN="localhost"
        ADMIN_EMAIL="admin@localhost"
        return 0
    fi
    
    # Domain
    DOMAIN=$(whiptail --title "Domain Yapılandırması" --inputbox \
        "Domain adınızı girin:\n\nÖrnekler:\n• habernexus.com (production)\n• localhost (geliştirme)\n• IP adresi (test)" \
        12 60 "$DOMAIN" 3>&1 1>&2 2>&3) || DOMAIN="localhost"
    
    # Admin Email
    local default_email="admin@$DOMAIN"
    [[ "$DOMAIN" == "localhost" ]] && default_email="admin@localhost"
    
    ADMIN_EMAIL=$(whiptail --title "Admin E-posta" --inputbox \
        "Admin e-posta adresinizi girin:\n\n(SSL sertifikası ve bildirimler için kullanılacak)" \
        10 60 "$default_email" 3>&1 1>&2 2>&3) || ADMIN_EMAIL="$default_email"
    
    # Admin Username
    ADMIN_USERNAME=$(whiptail --title "Admin Kullanıcı Adı" --inputbox \
        "Admin kullanıcı adını girin:" \
        10 60 "$ADMIN_USERNAME" 3>&1 1>&2 2>&3) || ADMIN_USERNAME="admin"
    
    # Admin Password
    ADMIN_PASSWORD=$(whiptail --title "Admin Şifresi" --passwordbox \
        "Admin şifresini girin:\n\n(Boş bırakırsanız güçlü bir şifre otomatik oluşturulur)" \
        10 60 3>&1 1>&2 2>&3) || ADMIN_PASSWORD=""
    
    # Cloudflare Tunnel (sadece gerçek domain için)
    if [[ "$DOMAIN" != "localhost" ]] && [[ ! "$DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        if whiptail --title "Cloudflare Tunnel" --yesno \
            "Cloudflare Tunnel kullanmak ister misiniz?\n\nAvantajları:\n• Port açmaya gerek yok (80/443)\n• Otomatik SSL sertifikası\n• DDoS koruması\n• Zero Trust güvenlik\n\nNot: Cloudflare hesabı ve domain gerektirir." \
            14 70; then
            USE_CLOUDFLARE=true
            
            whiptail --title "Cloudflare Token Rehberi" --msgbox \
                "Cloudflare Tunnel Token Nasıl Alınır:\n\n1. https://one.dash.cloudflare.com adresine gidin\n2. Networks → Tunnels bölümüne gidin\n3. 'Create a Tunnel' → 'Cloudflared' seçin\n4. Tunnel'a isim verin (örn: habernexus)\n5. Token'ı kopyalayın (eyJhIjoi... ile başlar)\n6. Public Hostnames'e domain ekleyin:\n   - Service: http://caddy:80" \
                18 70
            
            CLOUDFLARE_TUNNEL_TOKEN=$(whiptail --title "Cloudflare Token" --inputbox \
                "Cloudflare Tunnel Token'ınızı yapıştırın:" \
                10 70 3>&1 1>&2 2>&3) || CLOUDFLARE_TUNNEL_TOKEN=""
        fi
    fi
    
    # Google AI API Key (opsiyonel)
    if whiptail --title "Google AI API" --yesno \
        "Google Gemini AI API kullanmak ister misiniz?\n\nBu özellik:\n• Otomatik haber özetleme\n• AI destekli içerik üretimi\n• Akıllı kategorizasyon\n\nsağlar. (Opsiyonel - sonra da eklenebilir)" \
        12 70; then
        GOOGLE_API_KEY=$(whiptail --title "Google AI API Key" --inputbox \
            "Google AI API Key'inizi girin:\n\n(https://makersuite.google.com/app/apikey)" \
            10 70 3>&1 1>&2 2>&3) || GOOGLE_API_KEY=""
    fi
    
    # Özet ve onay
    local summary="Kurulum Özeti:\n\n"
    summary+="Domain: $DOMAIN\n"
    summary+="Admin E-posta: $ADMIN_EMAIL\n"
    summary+="Admin Kullanıcı: $ADMIN_USERNAME\n"
    summary+="Cloudflare Tunnel: $([ "$USE_CLOUDFLARE" = true ] && echo 'Evet' || echo 'Hayır')\n"
    summary+="Google AI: $([ -n "$GOOGLE_API_KEY" ] && echo 'Yapılandırıldı' || echo 'Yapılandırılmadı')\n"
    summary+="Mod: $([ "$DEV_MODE" = true ] && echo 'Geliştirici' || echo 'Production')\n"
    
    if ! whiptail --title "Kurulum Onayı" --yesno "$summary\nKuruluma devam etmek istiyor musunuz?" 18 70; then
        fatal "Kurulum kullanıcı tarafından iptal edildi."
    fi
}

# =============================================================================
# CONFIGURATION COLLECTION - CLI
# =============================================================================

collect_config_cli() {
    info "Komut satırı yapılandırması kullanılıyor..."
    
    echo ""
    echo -e "${BOLD}Yapılandırma Bilgileri${NC}"
    echo -e "${DIM}$(printf '%.0s─' {1..40})${NC}"
    
    # Domain
    if [[ -z "$DOMAIN" ]] || [[ "$DOMAIN" == "localhost" ]]; then
        DOMAIN=$(read_input "Domain adı [localhost]: " "localhost")
    fi
    
    # Admin Email
    if [[ -z "$ADMIN_EMAIL" ]]; then
        local default_email="admin@$DOMAIN"
        [[ "$DOMAIN" == "localhost" ]] && default_email="admin@localhost"
        ADMIN_EMAIL=$(read_input "Admin e-posta [$default_email]: " "$default_email")
    fi
    
    # Admin Username
    if [[ "$ADMIN_USERNAME" == "admin" ]]; then
        ADMIN_USERNAME=$(read_input "Admin kullanıcı adı [admin]: " "admin")
    fi
    
    # Admin Password
    if [[ -z "$ADMIN_PASSWORD" ]]; then
        echo -n "Admin şifresi (boş = otomatik): " > /dev/tty
        read -rs ADMIN_PASSWORD < /dev/tty
        echo ""
    fi
    
    # Cloudflare Tunnel
    if [[ "$DOMAIN" != "localhost" ]] && [[ ! "$DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        if confirm "Cloudflare Tunnel kullanmak ister misiniz?"; then
            USE_CLOUDFLARE=true
            CLOUDFLARE_TUNNEL_TOKEN=$(read_input "Cloudflare Tunnel Token: " "")
        fi
    fi
    
    success "Yapılandırma tamamlandı"
}

# =============================================================================
# CONFIGURATION COLLECTION - MAIN
# =============================================================================

collect_configuration() {
    step "4/8" "Yapılandırma Bilgileri Toplanıyor"
    
    if [[ "$QUICK_MODE" == true ]]; then
        info "Hızlı mod: Varsayılan değerler kullanılıyor"
        DOMAIN="localhost"
        ADMIN_EMAIL="admin@localhost"
        return 0
    fi
    
    if can_use_tui; then
        collect_config_tui
    else
        collect_config_cli
    fi
}

finalize_configuration() {
    # Otomatik değer oluşturma
    if [[ -z "$ADMIN_PASSWORD" ]]; then
        ADMIN_PASSWORD=$(generate_password 16)
        info "Admin şifresi otomatik oluşturuldu"
    fi
    
    if [[ -z "$DB_PASSWORD" ]]; then
        DB_PASSWORD=$(generate_password 24)
    fi
    
    if [[ -z "$SECRET_KEY" ]]; then
        SECRET_KEY=$(generate_secret_key)
    fi
    
    success "Tüm yapılandırma değerleri hazır"
}

# =============================================================================
# PROJECT INSTALLATION
# =============================================================================

clone_repository() {
    step "5/8" "Proje Dosyaları İndiriliyor"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] git clone https://github.com/${GITHUB_REPO}.git $INSTALL_DIR"
        return 0
    fi
    
    # Mevcut dizini temizle
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
    fi
    
    # Repo'yu klonla
    info "GitHub'dan proje indiriliyor..."
    
    if ! git clone --depth 1 "https://github.com/${GITHUB_REPO}.git" "$INSTALL_DIR" 2>&1; then
        fatal "GitHub'dan proje indirilemedi!"
    fi
    
    success "Proje dosyaları indirildi: $INSTALL_DIR"
}

create_environment_file() {
    step "6/8" "Ortam Değişkenleri Yapılandırılıyor"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] .env dosyası oluşturulacak"
        return 0
    fi
    
    cd "$INSTALL_DIR"
    
    # DEBUG değeri
    local debug_value="False"
    [[ "$DEV_MODE" == true ]] && debug_value="True"
    
    # SSL ayarları
    local ssl_redirect="True"
    local cookie_secure="True"
    if [[ "$DOMAIN" == "localhost" ]] || [[ "$DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ssl_redirect="False"
        cookie_secure="False"
    fi
    
    # .env dosyası oluştur
    cat > .env << ENVEOF
# =============================================================================
# HaberNexus Environment Configuration
# Generated: $(date)
# Version: $SCRIPT_VERSION
# =============================================================================

# Django Settings
DEBUG=$debug_value
DJANGO_SECRET_KEY=${SECRET_KEY}
ALLOWED_HOSTS=${DOMAIN},www.${DOMAIN},$(get_public_ip),localhost,127.0.0.1

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=postgres
DB_PORT=5432

# Redis / Celery
REDIS_URL=redis://redis:6379/0
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# Domain & SSL
# Note: SSL redirect is disabled by default to allow health checks inside containers
# Caddy handles SSL termination and redirects at the edge
DOMAIN=${DOMAIN}
SECURE_SSL_REDIRECT=False
SESSION_COOKIE_SECURE=${cookie_secure}
CSRF_COOKIE_SECURE=${cookie_secure}
SECURE_HSTS_SECONDS=0
SECURE_HSTS_INCLUDE_SUBDOMAINS=False
SECURE_HSTS_PRELOAD=False

# Admin User
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# AI Settings (Optional)
GOOGLE_GEMINI_API_KEY=${GOOGLE_API_KEY}
AI_MODEL=gemini-2.5-flash

# Cloudflare (Optional)
USE_CLOUDFLARE=${USE_CLOUDFLARE}
CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
ENVEOF

    chmod 600 .env
    success ".env dosyası oluşturuldu"
    
    # Caddyfile oluştur
    info "Caddy yapılandırması oluşturuluyor..."
    mkdir -p "$INSTALL_DIR/caddy"
    
    if [[ "$DOMAIN" == "localhost" || "$DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # IP/localhost modu - HTTP
        cat > "$INSTALL_DIR/caddy/Caddyfile" << 'CADDYEOF'
:80 {
    encode gzip
    
    # Health check endpoint for Caddy
    handle /health {
        respond "OK" 200
    }
    
    handle_path /static/* {
        root * /app/staticfiles
        file_server
    }
    
    handle_path /media/* {
        root * /app/media
        file_server
    }
    
    handle {
        reverse_proxy web:8000
    }
}
CADDYEOF
        success "Caddy yapılandırması oluşturuldu (HTTP modu)"
    else
        # Domain modu - HTTPS
        cat > "$INSTALL_DIR/caddy/Caddyfile" << CADDYEOF
{
    email $ADMIN_EMAIL
}

$DOMAIN {
    encode gzip
    
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
        Referrer-Policy strict-origin-when-cross-origin
    }
    
    # Health check endpoint for Caddy
    handle /health {
        respond "OK" 200
    }
    
    handle_path /static/* {
        root * /app/staticfiles
        file_server
    }
    
    handle_path /media/* {
        root * /app/media
        file_server
    }
    
    handle {
        reverse_proxy web:8000
    }
}

www.$DOMAIN {
    redir https://$DOMAIN{uri} permanent
}
CADDYEOF
        success "Caddy yapılandırması oluşturuldu (HTTPS modu)"
    fi
    
    # Cloudflare override dosyası
    if [[ "$USE_CLOUDFLARE" == true ]] && [[ -n "$CLOUDFLARE_TUNNEL_TOKEN" ]]; then
        cat > docker-compose.override.yml << 'OVERRIDEEOF'
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: habernexus-cloudflared
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
    networks:
      - habernexus-network
    depends_on:
      - caddy
OVERRIDEEOF
        success "Cloudflare Tunnel yapılandırması oluşturuldu"
    fi
}


# =============================================================================
# SERVICE STARTUP
# =============================================================================

start_services() {
    step "7/8" "Servisler Başlatılıyor"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Docker imajları build edilecek"
        info "[DRY-RUN] Container'lar başlatılacak"
        info "[DRY-RUN] Migration'lar çalıştırılacak"
        info "[DRY-RUN] Admin kullanıcı oluşturulacak"
        return 0
    fi
    
    cd "$INSTALL_DIR"
    
    # Docker Compose dosyası seç
    local compose_file="docker-compose.prod.yml"
    if [[ "$DEV_MODE" == true ]]; then
        compose_file="docker-compose.yml"
    fi
    
    # Override dosyası varsa ekle
    local compose_cmd="docker compose -f $compose_file"
    if [[ -f "docker-compose.override.yml" ]]; then
        compose_cmd="$compose_cmd -f docker-compose.override.yml"
    fi
    
    # İmajları build et
    info "Docker imajları build ediliyor..."
    if ! $compose_cmd build --no-cache 2>&1 | tee -a "$LOG_FILE"; then
        warning "Build sırasında uyarılar oluştu, devam ediliyor..."
    fi
    success "Docker imajları hazır"
    
    # Container'ları başlat
    info "Container'lar başlatılıyor..."
    if ! $compose_cmd up -d 2>&1 | tee -a "$LOG_FILE"; then
        fatal "Container'lar başlatılamadı!"
    fi
    success "Container'lar başlatıldı"
    
    # Veritabanının hazır olmasını bekle
    info "Veritabanı bağlantısı bekleniyor..."
    local max_attempts=30
    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        if docker exec habernexus-postgres pg_isready -U habernexus_user -d habernexus > /dev/null 2>&1; then
            break
        fi
        sleep 2
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        warning "Veritabanı bağlantısı zaman aşımına uğradı, yine de devam ediliyor..."
    else
        success "Veritabanı hazır"
    fi
    
    # Migration'ları çalıştır
    info "Veritabanı migration'ları çalıştırılıyor..."
    docker exec habernexus-web python manage.py migrate --noinput 2>&1 | tee -a "$LOG_FILE" || true
    success "Migration'lar tamamlandı"
    
    # Static dosyaları topla
    info "Static dosyalar toplanıyor..."
    docker exec habernexus-web python manage.py collectstatic --noinput 2>&1 | tee -a "$LOG_FILE" || true
    success "Static dosyalar hazır"
    
    # Admin kullanıcı oluştur
    info "Admin kullanıcı oluşturuluyor..."
    docker exec habernexus-web python manage.py shell << PYTHONEOF 2>&1 | tee -a "$LOG_FILE" || true
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='${ADMIN_USERNAME}').exists():
    user = User.objects.create_superuser(
        username='${ADMIN_USERNAME}',
        email='${ADMIN_EMAIL}',
        password='${ADMIN_PASSWORD}'
    )
    print(f'Admin user created: {user.username}')
else:
    print('Admin user already exists')
PYTHONEOF
    success "Admin kullanıcı hazır"
}

# =============================================================================
# VERIFICATION
# =============================================================================

verify_installation() {
    step "8/8" "Kurulum Doğrulanıyor"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Health check yapılacak"
        info "[DRY-RUN] Servis durumları kontrol edilecek"
        return 0
    fi
    
    local all_ok=true
    
    # Container durumları
    info "Container durumları kontrol ediliyor..."
    local containers=("habernexus-web" "habernexus-postgres" "habernexus-redis" "habernexus-caddy")
    
    for container in "${containers[@]}"; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            local status
            status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
            if [[ "$status" == "running" ]]; then
                success "$container: Çalışıyor"
            else
                warning "$container: $status"
                all_ok=false
            fi
        else
            warning "$container: Bulunamadı"
            all_ok=false
        fi
    done
    
    # Celery worker kontrolü
    if docker ps --format '{{.Names}}' | grep -q "habernexus-celery"; then
        success "habernexus-celery: Çalışıyor"
    else
        warning "habernexus-celery: Bulunamadı (opsiyonel)"
    fi
    
    # Cloudflare kontrolü
    if [[ "$USE_CLOUDFLARE" == true ]]; then
        if docker ps --format '{{.Names}}' | grep -q "habernexus-cloudflared"; then
            success "habernexus-cloudflared: Çalışıyor"
        else
            warning "habernexus-cloudflared: Bulunamadı"
        fi
    fi
    
    # Health check endpoint
    info "Web servisi kontrol ediliyor..."
    sleep 5  # Servisin tam başlamasını bekle
    
    local health_url="http://localhost/health/"
    if [[ "$DOMAIN" != "localhost" ]] && [[ "$USE_CLOUDFLARE" != true ]]; then
        health_url="https://${DOMAIN}/health/"
    fi
    
    local max_attempts=10
    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        if curl -fsSL --connect-timeout 5 "http://localhost:80/" > /dev/null 2>&1; then
            success "Web servisi erişilebilir"
            break
        fi
        sleep 3
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        warning "Web servisi henüz erişilebilir değil (birkaç dakika bekleyin)"
    fi
    
    if [[ "$all_ok" == true ]]; then
        success "Tüm servisler başarıyla çalışıyor!"
    else
        warning "Bazı servisler beklendiği gibi çalışmıyor."
        echo ""
        echo -e "${YELLOW}${BOLD}Sorun giderme için:${NC}"
        echo -e "  ${CYAN}Hızlı tanılama:${NC}  sudo bash ${INSTALL_DIR}/scripts/diagnostics.sh --quick"
        echo -e "  ${CYAN}Tam tanılama:${NC}   sudo bash ${INSTALL_DIR}/scripts/diagnostics.sh"
        echo -e "  ${CYAN}Otomatik düzelt:${NC} sudo bash ${INSTALL_DIR}/scripts/diagnostics.sh --fix"
    fi
}

# =============================================================================
# COMPLETION
# =============================================================================

show_completion_message() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    cat << 'EOF'
  ╔══════════════════════════════════════════════════════════════╗
  ║                                                              ║
  ║   ✨ KURULUM BAŞARIYLA TAMAMLANDI! ✨                        ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Erişim bilgileri
    echo -e "${BOLD}Erişim Bilgileri:${NC}"
    echo -e "${DIM}$(printf '%.0s─' {1..60})${NC}"
    
    local access_url
    if [[ "$DOMAIN" == "localhost" ]]; then
        access_url="http://localhost"
    elif [[ "$USE_CLOUDFLARE" == true ]]; then
        access_url="https://${DOMAIN}"
    else
        access_url="https://${DOMAIN}"
    fi
    
    echo -e "  ${CYAN}Web Arayüzü:${NC}     $access_url"
    echo -e "  ${CYAN}Admin Panel:${NC}     ${access_url}/admin/"
    echo ""
    
    # Giriş bilgileri
    echo -e "${BOLD}Admin Giriş Bilgileri:${NC}"
    echo -e "${DIM}$(printf '%.0s─' {1..60})${NC}"
    echo -e "  ${CYAN}Kullanıcı Adı:${NC}   ${ADMIN_USERNAME}"
    echo -e "  ${CYAN}Şifre:${NC}           ${ADMIN_PASSWORD}"
    echo -e "  ${CYAN}E-posta:${NC}         ${ADMIN_EMAIL}"
    echo ""
    
    # Credentials dosyası oluştur
    if [[ "$DRY_RUN" != true ]]; then
        cat > "${INSTALL_DIR}/CREDENTIALS.txt" << CREDEOF
HaberNexus Giriş Bilgileri
==========================
Oluşturulma Tarihi: $(date)

Web Arayüzü: $access_url
Admin Panel: ${access_url}/admin/

Admin Kullanıcı Adı: ${ADMIN_USERNAME}
Admin Şifresi: ${ADMIN_PASSWORD}
Admin E-posta: ${ADMIN_EMAIL}

Veritabanı:
  Host: postgres
  Port: 5432
  Database: habernexus
  User: habernexus_user
  Password: ${DB_PASSWORD}

Redis:
  URL: redis://redis:6379/0

ÖNEMLİ: Bu dosyayı güvenli bir yerde saklayın ve sunucudan silin!
CREDEOF
        chmod 600 "${INSTALL_DIR}/CREDENTIALS.txt"
        echo -e "${YELLOW}⚠ Giriş bilgileri kaydedildi:${NC} ${INSTALL_DIR}/CREDENTIALS.txt"
        echo -e "${YELLOW}  Bu dosyayı güvenli bir yere kopyalayıp sunucudan silin!${NC}"
    fi
    
    echo ""
    
    # Faydalı komutlar
    echo -e "${BOLD}Faydalı Komutlar:${NC}"
    echo -e "${DIM}$(printf '%.0s─' {1..60})${NC}"
    echo -e "  ${CYAN}Logları görüntüle:${NC}    docker compose -f docker-compose.prod.yml logs -f"
    echo -e "  ${CYAN}Servisleri yeniden başlat:${NC} docker compose -f docker-compose.prod.yml restart"
    echo -e "  ${CYAN}Servisleri durdur:${NC}    docker compose -f docker-compose.prod.yml down"
    echo -e "  ${CYAN}Yedek al:${NC}             sudo bash setup.sh --backup"
    echo -e "  ${CYAN}Yedekleri listele:${NC}    sudo bash setup.sh --list-backups"
    echo -e "  ${CYAN}Sistem tanılama:${NC}      sudo bash scripts/diagnostics.sh"
    echo -e "  ${CYAN}Otomatik düzeltme:${NC}    sudo bash scripts/diagnostics.sh --fix"
    echo ""
    
    # Log dosyası
    echo -e "${BOLD}Log Dosyası:${NC} $LOG_FILE"
    echo ""
    
    # Sonraki adımlar
    if [[ "$USE_CLOUDFLARE" == true ]]; then
        echo -e "${BOLD}Sonraki Adımlar:${NC}"
        echo -e "${DIM}$(printf '%.0s─' {1..60})${NC}"
        echo -e "  1. Cloudflare Dashboard'dan tunnel durumunu kontrol edin"
        echo -e "  2. DNS ayarlarının doğru yapılandırıldığından emin olun"
        echo -e "  3. ${access_url} adresinden siteye erişin"
    elif [[ "$DOMAIN" != "localhost" ]]; then
        echo -e "${BOLD}Sonraki Adımlar:${NC}"
        echo -e "${DIM}$(printf '%.0s─' {1..60})${NC}"
        echo -e "  1. DNS kaydınızı sunucu IP'sine yönlendirin"
        echo -e "  2. 80 ve 443 portlarının açık olduğundan emin olun"
        echo -e "  3. SSL sertifikası otomatik olarak alınacaktır"
    fi
    
    echo ""
    echo -e "${GREEN}${STAR} Kurulum tamamlandı! İyi çalışmalar! ${STAR}${NC}"
    echo ""
}

# =============================================================================
# MANUAL INSTALLATION MODE
# =============================================================================

manual_installation() {
    echo ""
    echo -e "${BOLD}Manuel Kurulum Modu${NC}"
    echo -e "${DIM}$(printf '%.0s─' {1..60})${NC}"
    echo ""
    echo "Bu mod, kurulum adımlarını tek tek kontrol etmenizi sağlar."
    echo "Her adımda onayınız istenecektir."
    echo ""
    
    # Adım 1: Sistem Gereksinimleri
    echo -e "${MAGENTA}[Adım 1/8]${NC} Sistem Gereksinimleri"
    if confirm "Sistem gereksinimlerini kontrol etmek istiyor musunuz?"; then
        check_system_requirements
    fi
    
    # Adım 2: Mevcut Kurulum
    echo ""
    echo -e "${MAGENTA}[Adım 2/8]${NC} Mevcut Kurulum Kontrolü"
    if confirm "Mevcut kurulum kontrolü yapmak istiyor musunuz?"; then
        check_existing_installation
    fi
    
    # Adım 3: Bağımlılıklar
    echo ""
    echo -e "${MAGENTA}[Adım 3/8]${NC} Bağımlılık Kurulumu"
    if confirm "Bağımlılıkları kurmak istiyor musunuz?"; then
        install_dependencies
    fi
    
    # Adım 4: Yapılandırma
    echo ""
    echo -e "${MAGENTA}[Adım 4/8]${NC} Yapılandırma"
    if confirm "Yapılandırma bilgilerini girmek istiyor musunuz?"; then
        collect_config_cli
        finalize_configuration
    fi
    
    # Adım 5: Proje İndirme
    echo ""
    echo -e "${MAGENTA}[Adım 5/8]${NC} Proje Dosyaları"
    if confirm "Proje dosyalarını indirmek istiyor musunuz?"; then
        clone_repository
    fi
    
    # Adım 6: Ortam Değişkenleri
    echo ""
    echo -e "${MAGENTA}[Adım 6/8]${NC} Ortam Değişkenleri"
    if confirm "Ortam değişkenlerini yapılandırmak istiyor musunuz?"; then
        create_environment_file
    fi
    
    # Adım 7: Servisleri Başlat
    echo ""
    echo -e "${MAGENTA}[Adım 7/8]${NC} Servisleri Başlatma"
    if confirm "Servisleri başlatmak istiyor musunuz?"; then
        start_services
    fi
    
    # Adım 8: Doğrulama
    echo ""
    echo -e "${MAGENTA}[Adım 8/8]${NC} Kurulum Doğrulama"
    if confirm "Kurulumu doğrulamak istiyor musunuz?"; then
        verify_installation
    fi
    
    show_completion_message
}

# =============================================================================
# UNINSTALL
# =============================================================================

uninstall_habernexus() {
    echo ""
    echo -e "${RED}${BOLD}HaberNexus Kaldırma${NC}"
    echo -e "${DIM}$(printf '%.0s─' {1..60})${NC}"
    echo ""
    
    warning "Bu işlem HaberNexus'u tamamen kaldıracak!"
    echo ""
    echo "Silinecekler:"
    echo "  • Docker container'ları"
    echo "  • Docker volume'ları (veritabanı dahil)"
    echo "  • Kurulum dizini ($INSTALL_DIR)"
    echo "  • Yapılandırma dosyaları"
    echo ""
    
    if ! confirm "Devam etmek istediğinizden emin misiniz?"; then
        info "Kaldırma işlemi iptal edildi."
        exit 0
    fi
    
    if confirm "Kaldırmadan önce yedek almak ister misiniz?"; then
        create_backup
    fi
    
    full_cleanup
    
    # Yedekleri de sil mi?
    if [[ -d "$BACKUP_DIR" ]]; then
        if confirm "Yedek dosyalarını da silmek ister misiniz?"; then
            rm -rf "$BACKUP_DIR"
            success "Yedekler silindi"
        fi
    fi
    
    success "HaberNexus başarıyla kaldırıldı!"
}

# =============================================================================
# DIAGNOSTICS
# =============================================================================

run_diagnostics() {
    echo ""
    echo -e "${CYAN}${BOLD}Sistem Tanılaması Başlatılıyor...${NC}"
    echo ""
    
    local diag_script="${INSTALL_DIR}/scripts/diagnostics.sh"
    
    # Script'in varlığını kontrol et
    if [[ ! -f "$diag_script" ]]; then
        # GitHub'dan indir
        info "Diagnostics script indiriliyor..."
        mkdir -p "${INSTALL_DIR}/scripts"
        if curl -fsSL "${GITHUB_RAW_URL}/scripts/diagnostics.sh" -o "$diag_script" 2>/dev/null; then
            chmod +x "$diag_script"
            success "Diagnostics script indirildi"
        else
            error "Diagnostics script indirilemedi"
            return 1
        fi
    fi
    
    # Script'i çalıştır
    local diag_args=""
    if [[ "$DIAGNOSE_FIX" == true ]]; then
        diag_args="--fix"
    fi
    
    bash "$diag_script" $diag_args
    return $?
}

# =============================================================================
# HELP & VERSION
# =============================================================================

show_help() {
    cat << HELPEOF
${BOLD}${SCRIPT_NAME} v${SCRIPT_VERSION}${NC}

${BOLD}KULLANIM:${NC}
  sudo bash setup.sh [SEÇENEKLER]

${BOLD}KURULUM MODLARI:${NC}
  (varsayılan)        Otomatik kurulum (TUI varsa etkileşimli)
  --quick, -q         Varsayılan değerlerle hızlı kurulum
  --dev               Geliştirici modu (DEBUG=True)
  --manual, -m        Manuel kurulum (adım adım)

${BOLD}YAPILANDIRMA:${NC}
  --domain, -d        Domain adı (varsayılan: localhost)
  --email, -e         Admin e-posta adresi
  --username, -u      Admin kullanıcı adı (varsayılan: admin)
  --password, -p      Admin şifresi (boş = otomatik)
  --config, -c        YAML yapılandırma dosyası

${BOLD}YEDEKLEME:${NC}
  --backup, -b        Yedek al
  --restore, -r       Yedekten geri yükle (backup_YYYYMMDD_HHMMSS)
  --list-backups      Mevcut yedekleri listele

${BOLD}TEMİZLİK:${NC}
  --reset             Mevcut kurulumu sıfırla ve yeniden kur
  --uninstall         Tamamen kaldır

${BOLD}TANI & SORUN GİDERME:${NC}
  --diagnose          Sistem tanılaması yap
  --diagnose-fix      Tanılama yap ve otomatik düzelt

${BOLD}DİĞER:${NC}
  --dry-run           Simülasyon modu (değişiklik yapmaz)
  --no-tui            TUI'yi devre dışı bırak
  --help, -h          Bu yardım mesajını göster
  --version, -v       Versiyon bilgisi

${BOLD}ÖRNEKLER:${NC}
  # Tek komutla kurulum
  curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/main/setup.sh | sudo bash

  # Domain ile kurulum
  sudo bash setup.sh --domain example.com --email admin@example.com

  # Hızlı kurulum
  sudo bash setup.sh --quick

  # Geliştirici kurulumu
  sudo bash setup.sh --dev

  # Yedek al
  sudo bash setup.sh --backup

  # Yedekten geri yükle
  sudo bash setup.sh --restore backup_20251218_120000

${BOLD}DAHA FAZLA BİLGİ:${NC}
  GitHub: https://github.com/${GITHUB_REPO}
  Wiki: https://github.com/${GITHUB_REPO}/wiki

HELPEOF
}

show_version() {
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --domain|-d)
                DOMAIN="$2"
                shift 2
                ;;
            --email|-e)
                ADMIN_EMAIL="$2"
                shift 2
                ;;
            --username|-u)
                ADMIN_USERNAME="$2"
                shift 2
                ;;
            --password|-p)
                ADMIN_PASSWORD="$2"
                shift 2
                ;;
            --quick|-q)
                QUICK_MODE=true
                shift
                ;;
            --dev)
                DEV_MODE=true
                shift
                ;;
            --manual|-m)
                MANUAL_MODE=true
                shift
                ;;
            --reset)
                FULL_RESET=true
                shift
                ;;
            --backup|-b)
                BACKUP_ONLY=true
                shift
                ;;
            --restore|-r)
                RESTORE_BACKUP="$2"
                shift 2
                ;;
            --list-backups)
                LIST_BACKUPS=true
                shift
                ;;
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --no-tui)
                NO_TUI=true
                shift
                ;;
            --diagnose)
                DIAGNOSE_MODE=true
                shift
                ;;
            --diagnose-fix)
                DIAGNOSE_MODE=true
                DIAGNOSE_FIX=true
                shift
                ;;
            --config|-c)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            *)
                error "Bilinmeyen parametre: $1"
                echo "Yardım için: sudo bash setup.sh --help"
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    # Renkleri ayarla
    setup_colors
    
    # Logging başlat
    init_logging
    
    # Parametreleri parse et
    parse_arguments "$@"
    
    # Banner göster
    print_banner
    
    log "INFO" "HaberNexus Installer v${SCRIPT_VERSION} started"
    log "INFO" "Arguments: $*"
    
    # Özel modlar
    if [[ "$LIST_BACKUPS" == true ]]; then
        list_backups
        exit 0
    fi
    
    if [[ "$BACKUP_ONLY" == true ]]; then
        create_backup
        exit 0
    fi
    
    if [[ -n "$RESTORE_BACKUP" ]]; then
        restore_backup "$RESTORE_BACKUP"
        exit 0
    fi
    
    if [[ "$UNINSTALL" == true ]]; then
        uninstall_habernexus
        exit 0
    fi
    
    # Diagnose modu
    if [[ "$DIAGNOSE_MODE" == true ]]; then
        run_diagnostics
        exit $?
    fi
    
    # Dry-run bilgisi
    if [[ "$DRY_RUN" == true ]]; then
        warning "DRY-RUN modu aktif - hiçbir değişiklik yapılmayacak"
        echo ""
    fi
    
    # Manuel veya otomatik kurulum
    if [[ "$MANUAL_MODE" == true ]]; then
        manual_installation
    else
        # Otomatik kurulum akışı
        check_system_requirements
        check_existing_installation
        install_dependencies
        collect_configuration
        finalize_configuration
        clone_repository
        create_environment_file
        start_services
        verify_installation
        show_completion_message
    fi
    
    log "INFO" "Installation completed successfully"
}

# =============================================================================
# ENTRY POINT
# =============================================================================

# Script'i çalıştır
main "$@"
