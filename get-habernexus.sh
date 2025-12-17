#!/bin/bash
# =============================================================================
# HaberNexus - Universal One-Line Installer
# =============================================================================
#
# Bu script, HaberNexus'u tek bir komut ile Ubuntu/Debian sunuculara kurar.
# Docker, Oh My Zsh ve diğer popüler projelerden ilham alınarak tasarlanmıştır.
#
# Kullanım (Tek Komut):
#   curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/get-habernexus.sh | bash
#
# Güvenli Kullanım (Önce İndir, Sonra Çalıştır):
#   curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/get-habernexus.sh -o install.sh
#   bash install.sh
#
# Parametreler:
#   --domain DOMAIN       Domain adı (varsayılan: localhost)
#   --email EMAIL         Admin e-posta adresi
#   --quick               Varsayılan değerlerle hızlı kurulum
#   --dry-run             Simülasyon modu (kurulum yapmaz)
#   --unattended          Etkileşimsiz mod (CI/CD için)
#   --help                Yardım mesajını göster
#
# Desteklenen Sistemler:
#   - Ubuntu 20.04, 22.04, 24.04
#   - Debian 11, 12
#   - Google Cloud VM, AWS EC2, DigitalOcean, Azure
#
# Geliştirici: Salih TANRISEVEN
# E-posta: salihtanriseven25@gmail.com
# Lisans: MIT
# =============================================================================

set -e

# =============================================================================
# GLOBAL CONSTANTS
# =============================================================================

readonly SCRIPT_VERSION="10.5.0"
readonly SCRIPT_NAME="HaberNexus Installer"
readonly GITHUB_REPO="sata2500/habernexus"
readonly GITHUB_RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main"
readonly INSTALL_DIR="/opt/habernexus"
readonly LOG_DIR="/var/log/habernexus"
readonly BACKUP_DIR="/opt/habernexus-backups"
readonly MIN_MEMORY_MB=1024
readonly MIN_DISK_GB=10

# Timestamp for logs and backups
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)

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
        BOLD='\033[1m'
        DIM='\033[2m'
        NC='\033[0m'
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        MAGENTA=''
        CYAN=''
        BOLD=''
        DIM=''
        NC=''
    fi
}

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

LOG_FILE=""

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
    echo -e "${DIM}Version ${SCRIPT_VERSION} | Universal One-Line Installer${NC}"
    echo ""
}

info() {
    log "INFO" "$*"
    echo -e "${BLUE}ℹ${NC}  $*"
}

success() {
    log "SUCCESS" "$*"
    echo -e "${GREEN}✓${NC}  $*"
}

warning() {
    log "WARNING" "$*"
    echo -e "${YELLOW}⚠${NC}  $*"
}

error() {
    log "ERROR" "$*"
    echo -e "${RED}✗${NC}  $*" >&2
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
    # TUI kullanılabilir mi kontrol et
    # Google Cloud Console SSH gibi ortamlarda TTY olmayabilir
    [[ "$UNATTENDED" != true ]] && \
    [[ -t 0 ]] && \
    [[ -t 1 ]] && \
    command_exists whiptail
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
    # Domain regex
    [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]] && return 0
    # localhost veya IP adresi
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
    step "1/7" "Sistem Gereksinimleri Kontrol Ediliyor"
    
    # Root kontrolü
    if ! is_root; then
        if command_exists sudo; then
            warning "Root yetkisi gerekiyor. Script sudo ile yeniden başlatılıyor..."
            exec sudo bash "$0" "$@"
        else
            fatal "Bu script root yetkisi gerektirir. 'sudo bash $0' ile çalıştırın."
        fi
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
            warning "Bu dağıtım ($distro) resmi olarak desteklenmiyor. Kurulum devam edecek ama sorunlar olabilir."
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
        warning "Container ortamı algılandı. Docker-in-Docker kurulumu gerekebilir."
    fi
}

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

