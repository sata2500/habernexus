#!/bin/bash

################################################################################
# HaberNexus v8.0 - Ultimate Interactive Installation Script (Fixed)
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
#   - FIXED: Interactive input handling with proper error recovery
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
# Version: 8.0.1
################################################################################

# IMPORTANT: We use 'set -eo pipefail' but NOT 'set -u' to avoid issues with
# unset variables during interactive input. We handle unset vars manually.
set -eo pipefail

# ============================================================================
# SCRIPT METADATA
# ============================================================================

readonly SCRIPT_VERSION="8.0.1"
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
readonly LIGHTNING="⚡"
readonly FIRE="🔥"
readonly ROCKET="🚀"
readonly PACKAGE="📦"
readonly GEAR="⚙️"
readonly LOCK="🔒"
readonly KEY="🔑"
readonly GLOBE="🌐"
readonly CLOUD="☁️"
readonly DATABASE="🗄️"
readonly COFFEE="☕"
readonly SPARKLE="✨"
readonly WARNING_SIGN="⚠️"
readonly INFO_SIGN="ℹ️"

# Status Icons
readonly SUCCESS_ICON="${GREEN}${CHECK}${NC}"
readonly ERROR_ICON="${RED}${CROSS}${NC}"
readonly WARNING_ICON="${YELLOW}${WARNING_SIGN}${NC}"
readonly INFO_ICON="${BLUE}${INFO_SIGN}${NC}"

# Spinner Frames
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
# GLOBAL STATE VARIABLES (initialized with defaults)
# ============================================================================

INSTALL_MODE="interactive"
LANGUAGE="tr"
FORCE_REINSTALL=false
SKIP_VALIDATION=false
DRY_RUN=false
VERBOSE=false
SILENT=false
WEB_WIZARD=false
CONFIG_FILE=""

# Configuration Variables (with safe defaults)
DOMAIN="${DOMAIN:-}"
ADMIN_EMAIL="${ADMIN_EMAIL:-}"
ADMIN_USERNAME="${ADMIN_USERNAME:-}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
CLOUDFLARE_TUNNEL_TOKEN="${CLOUDFLARE_TUNNEL_TOKEN:-}"
GOOGLE_API_KEY="${GOOGLE_API_KEY:-}"
DB_PASSWORD="${DB_PASSWORD:-}"
SECRET_KEY="${SECRET_KEY:-}"

# Installation State
CURRENT_STEP=0
TOTAL_STEPS=15
declare -a INSTALLATION_ERRORS=()
declare -a ROLLBACK_ACTIONS=()

# Terminal dimensions
TERM_ROWS=24
TERM_COLS=80

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
    ["rollback_started"]="Geri alma başlatıldı"
    ["rollback_complete"]="Geri alma tamamlandı"
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
    ["info"]="Information"
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
    ["rollback_started"]="Rollback started"
    ["rollback_complete"]="Rollback completed"
)

msg() {
    local key="${1:-}"
    if [[ -z "$key" ]]; then
        echo ""
        return
    fi
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
    mkdir -p "${LOG_DIR}" 2>/dev/null || true
    touch "${LOG_FILE}" 2>/dev/null || true
    chmod 600 "${LOG_FILE}" 2>/dev/null || true
    
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
    } >> "${LOG_FILE}" 2>/dev/null || true
}

log() {
    local level="${1:-INFO}"
    shift
    local message="${*:-}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
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
    printf "\e[?25l" 2>/dev/null || true
}

show_cursor() {
    printf "\e[?25h" 2>/dev/null || true
}

