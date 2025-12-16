#!/bin/bash
# ============================================================================
# HaberNexus v9.0 - Ultimate Installation Script
# ============================================================================
# 
# Bu script, Docker install script'inden ilham alarak tasarlanmıştır.
# Whiptail dialog'ları ve fallback mekanizması ile her ortamda çalışır.
#
# Kullanım:
#   sudo bash install_v9.sh                    # İnteraktif mod
#   sudo bash install_v9.sh --quick            # Varsayılan değerlerle hızlı kurulum
#   sudo bash install_v9.sh --config file.yml  # Config dosyasından kurulum
#   sudo bash install_v9.sh --domain example.com --email admin@example.com
#
# Tüm parametreler:
#   --domain DOMAIN          Domain adı (varsayılan: habernexus.com)
#   --email EMAIL            Admin e-posta adresi
#   --username USERNAME      Admin kullanıcı adı (varsayılan: admin)
#   --password PASSWORD      Admin şifresi (boş ise otomatik oluşturulur)
#   --cf-api-token TOKEN     Cloudflare API Token
#   --cf-tunnel-token TOKEN  Cloudflare Tunnel Token
#   --google-api-key KEY     Google AI API Key (opsiyonel)
#   --config FILE            YAML config dosyası
#   --quick                  Varsayılan değerlerle hızlı kurulum
#   --dry-run                Simülasyon modu (kurulum yapmaz)
#   --no-interactive         İnteraktif dialog'ları devre dışı bırak
#   --help                   Bu yardım mesajını göster
#   --version                Versiyon bilgisini göster
#
# Geliştirici: Salih TANRISEVEN
# E-posta: salihtanriseven25@gmail.com
# Lisans: MIT
# ============================================================================

set -e  # Hata durumunda çık (set -u KULLANILMIYOR - boş değişken sorunları için)

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================

readonly SCRIPT_VERSION="9.0.0"
readonly SCRIPT_NAME="HaberNexus Installer"
readonly INSTALL_DIR="/opt/habernexus"
readonly LOG_DIR="/var/log/habernexus"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/install_v9_${TIMESTAMP}.log"

# Varsayılan değerler
DEFAULT_DOMAIN="habernexus.com"
DEFAULT_USERNAME="admin"
DEFAULT_DB_NAME="habernexus"
DEFAULT_DB_USER="habernexus_user"

# Kurulum parametreleri
DOMAIN=""
ADMIN_EMAIL=""
ADMIN_USERNAME=""
ADMIN_PASSWORD=""
CLOUDFLARE_API_TOKEN=""
CLOUDFLARE_TUNNEL_TOKEN=""
GOOGLE_API_KEY=""
DB_PASSWORD=""
SECRET_KEY=""

# Modlar
DRY_RUN=false
QUICK_MODE=false
NO_INTERACTIVE=false
CONFIG_FILE=""

# Renkler (terminal desteği varsa)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    NC=''
fi

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

init_logging() {
    mkdir -p "$LOG_DIR" 2>/dev/null || true
    touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/habernexus_install_${TIMESTAMP}.log"
    exec > >(tee -a "$LOG_FILE") 2>&1
}

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
}