install_dependencies() {
    step "2/7" "Bağımlılıklar Kuruluyor"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Paket listesi güncellenecek"
        info "[DRY-RUN] Temel paketler kurulacak"
        info "[DRY-RUN] Docker kurulacak"
        return 0
    fi
    
    local distro
    distro=$(get_distribution)
    
    info "Paket listesi güncelleniyor..."
    apt-get update -qq > /dev/null 2>&1 || true
    
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
    )
    
    # Whiptail (TUI için)
    if ! command_exists whiptail; then
        packages+=(whiptail)
    fi
    
    info "Temel paketler kuruluyor..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${packages[@]}" > /dev/null 2>&1
    success "Temel paketler kuruldu"
    
    # Docker kurulumu
    if ! command_exists docker; then
        info "Docker kuruluyor..."
        curl -fsSL https://get.docker.com | sh > /dev/null 2>&1
        success "Docker kuruldu"
    else
        success "Docker zaten kurulu: $(docker --version 2>/dev/null | head -1)"
    fi
    
    # Docker Compose kontrolü
    if ! docker compose version > /dev/null 2>&1; then
        info "Docker Compose plugin kuruluyor..."
        apt-get install -y -qq docker-compose-plugin > /dev/null 2>&1 || true
    fi
    success "Docker Compose: $(docker compose version 2>/dev/null | head -1)"
    
    # Docker servisini başlat
    if has_systemd; then
        systemctl enable docker > /dev/null 2>&1 || true
        systemctl start docker > /dev/null 2>&1 || true
    fi
}

# =============================================================================
# CONFIGURATION COLLECTION
# =============================================================================

# Varsayılan değerler
DOMAIN="localhost"
ADMIN_EMAIL=""
ADMIN_USERNAME="admin"
ADMIN_PASSWORD=""
DB_PASSWORD=""
SECRET_KEY=""
QUICK_MODE=false
DRY_RUN=false
UNATTENDED=false
USE_CLOUDFLARE=false
CLOUDFLARE_TUNNEL_TOKEN=""

collect_configuration_interactive() {
    step "3/7" "Yapılandırma Bilgileri Toplanıyor"
    
    if can_use_tui; then
        collect_config_tui
    else
        collect_config_cli
    fi
}

collect_config_tui() {
    info "Etkileşimli yapılandırma başlatılıyor..."
    
    # Hoşgeldin mesajı
    whiptail --title "HaberNexus Kurulum Sihirbazı" --msgbox \
        "HaberNexus kurulum sihirbazına hoş geldiniz!\n\nBu sihirbaz size kurulum sürecinde rehberlik edecektir.\n\nDevam etmek için OK'a basın." \
        12 60
    
    # Domain
    DOMAIN=$(whiptail --title "Domain Yapılandırması" --inputbox \
        "Domain adınızı girin:\n\n(Örnek: habernexus.com veya localhost)" \
        10 60 "$DOMAIN" 3>&1 1>&2 2>&3) || DOMAIN="localhost"
    
    # Admin Email
    ADMIN_EMAIL=$(whiptail --title "Admin E-posta" --inputbox \
        "Admin e-posta adresinizi girin:\n\n(SSL sertifikası ve bildirimler için kullanılacak)" \
        10 60 "$ADMIN_EMAIL" 3>&1 1>&2 2>&3) || ADMIN_EMAIL="admin@$DOMAIN"
    
    # Admin Username
    ADMIN_USERNAME=$(whiptail --title "Admin Kullanıcı Adı" --inputbox \
        "Admin kullanıcı adını girin:" \
        10 60 "$ADMIN_USERNAME" 3>&1 1>&2 2>&3) || ADMIN_USERNAME="admin"
    
    # Admin Password
    ADMIN_PASSWORD=$(whiptail --title "Admin Şifresi" --passwordbox \
        "Admin şifresini girin:\n\n(Boş bırakırsanız otomatik oluşturulur)" \
        10 60 3>&1 1>&2 2>&3) || ADMIN_PASSWORD=""
    
    # Cloudflare Tunnel
    if whiptail --title "Cloudflare Tunnel" --yesno \
        "Cloudflare Tunnel kullanmak ister misiniz?\n\nCloudflare Tunnel, sunucunuza port açmadan güvenli erişim sağlar.\n\n• SSL sertifikası otomatik\n• DDoS koruması\n• Port 80/443 açmanıza gerek yok" \
        14 60; then
        USE_CLOUDFLARE=true
        
        whiptail --title "Cloudflare Token Rehberi" --msgbox \
            "Cloudflare Tunnel Token Nasıl Alınır:\n\n1. https://one.dash.cloudflare.com adresine gidin\n2. Networks > Tunnels bölümüne gidin\n3. 'Create a Tunnel' > 'Cloudflared' seçin\n4. Tunnel'a isim verin (örn: habernexus)\n5. Token'ı kopyalayın (eyJhIjoi... ile başlar)\n6. Public Hostnames'e domain ekleyin:\n   - Service: http://nginx:80" \
            18 70
        
        CLOUDFLARE_TUNNEL_TOKEN=$(whiptail --title "Cloudflare Token" --inputbox \
            "Cloudflare Tunnel Token'ınızı yapıştırın:" \
            10 70 3>&1 1>&2 2>&3) || CLOUDFLARE_TUNNEL_TOKEN=""
    fi
    
    # Özet
    local summary="Kurulum Özeti:\n\n"
    summary+="Domain: $DOMAIN\n"
    summary+="Admin E-posta: $ADMIN_EMAIL\n"
    summary+="Admin Kullanıcı: $ADMIN_USERNAME\n"
    summary+="Cloudflare Tunnel: $([ "$USE_CLOUDFLARE" = true ] && echo 'Evet' || echo 'Hayır')\n"
    
    if ! whiptail --title "Kurulum Onayı" --yesno "$summary\nKuruluma devam etmek istiyor musunuz?" 16 60; then
        fatal "Kurulum kullanıcı tarafından iptal edildi."
    fi
}