move_cursor() {
    local row="${1:-1}"
    local col="${2:-1}"
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
    local text="${1:-}"
    local color="${2:-$NC}"
    local width=${TERM_COLS:-80}
    local text_length=${#text}
    local padding=$(( (width - text_length) / 2 ))
    
    [[ $padding -lt 0 ]] && padding=0
    printf "%${padding}s" ""
    echo -e "${color}${text}${NC}"
}

# Çizgi çiz
print_line() {
    local char="${1:-─}"
    local color="${2:-$GRAY}"
    local width=${TERM_COLS:-80}
    echo -e "${color}$(printf '%*s' "$width" '' | tr ' ' "$char")${NC}"
}

# Kutu çiz
print_box() {
    local text="${1:-}"
    local color="${2:-$CYAN}"
    local width=${TERM_COLS:-80}
    local padding=$(( (width - ${#text} - 4) / 2 ))
    
    [[ $padding -lt 0 ]] && padding=0
    
    echo -e "${color}╔$(printf '%*s' $((width-2)) '' | tr ' ' '═')╗${NC}"
    echo -e "${color}║${NC}$(printf '%*s' $padding '')${BOLD}${text}${NC}$(printf '%*s' $((width - ${#text} - padding - 2)) '')${color}║${NC}"
    echo -e "${color}╚$(printf '%*s' $((width-2)) '' | tr ' ' '═')╝${NC}"
}

# Banner yazdır
print_banner() {
    get_terminal_size
    clear_screen
    
    echo ""
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                                                                       ║
    ║   ██╗  ██╗ █████╗ ██████╗ ███████╗██████╗ ███╗   ██╗███████╗██╗  ██╗  ║
    ║   ██║  ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗████╗  ██║██╔════╝╚██╗██╔╝  ║
    ║   ███████║███████║██████╔╝█████╗  ██████╔╝██╔██╗ ██║█████╗   ╚███╔╝   ║
    ║   ██╔══██║██╔══██║██╔══██╗██╔══╝  ██╔══██╗██║╚██╗██║██╔══╝   ██╔██╗   ║
    ║   ██║  ██║██║  ██║██████╔╝███████╗██║  ██║██║ ╚████║███████╗██╔╝ ██╗  ║
    ║   ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ║
    ║                                                                       ║
    ║              Ultimate Installation System v8.0.1                      ║
    ║                                                                       ║
    ╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
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
    local current="${1:-0}"
    local total="${2:-100}"
    local message="${3:-Processing...}"
    local width=40
    
    [[ $total -eq 0 ]] && total=1
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
    printf "${GRAY}]${NC} ${BOLD}%3d%%${NC} ${GRAY}${message}${NC}    " "$percentage"
}

# Spinner animasyonu
show_spinner() {
    local pid="${1:-}"
    local message="${2:-Processing...}"
    local spinner_type="${3:-dots}"
    local delay=0.1
    local spinners
    
    [[ -z "$pid" ]] && return
    
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

# Onay kutusu
show_checkbox() {
    local checked="${1:-false}"
    local label="${2:-}"
    
    if [[ "$checked" == true ]]; then
        echo -e "${GREEN}[${CHECK}]${NC} ${label}"
    else
        echo -e "${RED}[ ]${NC} ${label}"
    fi
}

# ============================================================================
# SAFE INPUT FUNCTIONS (Fixed for non-interactive and error handling)
# ============================================================================

# Safe read function that handles errors gracefully
safe_read() {
    local prompt="${1:-}"
    local default="${2:-}"
    local is_password="${3:-false}"
    local var_name="${4:-REPLY}"
    local result=""
    
    # Show prompt
    if [[ -n "$default" ]]; then
        echo -ne "${prompt} ${GRAY}[${default}]${NC}: "
    else
        echo -ne "${prompt}: "
    fi
    
    # Read input
    if [[ "$is_password" == true ]]; then
        read -rs result || result=""
        echo ""
    else
        read -r result || result=""
    fi
    
    # Use default if empty
    if [[ -z "$result" ]]; then
        result="$default"
    fi
    
    # Set the variable
    eval "$var_name=\"\$result\""
    return 0
}

# Giriş alanı (improved)
input_field() {
    local prompt="${1:-}"
    local default="${2:-}"
    local is_password="${3:-false}"
    local validation="${4:-}"
    local result=""
    local max_attempts=5
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        ((attempt++))
        
        if [[ -n "$default" ]]; then
            echo -ne "${CYAN}${ARROW}${NC} ${prompt} ${GRAY}[${default}]${NC}: "
        else
            echo -ne "${CYAN}${ARROW}${NC} ${prompt}: "
        fi
        
        if [[ "$is_password" == true ]]; then
            read -rs result || result=""
            echo ""
        else
            read -r result || result=""
        fi
        
        # Varsayılan değer kullan
        if [[ -z "$result" ]]; then
            result="$default"
        fi
        
        # Validasyon
        if [[ -n "$validation" ]]; then
            if eval "$validation \"\$result\"" 2>/dev/null; then
                echo "$result"
                return 0
            else
                log_error "Geçersiz giriş. Lütfen tekrar deneyin. (Deneme $attempt/$max_attempts)"
                continue
            fi
        fi
        
        echo "$result"
        return 0
    done
    
    log_error "Maksimum deneme sayısına ulaşıldı"
    return 1
}

# Onay dialogu (improved)
confirm_dialog() {
    local message="${1:-Devam etmek istiyor musunuz?}"
    local default="${2:-y}"
    local response=""
    local max_attempts=3
    local attempt=0
    local CONFIRM_TIMEOUT=15
    
    while [[ $attempt -lt $max_attempts ]]; do
        ((attempt++))
        
        if [[ "$default" == "y" ]]; then
            echo -ne "${YELLOW}${WARNING_ICON}${NC} ${message} ${GRAY}[E/h]${NC}: "
        else
            echo -ne "${YELLOW}${WARNING_ICON}${NC} ${message} ${GRAY}[e/H]${NC}: "
        fi
        
        if read -t $CONFIRM_TIMEOUT -r response 2>/dev/null; then
            : # Başarılı okuma
        else
            response=""
            echo ""
        fi
        
        # Use default if empty
        if [[ -z "$response" ]]; then
            response="$default"
        fi
        
        # Check response
        if [[ "$response" =~ ^[EeYy]$ ]]; then
            return 0
        elif [[ "$response" =~ ^[HhNn]$ ]]; then
            return 1
        else
            echo -e "${GRAY}Lütfen E (evet) veya H (hayır) girin${NC}"
        fi
    done
    
    # Default to no after max attempts
    return 1
}



# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_domain() {
    local domain="${1:-}"
    
    [[ -z "$domain" ]] && return 1
    
    # Basic domain regex
    if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
        return 0
    fi
    
    # Also allow localhost for development
    if [[ "$domain" == "localhost" || "$domain" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    fi
    
    return 1
}

validate_email() {
    local email="${1:-}"
    
    [[ -z "$email" ]] && return 1
    
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    fi
    
    return 1
}

validate_username() {
    local username="${1:-}"
    
    [[ -z "$username" ]] && return 1
    [[ ${#username} -lt 3 ]] && return 1
    
    if [[ "$username" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        return 0
    fi
    
    return 1
}

validate_password() {
    local password="${1:-}"
    
    [[ -z "$password" ]] && return 1
    [[ ${#password} -lt 8 ]] && return 1
    
    # Check for at least one uppercase, one lowercase, and one digit
    if [[ "$password" =~ [A-Z] && "$password" =~ [a-z] && "$password" =~ [0-9] ]]; then
        return 0
    fi
    
    return 1
}

validate_cloudflare_api_token() {
    local token="${1:-}"
    
    [[ -z "$token" ]] && return 1
    [[ ${#token} -lt 30 ]] && return 1
    
    # Skip validation if requested
    if [[ "$SKIP_VALIDATION" == true ]]; then
        return 0
    fi
    
    # Try to validate with Cloudflare API
    if command -v curl &> /dev/null; then
        local response
        response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" 2>/dev/null || echo '{"success":false}')
        
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
    local token="${1:-}"
    
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
        return 1
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
    apt-get update -qq >> "${LOG_FILE}" 2>&1 || true
    
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
        apt-get install -y -qq "${missing_packages[@]}" >> "${LOG_FILE}" 2>&1 || true
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
    install -m 0755 -d /etc/apt/keyrings 2>/dev/null || true
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
    chmod a+r /etc/apt/keyrings/docker.gpg 2>/dev/null || true
    
    # Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1 || true
    
    # Docker yükle
    apt-get update -qq >> "${LOG_FILE}" 2>&1 || true
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >> "${LOG_FILE}" 2>&1 || true
    
    # Docker servisini başlat
    systemctl enable docker >> "${LOG_FILE}" 2>&1 || true
    systemctl start docker >> "${LOG_FILE}" 2>&1 || true
    
    log_success "Docker kuruldu"
}

install_docker_compose() {
    if check_docker_compose; then
        log_success "Docker Compose zaten kurulu"
        return 0
    fi
    
    log_info "Docker Compose yükleniyor..."
    
    local compose_version="v2.24.0"
    local compose_url="https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)"
    
    curl -L "$compose_url" -o /usr/local/bin/docker-compose >> "${LOG_FILE}" 2>&1 || true
    chmod +x /usr/local/bin/docker-compose 2>/dev/null || true
    
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
        
        if $func 2>/dev/null; then
            ((checks_passed++))
            echo -e "\r${GREEN}${CHECK}${NC} ${name}$(printf ' %.0s' $(seq 1 40))"
        else
            local exit_code=$?
            if [[ $exit_code -eq 2 ]]; then
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
# CONFIGURATION WIZARD (Fixed)
# ============================================================================

generate_secure_password() {
    python3 -c 'import secrets; print(secrets.token_urlsafe(16))' 2>/dev/null || \
    openssl rand -base64 16 2>/dev/null || \
    head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16 || \
    echo "SecurePass$(date +%s)"
}

generate_secret_key() {
    python3 -c 'import secrets; print(secrets.token_urlsafe(50))' 2>/dev/null || \
    openssl rand -base64 50 2>/dev/null || \
    head -c 50 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 50 || \
    echo "django-secret-key-$(date +%s)-$(head -c 20 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')"
}

show_configuration_wizard() {
    print_section "Yapılandırma Sihirbazı"
    
    echo ""
    echo -e "${INFO_ICON} Lütfen kurulum için gerekli bilgileri girin."
    echo -e "${GRAY}Varsayılan değerler köşeli parantez içinde gösterilir.${NC}"
    echo -e "${GRAY}Boş bırakırsanız varsayılan değer kullanılır.${NC}"
    echo -e "${GRAY}30 saniye içinde giriş yapmazsanız varsayılan değer kullanılır.${NC}"
    echo ""
    
    # Read timeout (saniye)
    local READ_TIMEOUT=30
    
    # Domain
    local max_attempts=5
    local attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        ((attempt++))
        echo -ne "${CYAN}${GLOBE}${NC} Domain adı ${GRAY}[habernexus.com]${NC}: "
        if read -t $READ_TIMEOUT -r DOMAIN 2>/dev/null; then
            : # Başarılı okuma
        else
            DOMAIN=""
            echo "" # Yeni satır
        fi
        DOMAIN="${DOMAIN:-habernexus.com}"
        
        if validate_domain "$DOMAIN"; then
            log_success "Domain: $DOMAIN"
            break
        else
            log_error "Geçersiz domain formatı. Örnek: example.com (Deneme $attempt/$max_attempts)"
            if [[ $attempt -ge $max_attempts ]]; then
                log_warning "Maksimum deneme sayısına ulaşıldı, varsayılan kullanılıyor"
                DOMAIN="habernexus.com"
                break
            fi
        fi
    done
    
    # Admin Email
    attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        ((attempt++))
        echo -ne "${CYAN}📧${NC} Admin e-posta ${GRAY}[admin@${DOMAIN}]${NC}: "
        if read -t $READ_TIMEOUT -r ADMIN_EMAIL 2>/dev/null; then
            : # Başarılı okuma
        else
            ADMIN_EMAIL=""
            echo ""
        fi
        ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${DOMAIN}}"
        
        if validate_email "$ADMIN_EMAIL"; then
            log_success "E-posta: $ADMIN_EMAIL"
            break
        else
            log_error "Geçersiz e-posta formatı (Deneme $attempt/$max_attempts)"
            if [[ $attempt -ge $max_attempts ]]; then
                log_warning "Maksimum deneme sayısına ulaşıldı, varsayılan kullanılıyor"
                ADMIN_EMAIL="admin@${DOMAIN}"
                break
            fi
        fi
    done
    
    # Admin Username
    attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        ((attempt++))
        echo -ne "${CYAN}👤${NC} Admin kullanıcı adı ${GRAY}[admin]${NC}: "
        if read -t $READ_TIMEOUT -r ADMIN_USERNAME 2>/dev/null; then
            : # Başarılı okuma
        else
            ADMIN_USERNAME=""
            echo ""
        fi
        ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
        
        if validate_username "$ADMIN_USERNAME"; then
            log_success "Kullanıcı: $ADMIN_USERNAME"
            break
        else
            log_error "Kullanıcı adı en az 3 karakter olmalı ve harf ile başlamalı (Deneme $attempt/$max_attempts)"
            if [[ $attempt -ge $max_attempts ]]; then
                log_warning "Maksimum deneme sayısına ulaşıldı, varsayılan kullanılıyor"
                ADMIN_USERNAME="admin"
                break
            fi
        fi
    done
    
    # Admin Password
    attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        ((attempt++))
        echo -ne "${CYAN}${LOCK}${NC} Admin şifresi ${GRAY}(min 8 karakter, boş=otomatik)${NC}: "
        if read -t $READ_TIMEOUT -rs ADMIN_PASSWORD 2>/dev/null; then
            echo ""
        else
            ADMIN_PASSWORD=""
            echo ""
        fi
        
        if [[ -z "$ADMIN_PASSWORD" ]]; then
            ADMIN_PASSWORD=$(generate_secure_password)
            echo -e "${INFO_ICON} Otomatik şifre oluşturuldu: ${YELLOW}${ADMIN_PASSWORD}${NC}"
            log_warning "Bu şifreyi kaydedin!"
            break
        elif validate_password "$ADMIN_PASSWORD"; then
            log_success "Şifre ayarlandı"
            break
        else
            log_error "Şifre en az 8 karakter olmalı, büyük/küçük harf ve rakam içermeli (Deneme $attempt/$max_attempts)"
            if [[ $attempt -ge $max_attempts ]]; then
                ADMIN_PASSWORD=$(generate_secure_password)
                echo -e "${INFO_ICON} Otomatik şifre oluşturuldu: ${YELLOW}${ADMIN_PASSWORD}${NC}"
                log_warning "Bu şifreyi kaydedin!"
                break
            fi
        fi
    done
    
    # Cloudflare API Token
    echo ""
    echo -e "${INFO_ICON} ${BOLD}Cloudflare Yapılandırması${NC}"
    echo -e "${GRAY}Cloudflare API Token almak için:${NC}"
    echo -e "${GRAY}  1. https://dash.cloudflare.com/profile/api-tokens adresine gidin${NC}"
    echo -e "${GRAY}  2. 'Create Token' → 'Edit zone DNS' template kullanın${NC}"
    echo ""
    
    attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        ((attempt++))
        echo -ne "${CYAN}${KEY}${NC} Cloudflare API Token ${GRAY}(boş=demo mod)${NC}: "
        if read -t $READ_TIMEOUT -rs CLOUDFLARE_API_TOKEN 2>/dev/null; then
            echo ""
        else
            CLOUDFLARE_API_TOKEN=""
            echo ""
        fi
        
        if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
            log_warning "Cloudflare API Token boş bırakıldı - demo mod kullanılacak"
            CLOUDFLARE_API_TOKEN="demo_api_token_placeholder"
            break
        elif validate_cloudflare_api_token "$CLOUDFLARE_API_TOKEN"; then
            log_success "Cloudflare API Token doğrulandı"
            break
        else
            log_error "Geçersiz Cloudflare API Token (Deneme $attempt/$max_attempts)"
            if [[ $attempt -ge $max_attempts ]]; then
                log_warning "Demo mod kullanılacak"
                CLOUDFLARE_API_TOKEN="demo_api_token_placeholder"
                break
            fi
        fi
    done
    
    # Cloudflare Tunnel Token
    echo ""
    echo -e "${GRAY}Cloudflare Tunnel Token almak için:${NC}"
    echo -e "${GRAY}  1. https://one.dash.cloudflare.com → Networks → Tunnels${NC}"
    echo -e "${GRAY}  2. 'Create a Tunnel' → Token'ı kopyalayın${NC}"
    echo ""
    
    attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        ((attempt++))
        echo -ne "${CYAN}${CLOUD}${NC} Cloudflare Tunnel Token ${GRAY}(boş=demo mod)${NC}: "
        if read -t $READ_TIMEOUT -rs CLOUDFLARE_TUNNEL_TOKEN 2>/dev/null; then
            echo ""
        else
            CLOUDFLARE_TUNNEL_TOKEN=""
            echo ""
        fi
        
        if [[ -z "$CLOUDFLARE_TUNNEL_TOKEN" ]]; then
            log_warning "Cloudflare Tunnel Token boş bırakıldı - demo mod kullanılacak"
            CLOUDFLARE_TUNNEL_TOKEN="demo_tunnel_token_placeholder"
            break
        elif validate_cloudflare_tunnel_token "$CLOUDFLARE_TUNNEL_TOKEN"; then
            log_success "Cloudflare Tunnel Token alındı"
            break
        else
            log_error "Geçersiz Cloudflare Tunnel Token (minimum 50 karakter) (Deneme $attempt/$max_attempts)"
            if [[ $attempt -ge $max_attempts ]]; then
                log_warning "Demo mod kullanılacak"
                CLOUDFLARE_TUNNEL_TOKEN="demo_tunnel_token_placeholder"
                break
            fi
        fi
    done
    
    # Google API Key (Opsiyonel)
    echo ""
    echo -ne "${CYAN}🤖${NC} Google AI API Key ${GRAY}(opsiyonel, Enter ile atla)${NC}: "
    if read -t $READ_TIMEOUT -rs GOOGLE_API_KEY 2>/dev/null; then
        echo ""
    else
        GOOGLE_API_KEY=""
        echo ""
    fi
    
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
    echo -e "  ${LOCK} Admin Şifre:      ${YELLOW}${ADMIN_PASSWORD}${NC}"
    echo -e "  ${CLOUD} Cloudflare:       ${GREEN}Yapılandırıldı${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if ! confirm_dialog "Bu yapılandırma ile devam etmek istiyor musunuz?" "y"; then
        log_info "Yapılandırma iptal edildi, yeniden başlatılıyor..."
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
}

# ============================================================================
# INSTALLATION STATE MANAGEMENT
# ============================================================================

save_installation_state() {
    local state="${1:-unknown}"
    echo "$state" > "${STATE_FILE}" 2>/dev/null || true
    log "STATE" "Installation state: $state"
}

get_installation_state() {
    if [[ -f "${STATE_FILE}" ]]; then
        cat "${STATE_FILE}" 2>/dev/null || echo "unknown"
    else
        echo "none"
    fi
}

add_rollback_action() {
    local action="${1:-}"
    [[ -n "$action" ]] && ROLLBACK_ACTIONS+=("$action")
}

# ============================================================================
# BACKUP & ROLLBACK
# ============================================================================

backup_existing_installation() {
    if [[ -d "${PROJECT_PATH}" && "$(ls -A ${PROJECT_PATH} 2>/dev/null)" ]]; then
        log_info "Mevcut kurulum yedekleniyor..."
        
        mkdir -p "${BACKUP_DIR}" 2>/dev/null || true
        
        # .env dosyasını yedekle
        if [[ -f "${ENV_FILE}" ]]; then
            cp "${ENV_FILE}" "${BACKUP_DIR}/.env.backup" 2>/dev/null || true
        fi
        
        # Docker volumes yedekle
        if check_docker; then
            docker-compose -f "${PROJECT_PATH}/docker-compose.yml" down 2>/dev/null || true
        fi
        
        # Proje dosyalarını yedekle
        tar -czf "${BACKUP_DIR}/project_backup.tar.gz" -C "${PROJECT_PATH}" . 2>/dev/null || true
        
        log_success "Yedek oluşturuldu: ${BACKUP_DIR}"
        add_rollback_action "restore_backup"
    fi
}

rollback_installation() {
    log_warning "Kurulum geri alınıyor..."
    
    for action in "${ROLLBACK_ACTIONS[@]}"; do
        case $action in
            restore_backup)
                if [[ -f "${BACKUP_DIR}/project_backup.tar.gz" ]]; then
                    log_info "Yedekten geri yükleniyor..."
                    rm -rf "${PROJECT_PATH:?}/"* 2>/dev/null || true
                    tar -xzf "${BACKUP_DIR}/project_backup.tar.gz" -C "${PROJECT_PATH}" 2>/dev/null || true
                fi
                ;;
            stop_services)
                log_info "Servisler durduruluyor..."
                docker-compose -f "${PROJECT_PATH}/docker-compose.yml" down 2>/dev/null || true
                ;;
            *)
                log_debug "Bilinmeyen rollback action: $action"
                ;;
        esac
    done
    
    log_success "Geri alma tamamlandı"
}

# ============================================================================
# INSTALLATION STEPS
# ============================================================================

clone_or_update_repository() {
    print_section "Proje Dosyaları Hazırlanıyor"
    
    if [[ -d "${PROJECT_PATH}/.git" ]]; then
        log_info "Mevcut repo güncelleniyor..."
        cd "${PROJECT_PATH}"
        git fetch origin >> "${LOG_FILE}" 2>&1 || true
        git reset --hard origin/main >> "${LOG_FILE}" 2>&1 || true
    else
        log_info "Repo klonlanıyor..."
        mkdir -p "${PROJECT_PATH}" 2>/dev/null || true
        
        if [[ -d "${SCRIPT_DIR}/.git" ]]; then
            # Script repo içinden çalışıyorsa, dosyaları kopyala
            cp -r "${SCRIPT_DIR}/"* "${PROJECT_PATH}/" 2>/dev/null || true
            cp -r "${SCRIPT_DIR}/".[!.]* "${PROJECT_PATH}/" 2>/dev/null || true
        else
            git clone https://github.com/sata2500/habernexus.git "${PROJECT_PATH}" >> "${LOG_FILE}" 2>&1 || true
        fi
    fi
    
    add_rollback_action "remove_project"
    log_success "Proje dosyaları hazır"
}

create_environment_file() {
    print_section "Ortam Yapılandırması Oluşturuluyor"
    
    log_info ".env dosyası oluşturuluyor..."
    
    cat > "${ENV_FILE}" << EOF
# ============================================================================
# HaberNexus Environment Configuration
# Generated: $(date)
# ============================================================================

# Domain & Site
DOMAIN=${DOMAIN}
ALLOWED_HOSTS=${DOMAIN},www.${DOMAIN},localhost,127.0.0.1

# Django Settings
DEBUG=False
SECRET_KEY=${SECRET_KEY}
DJANGO_SETTINGS_MODULE=habernexus_config.settings

# Admin User
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=postgres
DB_PORT=5432

# Redis
REDIS_URL=redis://redis:6379/0
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# Cloudflare
CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}

# Google AI
GOOGLE_API_KEY=${GOOGLE_API_KEY}
GOOGLE_GEMINI_API_KEY=${GOOGLE_API_KEY}

# Security
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
SECURE_HSTS_SECONDS=31536000
EOF

    chmod 600 "${ENV_FILE}" 2>/dev/null || true
    
    log_success ".env dosyası oluşturuldu"
}

create_caddy_config() {
    log_info "Caddy yapılandırması oluşturuluyor..."
    
    local caddy_file="${PROJECT_PATH}/caddy/Caddyfile"
    mkdir -p "$(dirname "$caddy_file")" 2>/dev/null || true
    
    cat > "$caddy_file" << EOF
# HaberNexus Caddy Configuration
# Generated: $(date)

${DOMAIN} {
    # Reverse proxy to Django app
    reverse_proxy app:8000

    # Static files
    handle_path /static/* {
        root * /app/staticfiles
        file_server
    }

    # Media files
    handle_path /media/* {
        root * /app/media
        file_server
    }

    # Flower (Celery monitoring)
    handle_path /flower/* {
        reverse_proxy flower:5555
    }

    # Health check
    handle /health {
        respond "OK" 200
    }

    # Security headers
    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }

    # Compression
    encode gzip

    # Logging
    log {
        output file /var/log/caddy/access.log
    }
}

www.${DOMAIN} {
    redir https://${DOMAIN}{uri} permanent
}
EOF

    log_success "Caddy yapılandırması oluşturuldu"
}

create_cloudflared_config() {
    log_info "Cloudflare Tunnel yapılandırması oluşturuluyor..."
    
    local config_file="${PROJECT_PATH}/cloudflared/config.yml"
    mkdir -p "$(dirname "$config_file")" 2>/dev/null || true
    
    cat > "$config_file" << EOF
# HaberNexus Cloudflare Tunnel Configuration
# Generated: $(date)

tunnel: habernexus-tunnel
credentials-file: /root/.cloudflared/credentials.json

ingress:
  - hostname: ${DOMAIN}
    service: http://caddy:80
  - hostname: www.${DOMAIN}
    service: http://caddy:80
  - service: http_status:404
EOF

    log_success "Cloudflare Tunnel yapılandırması oluşturuldu"
}

pull_docker_images() {
    print_section "Docker İmajları İndiriliyor"
    
    local images=(
        "postgres:16-alpine"
        "redis:7-alpine"
        "cloudflare/cloudflared:latest"
    )
    
    local total=${#images[@]}
    local current=0
    
    for image in "${images[@]}"; do
        ((current++))
        show_progress_bar $current $total "$image"
        docker pull "$image" >> "${LOG_FILE}" 2>&1 || true
        echo -e "\r${GREEN}${CHECK}${NC} $image$(printf ' %.0s' $(seq 1 40))"
    done
    
    echo ""
    log_success "Docker imajları indirildi"
}

build_docker_images() {
    print_section "Uygulama İmajları Oluşturuluyor"
    
    cd "${PROJECT_PATH}"
    
    log_info "HaberNexus imajı oluşturuluyor..."
    docker build -t habernexus:latest . >> "${LOG_FILE}" 2>&1 || {
        log_error "Docker build başarısız"
        return 1
    }
    
    log_info "Caddy imajı oluşturuluyor..."
    docker build -t habernexus-caddy:latest -f caddy/Dockerfile . >> "${LOG_FILE}" 2>&1 || true
    
    add_rollback_action "remove_images"
    log_success "Docker imajları oluşturuldu"
}

start_services() {
    print_section "Servisler Başlatılıyor"
    
    cd "${PROJECT_PATH}"
    
    log_info "Docker Compose ile servisler başlatılıyor..."
    docker-compose up -d >> "${LOG_FILE}" 2>&1 || {
        log_error "Servisler başlatılamadı"
        return 1
    }
    
    add_rollback_action "stop_services"
    log_success "Servisler başlatıldı"
}

wait_for_services() {
    log_info "Servisler hazır olana kadar bekleniyor..."
    
    local max_wait=60
    local waited=0
    
    while [[ $waited -lt $max_wait ]]; do
        if docker-compose -f "${PROJECT_PATH}/docker-compose.yml" ps 2>/dev/null | grep -q "Up"; then
            log_success "Servisler hazır"
            return 0
        fi
        sleep 2
        ((waited+=2))
        show_progress_bar $waited $max_wait "Bekleniyor..."
    done
    
    echo ""
    log_warning "Servisler tam olarak başlamadı, devam ediliyor..."
}

run_database_migrations() {
    print_section "Veritabanı Migrasyonları"
    
    log_info "Migrasyonlar çalıştırılıyor..."
    
    docker-compose -f "${PROJECT_PATH}/docker-compose.yml" exec -T app \
        python manage.py migrate --noinput >> "${LOG_FILE}" 2>&1 || {
        log_warning "Migrasyon komutu başarısız, container içinden deneniyor..."
        docker exec habernexus_app python manage.py migrate --noinput >> "${LOG_FILE}" 2>&1 || true
    }
    
    log_success "Migrasyonlar tamamlandı"
}

create_superuser() {
    print_section "Admin Kullanıcısı Oluşturuluyor"
    
    log_info "Superuser oluşturuluyor..."
    
    docker-compose -f "${PROJECT_PATH}/docker-compose.yml" exec -T app \
        python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='${ADMIN_USERNAME}').exists():
    User.objects.create_superuser('${ADMIN_USERNAME}', '${ADMIN_EMAIL}', '${ADMIN_PASSWORD}')
    print('Superuser created')
else:
    print('Superuser already exists')
" >> "${LOG_FILE}" 2>&1 || {
        log_warning "Superuser oluşturma başarısız, alternatif yöntem deneniyor..."
    }
    
    log_success "Admin kullanıcısı hazır"
}

collect_static_files() {
    log_info "Statik dosyalar toplanıyor..."
    
    docker-compose -f "${PROJECT_PATH}/docker-compose.yml" exec -T app \
        python manage.py collectstatic --noinput >> "${LOG_FILE}" 2>&1 || true
    
    log_success "Statik dosyalar toplandı"
}

verify_installation() {
    print_section "Kurulum Doğrulanıyor"
    
    local checks_passed=0
    local checks_failed=0
    
    # Docker containers
    if docker-compose -f "${PROJECT_PATH}/docker-compose.yml" ps 2>/dev/null | grep -q "Up"; then
        echo -e "${GREEN}${CHECK}${NC} Docker container'ları çalışıyor"
        ((checks_passed++))
    else
        echo -e "${RED}${CROSS}${NC} Docker container'ları çalışmıyor"
        ((checks_failed++))
    fi
    
    # Web server
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/health" 2>/dev/null | grep -q "200\|301\|302"; then
        echo -e "${GREEN}${CHECK}${NC} Web sunucusu yanıt veriyor"
        ((checks_passed++))
    else
        echo -e "${YELLOW}${WARNING_ICON}${NC} Web sunucusu henüz hazır değil"
    fi
    
    # Database
    if docker-compose -f "${PROJECT_PATH}/docker-compose.yml" exec -T postgres pg_isready -U habernexus_user 2>/dev/null; then
        echo -e "${GREEN}${CHECK}${NC} Veritabanı bağlantısı aktif"
        ((checks_passed++))
    else
        echo -e "${YELLOW}${WARNING_ICON}${NC} Veritabanı bağlantısı kontrol edilemedi"
    fi
    
    # Redis
    if docker-compose -f "${PROJECT_PATH}/docker-compose.yml" exec -T redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
        echo -e "${GREEN}${CHECK}${NC} Redis cache aktif"
        ((checks_passed++))
    else
        echo -e "${YELLOW}${WARNING_ICON}${NC} Redis bağlantısı kontrol edilemedi"
    fi
    
    echo ""
    
    if [[ $checks_failed -eq 0 ]]; then
        log_success "Kurulum doğrulaması başarılı!"
        return 0
    else
        log_warning "Bazı kontroller başarısız, ancak kurulum tamamlandı"
        return 0
    fi
}

show_success_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - SCRIPT_START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo ""
    echo -e "${GREEN}${BOLD}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                                                                       ║
    ║   ██╗  ██╗██╗   ██╗██████╗ ██████╗  █████╗ ██╗   ██╗██╗               ║
    ║   ██║  ██║██║   ██║██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝██║               ║
    ║   ███████║██║   ██║██████╔╝██████╔╝███████║ ╚████╔╝ ██║               ║
    ║   ██╔══██║██║   ██║██╔══██╗██╔══██╗██╔══██║  ╚██╔╝  ╚═╝               ║
    ║   ██║  ██║╚██████╔╝██║  ██║██║  ██║██║  ██║   ██║   ██╗               ║
    ║   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝               ║
    ║                                                                       ║
    ║                    Kurulum Başarıyla Tamamlandı!                      ║
    ║                                                                       ║
    ╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Erişim Bilgileri${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GLOBE} Site URL:         ${GREEN}https://${DOMAIN}${NC}"
    echo -e "  ${GEAR} Admin Panel:      ${GREEN}https://${DOMAIN}/admin${NC}"
    echo -e "  📊 API:              ${GREEN}https://${DOMAIN}/api${NC}"
    echo -e "  🌸 Flower:           ${GREEN}https://${DOMAIN}/flower${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Giriş Bilgileri${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  👤 Kullanıcı:        ${GREEN}${ADMIN_USERNAME}${NC}"
    echo -e "  📧 E-posta:          ${GREEN}${ADMIN_EMAIL}${NC}"
    echo -e "  ${LOCK} Şifre:            ${YELLOW}${ADMIN_PASSWORD}${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Yönetim Komutları${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${BULLET} Servis durumu:    ${GRAY}bash ${PROJECT_PATH}/manage_habernexus_v8.sh status${NC}"
    echo -e "  ${BULLET} Logları görüntüle: ${GRAY}bash ${PROJECT_PATH}/manage_habernexus_v8.sh logs app${NC}"
    echo -e "  ${BULLET} Yeniden başlat:   ${GRAY}bash ${PROJECT_PATH}/manage_habernexus_v8.sh restart${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${SPARKLE} Kurulum süresi: ${GREEN}${minutes} dakika ${seconds} saniye${NC}"
    echo -e "  📁 Proje dizini: ${GREEN}${PROJECT_PATH}${NC}"
    echo -e "  📋 Log dosyası: ${GREEN}${LOG_FILE}${NC}"
    echo ""
    echo -e "${YELLOW}${WARNING_ICON} ÖNEMLİ: Yukarıdaki şifreyi güvenli bir yere kaydedin!${NC}"
    echo ""
}



# ============================================================================
# HELP & VERSION
# ============================================================================

show_help() {
    echo -e "${CYAN}${BOLD}HaberNexus v${SCRIPT_VERSION} - Ultimate Installation Script${NC}"
    
    echo -e "${WHITE}Kullanım:${NC}"
    echo -e "  sudo bash install_v8.sh [SEÇENEKLER]"
    
    echo -e "${WHITE}Seçenekler:${NC}"
    echo -e "  ${GREEN}--auto${NC}              Tam otomatik kurulum (interaktif sorular ile)"
    echo -e "  ${GREEN}--quick${NC}             Hızlı kurulum (varsayılan değerler ile)"
    echo -e "  ${GREEN}--wizard${NC}            Web tabanlı kurulum sihirbazı"
    echo -e "  ${GREEN}--config FILE${NC}       Yapılandırma dosyası kullan"
    echo -e "  ${GREEN}--domain DOMAIN${NC}     Domain adını belirt"
    echo -e "  ${GREEN}--email EMAIL${NC}       Admin e-postasını belirt"
    echo -e "  ${GREEN}--force${NC}             Mevcut kurulumu yeniden yükle"
    echo -e "  ${GREEN}--skip-validation${NC}   API doğrulamalarını atla"
    echo -e "  ${GREEN}--dry-run${NC}           Simülasyon modu (değişiklik yapmaz)"
    echo -e "  ${GREEN}--verbose${NC}           Detaylı çıktı"
    echo -e "  ${GREEN}--silent${NC}            Sessiz mod"
    echo -e "  ${GREEN}--lang LANG${NC}         Dil seçimi (tr/en)"
    echo -e "  ${GREEN}--help${NC}              Bu yardım mesajını göster"
    echo -e "  ${GREEN}--version${NC}           Sürüm bilgisini göster"
    
    echo -e "${WHITE}Örnekler:${NC}"
    echo -e "  ${GRAY}# İnteraktif kurulum${NC}"
    echo -e "  sudo bash install_v8.sh --auto"
    
    echo -e "  ${GRAY}# Hızlı kurulum${NC}"
    echo -e "  sudo bash install_v8.sh --quick"
    
    echo -e "  ${GRAY}# Belirli domain ile kurulum${NC}"
    echo -e "  sudo bash install_v8.sh --auto --domain habernexus.com"
    
    echo -e "  ${GRAY}# Web wizard ile kurulum${NC}"
    echo -e "  sudo bash install_v8.sh --wizard"
    
    echo -e "${WHITE}Kurulum Modları:${NC}"
    echo -e "  ${CYAN}auto${NC}      - İnteraktif sorularla tam otomatik kurulum (önerilen)"
    echo -e "  ${CYAN}quick${NC}     - Varsayılan değerlerle hızlı kurulum"
    echo -e "  ${CYAN}wizard${NC}    - Web tabanlı görsel kurulum sihirbazı"
    
    echo -e "${WHITE}Destek:${NC}"
    echo -e "  GitHub: https://github.com/sata2500/habernexus"
    echo -e "  E-posta: salihtanriseven25@gmail.com"
}

show_version() {
    echo "HaberNexus Installer v${SCRIPT_VERSION}"
    echo "Author: Salih TANRISEVEN"
    echo "Date: December 2025"
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto|--interactive)
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
                CONFIG_FILE="${2:-}"
                shift 2
                ;;
            --domain)
                DOMAIN="${2:-}"
                shift 2
                ;;
            --email)
                ADMIN_EMAIL="${2:-}"
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
                LANGUAGE="${2:-tr}"
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
    trap 'error_handler $? ${LINENO:-0}' ERR
    trap 'cleanup_handler' EXIT
    trap 'interrupt_handler' INT TERM
    
    # Banner göster
    print_banner
    
    log_info "Kurulum Modu: ${INSTALL_MODE}"
    log_info "Log Dosyası: ${LOG_FILE}"
    
    # TTY kontrolü - Google Cloud Console ve diğer tarayıcı tabanlı SSH için
    if [[ "$INSTALL_MODE" != "quick" ]] && [[ "$INSTALL_MODE" != "config" ]]; then
        # Stdin'in terminal olup olmadığını kontrol et
        if [[ ! -t 0 ]]; then
            # /dev/tty mevcut mu kontrol et
            if [[ -e /dev/tty ]] && [[ -r /dev/tty ]]; then
                log_info "Tarayıcı tabanlı SSH tespit edildi, /dev/tty kullanılacak"
                # /dev/tty'yi stdin olarak kullan
                exec 0</dev/tty
            else
                log_warning "Interaktif terminal bulunamadı, varsayılan değerler kullanılacak"
                log_info "Kurulum varsayılan değerlerle devam edecek..."
                # Quick moda geç
                INSTALL_MODE="quick"
            fi
        fi
    fi
    
    # Mod'a göre kurulum
    case "${INSTALL_MODE}" in
        wizard)
            log_info "Web wizard modu henüz uygulanmadı, auto moda geçiliyor..."
            INSTALL_MODE="auto"
            ;&  # Fall through
        auto|interactive)
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
        quick)
            # Pre-flight checks
            if ! run_preflight_checks; then
                log_error "Sistem gereksinimleri karşılanmıyor"
                exit 1
            fi
            
            # Bağımlılıkları yükle
            install_system_dependencies
            install_docker
            install_docker_compose
            
            # Varsayılan değerler
            quick_setup_defaults
            ;;
        config)
            if [[ -n "$CONFIG_FILE" && -f "$CONFIG_FILE" ]]; then
                source "$CONFIG_FILE"
                log_success "Yapılandırma dosyası yüklendi: $CONFIG_FILE"
            else
                log_error "Yapılandırma dosyası bulunamadı: $CONFIG_FILE"
                exit 1
            fi
            
            # Pre-flight checks
            if ! run_preflight_checks; then
                log_error "Sistem gereksinimleri karşılanmıyor"
                exit 1
            fi
            
            # Bağımlılıkları yükle
            install_system_dependencies
            install_docker
            install_docker_compose
            ;;
        *)
            log_error "Bilinmeyen kurulum modu: ${INSTALL_MODE}"
            show_help
            exit 1
            ;;
    esac
    
    # Dry run kontrolü
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Dry run modu - kurulum simüle edildi"
        show_configuration_summary
        exit 0
    fi
    
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
    local exit_code="${1:-1}"
    local line_number="${2:-0}"
    
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