log_info() {
    log "INFO" "$*"
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    log "SUCCESS" "$*"
    echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
    log "WARNING" "$*"
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    log "ERROR" "$*"
    echo -e "${RED}✗${NC} $*" >&2
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

is_root() {
    [[ $EUID -eq 0 ]]
}

is_dry_run() {
    [[ "$DRY_RUN" == true ]]
}

has_whiptail() {
    command_exists whiptail
}

has_dialog() {
    command_exists dialog
}

can_use_tui() {
    # TUI kullanılabilir mi kontrol et
    [[ "$NO_INTERACTIVE" != true ]] && (has_whiptail || has_dialog) && [[ -t 0 || -e /dev/tty ]]
}

generate_password() {
    # Güvenli rastgele şifre oluştur
    local length="${1:-16}"
    if command_exists openssl; then
        openssl rand -base64 32 | tr -dc 'a-zA-Z0-9!@#$%' | head -c "$length"
    elif command_exists python3; then
        python3 -c "import secrets, string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '!@#\$%') for _ in range($length)))"
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

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_domain() {
    local domain="$1"
    [[ -z "$domain" ]] && return 1
    # Basit domain regex
    [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]] && return 0
    # localhost veya IP adresi de kabul et
    [[ "$domain" == "localhost" || "$domain" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && return 0
    return 1
}

validate_email() {
    local email="$1"
    [[ -z "$email" ]] && return 1
    [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

validate_username() {
    local username="$1"
    [[ -z "$username" ]] && return 1
    [[ ${#username} -ge 3 && "$username" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]
}

validate_password() {
    local password="$1"
    [[ -z "$password" ]] && return 1
    [[ ${#password} -ge 8 ]]
}

# ============================================================================
# HELP AND VERSION
# ============================================================================

show_help() {
    cat << EOF
${BOLD}${SCRIPT_NAME} v${SCRIPT_VERSION}${NC}

Kullanım: sudo bash install_v9.sh [SEÇENEKLER]

${BOLD}Kurulum Modları:${NC}
  (varsayılan)              İnteraktif mod (Whiptail dialog'ları)
  --quick                   Varsayılan değerlerle hızlı kurulum
  --config FILE             YAML/ENV config dosyasından kurulum

${BOLD}Parametreler:${NC}
  --domain DOMAIN           Domain adı (varsayılan: habernexus.com)
  --email EMAIL             Admin e-posta adresi
  --username USERNAME       Admin kullanıcı adı (varsayılan: admin)
  --password PASSWORD       Admin şifresi (boş ise otomatik)
  --cf-api-token TOKEN      Cloudflare API Token
  --cf-tunnel-token TOKEN   Cloudflare Tunnel Token
  --google-api-key KEY      Google AI API Key (opsiyonel)

${BOLD}Diğer Seçenekler:${NC}
  --dry-run                 Simülasyon modu (kurulum yapmaz)
  --no-interactive          İnteraktif dialog'ları devre dışı bırak
  --help                    Bu yardım mesajını göster
  --version                 Versiyon bilgisini göster

${BOLD}Örnekler:${NC}
  # İnteraktif kurulum
  sudo bash install_v9.sh

  # Hızlı kurulum (varsayılan değerlerle)
  sudo bash install_v9.sh --quick

  # Parametrelerle kurulum
  sudo bash install_v9.sh --domain example.com --email admin@example.com

  # Config dosyasından kurulum
  sudo bash install_v9.sh --config install_config.yml

${BOLD}Daha fazla bilgi:${NC}
  https://github.com/sata2500/habernexus

EOF
}

show_version() {
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

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
            --cf-api-token)
                CLOUDFLARE_API_TOKEN="$2"
                shift 2
                ;;
            --cf-tunnel-token)
                CLOUDFLARE_TUNNEL_TOKEN="$2"
                shift 2
                ;;
            --google-api-key)
                GOOGLE_API_KEY="$2"
                shift 2
                ;;
            --config)
                CONFIG_FILE="$2"
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
            --no-interactive)
                NO_INTERACTIVE=true
                shift
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
                log_error "Bilinmeyen parametre: $1"
                echo "Kullanım için: $0 --help"
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# CONFIG FILE PARSING
# ============================================================================

parse_config_file() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Config dosyası bulunamadı: $config_file"
        return 1
    fi
    
    log_info "Config dosyası okunuyor: $config_file"
    
    # YAML veya ENV formatını destekle
    if [[ "$config_file" == *.yml || "$config_file" == *.yaml ]]; then
        # Basit YAML parser (python gerektirir)
        if command_exists python3; then
            eval "$(python3 << EOF
import yaml
import sys

try:
    with open('$config_file', 'r') as f:
        config = yaml.safe_load(f)
    
    mappings = {
        'domain': 'DOMAIN',
        'admin_email': 'ADMIN_EMAIL',
        'admin_username': 'ADMIN_USERNAME',
        'admin_password': 'ADMIN_PASSWORD',
        'cloudflare_api_token': 'CLOUDFLARE_API_TOKEN',
        'cloudflare_tunnel_token': 'CLOUDFLARE_TUNNEL_TOKEN',
        'google_api_key': 'GOOGLE_API_KEY',
    }
    
    for yaml_key, env_var in mappings.items():
        if yaml_key in config and config[yaml_key]:
            value = str(config[yaml_key]).replace("'", "'\\''")
            print(f"{env_var}='{value}'")
except Exception as e:
    print(f"# Error: {e}", file=sys.stderr)
    sys.exit(1)
EOF
)"
        else
            log_error "YAML config için Python3 gerekli"
            return 1
        fi
    else
        # ENV formatı
        while IFS='=' read -r key value; do
            # Yorum satırlarını ve boş satırları atla
            [[ -z "$key" || "$key" =~ ^# ]] && continue
            # Değeri temizle
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"
            
            case "$key" in
                DOMAIN) DOMAIN="$value" ;;
                ADMIN_EMAIL) ADMIN_EMAIL="$value" ;;
                ADMIN_USERNAME) ADMIN_USERNAME="$value" ;;
                ADMIN_PASSWORD) ADMIN_PASSWORD="$value" ;;
                CLOUDFLARE_API_TOKEN) CLOUDFLARE_API_TOKEN="$value" ;;
                CLOUDFLARE_TUNNEL_TOKEN) CLOUDFLARE_TUNNEL_TOKEN="$value" ;;
                GOOGLE_API_KEY) GOOGLE_API_KEY="$value" ;;
            esac
        done < "$config_file"
    fi
    
    log_success "Config dosyası yüklendi"
    return 0
}


# ============================================================================
# WHIPTAIL DIALOG FUNCTIONS
# ============================================================================

# Whiptail veya dialog kullan
tui_cmd() {
    if has_whiptail; then
        whiptail "$@"
    elif has_dialog; then
        dialog "$@"
    else
        return 1
    fi
}

# Mesaj kutusu
tui_msgbox() {
    local title="$1"
    local message="$2"
    tui_cmd --title "$title" --msgbox "$message" 12 60
}

# Input kutusu
tui_inputbox() {
    local title="$1"
    local message="$2"
    local default="$3"
    local result
    
    # 3>&1 1>&2 2>&3 trick: stdout ve stderr'i değiştir
    result=$(tui_cmd --title "$title" --inputbox "$message" 10 60 "$default" 3>&1 1>&2 2>&3)
    local exit_status=$?
    
    if [[ $exit_status -eq 0 ]]; then
        echo "$result"
        return 0
    else
        return 1
    fi
}

# Şifre kutusu
tui_passwordbox() {
    local title="$1"
    local message="$2"
    local result
    
    result=$(tui_cmd --title "$title" --passwordbox "$message" 10 60 3>&1 1>&2 2>&3)
    local exit_status=$?
    
    if [[ $exit_status -eq 0 ]]; then
        echo "$result"
        return 0
    else
        return 1
    fi
}

# Evet/Hayır kutusu
tui_yesno() {
    local title="$1"
    local message="$2"
    
    tui_cmd --title "$title" --yesno "$message" 10 60
    return $?
}

# Progress gauge
tui_gauge() {
    local title="$1"
    local message="$2"
    local percent="$3"
    
    echo "$percent" | tui_cmd --title "$title" --gauge "$message" 8 60 0
}

# ============================================================================
# INTERACTIVE WIZARD (WHIPTAIL)
# ============================================================================

run_whiptail_wizard() {
    log_info "Whiptail wizard başlatılıyor..."
    
    # Hoşgeldin mesajı
    tui_msgbox "HaberNexus Kurulum Sihirbazı" \
"HaberNexus v${SCRIPT_VERSION} Kurulum Sihirbazına Hoş Geldiniz!

Bu sihirbaz size kurulum için gerekli bilgileri soracak.
Varsayılan değerler parantez içinde gösterilecektir.

Devam etmek için OK'a basın."

    # Domain
    local input
    input=$(tui_inputbox "Domain Yapılandırması" \
"Lütfen domain adınızı girin:

Örnek: example.com, habernexus.com" \
"$DEFAULT_DOMAIN") || input="$DEFAULT_DOMAIN"
    
    if validate_domain "$input"; then
        DOMAIN="$input"
    else
        DOMAIN="$DEFAULT_DOMAIN"
        log_warning "Geçersiz domain, varsayılan kullanılıyor: $DOMAIN"
    fi
    
    # Admin Email
    local default_email="admin@${DOMAIN}"
    input=$(tui_inputbox "Admin E-posta" \
"Lütfen admin e-posta adresinizi girin:

Bu adres sistem bildirimleri için kullanılacak." \
"$default_email") || input="$default_email"
    
    if validate_email "$input"; then
        ADMIN_EMAIL="$input"
    else
        ADMIN_EMAIL="$default_email"
        log_warning "Geçersiz e-posta, varsayılan kullanılıyor: $ADMIN_EMAIL"
    fi
    
    # Admin Username
    input=$(tui_inputbox "Admin Kullanıcı Adı" \
"Lütfen admin kullanıcı adını girin:

En az 3 karakter, harf ile başlamalı." \
"$DEFAULT_USERNAME") || input="$DEFAULT_USERNAME"
    
    if validate_username "$input"; then
        ADMIN_USERNAME="$input"
    else
        ADMIN_USERNAME="$DEFAULT_USERNAME"
        log_warning "Geçersiz kullanıcı adı, varsayılan kullanılıyor: $ADMIN_USERNAME"
    fi
    
    # Admin Password
    input=$(tui_passwordbox "Admin Şifresi" \
"Lütfen admin şifresini girin:

En az 8 karakter olmalı.
Boş bırakırsanız otomatik oluşturulacak.") || input=""
    
    if [[ -n "$input" ]] && validate_password "$input"; then
        ADMIN_PASSWORD="$input"
    else
        ADMIN_PASSWORD=$(generate_password 16)
        log_info "Otomatik şifre oluşturuldu"
    fi
    
    # Cloudflare API Token
    input=$(tui_inputbox "Cloudflare API Token" \
"Cloudflare API Token'ınızı girin:

Token almak için:
1. https://dash.cloudflare.com/profile/api-tokens
2. Create Token → Edit zone DNS template

Boş bırakırsanız demo mod kullanılacak." \
"") || input=""
    
    if [[ -n "$input" ]]; then
        CLOUDFLARE_API_TOKEN="$input"
    else
        CLOUDFLARE_API_TOKEN="demo_api_token_placeholder"
        log_warning "Cloudflare API Token boş - demo mod"
    fi
    
    # Cloudflare Tunnel Token
    input=$(tui_inputbox "Cloudflare Tunnel Token" \
"Cloudflare Tunnel Token'ınızı girin:

Token almak için:
1. https://one.dash.cloudflare.com
2. Networks → Tunnels → Create a Tunnel

Boş bırakırsanız demo mod kullanılacak." \
"") || input=""
    
    if [[ -n "$input" ]]; then
        CLOUDFLARE_TUNNEL_TOKEN="$input"
    else
        CLOUDFLARE_TUNNEL_TOKEN="demo_tunnel_token_placeholder"
        log_warning "Cloudflare Tunnel Token boş - demo mod"
    fi
    
    # Google API Key (opsiyonel)
    input=$(tui_inputbox "Google AI API Key (Opsiyonel)" \
"Google AI API Key'inizi girin:

Bu opsiyoneldir, AI özelliklerini kullanmak
istiyorsanız girin.

Atlamak için boş bırakın." \
"") || input=""
    
    GOOGLE_API_KEY="$input"
    
    # Otomatik değerler
    DB_PASSWORD=$(generate_password 20)
    SECRET_KEY=$(generate_secret_key)
    
    # Özet göster
    if tui_yesno "Yapılandırma Özeti" \
"Aşağıdaki yapılandırma ile kurulum yapılacak:

Domain:        $DOMAIN
E-posta:       $ADMIN_EMAIL
Kullanıcı:     $ADMIN_USERNAME
Cloudflare:    $([ -n "$CLOUDFLARE_API_TOKEN" ] && echo 'Yapılandırıldı' || echo 'Demo mod')

Devam etmek istiyor musunuz?"; then
        log_success "Yapılandırma onaylandı"
        return 0
    else
        log_warning "Kurulum iptal edildi"
        exit 0
    fi
}

# ============================================================================
# FALLBACK WIZARD (BASIC READ)
# ============================================================================

run_basic_wizard() {
    log_info "Basit wizard başlatılıyor..."
    
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  HaberNexus v${SCRIPT_VERSION} - Kurulum Sihirbazı${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Lütfen kurulum için gerekli bilgileri girin."
    echo "Varsayılan değerler köşeli parantez içinde gösterilir."
    echo "Boş bırakırsanız varsayılan değer kullanılır."
    echo ""
    
    # Domain
    echo -ne "${CYAN}→${NC} Domain adı [${DEFAULT_DOMAIN}]: "
    if read -r input </dev/tty 2>/dev/null; then
        DOMAIN="${input:-$DEFAULT_DOMAIN}"
    else
        DOMAIN="$DEFAULT_DOMAIN"
    fi
    
    if ! validate_domain "$DOMAIN"; then
        log_warning "Geçersiz domain, varsayılan kullanılıyor"
        DOMAIN="$DEFAULT_DOMAIN"
    fi
    log_success "Domain: $DOMAIN"
    
    # Admin Email
    local default_email="admin@${DOMAIN}"
    echo -ne "${CYAN}→${NC} Admin e-posta [${default_email}]: "
    if read -r input </dev/tty 2>/dev/null; then
        ADMIN_EMAIL="${input:-$default_email}"
    else
        ADMIN_EMAIL="$default_email"
    fi
    
    if ! validate_email "$ADMIN_EMAIL"; then
        log_warning "Geçersiz e-posta, varsayılan kullanılıyor"
        ADMIN_EMAIL="$default_email"
    fi
    log_success "E-posta: $ADMIN_EMAIL"
    
    # Admin Username
    echo -ne "${CYAN}→${NC} Admin kullanıcı adı [${DEFAULT_USERNAME}]: "
    if read -r input </dev/tty 2>/dev/null; then
        ADMIN_USERNAME="${input:-$DEFAULT_USERNAME}"
    else
        ADMIN_USERNAME="$DEFAULT_USERNAME"
    fi
    
    if ! validate_username "$ADMIN_USERNAME"; then
        log_warning "Geçersiz kullanıcı adı, varsayılan kullanılıyor"
        ADMIN_USERNAME="$DEFAULT_USERNAME"
    fi
    log_success "Kullanıcı: $ADMIN_USERNAME"
    
    # Admin Password
    echo -ne "${CYAN}→${NC} Admin şifresi (boş=otomatik): "
    if read -rs input </dev/tty 2>/dev/null; then
        echo ""
        ADMIN_PASSWORD="$input"
    else
        ADMIN_PASSWORD=""
    fi
    
    if [[ -z "$ADMIN_PASSWORD" ]] || ! validate_password "$ADMIN_PASSWORD"; then
        ADMIN_PASSWORD=$(generate_password 16)
        echo -e "${YELLOW}⚠${NC} Otomatik şifre oluşturuldu: ${BOLD}${ADMIN_PASSWORD}${NC}"
        echo -e "${YELLOW}⚠${NC} Bu şifreyi kaydedin!"
    else
        log_success "Şifre ayarlandı"
    fi
    
    # Cloudflare API Token
    echo ""
    echo -e "${CYAN}Cloudflare Yapılandırması${NC}"
    echo "API Token almak için: https://dash.cloudflare.com/profile/api-tokens"
    echo -ne "${CYAN}→${NC} Cloudflare API Token (boş=demo): "
    if read -rs input </dev/tty 2>/dev/null; then
        echo ""
        CLOUDFLARE_API_TOKEN="${input:-demo_api_token_placeholder}"
    else
        CLOUDFLARE_API_TOKEN="demo_api_token_placeholder"
    fi
    
    if [[ "$CLOUDFLARE_API_TOKEN" == "demo_api_token_placeholder" ]]; then
        log_warning "Demo mod kullanılacak"
    else
        log_success "Cloudflare API Token alındı"
    fi
    
    # Cloudflare Tunnel Token
    echo "Tunnel Token almak için: https://one.dash.cloudflare.com → Networks → Tunnels"
    echo -ne "${CYAN}→${NC} Cloudflare Tunnel Token (boş=demo): "
    if read -rs input </dev/tty 2>/dev/null; then
        echo ""
        CLOUDFLARE_TUNNEL_TOKEN="${input:-demo_tunnel_token_placeholder}"
    else
        CLOUDFLARE_TUNNEL_TOKEN="demo_tunnel_token_placeholder"
    fi
    
    if [[ "$CLOUDFLARE_TUNNEL_TOKEN" == "demo_tunnel_token_placeholder" ]]; then
        log_warning "Demo mod kullanılacak"
    else
        log_success "Cloudflare Tunnel Token alındı"
    fi
    
    # Google API Key
    echo ""
    echo -ne "${CYAN}→${NC} Google AI API Key (opsiyonel, Enter ile atla): "
    if read -rs input </dev/tty 2>/dev/null; then
        echo ""
        GOOGLE_API_KEY="$input"
    else
        GOOGLE_API_KEY=""
    fi
    
    if [[ -n "$GOOGLE_API_KEY" ]]; then
        log_success "Google AI API Key alındı"
    else
        log_info "Google AI API Key atlandı"
    fi
    
    # Otomatik değerler
    DB_PASSWORD=$(generate_password 20)
    SECRET_KEY=$(generate_secret_key)
    
    log_success "Veritabanı şifresi otomatik oluşturuldu"
    log_success "Django secret key otomatik oluşturuldu"
    
    # Özet
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Yapılandırma Özeti${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Domain:        ${GREEN}${DOMAIN}${NC}"
    echo -e "  E-posta:       ${GREEN}${ADMIN_EMAIL}${NC}"
    echo -e "  Kullanıcı:     ${GREEN}${ADMIN_USERNAME}${NC}"
    echo -e "  Şifre:         ${YELLOW}${ADMIN_PASSWORD}${NC}"
    echo -e "  Cloudflare:    ${GREEN}Yapılandırıldı${NC}"
    echo ""
    
    echo -ne "${YELLOW}⚠${NC} Bu yapılandırma ile devam etmek istiyor musunuz? [E/h]: "
    local confirm
    if read -r confirm </dev/tty 2>/dev/null; then
        if [[ "$confirm" =~ ^[HhNn]$ ]]; then
            log_warning "Kurulum iptal edildi"
            exit 0
        fi
    fi
    
    log_success "Yapılandırma onaylandı"
    return 0
}


# ============================================================================
# QUICK SETUP (VARSAYILAN DEĞERLERLE)
# ============================================================================

run_quick_setup() {
    log_info "Hızlı kurulum modu - varsayılan değerler kullanılıyor..."
    
    # Varsayılan değerleri ayarla (eğer zaten ayarlanmamışsa)
    DOMAIN="${DOMAIN:-$DEFAULT_DOMAIN}"
    ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${DOMAIN}}"
    ADMIN_USERNAME="${ADMIN_USERNAME:-$DEFAULT_USERNAME}"
    ADMIN_PASSWORD="${ADMIN_PASSWORD:-$(generate_password 16)}"
    CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-demo_api_token_placeholder}"
    CLOUDFLARE_TUNNEL_TOKEN="${CLOUDFLARE_TUNNEL_TOKEN:-demo_tunnel_token_placeholder}"
    DB_PASSWORD=$(generate_password 20)
    SECRET_KEY=$(generate_secret_key)
    
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Hızlı Kurulum - Yapılandırma${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Domain:        ${GREEN}${DOMAIN}${NC}"
    echo -e "  E-posta:       ${GREEN}${ADMIN_EMAIL}${NC}"
    echo -e "  Kullanıcı:     ${GREEN}${ADMIN_USERNAME}${NC}"
    echo -e "  Şifre:         ${YELLOW}${ADMIN_PASSWORD}${NC}"
    echo ""
    echo -e "${YELLOW}⚠${NC} Bu şifreyi kaydedin!"
    echo ""
    
    log_success "Hızlı kurulum yapılandırması tamamlandı"
}

# ============================================================================
# SYSTEM CHECKS
# ============================================================================

check_system_requirements() {
    log_info "Sistem gereksinimleri kontrol ediliyor..."
    
    local errors=0
    
    # Root kontrolü (dry-run modunda atla)
    if ! is_root && ! is_dry_run; then
        log_error "Bu script root yetkisi gerektirir. 'sudo' ile çalıştırın."
        ((errors++))
    elif is_dry_run; then
        log_info "[DRY RUN] Root kontrolü atlandı"
    else
        log_success "Root yetkisi: OK"
    fi
    
    # OS kontrolü
    if [[ ! -f /etc/os-release ]]; then
        log_error "Desteklenmeyen işletim sistemi"
        ((errors++))
    else
        source /etc/os-release
        case "$ID" in
            ubuntu|debian)
                log_success "İşletim sistemi: $PRETTY_NAME"
                ;;
            *)
                log_warning "Test edilmemiş işletim sistemi: $PRETTY_NAME"
                ;;
        esac
    fi
    
    # RAM kontrolü
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $total_ram -lt 1500 ]]; then
        log_warning "Yetersiz RAM: ${total_ram}MB (önerilen: 2GB+)"
    else
        log_success "RAM: ${total_ram}MB"
    fi
    
    # Disk kontrolü
    local free_disk=$(df -m /opt 2>/dev/null | awk 'NR==2{print $4}' || echo "0")
    if [[ $free_disk -lt 10000 ]]; then
        log_warning "Düşük disk alanı: ${free_disk}MB (önerilen: 20GB+)"
    else
        log_success "Boş disk: ${free_disk}MB"
    fi
    
    # İnternet kontrolü (dry-run modunda atla)
    if is_dry_run; then
        log_info "[DRY RUN] İnternet kontrolü atlandı"
    elif ping -c 1 -W 5 8.8.8.8 &>/dev/null || curl -s --max-time 5 https://google.com &>/dev/null; then
        log_success "İnternet bağlantısı: OK"
    else
        log_warning "İnternet bağlantısı kontrol edilemedi (kurulum devam edecek)"
    fi
    
    if [[ $errors -gt 0 ]]; then
        log_error "Sistem gereksinimleri karşılanmıyor ($errors hata)"
        return 1
    fi
    
    log_success "Sistem gereksinimleri karşılanıyor"
    return 0
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

install_dependencies() {
    log_info "Sistem bağımlılıkları yükleniyor..."
    
    if is_dry_run; then
        log_info "[DRY RUN] apt-get update && apt-get install ..."
        return 0
    fi
    
    apt-get update -qq
    apt-get install -y -qq \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        git \
        whiptail \
        jq \
        python3 \
        python3-pip \
        python3-yaml \
        > /dev/null 2>&1
    
    log_success "Sistem bağımlılıkları yüklendi"
}

install_docker() {
    log_info "Docker kontrol ediliyor..."
    
    if command_exists docker; then
        local docker_version=$(docker --version | grep -oP '\d+\.\d+\.\d+' | head -1)
        log_success "Docker zaten kurulu: $docker_version"
        return 0
    fi
    
    log_info "Docker yükleniyor..."
    
    if is_dry_run; then
        log_info "[DRY RUN] Docker kurulumu simüle edildi"
        return 0
    fi
    
    # Docker GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Docker repo
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
    
    # Docker servisini başlat
    systemctl enable docker
    systemctl start docker
    
    log_success "Docker yüklendi"
}

clone_repository() {
    log_info "Repository klonlanıyor..."
    
    if is_dry_run; then
        log_info "[DRY RUN] git clone simüle edildi"
        return 0
    fi
    
    # Mevcut kurulumu yedekle
    if [[ -d "$INSTALL_DIR" ]]; then
        local backup_dir="${INSTALL_DIR}_backup_${TIMESTAMP}"
        log_info "Mevcut kurulum yedekleniyor: $backup_dir"
        mv "$INSTALL_DIR" "$backup_dir"
    fi
    
    # Klonla
    git clone https://github.com/sata2500/habernexus.git "$INSTALL_DIR" > /dev/null 2>&1
    
    log_success "Repository klonlandı: $INSTALL_DIR"
}

create_env_file() {
    log_info ".env dosyası oluşturuluyor..."
    
    if is_dry_run; then
        log_info "[DRY RUN] .env dosyası simüle edildi"
        return 0
    fi
    
    cat > "${INSTALL_DIR}/.env" << EOF
# HaberNexus Environment Configuration
# Generated: $(date)
# Version: ${SCRIPT_VERSION}

# Domain
DOMAIN=${DOMAIN}
ALLOWED_HOSTS=${DOMAIN},www.${DOMAIN},localhost,127.0.0.1

# Django
DEBUG=False
SECRET_KEY=${SECRET_KEY}

# Database
DB_NAME=${DEFAULT_DB_NAME}
DB_USER=${DEFAULT_DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DATABASE_URL=postgresql://${DEFAULT_DB_USER}:${DB_PASSWORD}@postgres:5432/${DEFAULT_DB_NAME}

# Redis
REDIS_URL=redis://redis:6379/0
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# Admin
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# Cloudflare
CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}

# Google AI (opsiyonel)
GOOGLE_API_KEY=${GOOGLE_API_KEY}

# Timezone
TZ=Europe/Istanbul
EOF

    chmod 600 "${INSTALL_DIR}/.env"
    log_success ".env dosyası oluşturuldu"
}

create_caddy_config() {
    log_info "Caddy yapılandırması oluşturuluyor..."
    
    if is_dry_run; then
        log_info "[DRY RUN] Caddy config simüle edildi"
        return 0
    fi
    
    mkdir -p "${INSTALL_DIR}/caddy"
    
    cat > "${INSTALL_DIR}/caddy/Caddyfile" << EOF
# HaberNexus Caddy Configuration
# Domain: ${DOMAIN}

${DOMAIN} {
    reverse_proxy app:8000

    # Logging
    log {
        output file /var/log/caddy/access.log
        format json
    }

    # Security headers
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
        Referrer-Policy strict-origin-when-cross-origin
    }

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

    # Health check
    handle /health {
        respond "OK" 200
    }
}
EOF

    log_success "Caddy yapılandırması oluşturuldu"
}

start_services() {
    log_info "Servisler başlatılıyor..."
    
    if is_dry_run; then
        log_info "[DRY RUN] docker compose up simüle edildi"
        return 0
    fi
    
    cd "$INSTALL_DIR"
    
    # Docker Compose ile başlat
    docker compose pull > /dev/null 2>&1 || true
    docker compose build --quiet > /dev/null 2>&1
    docker compose up -d > /dev/null 2>&1
    
    log_success "Servisler başlatıldı"
}

wait_for_services() {
    log_info "Servislerin hazır olması bekleniyor..."
    
    if is_dry_run; then
        log_info "[DRY RUN] Servis bekleme simüle edildi"
        return 0
    fi
    
    local max_wait=60
    local waited=0
    
    while [[ $waited -lt $max_wait ]]; do
        if docker compose -f "${INSTALL_DIR}/docker-compose.yml" ps | grep -q "healthy\|running"; then
            log_success "Servisler hazır"
            return 0
        fi
        sleep 2
        ((waited+=2))
        echo -ne "\r${CYAN}→${NC} Bekleniyor... ${waited}s"
    done
    
    echo ""
    log_warning "Servisler henüz tam hazır değil, kontrol edin: docker compose ps"
}

show_completion_message() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ HaberNexus v${SCRIPT_VERSION} Kurulumu Tamamlandı!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}Erişim Bilgileri:${NC}"
    echo -e "  Web Sitesi:    https://${DOMAIN}"
    echo -e "  Admin Panel:   https://${DOMAIN}/admin"
    echo ""
    echo -e "${BOLD}Admin Giriş Bilgileri:${NC}"
    echo -e "  Kullanıcı:     ${GREEN}${ADMIN_USERNAME}${NC}"
    echo -e "  Şifre:         ${YELLOW}${ADMIN_PASSWORD}${NC}"
    echo -e "  E-posta:       ${GREEN}${ADMIN_EMAIL}${NC}"
    echo ""
    echo -e "${BOLD}Yönetim Komutları:${NC}"
    echo -e "  Durum:         cd ${INSTALL_DIR} && docker compose ps"
    echo -e "  Loglar:        cd ${INSTALL_DIR} && docker compose logs -f"
    echo -e "  Yeniden Başlat: cd ${INSTALL_DIR} && docker compose restart"
    echo ""
    echo -e "${YELLOW}⚠ ÖNEMLİ: Admin şifresini güvenli bir yere kaydedin!${NC}"
    echo ""
    echo -e "Log dosyası: ${LOG_FILE}"
    echo ""
}

# ============================================================================
# MAIN FUNCTION
# ============================================================================

do_install() {
    # Banner
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  HaberNexus v${SCRIPT_VERSION} - Kurulum Scripti${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Logging başlat
    init_logging
    log_info "Kurulum başlatılıyor..."
    log_info "Log dosyası: $LOG_FILE"
    
    # Dry run modu
    if is_dry_run; then
        log_warning "DRY RUN MODU - Gerçek kurulum yapılmayacak"
    fi
    
    # Sistem kontrolü
    if ! check_system_requirements; then
        log_error "Sistem gereksinimleri karşılanmıyor"
        exit 1
    fi
    
    # Config dosyası varsa oku
    if [[ -n "$CONFIG_FILE" ]]; then
        if ! parse_config_file "$CONFIG_FILE"; then
            log_error "Config dosyası okunamadı"
            exit 1
        fi
    fi
    
    # Yapılandırma modu seç
    if [[ "$QUICK_MODE" == true ]]; then
        # Hızlı kurulum
        run_quick_setup
    elif [[ -n "$DOMAIN" && -n "$ADMIN_EMAIL" ]]; then
        # Komut satırı parametreleri ile
        log_info "Komut satırı parametreleri kullanılıyor..."
        ADMIN_USERNAME="${ADMIN_USERNAME:-$DEFAULT_USERNAME}"
        ADMIN_PASSWORD="${ADMIN_PASSWORD:-$(generate_password 16)}"
        CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-demo_api_token_placeholder}"
        CLOUDFLARE_TUNNEL_TOKEN="${CLOUDFLARE_TUNNEL_TOKEN:-demo_tunnel_token_placeholder}"
        DB_PASSWORD=$(generate_password 20)
        SECRET_KEY=$(generate_secret_key)
    elif can_use_tui; then
        # Whiptail wizard
        run_whiptail_wizard
    elif [[ -e /dev/tty ]]; then
        # Basit read wizard
        run_basic_wizard
    else
        # Hiçbir interaktif mod çalışmıyor, quick mode'a geç
        log_warning "İnteraktif mod kullanılamıyor, varsayılan değerlerle devam ediliyor"
        run_quick_setup
    fi
    
    # Kurulum adımları
    echo ""
    log_info "Kurulum başlıyor..."
    echo ""
    
    install_dependencies
    install_docker
    clone_repository
    create_env_file
    create_caddy_config
    start_services
    wait_for_services
    
    # Tamamlandı
    show_completion_message
}

# ============================================================================
# ENTRY POINT
# ============================================================================

# Argümanları parse et
parse_arguments "$@"

# Kurulumu çalıştır (fonksiyon içinde - curl | bash koruması)
do_install
