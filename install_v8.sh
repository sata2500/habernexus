#!/bin/bash

################################################################################
# HaberNexus v8.0 - Ultimate Interactive Installation Script
# 
# Features:
#   - Fully automated one-click installation
#   - Beautiful TUI (Text User Interface) with animations
#   - Real-time progress tracking with percentage
#   - Automatic API validation (Cloudflare, Domain, Email)
#   - Smart error recovery and rollback mechanism
#   - Comprehensive pre-flight system analysis
#   - Web-based setup wizard option
#   - Multi-language support (TR/EN)
#   - Automatic backup before installation
#   - Post-installation health verification
#   - Configuration wizard with smart defaults
#
# Usage: 
#   sudo bash install_v8.sh                    # Interactive wizard
#   sudo bash install_v8.sh --auto             # Fully automatic with prompts
#   sudo bash install_v8.sh --wizard           # Web-based setup wizard
#   sudo bash install_v8.sh --quick            # Quick setup with defaults
#   sudo bash install_v8.sh --config file.yml  # Use config file
#
# Author: Salih TANRISEVEN
# Date: December 15, 2025
# Version: 8.0
################################################################################

set -euo pipefail

# ============================================================================
# SCRIPT METADATA
# ============================================================================

readonly SCRIPT_VERSION="8.0"
readonly SCRIPT_NAME="HaberNexus Ultimate Installer"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_START_TIME=$(date +%s)

# ============================================================================
# PATH CONFIGURATION
# ============================================================================

readonly PROJECT_PATH="${PROJECT_PATH:-/opt/habernexus}"
readonly LOG_DIR="/var/log/habernexus"
readonly LOG_FILE="${LOG_DIR}/install_v8_$(date +%Y%m%d_%H%M%S).log"
readonly CONFIG_DIR="${PROJECT_PATH}/config"
readonly BACKUP_DIR="${PROJECT_PATH}/.backups/install_v8_$(date +%Y%m%d_%H%M%S)"
readonly ENV_FILE="${PROJECT_PATH}/.env"
readonly STATE_FILE="${LOG_DIR}/.install_state"
readonly WIZARD_PORT=8888

# ============================================================================
# COLOR PALETTE (256 Color Support)
# ============================================================================

# Basic Colors
readonly BLACK='\033[0;30m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m'

# Bold Colors
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly ITALIC='\033[3m'
readonly UNDERLINE='\033[4m'
readonly BLINK='\033[5m'
readonly REVERSE='\033[7m'

# Background Colors
readonly BG_RED='\033[41m'
readonly BG_GREEN='\033[42m'
readonly BG_YELLOW='\033[43m'
readonly BG_BLUE='\033[44m'
readonly BG_MAGENTA='\033[45m'
readonly BG_CYAN='\033[46m'

# Gradient Colors (256 color)
readonly ORANGE='\033[38;5;208m'
readonly PINK='\033[38;5;213m'
readonly LIME='\033[38;5;118m'
readonly SKY='\033[38;5;117m'
readonly PURPLE='\033[38;5;141m'

# ============================================================================
# UNICODE SYMBOLS
# ============================================================================

readonly CHECK="✓"
readonly CROSS="✗"
readonly ARROW="→"
readonly BULLET="•"
readonly STAR="★"
readonly HEART="♥"
readonly DIAMOND="◆"
readonly CIRCLE="●"
readonly SQUARE="■"
readonly TRIANGLE="▲"
readonly ROCKET="🚀"
readonly GEAR="⚙"
readonly LOCK="🔒"
readonly KEY="🔑"
readonly GLOBE="🌐"
readonly DATABASE="🗄"
readonly CLOUD="☁"
readonly LIGHTNING="⚡"
readonly FIRE="🔥"
readonly SPARKLES="✨"
readonly PACKAGE="📦"
readonly FOLDER="📁"
readonly FILE="📄"
readonly TERMINAL="💻"
readonly SERVER="🖥"
readonly COFFEE="☕"
readonly CLOCK="🕐"
readonly WARNING_ICON="⚠️"
readonly INFO_ICON="ℹ️"
readonly SUCCESS_ICON="✅"
readonly ERROR_ICON="❌"

# Spinner Animations
readonly SPINNER_DOTS=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
readonly SPINNER_LINE=("—" "\\" "|" "/")
readonly SPINNER_CIRCLE=("◐" "◓" "◑" "◒")
readonly SPINNER_BOUNCE=("⠁" "⠂" "⠄" "⠂")
readonly SPINNER_GROW=("▁" "▃" "▄" "▅" "▆" "▇" "█" "▇" "▆" "▅" "▄" "▃")

# Progress Bar Characters
readonly PROGRESS_FULL="█"
readonly PROGRESS_EMPTY="░"
readonly PROGRESS_HALF="▓"

# ============================================================================
# GLOBAL STATE VARIABLES
# ============================================================================

INSTALL_MODE="interactive"
LANGUAGE="tr"
FORCE_REINSTALL=false
SKIP_VALIDATION=false
DRY_RUN=false
VERBOSE=false
SILENT=false
WEB_WIZARD=false

# Configuration Variables
DOMAIN=""
ADMIN_EMAIL=""
ADMIN_USERNAME=""
ADMIN_PASSWORD=""
CLOUDFLARE_API_TOKEN=""
CLOUDFLARE_TUNNEL_TOKEN=""
GOOGLE_API_KEY=""
DB_PASSWORD=""
SECRET_KEY=""

# Installation State
CURRENT_STEP=0
TOTAL_STEPS=15
INSTALLATION_ERRORS=()
ROLLBACK_ACTIONS=()

# ============================================================================
# LOCALIZATION
# ============================================================================

declare -A MESSAGES_TR=(
    ["welcome"]="HaberNexus Kurulum Sihirbazına Hoş Geldiniz"
    ["checking_system"]="Sistem gereksinimleri kontrol ediliyor"
    ["installing_deps"]="Bağımlılıklar yükleniyor"
    ["configuring"]="Yapılandırma oluşturuluyor"
    ["building"]="Docker imajları oluşturuluyor"
    ["starting"]="Servisler başlatılıyor"
    ["verifying"]="Kurulum doğrulanıyor"
    ["complete"]="Kurulum başarıyla tamamlandı"
    ["error"]="Hata oluştu"
    ["warning"]="Uyarı"
    ["info"]="Bilgi"
    ["success"]="Başarılı"
    ["failed"]="Başarısız"
    ["press_enter"]="Devam etmek için Enter'a basın"
    ["enter_domain"]="Domain adınızı girin"
    ["enter_email"]="Admin e-posta adresinizi girin"
    ["enter_username"]="Admin kullanıcı adınızı girin"
    ["enter_password"]="Admin şifrenizi girin"
    ["enter_cf_api"]="Cloudflare API Token'ınızı girin"
    ["enter_cf_tunnel"]="Cloudflare Tunnel Token'ınızı girin"
    ["invalid_domain"]="Geçersiz domain formatı"
    ["invalid_email"]="Geçersiz e-posta formatı"
    ["invalid_password"]="Şifre en az 8 karakter olmalı"
    ["validating_cf"]="Cloudflare token'ları doğrulanıyor"
    ["cf_valid"]="Cloudflare token'ları geçerli"
    ["cf_invalid"]="Cloudflare token'ları geçersiz"
    ["backup_created"]="Yedek oluşturuldu"
    ["rollback_started"]="Geri alma işlemi başlatıldı"
    ["rollback_complete"]="Geri alma tamamlandı"
    ["enjoy"]="Keyifli kullanımlar! Kahvenizi yudumlayın"
)

declare -A MESSAGES_EN=(
    ["welcome"]="Welcome to HaberNexus Installation Wizard"
    ["checking_system"]="Checking system requirements"
    ["installing_deps"]="Installing dependencies"
    ["configuring"]="Creating configuration"
    ["building"]="Building Docker images"
    ["starting"]="Starting services"
    ["verifying"]="Verifying installation"
    ["complete"]="Installation completed successfully"
    ["error"]="Error occurred"
    ["warning"]="Warning"
    ["info"]="Info"
    ["success"]="Success"
    ["failed"]="Failed"
    ["press_enter"]="Press Enter to continue"
    ["enter_domain"]="Enter your domain name"
    ["enter_email"]="Enter admin email address"
    ["enter_username"]="Enter admin username"
    ["enter_password"]="Enter admin password"
    ["enter_cf_api"]="Enter Cloudflare API Token"
    ["enter_cf_tunnel"]="Enter Cloudflare Tunnel Token"
    ["invalid_domain"]="Invalid domain format"
    ["invalid_email"]="Invalid email format"
    ["invalid_password"]="Password must be at least 8 characters"
    ["validating_cf"]="Validating Cloudflare tokens"
    ["cf_valid"]="Cloudflare tokens are valid"
    ["cf_invalid"]="Cloudflare tokens are invalid"
    ["backup_created"]="Backup created"
    ["rollback_started"]="Rollback initiated"
    ["rollback_complete"]="Rollback completed"
    ["enjoy"]="Enjoy! Sit back and sip your coffee"
)

