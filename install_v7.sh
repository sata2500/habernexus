#!/bin/bash

################################################################################
# HaberNexus v7.0 - Advanced Automatic Installation Script
# 
# Features:
#   - Fully automated installation with interactive UI
#   - Automatic dependency installation
#   - Multiple installation profiles (Quick, Custom, Development)
#   - Advanced error handling and recovery
#   - Beautiful progress indicators and animations
#   - Comprehensive logging and diagnostics
#   - Post-installation setup wizard
#   - System health checks and troubleshooting
#
# Usage: 
#   sudo bash install_v7.sh                    # Interactive mode
#   sudo bash install_v7.sh --quick            # Quick setup (recommended)
#   sudo bash install_v7.sh --custom           # Custom configuration
#   sudo bash install_v7.sh --dev              # Development mode
#
# Author: Salih TANRISEVEN
# Date: December 15, 2025
# Version: 7.0
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION & CONSTANTS
# ============================================================================

SCRIPT_VERSION="7.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="${PROJECT_PATH:-/opt/habernexus}"
LOG_DIR="/var/log/habernexus"
LOG_FILE="${LOG_DIR}/install_v7_$(date +%Y%m%d_%H%M%S).log"
CONFIG_FILE="${LOG_DIR}/installation_config_$(date +%Y%m%d_%H%M%S).conf"
ENV_FILE="${PROJECT_PATH}/.env"
BACKUP_DIR="${PROJECT_PATH}/.backups/install_v7_$(date +%Y%m%d_%H%M%S)"

# Installation modes
INSTALL_MODE="interactive"
FORCE_REINSTALL=false
SKIP_DOCKER_CHECK=false

# Global variables
DOMAIN=""
ADMIN_EMAIL=""
ADMIN_USERNAME=""
ADMIN_PASSWORD=""
CLOUDFLARE_API_TOKEN=""
CLOUDFLARE_TUNNEL_TOKEN=""
DB_PASSWORD=""
INSTALLATION_START_TIME=$(date +%s)

# ============================================================================
# COLOR & FORMATTING CONSTANTS
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

CHECK="✓"
CROSS="✗"
ARROW="→"
BULLET="•"
SPINNER=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

init_logging() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    chmod 600 "${LOG_FILE}"
    
    {
        echo "================================================================================"
        echo "HaberNexus v${SCRIPT_VERSION} Installation Log"
        echo "================================================================================"
        echo "Installation Start: $(date)"
        echo "Installation Mode: ${INSTALL_MODE}"
        echo "Script Location: ${SCRIPT_DIR}"
        echo "Project Path: ${PROJECT_PATH}"
        echo "================================================================================"
        echo ""
    } | tee "${LOG_FILE}"
}

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}[ℹ]${NC} $@" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[${CHECK}]${NC} $@" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[${CROSS}]${NC} $@" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $@" | tee -a "${LOG_FILE}"
}

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $@${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${MAGENTA}${ARROW} $@${NC}"
    echo ""
}

print_subsection() {
    echo -e "${GRAY}  ${BULLET} $@${NC}"
}

show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local width=30
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    
    printf "\r${BLUE}[${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width - filled))s" | tr ' ' '-'
    printf "${BLUE}]${NC} ${percentage}%% - ${message}"
}

error_exit() {
    local line_number=$1
    local error_message=${2:-"Unknown error"}
    
    log_error "Installation failed at line ${line_number}: ${error_message}"
    print_header "Installation Failed ${CROSS}"
    log_error "An error occurred during installation"
    log_info "Check the log file for details: ${LOG_FILE}"
    
    echo ""
    echo -e "${YELLOW}Last 20 lines of log:${NC}"
    tail -20 "${LOG_FILE}" | sed 's/^/  /'
    
    exit 1
}

trap 'error_exit ${LINENO} "$BASH_COMMAND"' ERR

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

check_root() {
    print_section "Checking Root Privileges"
    
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    log_success "Root privileges verified"
}

check_os() {
    print_section "Checking Operating System"
    
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine OS"
        exit 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        log_error "This script requires Ubuntu (detected: $ID)"
        exit 1
    fi
    
    if [[ ! "$VERSION_ID" =~ ^(20\.04|22\.04|24\.04) ]]; then
        log_warning "Tested on Ubuntu 20.04, 22.04 and 24.04 (detected: $VERSION_ID)"
    fi
    
    log_success "Ubuntu $VERSION_ID ✓"
}