collect_config_cli() {
    info "Komut satırı yapılandırması kullanılıyor..."
    
    # Eğer parametreler verilmemişse varsayılanları kullan
    if [[ -z "$DOMAIN" || "$DOMAIN" == "localhost" ]]; then
        if [[ "$UNATTENDED" != true ]]; then
            echo -n "Domain adı [localhost]: "
            read -r input
            DOMAIN="${input:-localhost}"
        fi
    fi
    
    if [[ -z "$ADMIN_EMAIL" ]]; then
        if [[ "$UNATTENDED" != true ]]; then
            echo -n "Admin e-posta [admin@$DOMAIN]: "
            read -r input
            ADMIN_EMAIL="${input:-admin@$DOMAIN}"
        else
            ADMIN_EMAIL="admin@$DOMAIN"
        fi
    fi
    
    success "Yapılandırma tamamlandı"
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
# INSTALLATION
# =============================================================================

clone_repository() {
    step "4/7" "Proje Dosyaları İndiriliyor"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] git clone https://github.com/${GITHUB_REPO}.git $INSTALL_DIR"
        return 0
    fi
    
    # Mevcut kurulum varsa yedekle
    if [[ -d "$INSTALL_DIR" ]]; then
        warning "Mevcut kurulum bulundu: $INSTALL_DIR"
        
        # Backup oluştur
        mkdir -p "$BACKUP_DIR"
        local backup_path="${BACKUP_DIR}/backup_${TIMESTAMP}"
        
        info "Mevcut kurulum yedekleniyor: $backup_path"
        
        # Docker container'ları durdur
        if [[ -f "$INSTALL_DIR/docker-compose.yml" ]] || [[ -f "$INSTALL_DIR/docker-compose.prod.yml" ]]; then
            cd "$INSTALL_DIR"
            docker compose down -v --remove-orphans 2>/dev/null || true
            docker compose -f docker-compose.prod.yml down -v --remove-orphans 2>/dev/null || true
        fi
        
        # Yedekle
        cp -r "$INSTALL_DIR" "$backup_path" 2>/dev/null || true
        rm -rf "$INSTALL_DIR"
        
        success "Yedekleme tamamlandı"
    fi
    
    # Repo'yu klonla
    info "GitHub'dan proje indiriliyor..."
    git clone --depth 1 "https://github.com/${GITHUB_REPO}.git" "$INSTALL_DIR" > /dev/null 2>&1
    
    success "Proje dosyaları indirildi: $INSTALL_DIR"
}

create_environment_file() {
    step "5/7" "Ortam Değişkenleri Yapılandırılıyor"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] .env dosyası oluşturulacak"
        return 0
    fi
    
    cd "$INSTALL_DIR"
    
    # .env dosyası oluştur
    cat > .env << ENVEOF
# =============================================================================
# HaberNexus Environment Configuration
# Generated: $(date)
# =============================================================================

# Django Settings
DEBUG=False
DJANGO_SECRET_KEY=${SECRET_KEY}
ALLOWED_HOSTS=${DOMAIN},www.${DOMAIN},localhost,127.0.0.1

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
DOMAIN=${DOMAIN}
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True

# Admin User
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# AI Settings (Optional)
GOOGLE_GEMINI_API_KEY=
AI_MODEL=gemini-2.5-flash

# Cloudflare (Optional)
USE_CLOUDFLARE=${USE_CLOUDFLARE}
CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
ENVEOF

    chmod 600 .env
    success ".env dosyası oluşturuldu"
    
    # Cloudflare override dosyası
    if [[ "$USE_CLOUDFLARE" == true ]] && [[ -n "$CLOUDFLARE_TUNNEL_TOKEN" ]]; then
        cat > docker-compose.override.yml << 'OVERRIDEEOF'
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
    networks:
      - habernexus_network
    depends_on:
      - nginx
OVERRIDEEOF
        success "Cloudflare Tunnel yapılandırması oluşturuldu"
    fi
}