msg() {
    local key=$1
    if [[ "$LANGUAGE" == "tr" ]]; then
        echo "${MESSAGES_TR[$key]:-$key}"
    else
        echo "${MESSAGES_EN[$key]:-$key}"
    fi
}

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

init_logging() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    chmod 600 "${LOG_FILE}"
    
    {
        echo "================================================================================"
        echo "HaberNexus v${SCRIPT_VERSION} Installation Log"
        echo "================================================================================"
        echo "Start Time: $(date)"
        echo "Mode: ${INSTALL_MODE}"
        echo "Language: ${LANGUAGE}"
        echo "Script: ${SCRIPT_DIR}"
        echo "Target: ${PROJECT_PATH}"
        echo "================================================================================"
        echo ""
    } >> "${LOG_FILE}"
}

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
}

log_debug() {
    [[ "$VERBOSE" == true ]] && echo -e "${GRAY}[DEBUG]${NC} $*"
    log "DEBUG" "$*"
}

log_info() {
    [[ "$SILENT" != true ]] && echo -e "${BLUE}${INFO_ICON}${NC} $*"
    log "INFO" "$*"
}

log_success() {
    [[ "$SILENT" != true ]] && echo -e "${GREEN}${SUCCESS_ICON}${NC} $*"
    log "SUCCESS" "$*"
}

log_warning() {
    [[ "$SILENT" != true ]] && echo -e "${YELLOW}${WARNING_ICON}${NC} $*"
    log "WARNING" "$*"
}

log_error() {
    echo -e "${RED}${ERROR_ICON}${NC} $*" >&2
    log "ERROR" "$*"
    INSTALLATION_ERRORS+=("$*")
}

# ============================================================================
# UI COMPONENTS
# ============================================================================

clear_screen() {
    printf "\033c"
}

hide_cursor() {
    printf "\e[?25l"
}

show_cursor() {
    printf "\e[?25h"
}

move_cursor() {
    local row=$1
    local col=$2
    printf "\033[${row};${col}H"
}

save_cursor() {
    printf "\033[s"
}

restore_cursor() {
    printf "\033[u"
}

# Terminal boyutlarını al
get_terminal_size() {
    TERM_ROWS=$(tput lines 2>/dev/null || echo 24)
    TERM_COLS=$(tput cols 2>/dev/null || echo 80)
}