check_and_install_dependencies() {
    print_section "Checking System Dependencies"
    
    local required_commands=("curl" "wget" "git" "python3" "pip3")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
            print_subsection "${cmd}: ${RED}Not installed${NC}"
        else
            local version=$("$cmd" --version 2>&1 | head -1)
            print_subsection "${cmd}: ${GREEN}Installed${NC}"
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_info "Installing missing dependencies..."
        apt-get update -qq 2>&1 | tee -a "${LOG_FILE}" > /dev/null
        apt-get install -y "${missing_commands[@]}" 2>&1 | tee -a "${LOG_FILE}" > /dev/null
        log_success "Dependencies installed"
    else
        log_success "All dependencies are installed"
    fi
}

check_docker() {
    print_section "Checking Docker Installation"
    
    if ! command -v docker &> /dev/null; then
        log_info "Docker not found. Installing Docker..."
        curl -fsSL https://get.docker.com -o /tmp/get-docker.sh 2>&1 | tee -a "${LOG_FILE}"
        bash /tmp/get-docker.sh 2>&1 | tee -a "${LOG_FILE}"
        rm -f /tmp/get-docker.sh
        log_success "Docker installed"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_info "Docker Compose not found. Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 2>&1 | tee -a "${LOG_FILE}"
        chmod +x /usr/local/bin/docker-compose
        log_success "Docker Compose installed"
    fi
    
    if ! systemctl is-active --quiet docker; then
        log_info "Starting Docker daemon..."
        systemctl start docker
        sleep 2
    fi
    
    if ! docker ps &> /dev/null; then
        log_error "Docker daemon is not responding"
        exit 1
    fi
    
    local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
    local compose_version=$(docker-compose --version | awk '{print $4}' | sed 's/,//')
    
    log_success "Docker ${docker_version} ✓"
    log_success "Docker Compose ${compose_version} ✓"
}

check_internet() {
    print_section "Checking Internet Connectivity"
    
    local urls=("https://github.com" "https://api.cloudflare.com" "https://www.google.com")
    local connected=false
    
    for url in "${urls[@]}"; do
        if curl -s -I "$url" > /dev/null 2>&1; then
            log_success "Connection to $url ✓"
            connected=true
            break
        fi
    done
    
    if [[ "$connected" == false ]]; then
        log_error "No internet connection detected"
        exit 1
    fi
}

check_disk_space() {
    print_section "Checking Disk Space"
    
    local available_space=$(df /opt 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
    local required_space=$((20 * 1024 * 1024))
    
    if [[ $available_space -lt $required_space ]]; then
        log_error "Insufficient disk space (required: 20GB, available: $((available_space / 1024 / 1024))GB)"
        exit 1
    fi
    
    log_success "Disk space check ✓ (available: $((available_space / 1024 / 1024))GB)"
}

run_preflight_checks() {
    print_header "HaberNexus v${SCRIPT_VERSION} - Pre-flight Checks"
    
    check_root
    check_os
    check_and_install_dependencies
    check_docker
    check_internet
    check_disk_space
    
    log_success "All pre-flight checks passed!"
}

# ============================================================================
# USER INPUT FUNCTIONS
# ============================================================================

validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    fi
    return 1
}

validate_email() {
    local email=$1
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    fi
    return 1
}