start_services() {
    step "6/7" "Servisler Başlatılıyor"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] docker compose up -d"
        return 0
    fi
    
    cd "$INSTALL_DIR"
    
    info "Docker imajları indiriliyor ve container'lar başlatılıyor..."
    info "Bu işlem birkaç dakika sürebilir..."
    
    # Production compose dosyasını kullan
    if [[ -f "docker-compose.prod.yml" ]]; then
        docker compose -f docker-compose.prod.yml up -d --build 2>&1 | while read -r line; do
            echo -e "${DIM}  $line${NC}"
        done
    else
        docker compose up -d --build 2>&1 | while read -r line; do
            echo -e "${DIM}  $line${NC}"
        done
    fi
    
    success "Docker container'ları başlatıldı"
    
    # Servislerin başlamasını bekle
    info "Servislerin hazır olması bekleniyor..."
    sleep 15
    
    # Database migration
    info "Veritabanı migration'ları çalıştırılıyor..."
    local max_retries=5
    local retry=0
    
    while [[ $retry -lt $max_retries ]]; do
        if docker compose -f docker-compose.prod.yml exec -T web python manage.py migrate --noinput 2>/dev/null; then
            success "Veritabanı migration'ları tamamlandı"
            break
        fi
        
        retry=$((retry + 1))
        if [[ $retry -lt $max_retries ]]; then
            warning "Migration başarısız, yeniden deneniyor... ($retry/$max_retries)"
            sleep 10
        else
            warning "Migration'lar başarısız oldu. Manuel olarak çalıştırmanız gerekebilir."
        fi
    done
    
    # Static dosyaları topla
    info "Static dosyalar toplanıyor..."
    docker compose -f docker-compose.prod.yml exec -T web python manage.py collectstatic --noinput 2>/dev/null || true
    success "Static dosyalar hazır"
    
    # Superuser oluştur
    info "Admin kullanıcısı oluşturuluyor..."
    docker compose -f docker-compose.prod.yml exec -T web python manage.py shell << PYEOF 2>/dev/null || true
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='${ADMIN_USERNAME}').exists():
    User.objects.create_superuser('${ADMIN_USERNAME}', '${ADMIN_EMAIL}', '${ADMIN_PASSWORD}')
    print('Admin user created')
else:
    print('Admin user already exists')
PYEOF
    success "Admin kullanıcısı hazır"
}

show_completion_message() {
    step "7/7" "Kurulum Tamamlandı"
    
    local public_ip
    public_ip=$(get_public_ip)
    
    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║         🎉 HaberNexus Başarıyla Kuruldu! 🎉                  ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BOLD}Erişim Bilgileri:${NC}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ "$USE_CLOUDFLARE" == true ]] && [[ -n "$CLOUDFLARE_TUNNEL_TOKEN" ]]; then
        echo -e "  ${CYAN}Web Sitesi:${NC}     https://${DOMAIN}"
        echo -e "  ${CYAN}Admin Panel:${NC}    https://${DOMAIN}/admin/"
    else
        echo -e "  ${CYAN}Web Sitesi:${NC}     http://${public_ip}"
        echo -e "  ${CYAN}Admin Panel:${NC}    http://${public_ip}/admin/"
        if [[ "$DOMAIN" != "localhost" ]]; then
            echo -e "  ${YELLOW}Not:${NC} DNS ayarlarınızı ${DOMAIN} -> ${public_ip} olarak yapılandırın"
        fi
    fi
    
    echo ""
    echo -e "${BOLD}Admin Giriş Bilgileri:${NC}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${CYAN}Kullanıcı Adı:${NC}  ${ADMIN_USERNAME}"
    echo -e "  ${CYAN}Şifre:${NC}          ${ADMIN_PASSWORD}"
    echo -e "  ${CYAN}E-posta:${NC}        ${ADMIN_EMAIL}"
    
    echo ""
    echo -e "${BOLD}Faydalı Komutlar:${NC}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${DIM}# Servislerin durumunu görüntüle${NC}"
    echo -e "  cd $INSTALL_DIR && docker compose -f docker-compose.prod.yml ps"
    echo ""
    echo -e "  ${DIM}# Logları görüntüle${NC}"
    echo -e "  cd $INSTALL_DIR && docker compose -f docker-compose.prod.yml logs -f"
    echo ""
    echo -e "  ${DIM}# Servisleri yeniden başlat${NC}"
    echo -e "  cd $INSTALL_DIR && docker compose -f docker-compose.prod.yml restart"
    
    echo ""
    echo -e "${BOLD}Kurulum Detayları:${NC}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${CYAN}Kurulum Dizini:${NC}  $INSTALL_DIR"
    echo -e "  ${CYAN}Log Dosyası:${NC}     $LOG_FILE"
    echo -e "  ${CYAN}Versiyon:${NC}        $SCRIPT_VERSION"
    
    echo ""
    echo -e "${YELLOW}⚠ ÖNEMLİ: Admin şifrenizi güvenli bir yere kaydedin!${NC}"
    echo ""
    
    # Credentials dosyasına kaydet (dry-run modunda atla)
    if [[ "$DRY_RUN" != true ]]; then
    cat > "$INSTALL_DIR/CREDENTIALS.txt" << CREDEOF