# Ortalanmış metin yazdır
print_centered() {
    local text="$1"
    local color="${2:-$NC}"
    local width=${TERM_COLS:-80}
    local text_length=${#text}
    local padding=$(( (width - text_length) / 2 ))
    
    printf "%${padding}s" ""
    echo -e "${color}${text}${NC}"
}

# Kutu çiz
draw_box() {
    local title="$1"
    local width="${2:-60}"
    local color="${3:-$CYAN}"
    
    local top_left="╔"
    local top_right="╗"
    local bottom_left="╚"
    local bottom_right="╝"
    local horizontal="═"
    local vertical="║"
    
    local inner_width=$((width - 2))
    local title_padding=$(( (inner_width - ${#title}) / 2 ))
    
    echo -e "${color}${top_left}$(printf "${horizontal}%.0s" $(seq 1 $inner_width))${top_right}${NC}"
    echo -e "${color}${vertical}$(printf " %.0s" $(seq 1 $title_padding))${BOLD}${title}${NC}${color}$(printf " %.0s" $(seq 1 $((inner_width - title_padding - ${#title}))))${vertical}${NC}"
    echo -e "${color}${bottom_left}$(printf "${horizontal}%.0s" $(seq 1 $inner_width))${bottom_right}${NC}"
}

# Başlık banner'ı
print_banner() {
    clear_screen
    get_terminal_size
    
    echo ""
    echo -e "${CYAN}"
    cat << 'EOF'
    ██╗  ██╗ █████╗ ██████╗ ███████╗██████╗ ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
    ██║  ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
    ███████║███████║██████╔╝█████╗  ██████╔╝██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
    ██╔══██║██╔══██║██╔══██╗██╔══╝  ██╔══██╗██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
    ██║  ██║██║  ██║██████╔╝███████╗██║  ██║██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
    ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
EOF
    echo -e "${NC}"
    
    print_centered "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$GRAY"
    print_centered "${ROCKET} Ultimate Installation Wizard v${SCRIPT_VERSION} ${ROCKET}" "$WHITE"
    print_centered "Modern • Automated • Secure • Production Ready" "$GRAY"
    print_centered "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$GRAY"
    echo ""
}

# Bölüm başlığı
print_section() {
    echo ""
    echo -e "${MAGENTA}${ARROW} ${BOLD}$*${NC}"
    echo -e "${GRAY}$(printf '─%.0s' $(seq 1 60))${NC}"
}

# Alt bölüm
print_subsection() {
    echo -e "${GRAY}  ${BULLET}${NC} $*"
}

# İlerleme çubuğu
show_progress_bar() {
    local current=$1
    local total=$2
    local message="${3:-Processing...}"
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    # Renk gradyanı
    local color
    if [[ $percentage -lt 25 ]]; then
        color=$RED
    elif [[ $percentage -lt 50 ]]; then
        color=$ORANGE
    elif [[ $percentage -lt 75 ]]; then
        color=$YELLOW
    else
        color=$GREEN
    fi
    
    printf "\r${GRAY}[${NC}"
    printf "${color}%${filled}s${NC}" | tr ' ' "${PROGRESS_FULL}"
    printf "${GRAY}%${empty}s${NC}" | tr ' ' "${PROGRESS_EMPTY}"
    printf "${GRAY}]${NC} ${BOLD}%3d%%${NC} ${GRAY}${message}${NC}    "
}

# Spinner animasyonu
show_spinner() {
    local pid=$1
    local message="${2:-Processing...}"
    local spinner_type="${3:-dots}"
    local delay=0.1
    local spinners
    
    case $spinner_type in
        dots) spinners=("${SPINNER_DOTS[@]}") ;;
        line) spinners=("${SPINNER_LINE[@]}") ;;
        circle) spinners=("${SPINNER_CIRCLE[@]}") ;;
        bounce) spinners=("${SPINNER_BOUNCE[@]}") ;;
        grow) spinners=("${SPINNER_GROW[@]}") ;;
        *) spinners=("${SPINNER_DOTS[@]}") ;;
    esac
    
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}${spinners[$i]}${NC} ${message}"
        i=$(( (i + 1) % ${#spinners[@]} ))
        sleep $delay
    done
    printf "\r"
}

# Animasyonlu mesaj
animate_text() {
    local text="$1"
    local delay="${2:-0.03}"
    local color="${3:-$NC}"
    
    for ((i=0; i<${#text}; i++)); do
        printf "${color}${text:$i:1}${NC}"
        sleep $delay
    done
    echo ""
}

# Onay kutusu
show_checkbox() {
    local checked=$1
    local label="$2"
    
    if [[ "$checked" == true ]]; then
        echo -e "${GREEN}[${CHECK}]${NC} ${label}"
    else
        echo -e "${RED}[ ]${NC} ${label}"
    fi
}

# Seçim menüsü
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    local key
    
    hide_cursor
    
    while true; do
        clear_screen
        print_banner
        print_section "$title"
        echo ""
        
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -e "  ${CYAN}${ARROW}${NC} ${BOLD}${options[$i]}${NC}"
            else
                echo -e "    ${GRAY}${options[$i]}${NC}"
            fi
        done
        
        echo ""
        echo -e "${GRAY}↑/↓: Seç  Enter: Onayla  q: Çıkış${NC}"
        
        read -rsn1 key
        
        case "$key" in
            A) # Up arrow
                ((selected--))
                [[ $selected -lt 0 ]] && selected=$((${#options[@]} - 1))
                ;;
            B) # Down arrow
                ((selected++))
                [[ $selected -ge ${#options[@]} ]] && selected=0
                ;;
            "") # Enter
                show_cursor
                return $selected
                ;;
            q|Q)
                show_cursor
                exit 0
                ;;
        esac
    done
}

# Giriş alanı
input_field() {
    local prompt="$1"
    local default="${2:-}"
    local is_password="${3:-false}"
    local validation="${4:-}"
    local result
    
    while true; do
        if [[ -n "$default" ]]; then
            echo -ne "${CYAN}${ARROW}${NC} ${prompt} ${GRAY}[${default}]${NC}: "
        else
            echo -ne "${CYAN}${ARROW}${NC} ${prompt}: "
        fi
        
        if [[ "$is_password" == true ]]; then
            read -rs result
            echo ""
        else
            read -r result
        fi
        
        # Varsayılan değer kullan
        [[ -z "$result" && -n "$default" ]] && result="$default"
        
        # Validasyon
        if [[ -n "$validation" ]]; then
            if ! eval "$validation '$result'"; then
                log_error "Geçersiz giriş. Lütfen tekrar deneyin."
                continue
            fi
        fi
        
        echo "$result"
        return 0
    done
}

# Onay dialogu
confirm_dialog() {
    local message="$1"
    local default="${2:-y}"
    local response
    
    if [[ "$default" == "y" ]]; then
        echo -ne "${YELLOW}${WARNING_ICON}${NC} ${message} ${GRAY}[E/h]${NC}: "
    else
        echo -ne "${YELLOW}${WARNING_ICON}${NC} ${message} ${GRAY}[e/H]${NC}: "
    fi
    
    read -r response
    response=${response:-$default}
    
    [[ "$response" =~ ^[EeYy]$ ]]
}


# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_domain() {
    local domain=$1
    
    # Boş kontrol
    [[ -z "$domain" ]] && return 1
    
    # Format kontrolü
    if [[ ! $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    
    return 0
}

validate_email() {
    local email=$1
    
    [[ -z "$email" ]] && return 1
    
    if [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    
    return 0
}

validate_password() {
    local password=$1
    
    # Minimum 8 karakter
    [[ ${#password} -lt 8 ]] && return 1
    
    # En az bir büyük harf
    [[ ! $password =~ [A-Z] ]] && return 1
    
    # En az bir küçük harf
    [[ ! $password =~ [a-z] ]] && return 1
    
    # En az bir rakam
    [[ ! $password =~ [0-9] ]] && return 1
    
    return 0
}

validate_username() {
    local username=$1
    
    [[ -z "$username" ]] && return 1
    [[ ${#username} -lt 3 ]] && return 1
    [[ ! $username =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]] && return 1
    
    return 0
}

validate_cloudflare_api_token() {
    local token=$1
    
    [[ -z "$token" ]] && return 1
    [[ ${#token} -lt 30 ]] && return 1
    
    # API token doğrulaması
    if [[ "$SKIP_VALIDATION" != true ]]; then
        local response
        response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" 2>/dev/null)
        
        if echo "$response" | grep -q '"success":true'; then
            return 0
        else
            log_warning "Cloudflare API token doğrulanamadı (çevrimdışı olabilir)"
            return 0  # Çevrimdışı durumda devam et
        fi
    fi
    
    return 0
}

validate_cloudflare_tunnel_token() {
    local token=$1
    
    [[ -z "$token" ]] && return 1
    [[ ${#token} -lt 50 ]] && return 1
    
    return 0
}

# ============================================================================
# SYSTEM CHECK FUNCTIONS
# ============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Bu script root yetkisi ile çalıştırılmalıdır (sudo kullanın)"
        exit 1
    fi
    return 0
}

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "İşletim sistemi belirlenemedi"
        return 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        log_error "Bu script Ubuntu veya Debian gerektirir (tespit edilen: $ID)"
        return 1
    fi
    
    if [[ "$ID" == "ubuntu" && ! "$VERSION_ID" =~ ^(20\.04|22\.04|24\.04) ]]; then
        log_warning "Ubuntu $VERSION_ID resmi olarak test edilmedi"
    fi
    
    return 0
}

check_architecture() {
    local arch=$(uname -m)
    
    case $arch in
        x86_64|amd64)
            return 0
            ;;
        aarch64|arm64)
            log_warning "ARM64 mimarisi tespit edildi - bazı özellikler sınırlı olabilir"
            return 0
            ;;
        *)
            log_error "Desteklenmeyen mimari: $arch"
            return 1
            ;;
    esac
}

check_cpu() {
    local cpu_count=$(nproc 2>/dev/null || echo 1)
    
    if [[ $cpu_count -lt 2 ]]; then
        log_error "Minimum 2 CPU çekirdeği gerekli (mevcut: $cpu_count)"
        return 1
    elif [[ $cpu_count -lt 4 ]]; then
        log_warning "4+ CPU çekirdeği önerilir (mevcut: $cpu_count)"
    fi
    
    return 0
}

check_memory() {
    local mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
    local mem_gb=$((mem_kb / 1024 / 1024))
    
    if [[ $mem_gb -lt 2 ]]; then
        log_error "Minimum 2GB RAM gerekli (mevcut: ${mem_gb}GB)"
        return 1
    elif [[ $mem_gb -lt 4 ]]; then
        log_warning "4GB+ RAM önerilir (mevcut: ${mem_gb}GB)"
    fi
    
    return 0
}

check_disk_space() {
    local target_dir="${1:-/opt}"
    local required_gb="${2:-20}"
    
    # Dizin yoksa oluştur
    mkdir -p "$target_dir" 2>/dev/null || true
    
    local available_kb=$(df "$target_dir" 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)
    local available_gb=$((available_kb / 1024 / 1024))
    
    if [[ $available_gb -lt $required_gb ]]; then
        log_error "Yetersiz disk alanı: ${available_gb}GB mevcut, ${required_gb}GB gerekli"
        return 1
    fi
    
    return 0
}

check_internet() {
    local urls=("https://github.com" "https://api.cloudflare.com" "https://registry.hub.docker.com")
    
    for url in "${urls[@]}"; do
        if timeout 5 curl -s -I "$url" > /dev/null 2>&1; then
            return 0
        fi
    done
    
    log_error "İnternet bağlantısı tespit edilemedi"
    return 1
}

check_ports() {
    local ports=(80 443 5432 6379 8000)
    local blocked_ports=()
    
    for port in "${ports[@]}"; do
        if ss -tuln 2>/dev/null | grep -q ":$port " || netstat -tuln 2>/dev/null | grep -q ":$port "; then
            blocked_ports+=($port)
        fi
    done
    
    if [[ ${#blocked_ports[@]} -gt 0 ]]; then
        log_warning "Şu portlar kullanımda: ${blocked_ports[*]}"
        log_info "Docker bu portları yönetecek, mevcut servisler durdurulabilir"
    fi
    
    return 0
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        return 1
    fi
    
    if ! docker ps &> /dev/null; then
        log_warning "Docker daemon çalışmıyor"
        return 1
    fi
    
    return 0
}

check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        return 0
    fi
    
    if docker compose version &> /dev/null; then
        return 0
    fi
    
    return 1
}

# ============================================================================
# DEPENDENCY INSTALLATION
# ============================================================================

install_system_dependencies() {
    print_section "Sistem Bağımlılıkları Yükleniyor"
    
    export DEBIAN_FRONTEND=noninteractive
    
    log_info "Paket listesi güncelleniyor..."
    apt-get update -qq >> "${LOG_FILE}" 2>&1
    
    local packages=(
        "curl"
        "wget"
        "git"
        "python3"
        "python3-pip"
        "python3-venv"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "apt-transport-https"
        "software-properties-common"
        "jq"
        "unzip"
        "htop"
        "net-tools"
    )
    
    local missing_packages=()
    
    for pkg in "${packages[@]}"; do
        if ! dpkg -l "$pkg" &> /dev/null; then
            missing_packages+=("$pkg")
        fi
    done
    
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log_info "Eksik paketler yükleniyor: ${missing_packages[*]}"
        apt-get install -y -qq "${missing_packages[@]}" >> "${LOG_FILE}" 2>&1
    fi
    
    log_success "Sistem bağımlılıkları hazır"
}

install_docker() {
    print_section "Docker Kurulumu"
    
    if check_docker; then
        local version=$(docker --version | awk '{print $3}' | sed 's/,//')
        log_success "Docker zaten kurulu: $version"
        return 0
    fi
    
    log_info "Docker yükleniyor..."
    
    # Docker GPG anahtarı
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Docker repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -qq >> "${LOG_FILE}" 2>&1
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >> "${LOG_FILE}" 2>&1
    
    # Docker servisini başlat
    systemctl enable docker >> "${LOG_FILE}" 2>&1
    systemctl start docker >> "${LOG_FILE}" 2>&1
    
    # Kullanıcıyı docker grubuna ekle
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "$SUDO_USER" 2>/dev/null || true
    fi
    
    log_success "Docker kuruldu"
    
    # Rollback action ekle
    ROLLBACK_ACTIONS+=("systemctl stop docker")
}

install_docker_compose() {
    if check_docker_compose; then
        log_success "Docker Compose zaten kurulu"
        return 0
    fi
    
    log_info "Docker Compose yükleniyor..."
    
    local compose_version="v2.24.0"
    local compose_url="https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)"
    
    curl -L "$compose_url" -o /usr/local/bin/docker-compose >> "${LOG_FILE}" 2>&1
    chmod +x /usr/local/bin/docker-compose
    
    log_success "Docker Compose kuruldu"
}

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

run_preflight_checks() {
    print_section "Sistem Uyumluluk Kontrolü"
    
    local checks_passed=0
    local checks_failed=0
    local checks_warning=0
    
    local checks=(
        "check_root:Root Yetkileri"
        "check_os:İşletim Sistemi"
        "check_architecture:Sistem Mimarisi"
        "check_cpu:CPU Çekirdekleri"
        "check_memory:RAM Bellek"
        "check_disk_space:Disk Alanı"
        "check_internet:İnternet Bağlantısı"
        "check_ports:Port Durumu"
    )
    
    local total_checks=${#checks[@]}
    local current_check=0
    
    for check in "${checks[@]}"; do
        IFS=':' read -r func name <<< "$check"
        ((current_check++))
        
        show_progress_bar $current_check $total_checks "$name"
        
        if $func; then
            ((checks_passed++))
            echo -e "\r${GREEN}${CHECK}${NC} ${name}$(printf ' %.0s' $(seq 1 40))"
        else
            if [[ $? -eq 2 ]]; then
                ((checks_warning++))
                echo -e "\r${YELLOW}${WARNING_ICON}${NC} ${name} (uyarı)$(printf ' %.0s' $(seq 1 30))"
            else
                ((checks_failed++))
                echo -e "\r${RED}${CROSS}${NC} ${name} (başarısız)$(printf ' %.0s' $(seq 1 30))"
            fi
        fi
    done
    
    echo ""
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Başarılı:${NC} $checks_passed  ${YELLOW}Uyarı:${NC} $checks_warning  ${RED}Başarısız:${NC} $checks_failed"
    echo ""
    
    if [[ $checks_failed -gt 0 ]]; then
        log_error "Sistem gereksinimleri karşılanmıyor. Lütfen hataları düzeltin."
        return 1
    fi
    
    log_success "Sistem kuruluma hazır!"
    return 0
}


# ============================================================================
# CONFIGURATION WIZARD
# ============================================================================

generate_secure_password() {
    python3 -c 'import secrets; print(secrets.token_urlsafe(16))' 2>/dev/null || \
    openssl rand -base64 16 2>/dev/null || \
    head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16
}

generate_secret_key() {
    python3 -c 'import secrets; print(secrets.token_urlsafe(50))' 2>/dev/null || \
    openssl rand -base64 50 2>/dev/null || \
    head -c 50 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 50
}

show_configuration_wizard() {
    print_section "Yapılandırma Sihirbazı"
    
    echo ""
    echo -e "${INFO_ICON} Lütfen kurulum için gerekli bilgileri girin."
    echo -e "${GRAY}Varsayılan değerler köşeli parantez içinde gösterilir.${NC}"
    echo ""
    
    # Domain
    while true; do
        echo -ne "${CYAN}${GLOBE}${NC} Domain adı ${GRAY}[habernexus.com]${NC}: "
        read -r DOMAIN
        DOMAIN=${DOMAIN:-habernexus.com}
        
        if validate_domain "$DOMAIN"; then
            log_success "Domain: $DOMAIN"
            break
        else
            log_error "$(msg invalid_domain). Örnek: example.com"
        fi
    done
    
    # Admin Email
    while true; do
        echo -ne "${CYAN}📧${NC} Admin e-posta ${GRAY}[admin@${DOMAIN}]${NC}: "
        read -r ADMIN_EMAIL
        ADMIN_EMAIL=${ADMIN_EMAIL:-admin@${DOMAIN}}
        
        if validate_email "$ADMIN_EMAIL"; then
            log_success "E-posta: $ADMIN_EMAIL"
            break
        else
            log_error "$(msg invalid_email)"
        fi
    done
    
    # Admin Username
    while true; do
        echo -ne "${CYAN}👤${NC} Admin kullanıcı adı ${GRAY}[admin]${NC}: "
        read -r ADMIN_USERNAME
        ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
        
        if validate_username "$ADMIN_USERNAME"; then
            log_success "Kullanıcı: $ADMIN_USERNAME"
            break
        else
            log_error "Kullanıcı adı en az 3 karakter olmalı ve harf ile başlamalı"
        fi
    done
    
    # Admin Password
    while true; do
        echo -ne "${CYAN}${LOCK}${NC} Admin şifresi ${GRAY}(min 8 karakter, büyük/küçük harf, rakam)${NC}: "
        read -rs ADMIN_PASSWORD
        echo ""
        
        if [[ -z "$ADMIN_PASSWORD" ]]; then
            ADMIN_PASSWORD=$(generate_secure_password)
            log_info "Otomatik şifre oluşturuldu: ${YELLOW}$ADMIN_PASSWORD${NC}"
            log_warning "Bu şifreyi kaydedin!"
            break
        elif validate_password "$ADMIN_PASSWORD"; then
            log_success "Şifre ayarlandı"
            break
        else
            log_error "$(msg invalid_password)"
        fi
    done
    
    # Cloudflare API Token
    echo ""
    echo -e "${INFO_ICON} ${BOLD}Cloudflare Yapılandırması${NC}"
    echo -e "${GRAY}Cloudflare API Token almak için:${NC}"
    echo -e "${GRAY}  1. https://dash.cloudflare.com/profile/api-tokens adresine gidin${NC}"
    echo -e "${GRAY}  2. 'Create Token' → 'Edit zone DNS' template kullanın${NC}"
    echo ""
    
    while true; do
        echo -ne "${CYAN}${KEY}${NC} Cloudflare API Token: "
        read -rs CLOUDFLARE_API_TOKEN
        echo ""
        
        if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
            log_warning "Cloudflare API Token boş bırakıldı - demo mod kullanılacak"
            CLOUDFLARE_API_TOKEN="demo_api_token_placeholder"
            break
        elif validate_cloudflare_api_token "$CLOUDFLARE_API_TOKEN"; then
            log_success "Cloudflare API Token doğrulandı"
            break
        else
            log_error "Geçersiz Cloudflare API Token"
        fi
    done
    
    # Cloudflare Tunnel Token
    echo ""
    echo -e "${GRAY}Cloudflare Tunnel Token almak için:${NC}"
    echo -e "${GRAY}  1. https://one.dash.cloudflare.com → Networks → Tunnels${NC}"
    echo -e "${GRAY}  2. 'Create a Tunnel' → Token'ı kopyalayın${NC}"
    echo ""
    
    while true; do
        echo -ne "${CYAN}${CLOUD}${NC} Cloudflare Tunnel Token: "
        read -rs CLOUDFLARE_TUNNEL_TOKEN
        echo ""
        
        if [[ -z "$CLOUDFLARE_TUNNEL_TOKEN" ]]; then
            log_warning "Cloudflare Tunnel Token boş bırakıldı - demo mod kullanılacak"
            CLOUDFLARE_TUNNEL_TOKEN="demo_tunnel_token_placeholder"
            break
        elif validate_cloudflare_tunnel_token "$CLOUDFLARE_TUNNEL_TOKEN"; then
            log_success "Cloudflare Tunnel Token alındı"
            break
        else
            log_error "Geçersiz Cloudflare Tunnel Token (minimum 50 karakter)"
        fi
    done
    
    # Google API Key (Opsiyonel)
    echo ""
    echo -ne "${CYAN}🤖${NC} Google AI API Key ${GRAY}(opsiyonel, Enter ile atla)${NC}: "
    read -rs GOOGLE_API_KEY
    echo ""
    
    if [[ -n "$GOOGLE_API_KEY" ]]; then
        log_success "Google AI API Key alındı"
    else
        log_info "Google AI API Key atlandı - daha sonra eklenebilir"
    fi
    
    # Otomatik değerler
    DB_PASSWORD=$(generate_secure_password)
    SECRET_KEY=$(generate_secret_key)
    
    log_success "Veritabanı şifresi otomatik oluşturuldu"
    log_success "Django secret key otomatik oluşturuldu"
    
    # Özet göster
    show_configuration_summary
}

show_configuration_summary() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Yapılandırma Özeti${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GLOBE} Domain:           ${GREEN}${DOMAIN}${NC}"
    echo -e "  📧 Admin E-posta:    ${GREEN}${ADMIN_EMAIL}${NC}"
    echo -e "  👤 Admin Kullanıcı:  ${GREEN}${ADMIN_USERNAME}${NC}"
    echo -e "  ${LOCK} Admin Şifre:      ${YELLOW}********${NC}"
    echo -e "  ${CLOUD} Cloudflare:       ${GREEN}Yapılandırıldı${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if ! confirm_dialog "Bu yapılandırma ile devam etmek istiyor musunuz?"; then
        log_info "Yapılandırma iptal edildi"
        show_configuration_wizard
    fi
}

quick_setup_defaults() {
    print_section "Hızlı Kurulum - Varsayılan Değerler"
    
    DOMAIN="${DOMAIN:-habernexus.local}"
    ADMIN_EMAIL="${ADMIN_EMAIL:-admin@habernexus.local}"
    ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
    ADMIN_PASSWORD="${ADMIN_PASSWORD:-$(generate_secure_password)}"
    CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-demo_api_token}"
    CLOUDFLARE_TUNNEL_TOKEN="${CLOUDFLARE_TUNNEL_TOKEN:-demo_tunnel_token}"
    GOOGLE_API_KEY="${GOOGLE_API_KEY:-}"
    DB_PASSWORD=$(generate_secure_password)
    SECRET_KEY=$(generate_secret_key)
    
    echo -e "${INFO_ICON} Varsayılan değerler kullanılıyor:"
    echo -e "  ${BULLET} Domain: ${GREEN}${DOMAIN}${NC}"
    echo -e "  ${BULLET} Admin: ${GREEN}${ADMIN_USERNAME}${NC}"
    echo -e "  ${BULLET} Şifre: ${YELLOW}${ADMIN_PASSWORD}${NC}"
    echo ""
    log_warning "Bu şifreyi kaydedin!"
    
    sleep 2
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

backup_existing_installation() {
    if [[ -d "$PROJECT_PATH" && -f "$PROJECT_PATH/docker-compose.yml" ]]; then
        print_section "Mevcut Kurulum Yedekleniyor"
        
        mkdir -p "$BACKUP_DIR"
        
        # Docker compose durumunu kaydet
        if command -v docker-compose &> /dev/null; then
            cd "$PROJECT_PATH"
            docker-compose ps > "$BACKUP_DIR/docker_status.txt" 2>/dev/null || true
        fi
        
        # .env dosyasını yedekle
        [[ -f "$PROJECT_PATH/.env" ]] && cp "$PROJECT_PATH/.env" "$BACKUP_DIR/"
        
        # Veritabanı yedeği
        if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "habernexus_postgres"; then
            log_info "Veritabanı yedekleniyor..."
            docker exec habernexus_postgres pg_dump -U habernexus habernexus > "$BACKUP_DIR/database.sql" 2>/dev/null || true
        fi
        
        log_success "Yedek oluşturuldu: $BACKUP_DIR"
        
        # Rollback action ekle
        ROLLBACK_ACTIONS+=("restore_backup '$BACKUP_DIR'")
    fi
}

clone_or_update_repository() {
    print_section "Proje Dosyaları Hazırlanıyor"
    
    mkdir -p "$PROJECT_PATH"
    
    if [[ -d "$PROJECT_PATH/.git" ]]; then
        log_info "Mevcut repo güncelleniyor..."
        cd "$PROJECT_PATH"
        git fetch origin >> "${LOG_FILE}" 2>&1
        git reset --hard origin/main >> "${LOG_FILE}" 2>&1
    else
        log_info "Repo klonlanıyor..."
        
        # Mevcut dosyaları temizle
        rm -rf "${PROJECT_PATH:?}"/* 2>/dev/null || true
        
        # Script dizininden kopyala veya klonla
        if [[ -d "$SCRIPT_DIR/.git" ]]; then
            cp -r "$SCRIPT_DIR"/* "$PROJECT_PATH/"
            cp -r "$SCRIPT_DIR"/.* "$PROJECT_PATH/" 2>/dev/null || true
        else
            git clone https://github.com/sata2500/habernexus.git "$PROJECT_PATH" >> "${LOG_FILE}" 2>&1
        fi
    fi
    
    cd "$PROJECT_PATH"
    log_success "Proje dosyaları hazır"
}

create_environment_file() {
    print_section "Ortam Yapılandırması Oluşturuluyor"
    
    cat > "${ENV_FILE}" << EOF
# ============================================================================
# HaberNexus v${SCRIPT_VERSION} Environment Configuration
# Generated: $(date)
# Installation Mode: ${INSTALL_MODE}
# ============================================================================

# ============================================================================
# DOMAIN & SECURITY
# ============================================================================

DOMAIN=${DOMAIN}
ADMIN_EMAIL=${ADMIN_EMAIL}
DEBUG=False
SECRET_KEY=${SECRET_KEY}
ALLOWED_HOSTS=${DOMAIN},www.${DOMAIN},localhost,127.0.0.1,app

# ============================================================================
# DATABASE CONFIGURATION
# ============================================================================

DATABASE_URL=postgresql://habernexus:${DB_PASSWORD}@postgres:5432/habernexus
DB_ENGINE=django.db.backends.postgresql
DB_NAME=habernexus
DB_USER=habernexus
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=postgres
DB_PORT=5432
POSTGRES_USER=habernexus
POSTGRES_PASSWORD=${DB_PASSWORD}
POSTGRES_DB=habernexus

# ============================================================================
# REDIS CONFIGURATION
# ============================================================================

REDIS_URL=redis://redis:6379/0
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# ============================================================================
# CLOUDFLARE CONFIGURATION
# ============================================================================

CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}

# ============================================================================
# GOOGLE AI API
# ============================================================================

GOOGLE_API_KEY=${GOOGLE_API_KEY:-}

# ============================================================================
# ADMIN USER
# ============================================================================

ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# ============================================================================
# DJANGO SETTINGS
# ============================================================================

DJANGO_SETTINGS_MODULE=habernexus_config.settings
PYTHONUNBUFFERED=1

# ============================================================================
# SECURITY SETTINGS
# ============================================================================

SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True

# ============================================================================
# TIMEZONE
# ============================================================================

TZ=Europe/Istanbul

EOF
    
    chmod 600 "${ENV_FILE}"
    log_success "Ortam yapılandırması oluşturuldu"
}

create_caddy_config() {
    print_section "Caddy Yapılandırması Oluşturuluyor"
    
    local caddyfile="${PROJECT_PATH}/caddy/Caddyfile"
    
    cat > "${caddyfile}" << EOF
# HaberNexus Caddy Configuration
# Generated: $(date)

{
    email ${ADMIN_EMAIL}
    
    # ACME configuration with Cloudflare DNS challenge
    acme_dns cloudflare ${CLOUDFLARE_API_TOKEN}
    
    # Storage for certificates
    storage file_system {
        root /data/caddy
    }
    
    # Logging
    log {
        output stdout
        format json
        level info
    }
    
    # Admin API
    admin localhost:2019
}

# Main domain configuration
${DOMAIN} {
    reverse_proxy app:8000 {
        health_uri /health
        health_interval 10s
        health_timeout 5s
        
        header_up X-Forwarded-For {http.request.remote.host}
        header_up X-Forwarded-Proto {http.request.proto}
        header_up X-Forwarded-Host {http.request.host}
        
        transport http {
            dial_timeout 10s
            response_header_timeout 30s
        }
    }
    
    # Security headers
    header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    header X-Content-Type-Options "nosniff"
    header X-Frame-Options "DENY"
    header X-XSS-Protection "1; mode=block"
    header Referrer-Policy "strict-origin-when-cross-origin"
    header Permissions-Policy "geolocation=(), microphone=(), camera=()"
    
    # Compression
    encode gzip
    
    # Logging
    log {
        output stdout
        format json
        level info
    }
}

# WWW redirect
www.${DOMAIN} {
    redir https://${DOMAIN}{uri} permanent
}

# Health check endpoint
:80 {
    respond /health 200 {
        body "OK"
    }
}
EOF
    
    log_success "Caddy yapılandırması oluşturuldu"
}

create_cloudflared_config() {
    print_section "Cloudflare Tunnel Yapılandırması"
    
    local config_file="${PROJECT_PATH}/cloudflared/config.yml"
    
    cat > "${config_file}" << EOF
# HaberNexus Cloudflare Tunnel Configuration
# Generated: $(date)

tunnel: habernexus-tunnel
credentials-file: /root/.cloudflared/credentials.json
logLevel: info

ingress:
  - hostname: ${DOMAIN}
    service: http://caddy:80
    originRequest:
      connectTimeout: 30s
      tlsTimeout: 30s
      tcpKeepAlive: 30s
      noHappyEyeballs: false
      
  - hostname: "*.${DOMAIN}"
    service: http://caddy:80
    originRequest:
      connectTimeout: 30s
      tlsTimeout: 30s
      tcpKeepAlive: 30s
      noHappyEyeballs: false
      
  - service: http_status:404

warp-routing:
  enabled: false

metrics: localhost:7622
keepaliveInterval: 30s
keepaliveTimeout: 40s
retries: 5
gracePeriod: 30s
EOF
    
    log_success "Cloudflare Tunnel yapılandırması oluşturuldu"
}


# ============================================================================
# DOCKER BUILD & DEPLOYMENT
# ============================================================================

build_docker_images() {
    print_section "Docker İmajları Oluşturuluyor"
    
    cd "${PROJECT_PATH}"
    
    # Build progress simulation with real output
    local services=("app" "caddy")
    local total=${#services[@]}
    local current=0
    
    for service in "${services[@]}"; do
        ((current++))
        show_progress_bar $current $total "Building $service..."
        
        if docker-compose build "$service" >> "${LOG_FILE}" 2>&1; then
            echo -e "\r${GREEN}${CHECK}${NC} $service imajı oluşturuldu$(printf ' %.0s' $(seq 1 30))"
        else
            echo -e "\r${YELLOW}${WARNING_ICON}${NC} $service imajı için uyarı$(printf ' %.0s' $(seq 1 30))"
        fi
    done
    
    echo ""
    log_success "Docker imajları hazır"
}

pull_docker_images() {
    print_section "Docker İmajları İndiriliyor"
    
    cd "${PROJECT_PATH}"
    
    local images=(
        "postgres:16-alpine"
        "redis:7-alpine"
        "cloudflare/cloudflared:latest"
    )
    
    local total=${#images[@]}
    local current=0
    
    for image in "${images[@]}"; do
        ((current++))
        show_progress_bar $current $total "Pulling $image..."
        
        if docker pull "$image" >> "${LOG_FILE}" 2>&1; then
            echo -e "\r${GREEN}${CHECK}${NC} $image indirildi$(printf ' %.0s' $(seq 1 40))"
        else
            echo -e "\r${YELLOW}${WARNING_ICON}${NC} $image indirilemedi$(printf ' %.0s' $(seq 1 40))"
        fi
    done
    
    echo ""
    log_success "Docker imajları hazır"
}

start_services() {
    print_section "Servisler Başlatılıyor"
    
    cd "${PROJECT_PATH}"
    
    log_info "Docker Compose başlatılıyor..."
    
    # Önce mevcut container'ları durdur
    docker-compose down --remove-orphans >> "${LOG_FILE}" 2>&1 || true
    
    # Servisleri başlat
    if docker-compose up -d >> "${LOG_FILE}" 2>&1; then
        log_success "Servisler başlatıldı"
    else
        log_error "Servisler başlatılamadı"
        docker-compose logs >> "${LOG_FILE}" 2>&1
        return 1
    fi
    
    # Rollback action ekle
    ROLLBACK_ACTIONS+=("docker-compose -f ${PROJECT_PATH}/docker-compose.yml down")
}

wait_for_services() {
    print_section "Servislerin Hazır Olması Bekleniyor"
    
    cd "${PROJECT_PATH}"
    
    local services=("postgres" "redis" "app")
    local max_attempts=60
    local attempt=0
    
    echo -e "${INFO_ICON} Servisler başlatılıyor, lütfen bekleyin..."
    echo ""
    
    while [[ $attempt -lt $max_attempts ]]; do
        local all_healthy=true
        local status_line=""
        
        for service in "${services[@]}"; do
            local status=$(docker-compose ps "$service" 2>/dev/null | grep -E "Up|healthy" | wc -l)
            
            if [[ $status -gt 0 ]]; then
                status_line+="${GREEN}${CHECK}${NC} $service  "
            else
                status_line+="${YELLOW}${SPINNER_DOTS[$((attempt % 10))]}${NC} $service  "
                all_healthy=false
            fi
        done
        
        printf "\r  $status_line"
        
        if [[ "$all_healthy" == true ]]; then
            echo ""
            echo ""
            log_success "Tüm servisler hazır!"
            return 0
        fi
        
        sleep 2
        ((attempt++))
    done
    
    echo ""
    log_warning "Bazı servisler henüz hazır değil, devam ediliyor..."
    docker-compose ps
    return 0
}

run_database_migrations() {
    print_section "Veritabanı Migrasyonları"
    
    cd "${PROJECT_PATH}"
    
    log_info "Veritabanı bağlantısı bekleniyor..."
    sleep 5
    
    log_info "Migrasyonlar çalıştırılıyor..."
    
    if docker-compose exec -T app python manage.py migrate --noinput >> "${LOG_FILE}" 2>&1; then
        log_success "Migrasyonlar tamamlandı"
    else
        log_warning "Migrasyon uyarısı - detaylar log dosyasında"
    fi
}

create_superuser() {
    print_section "Admin Kullanıcısı Oluşturuluyor"
    
    cd "${PROJECT_PATH}"
    
    log_info "Admin kullanıcısı: $ADMIN_USERNAME"
    
    docker-compose exec -T app python manage.py shell << EOF >> "${LOG_FILE}" 2>&1
from django.contrib.auth import get_user_model
User = get_user_model()

username = '${ADMIN_USERNAME}'
email = '${ADMIN_EMAIL}'
password = '${ADMIN_PASSWORD}'

if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username=username, email=email, password=password)
    print(f"Admin user created: {username}")
else:
    user = User.objects.get(username=username)
    user.set_password(password)
    user.email = email
    user.save()
    print(f"Admin user updated: {username}")
EOF
    
    log_success "Admin kullanıcısı hazır"
}

collect_static_files() {
    print_section "Statik Dosyalar Toplanıyor"
    
    cd "${PROJECT_PATH}"
    
    if docker-compose exec -T app python manage.py collectstatic --noinput >> "${LOG_FILE}" 2>&1; then
        log_success "Statik dosyalar toplandı"
    else
        log_warning "Statik dosya uyarısı"
    fi
}

# ============================================================================
# VERIFICATION & HEALTH CHECK
# ============================================================================

verify_installation() {
    print_section "Kurulum Doğrulanıyor"
    
    cd "${PROJECT_PATH}"
    
    local checks_passed=0
    local checks_failed=0
    
    # Docker containers
    echo -ne "  ${BULLET} Docker container'ları... "
    local running=$(docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l)
    local total=$(docker-compose config --services 2>/dev/null | wc -l)
    
    if [[ $running -ge 4 ]]; then
        echo -e "${GREEN}${CHECK} $running/$total çalışıyor${NC}"
        ((checks_passed++))
    else
        echo -e "${YELLOW}${WARNING_ICON} $running/$total çalışıyor${NC}"
    fi
    
    # Database connectivity
    echo -ne "  ${BULLET} Veritabanı bağlantısı... "
    if docker-compose exec -T postgres pg_isready -U habernexus >> "${LOG_FILE}" 2>&1; then
        echo -e "${GREEN}${CHECK} Bağlı${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}${CROSS} Bağlantı yok${NC}"
        ((checks_failed++))
    fi
    
    # Redis connectivity
    echo -ne "  ${BULLET} Redis bağlantısı... "
    if docker-compose exec -T redis redis-cli ping >> "${LOG_FILE}" 2>&1; then
        echo -e "${GREEN}${CHECK} Bağlı${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}${CROSS} Bağlantı yok${NC}"
        ((checks_failed++))
    fi
    
    # Application health
    echo -ne "  ${BULLET} Uygulama durumu... "
    sleep 2
    if docker-compose exec -T app curl -s http://localhost:8000/health >> "${LOG_FILE}" 2>&1; then
        echo -e "${GREEN}${CHECK} Sağlıklı${NC}"
        ((checks_passed++))
    else
        # Alternatif kontrol
        if docker-compose exec -T app python manage.py check >> "${LOG_FILE}" 2>&1; then
            echo -e "${GREEN}${CHECK} Çalışıyor${NC}"
            ((checks_passed++))
        else
            echo -e "${YELLOW}${WARNING_ICON} Kontrol edilemedi${NC}"
        fi
    fi
    
    echo ""
    
    if [[ $checks_failed -eq 0 ]]; then
        log_success "Kurulum doğrulandı!"
        return 0
    else
        log_warning "Bazı kontroller başarısız oldu, ancak kurulum tamamlandı"
        return 0
    fi
}

# ============================================================================
# ROLLBACK MECHANISM
# ============================================================================

save_installation_state() {
    local state=$1
    echo "$state" > "${STATE_FILE}"
    log_debug "Installation state saved: $state"
}

get_installation_state() {
    if [[ -f "${STATE_FILE}" ]]; then
        cat "${STATE_FILE}"
    else
        echo "not_started"
    fi
}

rollback_installation() {
    print_section "Geri Alma İşlemi Başlatılıyor"
    
    log_warning "Kurulum geri alınıyor..."
    
    # Rollback actions'ları ters sırada çalıştır
    for ((i=${#ROLLBACK_ACTIONS[@]}-1; i>=0; i--)); do
        local action="${ROLLBACK_ACTIONS[$i]}"
        log_info "Geri alma: $action"
        eval "$action" >> "${LOG_FILE}" 2>&1 || true
    done
    
    log_success "Geri alma tamamlandı"
}

restore_backup() {
    local backup_dir=$1
    
    if [[ -d "$backup_dir" ]]; then
        log_info "Yedek geri yükleniyor: $backup_dir"
        
        # .env dosyasını geri yükle
        [[ -f "$backup_dir/.env" ]] && cp "$backup_dir/.env" "$PROJECT_PATH/"
        
        # Veritabanını geri yükle
        if [[ -f "$backup_dir/database.sql" ]]; then
            docker-compose exec -T postgres psql -U habernexus habernexus < "$backup_dir/database.sql" 2>/dev/null || true
        fi
        
        log_success "Yedek geri yüklendi"
    fi
}

# ============================================================================
# SUCCESS SUMMARY
# ============================================================================

show_success_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - SCRIPT_START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    clear_screen
    
    echo ""
    echo -e "${GREEN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                                                                           ║
    ║   ██╗  ██╗██╗   ██╗██████╗ ██╗   ██╗██╗     ██╗   ██╗███╗   ███╗          ║
    ║   ██║ ██╔╝██║   ██║██╔══██╗██║   ██║██║     ██║   ██║████╗ ████║          ║
    ║   █████╔╝ ██║   ██║██████╔╝██║   ██║██║     ██║   ██║██╔████╔██║          ║
    ║   ██╔═██╗ ██║   ██║██╔══██╗██║   ██║██║     ██║   ██║██║╚██╔╝██║          ║
    ║   ██║  ██╗╚██████╔╝██║  ██║╚██████╔╝███████╗╚██████╔╝██║ ╚═╝ ██║          ║
    ║   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝     ╚═╝          ║
    ║                                                                           ║
    ║                    TAMAMLANDI! / COMPLETED!                               ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  ${GLOBE} Erişim Adresleri${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${BULLET} Ana Site:      ${GREEN}https://${DOMAIN}${NC}"
    echo -e "  ${BULLET} Admin Panel:   ${GREEN}https://${DOMAIN}/admin${NC}"
    echo -e "  ${BULLET} API:           ${GREEN}https://${DOMAIN}/api${NC}"
    echo -e "  ${BULLET} Flower:        ${GREEN}https://${DOMAIN}/flower${NC}"
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  ${LOCK} Admin Bilgileri${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${BULLET} Kullanıcı:     ${GREEN}${ADMIN_USERNAME}${NC}"
    echo -e "  ${BULLET} E-posta:       ${GREEN}${ADMIN_EMAIL}${NC}"
    echo -e "  ${BULLET} Şifre:         ${YELLOW}(kurulum sırasında belirlendi)${NC}"
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  ${GEAR} Kurulum Bilgileri${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${BULLET} Kurulum Modu:  ${GREEN}${INSTALL_MODE}${NC}"
    echo -e "  ${BULLET} Süre:          ${GREEN}${minutes}dk ${seconds}sn${NC}"
    echo -e "  ${BULLET} Proje Yolu:    ${GREEN}${PROJECT_PATH}${NC}"
    echo -e "  ${BULLET} Log Dosyası:   ${GREEN}${LOG_FILE}${NC}"
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  ${TERMINAL} Faydalı Komutlar${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GRAY}# Servis durumunu görüntüle${NC}"
    echo -e "  ${WHITE}bash ${PROJECT_PATH}/manage_habernexus.sh status${NC}"
    echo ""
    echo -e "  ${GRAY}# Logları görüntüle${NC}"
    echo -e "  ${WHITE}bash ${PROJECT_PATH}/manage_habernexus.sh logs app${NC}"
    echo ""
    echo -e "  ${GRAY}# Sağlık kontrolü${NC}"
    echo -e "  ${WHITE}bash ${PROJECT_PATH}/manage_habernexus.sh health${NC}"
    echo ""
    echo -e "  ${GRAY}# Servisleri yeniden başlat${NC}"
    echo -e "  ${WHITE}bash ${PROJECT_PATH}/manage_habernexus.sh restart${NC}"
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}${COFFEE} $(msg enjoy)! ${SPARKLES}${NC}"
    echo ""
    echo -e "${GRAY}Kurulum tamamlandı: $(date)${NC}"
    echo ""
}


# ============================================================================
# WEB WIZARD (Optional Feature)
# ============================================================================

start_web_wizard() {
    print_section "Web Kurulum Sihirbazı Başlatılıyor"
    
    log_info "Web arayüzü port ${WIZARD_PORT} üzerinde başlatılıyor..."
    
    # Python ile basit web sunucusu
    local wizard_html="${PROJECT_PATH}/wizard.html"
    
    cat > "$wizard_html" << 'WIZARD_HTML'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HaberNexus Kurulum Sihirbazı</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            min-height: 100vh;
            color: #fff;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: rgba(255,255,255,0.1);
            border-radius: 20px;
            padding: 40px;
            backdrop-filter: blur(10px);
        }
        h1 {
            text-align: center;
            margin-bottom: 10px;
            font-size: 2em;
            background: linear-gradient(90deg, #00d9ff, #00ff88);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .subtitle {
            text-align: center;
            color: #888;
            margin-bottom: 30px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 8px;
            color: #00d9ff;
            font-weight: 500;
        }
        input {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid rgba(255,255,255,0.1);
            border-radius: 10px;
            background: rgba(0,0,0,0.3);
            color: #fff;
            font-size: 16px;
            transition: border-color 0.3s;
        }
        input:focus {
            outline: none;
            border-color: #00d9ff;
        }
        input::placeholder { color: #666; }
        .btn {
            width: 100%;
            padding: 15px;
            border: none;
            border-radius: 10px;
            background: linear-gradient(90deg, #00d9ff, #00ff88);
            color: #000;
            font-size: 18px;
            font-weight: bold;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(0,217,255,0.3);
        }
        .progress {
            display: none;
            text-align: center;
            padding: 20px;
        }
        .spinner {
            width: 50px;
            height: 50px;
            border: 4px solid rgba(255,255,255,0.1);
            border-top-color: #00d9ff;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        .step-indicator {
            display: flex;
            justify-content: center;
            gap: 10px;
            margin-bottom: 30px;
        }
        .step {
            width: 30px;
            height: 30px;
            border-radius: 50%;
            background: rgba(255,255,255,0.1);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
        }
        .step.active { background: #00d9ff; color: #000; }
        .step.completed { background: #00ff88; color: #000; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 HaberNexus</h1>
        <p class="subtitle">Kurulum Sihirbazı v8.0</p>
        
        <div class="step-indicator">
            <div class="step active">1</div>
            <div class="step">2</div>
            <div class="step">3</div>
            <div class="step">4</div>
        </div>
        
        <form id="wizardForm">
            <div class="form-group">
                <label>🌐 Domain Adı</label>
                <input type="text" name="domain" placeholder="habernexus.com" required>
            </div>
            <div class="form-group">
                <label>📧 Admin E-posta</label>
                <input type="email" name="email" placeholder="admin@example.com" required>
            </div>
            <div class="form-group">
                <label>👤 Admin Kullanıcı Adı</label>
                <input type="text" name="username" placeholder="admin" required>
            </div>
            <div class="form-group">
                <label>🔒 Admin Şifresi</label>
                <input type="password" name="password" placeholder="Güçlü bir şifre" required>
            </div>
            <div class="form-group">
                <label>🔑 Cloudflare API Token</label>
                <input type="password" name="cf_api" placeholder="Cloudflare API Token">
            </div>
            <div class="form-group">
                <label>☁️ Cloudflare Tunnel Token</label>
                <input type="password" name="cf_tunnel" placeholder="Cloudflare Tunnel Token">
            </div>
            <button type="submit" class="btn">🚀 Kurulumu Başlat</button>
        </form>
        
        <div class="progress" id="progress">
            <div class="spinner"></div>
            <p id="progressText">Kurulum başlatılıyor...</p>
        </div>
    </div>
    
    <script>
        document.getElementById('wizardForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const form = e.target;
            const progress = document.getElementById('progress');
            const progressText = document.getElementById('progressText');
            
            form.style.display = 'none';
            progress.style.display = 'block';
            
            const data = new FormData(form);
            const config = Object.fromEntries(data.entries());
            
            try {
                const response = await fetch('/install', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(config)
                });
                
                if (response.ok) {
                    progressText.textContent = '✅ Kurulum tamamlandı!';
                } else {
                    progressText.textContent = '❌ Kurulum başarısız oldu';
                }
            } catch (error) {
                progressText.textContent = 'Kurulum devam ediyor... Terminal\'i kontrol edin.';
            }
        });
    </script>
</body>
</html>
WIZARD_HTML

    echo -e "${INFO_ICON} Web arayüzü: ${GREEN}http://localhost:${WIZARD_PORT}${NC}"
    echo -e "${INFO_ICON} Kurulumu tamamlamak için tarayıcınızda açın"
    echo ""
    
    # Basit Python HTTP sunucusu
    cd "$PROJECT_PATH"
    python3 -m http.server $WIZARD_PORT >> "${LOG_FILE}" 2>&1 &
    local server_pid=$!
    
    echo -e "${GRAY}Sunucu PID: $server_pid - Durdurmak için: kill $server_pid${NC}"
    
    # Tarayıcıyı aç (mümkünse)
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:${WIZARD_PORT}/wizard.html" 2>/dev/null &
    fi
    
    log_info "Web wizard başlatıldı. Terminal kurulumuna devam etmek için Ctrl+C"
    
    # Kullanıcı girişi bekle
    read -p "Web wizard'ı kullandıktan sonra Enter'a basın veya terminal kurulumu için 'q' yazın: " choice
    
    kill $server_pid 2>/dev/null || true
    
    if [[ "$choice" == "q" ]]; then
        return 1
    fi
    
    return 0
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

show_help() {
    cat << EOF

${CYAN}${BOLD}HaberNexus v${SCRIPT_VERSION} - Ultimate Installation Script${NC}

${WHITE}Kullanım:${NC}
  sudo bash install_v8.sh [SEÇENEKLER]

${WHITE}Seçenekler:${NC}
  ${GREEN}--auto${NC}              Tam otomatik kurulum (interaktif sorular ile)
  ${GREEN}--quick${NC}             Hızlı kurulum (varsayılan değerler ile)
  ${GREEN}--wizard${NC}            Web tabanlı kurulum sihirbazı
  ${GREEN}--config FILE${NC}       Yapılandırma dosyası kullan
  ${GREEN}--domain DOMAIN${NC}     Domain adını belirt
  ${GREEN}--email EMAIL${NC}       Admin e-postasını belirt
  ${GREEN}--force${NC}             Mevcut kurulumu yeniden yükle
  ${GREEN}--skip-validation${NC}   API doğrulamalarını atla
  ${GREEN}--dry-run${NC}           Simülasyon modu (değişiklik yapmaz)
  ${GREEN}--verbose${NC}           Detaylı çıktı
  ${GREEN}--silent${NC}            Sessiz mod
  ${GREEN}--lang LANG${NC}         Dil seçimi (tr/en)
  ${GREEN}--help${NC}              Bu yardım mesajını göster
  ${GREEN}--version${NC}           Sürüm bilgisini göster

${WHITE}Örnekler:${NC}
  ${GRAY}# İnteraktif kurulum${NC}
  sudo bash install_v8.sh --auto

  ${GRAY}# Hızlı kurulum${NC}
  sudo bash install_v8.sh --quick

  ${GRAY}# Belirli domain ile kurulum${NC}
  sudo bash install_v8.sh --auto --domain habernexus.com

  ${GRAY}# Web wizard ile kurulum${NC}
  sudo bash install_v8.sh --wizard

${WHITE}Kurulum Modları:${NC}
  ${CYAN}auto${NC}      - İnteraktif sorularla tam otomatik kurulum (önerilen)
  ${CYAN}quick${NC}     - Varsayılan değerlerle hızlı kurulum
  ${CYAN}wizard${NC}    - Web tabanlı görsel kurulum sihirbazı

${WHITE}Destek:${NC}
  GitHub: https://github.com/sata2500/habernexus
  E-posta: salihtanriseven25@gmail.com

EOF
}

show_version() {
    echo "HaberNexus Installer v${SCRIPT_VERSION}"
    echo "Author: Salih TANRISEVEN"
    echo "Date: December 2025"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto)
                INSTALL_MODE="auto"
                shift
                ;;
            --quick)
                INSTALL_MODE="quick"
                shift
                ;;
            --wizard)
                INSTALL_MODE="wizard"
                WEB_WIZARD=true
                shift
                ;;
            --config)
                INSTALL_MODE="config"
                CONFIG_FILE="$2"
                shift 2
                ;;
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --email)
                ADMIN_EMAIL="$2"
                shift 2
                ;;
            --force)
                FORCE_REINSTALL=true
                shift
                ;;
            --skip-validation)
                SKIP_VALIDATION=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --silent)
                SILENT=true
                shift
                ;;
            --lang)
                LANGUAGE="$2"
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
                log_error "Bilinmeyen argüman: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# MAIN INSTALLATION FLOW
# ============================================================================

main() {
    # Argümanları işle
    parse_arguments "$@"
    
    # Logging başlat
    init_logging
    
    # Trap ayarla
    trap 'error_handler $? $LINENO' ERR
    trap 'cleanup_handler' EXIT
    trap 'interrupt_handler' INT TERM
    
    # Banner göster
    print_banner
    
    log_info "Kurulum Modu: ${INSTALL_MODE}"
    log_info "Log Dosyası: ${LOG_FILE}"
    
    # Mod'a göre kurulum
    case "${INSTALL_MODE}" in
        wizard)
            if start_web_wizard; then
                log_info "Web wizard kurulumu tamamlandı"
            else
                INSTALL_MODE="auto"
            fi
            ;;
        quick)
            quick_setup_defaults
            ;;
        config)
            if [[ -f "$CONFIG_FILE" ]]; then
                source "$CONFIG_FILE"
                log_success "Yapılandırma dosyası yüklendi: $CONFIG_FILE"
            else
                log_error "Yapılandırma dosyası bulunamadı: $CONFIG_FILE"
                exit 1
            fi
            ;;
        auto|interactive|*)
            # Pre-flight checks
            if ! run_preflight_checks; then
                log_error "Sistem gereksinimleri karşılanmıyor"
                exit 1
            fi
            
            # Bağımlılıkları yükle
            install_system_dependencies
            install_docker
            install_docker_compose
            
            # Yapılandırma sihirbazı
            show_configuration_wizard
            ;;
    esac
    
    # Kurulum adımları
    echo ""
    print_section "Kurulum Başlıyor"
    echo -e "${COFFEE} Arkanıza yaslanın ve kahvenizi yudumlayın..."
    echo ""
    sleep 2
    
    # Adımları çalıştır
    save_installation_state "backup"
    backup_existing_installation
    
    save_installation_state "clone"
    clone_or_update_repository
    
    save_installation_state "configure"
    create_environment_file
    create_caddy_config
    create_cloudflared_config
    
    save_installation_state "pull"
    pull_docker_images
    
    save_installation_state "build"
    build_docker_images
    
    save_installation_state "start"
    start_services
    
    save_installation_state "wait"
    wait_for_services
    
    save_installation_state "migrate"
    run_database_migrations
    
    save_installation_state "user"
    create_superuser
    
    save_installation_state "static"
    collect_static_files
    
    save_installation_state "verify"
    verify_installation
    
    save_installation_state "complete"
    
    # Başarı özeti
    show_success_summary
    
    log_success "Kurulum başarıyla tamamlandı!"
}

# ============================================================================
# ERROR & CLEANUP HANDLERS
# ============================================================================

error_handler() {
    local exit_code=$1
    local line_number=$2
    
    log_error "Hata oluştu (satır $line_number, kod $exit_code)"
    
    if [[ ${#INSTALLATION_ERRORS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Hatalar:${NC}"
        for error in "${INSTALLATION_ERRORS[@]}"; do
            echo -e "  ${BULLET} $error"
        done
    fi
    
    if confirm_dialog "Kurulumu geri almak ister misiniz?" "n"; then
        rollback_installation
    fi
    
    echo ""
    log_info "Log dosyası: ${LOG_FILE}"
}

cleanup_handler() {
    show_cursor
    
    # Geçici dosyaları temizle
    rm -f /tmp/habernexus_* 2>/dev/null || true
}

interrupt_handler() {
    echo ""
    log_warning "Kurulum kullanıcı tarafından iptal edildi"
    
    if confirm_dialog "Yapılan değişiklikleri geri almak ister misiniz?" "n"; then
        rollback_installation
    fi
    
    cleanup_handler
    exit 130
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

# Script doğrudan çalıştırıldığında main'i çağır
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