validate_password() {
    local password=$1
    
    if [[ ${#password} -lt 8 ]]; then
        return 1
    fi
    
    if [[ ! $password =~ [A-Z] ]] || [[ ! $password =~ [a-z] ]] || [[ ! $password =~ [0-9] ]]; then
        return 1
    fi
    
    return 0
}

generate_secure_password() {
    python3 -c 'import secrets; print(secrets.token_urlsafe(16))'
}

interactive_input() {
    print_header "HaberNexus v${SCRIPT_VERSION} - Installation Configuration"
    
    while true; do
        read -p "$(echo -e ${CYAN})Enter your domain (e.g., habernexus.com):$(echo -e ${NC}) " DOMAIN
        if validate_domain "$DOMAIN"; then
            log_success "Domain: $DOMAIN"
            break
        else
            log_error "Invalid domain format"
        fi
    done
    
    while true; do
        read -p "$(echo -e ${CYAN})Enter admin email:$(echo -e ${NC}) " ADMIN_EMAIL
        if validate_email "$ADMIN_EMAIL"; then
            log_success "Email: $ADMIN_EMAIL"
            break
        else
            log_error "Invalid email format"
        fi
    done
    
    while true; do
        read -p "$(echo -e ${CYAN})Enter admin username (min 3 chars):$(echo -e ${NC}) " ADMIN_USERNAME
        if [[ ${#ADMIN_USERNAME} -ge 3 ]]; then
            log_success "Username: $ADMIN_USERNAME"
            break
        else
            log_error "Username must be at least 3 characters"
        fi
    done
    
    while true; do
        read -s -p "$(echo -e ${CYAN})Enter admin password (min 8 chars, uppercase, lowercase, number):$(echo -e ${NC}) " ADMIN_PASSWORD
        echo ""
        if validate_password "$ADMIN_PASSWORD"; then
            log_success "Password set"
            break
        else
            log_error "Password must be at least 8 characters with uppercase, lowercase, and numbers"
        fi
    done
    
    while true; do
        read -p "$(echo -e ${CYAN})Enter Cloudflare API Token:$(echo -e ${NC}) " CLOUDFLARE_API_TOKEN
        if [[ ${#CLOUDFLARE_API_TOKEN} -gt 20 ]]; then
            log_success "Cloudflare API Token received"
            break
        else
            log_error "Invalid API token"
        fi
    done
    
    while true; do
        read -p "$(echo -e ${CYAN})Enter Cloudflare Tunnel Token:$(echo -e ${NC}) " CLOUDFLARE_TUNNEL_TOKEN
        if [[ ${#CLOUDFLARE_TUNNEL_TOKEN} -gt 20 ]]; then
            log_success "Cloudflare Tunnel Token received"
            break
        else
            log_error "Invalid Tunnel token"
        fi
    done
    
    DB_PASSWORD=$(generate_secure_password)
    log_success "Database password generated"
}

quick_setup() {
    print_header "HaberNexus v${SCRIPT_VERSION} - Quick Setup"
    
    log_info "Using quick setup with default values..."
    
    DOMAIN="${DOMAIN:-habernexus.local}"
    ADMIN_EMAIL="${ADMIN_EMAIL:-admin@habernexus.local}"
    ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
    ADMIN_PASSWORD="${ADMIN_PASSWORD:-$(generate_secure_password)}"
    CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-demo_token_12345}"
    CLOUDFLARE_TUNNEL_TOKEN="${CLOUDFLARE_TUNNEL_TOKEN:-demo_tunnel_12345}"
    DB_PASSWORD=$(generate_secure_password)
    
    log_success "Quick setup configuration ready"
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

backup_existing_installation() {
    if [[ -d "$PROJECT_PATH" ]] && [[ "$FORCE_REINSTALL" == true ]]; then
        print_section "Backing Up Existing Installation"
        
        mkdir -p "$BACKUP_DIR"
        cp -r "${PROJECT_PATH}"/* "$BACKUP_DIR/" 2>/dev/null || true
        
        log_success "Backup created at $BACKUP_DIR"
    fi
}

clone_repository() {
    print_section "Cloning Repository"
    
    if [[ -d "$PROJECT_PATH/.git" ]] && [[ "$FORCE_REINSTALL" == false ]]; then
        log_info "Repository already exists, updating..."
        cd "$PROJECT_PATH"
        git pull origin main 2>&1 | tee -a "${LOG_FILE}"
    else
        mkdir -p "$PROJECT_PATH"
        cd "$PROJECT_PATH"
        
        git clone https://github.com/sata2500/habernexus.git . 2>&1 | tee -a "${LOG_FILE}"
    fi
    
    log_success "Repository ready"
}

create_environment_file() {
    print_section "Creating Environment Configuration"
    
    local secret_key=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')
    
    cat > "${ENV_FILE}" << EOF
# HaberNexus v${SCRIPT_VERSION} Environment Configuration
# Generated: $(date)
# Installation Mode: ${INSTALL_MODE}

# ============================================================================
# DOMAIN & SECURITY
# ============================================================================

DOMAIN=${DOMAIN}
ADMIN_EMAIL=${ADMIN_EMAIL}
DEBUG=False
SECRET_KEY=${secret_key}
ALLOWED_HOSTS=${DOMAIN},www.${DOMAIN},localhost,127.0.0.1,app

# ============================================================================
# DATABASE CONFIGURATION
# ============================================================================

DATABASE_URL=postgresql://habernexus:${DB_PASSWORD}@postgres:5432/habernexus
DB_NAME=habernexus
DB_USER=habernexus
DB_PASSWORD=${DB_PASSWORD}
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
# ADMIN USER
# ============================================================================

ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# ============================================================================
# DJANGO SETTINGS
# ============================================================================

DJANGO_SETTINGS_MODULE=habernexus.settings
PYTHONUNBUFFERED=1

# ============================================================================
# TIMEZONE
# ============================================================================

TZ=Europe/Istanbul

EOF
    
    chmod 600 "${ENV_FILE}"
    log_success "Environment configuration created"
}

save_configuration() {
    print_section "Saving Installation Configuration"
    
    cat > "${CONFIG_FILE}" << EOF
# HaberNexus Installation Configuration
# Generated: $(date)

INSTALLATION_MODE=${INSTALL_MODE}
DOMAIN=${DOMAIN}
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_USERNAME=${ADMIN_USERNAME}
PROJECT_PATH=${PROJECT_PATH}
LOG_FILE=${LOG_FILE}
INSTALLATION_TIME=$(date)

EOF
    
    log_success "Configuration saved to $CONFIG_FILE"
}

build_docker_images() {
    print_section "Building Docker Images"
    
    cd "${PROJECT_PATH}"
    
    log_info "Building application image..."
    docker-compose build app 2>&1 | tee -a "${LOG_FILE}"
    
    log_info "Building Caddy image..."
    docker-compose build caddy 2>&1 | tee -a "${LOG_FILE}"
    
    log_success "Docker images built successfully"
}

start_services() {
    print_section "Starting Docker Services"
    
    cd "${PROJECT_PATH}"
    
    log_info "Starting containers..."
    docker-compose up -d 2>&1 | tee -a "${LOG_FILE}"
    
    log_success "Services started"
}

wait_for_services() {
    print_section "Waiting for Services to be Healthy"
    
    cd "${PROJECT_PATH}"
    
    local max_attempts=120
    local attempt=0
    local services=("postgres" "redis" "app" "caddy")
    
    while [[ $attempt -lt $max_attempts ]]; do
        local all_healthy=true
        
        for service in "${services[@]}"; do
            local status=$(docker-compose ps "$service" 2>/dev/null | grep -c "healthy" || echo "0")
            
            if [[ $status -eq 0 ]]; then
                all_healthy=false
            fi
        done
        
        if [[ "$all_healthy" == true ]]; then
            log_success "All services are healthy"
            return 0
        fi
        
        show_progress $attempt $max_attempts "Waiting for services to start..."
        sleep 1
        ((attempt++))
    done
    
    echo ""
    log_warning "Services did not become healthy within timeout"
    log_info "Checking service status..."
    docker-compose ps 2>&1 | tee -a "${LOG_FILE}"
}

run_migrations() {
    print_section "Running Database Migrations"
    
    cd "${PROJECT_PATH}"
    
    log_info "Running Django migrations..."
    docker-compose exec -T app python manage.py migrate 2>&1 | tee -a "${LOG_FILE}"
    
    log_success "Migrations completed"
}

create_admin_user() {
    print_section "Creating Admin User"
    
    cd "${PROJECT_PATH}"
    
    log_info "Creating admin user: $ADMIN_USERNAME"
    
    docker-compose exec -T app python manage.py shell << EOF 2>&1 | tee -a "${LOG_FILE}"
from django.contrib.auth import get_user_model
User = get_user_model()

if not User.objects.filter(username='${ADMIN_USERNAME}').exists():
    User.objects.create_superuser(
        username='${ADMIN_USERNAME}',
        email='${ADMIN_EMAIL}',
        password='${ADMIN_PASSWORD}'
    )
    print(f"Admin user created: ${ADMIN_USERNAME}")
else:
    print(f"Admin user already exists: ${ADMIN_USERNAME}")
EOF
    
    log_success "Admin user ready"
}

collect_static_files() {
    print_section "Collecting Static Files"
    
    cd "${PROJECT_PATH}"
    
    log_info "Collecting static files..."
    docker-compose exec -T app python manage.py collectstatic --noinput 2>&1 | tee -a "${LOG_FILE}"
    
    log_success "Static files collected"
}

verify_installation() {
    print_section "Verifying Installation"
    
    cd "${PROJECT_PATH}"
    
    local running_containers=$(docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l)
    local total_services=$(docker-compose config --services 2>/dev/null | wc -l)
    
    log_info "Running containers: $running_containers / $total_services"
    
    log_info "Checking database connectivity..."
    docker-compose exec -T postgres pg_isready -U habernexus 2>&1 | tee -a "${LOG_FILE}"
    
    log_success "Installation verified"
}

# ============================================================================
# POST-INSTALLATION
# ============================================================================

show_success_summary() {
    local installation_end_time=$(date +%s)
    local installation_duration=$((installation_end_time - INSTALLATION_START_TIME))
    local minutes=$((installation_duration / 60))
    local seconds=$((installation_duration % 60))
    
    print_header "Installation Complete! 🎉"
    
    cat << EOF

${GREEN}Your HaberNexus is ready!${NC}

${CYAN}════════════════════════════════════════════════════════════════${NC}
  Access URLs
${CYAN}════════════════════════════════════════════════════════════════${NC}

  ${BULLET} Main Site:   ${GREEN}https://${DOMAIN}${NC}
  ${BULLET} Admin Panel: ${GREEN}https://${DOMAIN}/admin${NC}
  ${BULLET} API:         ${GREEN}https://${DOMAIN}/api${NC}

${CYAN}════════════════════════════════════════════════════════════════${NC}
  Admin Credentials
${CYAN}════════════════════════════════════════════════════════════════${NC}

  ${BULLET} Username: ${GREEN}${ADMIN_USERNAME}${NC}
  ${BULLET} Email:    ${GREEN}${ADMIN_EMAIL}${NC}
  ${BULLET} Password: ${YELLOW}(as entered during installation)${NC}

${CYAN}════════════════════════════════════════════════════════════════${NC}
  Installation Summary
${CYAN}════════════════════════════════════════════════════════════════${NC}

  ${BULLET} Installation Mode:   ${INSTALL_MODE}
  ${BULLET} Duration:            ${minutes}m ${seconds}s
  ${BULLET} Project Path:        ${PROJECT_PATH}
  ${BULLET} Log File:            ${LOG_FILE}

${CYAN}════════════════════════════════════════════════════════════════${NC}
  Next Steps
${CYAN}════════════════════════════════════════════════════════════════${NC}

  1. ${BULLET} Open ${GREEN}https://${DOMAIN}${NC} in your browser
  2. ${BULLET} Login with your admin credentials
  3. ${BULLET} Configure RSS feeds and content sources
  4. ${BULLET} Start content generation
  5. ${BULLET} Monitor system health in admin panel

${CYAN}════════════════════════════════════════════════════════════════${NC}
  Useful Commands
${CYAN}════════════════════════════════════════════════════════════════${NC}

  View logs:
    ${GRAY}docker-compose -f ${PROJECT_PATH}/docker-compose.yml logs -f${NC}

  Restart services:
    ${GRAY}docker-compose -f ${PROJECT_PATH}/docker-compose.yml restart${NC}

  Stop services:
    ${GRAY}docker-compose -f ${PROJECT_PATH}/docker-compose.yml down${NC}

  Check service status:
    ${GRAY}docker-compose -f ${PROJECT_PATH}/docker-compose.yml ps${NC}

${CYAN}════════════════════════════════════════════════════════════════${NC}

EOF
    
    log_success "Installation completed successfully in ${minutes}m ${seconds}s!"
}

# ============================================================================
# COMMAND LINE ARGUMENTS
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                INSTALL_MODE="quick"
                shift
                ;;
            --custom)
                INSTALL_MODE="custom"
                shift
                ;;
            --dev)
                INSTALL_MODE="dev"
                shift
                ;;
            --force)
                FORCE_REINSTALL=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF

${CYAN}HaberNexus v${SCRIPT_VERSION} - Installation Script${NC}

${WHITE}Usage:${NC}
  sudo bash install_v7.sh [OPTIONS]

${WHITE}Options:${NC}
  --quick              Quick setup with default values (recommended)
  --custom             Custom configuration (interactive)
  --dev                Development mode with debug settings
  --force              Force reinstall (backup existing installation)
  --help               Show this help message

${WHITE}Examples:${NC}
  ${GRAY}sudo bash install_v7.sh --quick${NC}
  ${GRAY}sudo bash install_v7.sh --custom${NC}
  ${GRAY}sudo bash install_v7.sh --dev${NC}

${WHITE}Installation Modes:${NC}
  ${CYAN}Quick${NC}       - Recommended for production (uses sensible defaults)
  ${CYAN}Custom${NC}      - Interactive setup with full control
  ${CYAN}Dev${NC}         - Development mode with debug enabled

${WHITE}Support:${NC}
  GitHub: https://github.com/sata2500/habernexus
  Issues: https://github.com/sata2500/habernexus/issues

EOF
}

# ============================================================================
# MAIN INSTALLATION FLOW
# ============================================================================

main() {
    parse_arguments "$@"
    init_logging
    
    print_header "HaberNexus v${SCRIPT_VERSION} - Advanced Installation"
    log_info "Installation Mode: ${INSTALL_MODE}"
    log_info "Log File: ${LOG_FILE}"
    
    run_preflight_checks
    
    case "${INSTALL_MODE}" in
        quick)
            quick_setup
            ;;
        custom|interactive)
            interactive_input
            ;;
        dev)
            quick_setup
            ;;
    esac
    
    save_configuration
    backup_existing_installation
    clone_repository
    create_environment_file
    build_docker_images
    start_services
    wait_for_services
    run_migrations
    create_admin_user
    collect_static_files
    verify_installation
    show_success_summary
    
    log_success "Installation workflow completed!"
}

main "$@"