HaberNexus Kurulum Bilgileri
============================
Kurulum Tarihi: $(date)

Web Sitesi: ${DOMAIN}
Admin Panel: ${DOMAIN}/admin/

Admin Kullanıcı Adı: ${ADMIN_USERNAME}
Admin Şifre: ${ADMIN_PASSWORD}
Admin E-posta: ${ADMIN_EMAIL}

Veritabanı Şifresi: ${DB_PASSWORD}
Django Secret Key: ${SECRET_KEY}

Bu dosyayı güvenli bir yere kaydedin ve sunucudan silin!
CREDEOF
    chmod 600 "$INSTALL_DIR/CREDENTIALS.txt"
    echo -e "${GREEN}Giriş bilgileri kaydedildi: ${INSTALL_DIR}/CREDENTIALS.txt${NC}"
    fi
    echo ""
}

# =============================================================================
# HELP AND ARGUMENT PARSING
# =============================================================================

show_help() {
    cat << EOF
${BOLD}${SCRIPT_NAME} v${SCRIPT_VERSION}${NC}

Tek komutla HaberNexus kurulumu için evrensel installer.

${BOLD}Kullanım:${NC}
  curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/main/get-habernexus.sh | bash
  
  veya
  
  bash get-habernexus.sh [SEÇENEKLER]

${BOLD}Seçenekler:${NC}
  --domain DOMAIN       Domain adı (varsayılan: localhost)
  --email EMAIL         Admin e-posta adresi
  --username USERNAME   Admin kullanıcı adı (varsayılan: admin)
  --password PASSWORD   Admin şifresi (boş ise otomatik)
  --quick               Varsayılan değerlerle hızlı kurulum
  --dry-run             Simülasyon modu (kurulum yapmaz)
  --unattended          Etkileşimsiz mod (CI/CD için)
  --help, -h            Bu yardım mesajını göster
  --version, -v         Versiyon bilgisini göster

${BOLD}Örnekler:${NC}
  # Etkileşimli kurulum
  curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/main/get-habernexus.sh | sudo bash

  # Parametrelerle kurulum
  curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/main/get-habernexus.sh | sudo bash -s -- --domain example.com --email admin@example.com

  # Hızlı kurulum
  curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/main/get-habernexus.sh | sudo bash -s -- --quick

${BOLD}Desteklenen Sistemler:${NC}
  - Ubuntu 20.04, 22.04, 24.04
  - Debian 11, 12
  - Google Cloud VM, AWS EC2, DigitalOcean, Azure

${BOLD}Daha fazla bilgi:${NC}
  https://github.com/${GITHUB_REPO}

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --email)
                ADMIN_EMAIL="$2"
                shift 2
                ;;
            --username)
                ADMIN_USERNAME="$2"
                shift 2
                ;;
            --password)
                ADMIN_PASSWORD="$2"
                shift 2
                ;;
            --quick)
                QUICK_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --unattended)
                UNATTENDED=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
                exit 0
                ;;
            *)
                error "Bilinmeyen parametre: $1"
                echo "Kullanım için: $0 --help"
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
    
    # Argümanları parse et
    parse_arguments "$@"
    
    # Banner göster
    print_banner
    
    # Logging başlat
    init_logging
    log "INFO" "HaberNexus Installer v${SCRIPT_VERSION} başlatıldı"
    
    # Dry-run modu bildirimi
    if [[ "$DRY_RUN" == true ]]; then
        warning "DRY-RUN MODU: Hiçbir değişiklik yapılmayacak"
        echo ""
    fi
    
    # Kurulum adımları
    check_system_requirements
    install_dependencies
    
    if [[ "$QUICK_MODE" != true ]]; then
        collect_configuration_interactive
    else
        info "Hızlı mod: Varsayılan değerler kullanılıyor"
        ADMIN_EMAIL="admin@$DOMAIN"
    fi
    
    finalize_configuration
    clone_repository
    create_environment_file
    start_services
    show_completion_message
    
    log "INFO" "Kurulum başarıyla tamamlandı"
}

# Script'i çalıştır
main "$@"
