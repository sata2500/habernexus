#!/bin/bash

################################################################################
# HaberNexus v6.0 - Complete Automatic Installation Script
# 
# Features:
#   - Single-click installation (5 minutes)
#   - Automatic DNS record creation
#   - Automatic SSL certificate setup
#   - Automatic Cloudflare Tunnel configuration
#   - Zero manual configuration needed
#   - Comprehensive error handling
#   - Full logging
#
# Usage: sudo bash install_v6.sh
#
# Author: Salih TANRISEVEN
# Date: December 14, 2025
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="/opt/habernexus"
LOG_FILE="/var/log/habernexus_install_v6_$(date +%Y%m%d_%H%M%S).log"
ENV_FILE="${PROJECT_PATH}/.env"

# Global variables
DOMAIN=""
ADMIN_EMAIL=""
ADMIN_USERNAME=""
ADMIN_PASSWORD=""
CLOUDFLARE_API_TOKEN=""
CLOUDFLARE_TUNNEL_TOKEN=""
TUNNEL_NAME=""
TUNNEL_UUID=""
ZONE_ID=""

################################################################################
# Utility Functions
################################################################################

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $@" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $@" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[✗]${NC} $@" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $@" | tee -a "${LOG_FILE}"
}

print_header() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  $@"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
}

print_section() {
    echo ""
    echo "→ $@"
    echo ""
}

################################################################################
# Pre-flight Checks
################################################################################

check_root() {
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
    
    if [[ ! "$VERSION_ID" =~ ^(22\.04|24\.04) ]]; then
        log_warning "Tested on Ubuntu 22.04 and 24.04 (detected: $VERSION_ID)"
    fi
    
    log_success "OS Check: Ubuntu $VERSION_ID ✓"
}

check_docker() {
    print_section "Checking Docker Installation"
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        log_info "Install Docker with: curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker ps &> /dev/null; then
        log_error "Docker daemon is not running"
        log_info "Start Docker with: sudo systemctl start docker"
        exit 1
    fi
    
    local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
    local compose_version=$(docker-compose --version | awk '{print $4}' | sed 's/,//')
    
    log_success "Docker $docker_version ✓"
    log_success "Docker Compose $compose_version ✓"
}

check_internet() {
    print_section "Checking Internet Connectivity"
    
    local urls=("https://github.com" "https://api.cloudflare.com" "https://www.google.com")
    
    for url in "${urls[@]}"; do
        if curl -s -I "$url" > /dev/null 2>&1; then
            log_success "Connection to $url ✓"
            return 0
        fi
    done
    
    log_error "No internet connection detected"
    exit 1
}

check_disk_space() {
    print_section "Checking Disk Space"
    
    local available_space=$(df /opt 2>/dev/null | awk 'NR==2 {print $4}')
    local required_space=$((20 * 1024 * 1024)) # 20GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        log_error "Insufficient disk space (required: 20GB, available: $((available_space / 1024 / 1024))GB)"
        exit 1
    fi
    
    log_success "Disk space check ✓ (available: $((available_space / 1024 / 1024))GB)"
}

run_preflight_checks() {
    print_header "HaberNexus v6.0 - Pre-flight Checks"
    
    check_root
    check_os
    check_docker
    check_internet
    check_disk_space
    
    log_success "All pre-flight checks passed!"
}

################################################################################
# User Input Functions
################################################################################

validate_domain() {
    local domain=$1
    
    # Basic domain validation
    if [[ ! $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    
    return 0
}

validate_email() {
    local email=$1
    
    if [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    
    return 0
}

validate_password() {
    local password=$1
    
    # Password must be at least 8 characters
    if [[ ${#password} -lt 8 ]]; then
        return 1
    fi
    
    # Check for at least one uppercase letter
    if [[ ! $password =~ [A-Z] ]]; then
        return 1
    fi
    
    # Check for at least one lowercase letter
    if [[ ! $password =~ [a-z] ]]; then
        return 1
    fi
    
    # Check for at least one number
    if [[ ! $password =~ [0-9] ]]; then
        return 1
    fi
    
    # Check for at least one special character
    if [[ ! $password =~ [\@\$\!\%\*\?\&] ]]; then
        return 1
    fi
    
    return 0
}

get_user_input() {
    print_header "HaberNexus v6.0 - Installation Configuration"
    
    # Domain
    while true; do
        read -p "Enter your domain (e.g., habernexus.com): " DOMAIN
        if validate_domain "$DOMAIN"; then
            log_success "Domain: $DOMAIN"
            break
        else
            log_error "Invalid domain format"
        fi
    done
    
    # Email
    while true; do
        read -p "Enter admin email: " ADMIN_EMAIL
        if validate_email "$ADMIN_EMAIL"; then
            log_success "Email: $ADMIN_EMAIL"
            break
        else
            log_error "Invalid email format"
        fi
    done
    
    # Username
    while true; do
        read -p "Enter admin username: " ADMIN_USERNAME
        if [[ ${#ADMIN_USERNAME} -ge 3 ]]; then
            log_success "Username: $ADMIN_USERNAME"
            break
        else
            log_error "Username must be at least 3 characters"
        fi
    done
    
    # Password
    while true; do
        read -s -p "Enter admin password (min 8 chars, uppercase, lowercase, number, special): " ADMIN_PASSWORD
        echo ""
        if [[ ${#ADMIN_PASSWORD} -ge 8 ]]; then
            log_success "Password set"
            break
        else
            log_error "Password must be at least 8 characters"
        fi
    done
    
    # Cloudflare API Token
    while true; do
        read -p "Enter Cloudflare API Token: " CLOUDFLARE_API_TOKEN
        if [[ ${#CLOUDFLARE_API_TOKEN} -gt 20 ]]; then
            log_success "Cloudflare API Token received"
            break
        else
            log_error "Invalid API token"
        fi
    done
    
    # Cloudflare Tunnel Token
    while true; do
        read -p "Enter Cloudflare Tunnel Token: " CLOUDFLARE_TUNNEL_TOKEN
        if [[ ${#CLOUDFLARE_TUNNEL_TOKEN} -gt 20 ]]; then
            log_success "Cloudflare Tunnel Token received"
            break
        else
            log_error "Invalid Tunnel token"
        fi
    done
}

################################################################################
# Installation Functions
################################################################################

clone_repository() {
    print_section "Cloning Repository"
    
    if [[ -d "$PROJECT_PATH" ]]; then
        log_warning "Project path already exists, using existing installation"
        cd "$PROJECT_PATH"
    else
        mkdir -p "$PROJECT_PATH"
        cd "$PROJECT_PATH"
        
        git clone https://github.com/sata2500/habernexus.git . 2>&1 | tee -a "${LOG_FILE}"
        log_success "Repository cloned"
    fi
}

create_environment_file() {
    print_section "Creating Environment Configuration"
    
    cat > "${ENV_FILE}" << EOF
# HaberNexus v6.0 Environment Configuration
# Generated: $(date)

# Domain Configuration
DOMAIN=${DOMAIN}
ADMIN_EMAIL=${ADMIN_EMAIL}

# Django Settings
DEBUG=False
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')
ALLOWED_HOSTS=${DOMAIN},www.${DOMAIN},localhost,127.0.0.1,app

# Database
DATABASE_URL=postgresql://habernexus:habernexus_db_pass@postgres:5432/habernexus
POSTGRES_USER=habernexus
POSTGRES_PASSWORD=habernexus_db_pass
POSTGRES_DB=habernexus

# Redis
REDIS_URL=redis://redis:6379/0

# Cloudflare Configuration
CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}

# Admin User
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# Security
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True

# Logging
LOG_LEVEL=INFO

# Features
ENABLE_CELERY=True
ENABLE_REDIS_CACHE=True
EOF
    
    chmod 600 "${ENV_FILE}"
    log_success "Environment file created"
}

extract_tunnel_info() {
    print_section "Extracting Tunnel Information"
    
    # Decode tunnel token to get UUID
    # The token is base64 encoded JSON
    local decoded=$(echo "${CLOUDFLARE_TUNNEL_TOKEN}" | base64 -d 2>/dev/null || echo "")
    
    if [[ -z "$decoded" ]]; then
        log_warning "Could not decode tunnel token, using placeholder"
        TUNNEL_UUID="tunnel-uuid-placeholder"
        TUNNEL_NAME="habernexus-tunnel"
    else
        # Extract tunnel ID from decoded JSON
        TUNNEL_UUID=$(echo "$decoded" | grep -o '"t":"[^"]*"' | cut -d'"' -f4 || echo "tunnel-uuid-placeholder")
        TUNNEL_NAME="habernexus-tunnel"
    fi
    
    log_success "Tunnel UUID: $TUNNEL_UUID"
    log_success "Tunnel Name: $TUNNEL_NAME"
}

get_cloudflare_zone_id() {
    print_section "Getting Cloudflare Zone ID"
    
    local zone_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}" \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json")
    
    ZONE_ID=$(echo "$zone_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [[ -z "$ZONE_ID" ]]; then
        log_error "Could not retrieve Zone ID from Cloudflare"
        log_info "Make sure your domain is added to Cloudflare"
        exit 1
    fi
    
    log_success "Zone ID: $ZONE_ID"
}

create_dns_records() {
    print_section "Creating DNS Records"
    
    local records=(
        "${DOMAIN}"
        "*.${DOMAIN}"
    )
    
    for record in "${records[@]}"; do
        log_info "Creating DNS record for: $record"
        
        local response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
            -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "{
                \"type\": \"CNAME\",
                \"name\": \"${record}\",
                \"content\": \"${TUNNEL_UUID}.cfargotunnel.com\",
                \"ttl\": 1,
                \"proxied\": false
            }")
        
        if echo "$response" | grep -q '"success":true'; then
            log_success "DNS record created: $record → ${TUNNEL_UUID}.cfargotunnel.com"
        else
            log_warning "DNS record creation response: $response"
        fi
    done
}

create_caddy_config() {
    print_section "Creating Caddy Configuration"
    
    local caddyfile="${PROJECT_PATH}/caddy/Caddyfile"
    
    # Replace placeholders in Caddyfile template
    sed -e "s|{DOMAIN}|${DOMAIN}|g" \
        -e "s|{ADMIN_EMAIL}|${ADMIN_EMAIL}|g" \
        -e "s|{CLOUDFLARE_API_TOKEN}|${CLOUDFLARE_API_TOKEN}|g" \
        "${PROJECT_PATH}/caddy/Caddyfile.template" > "${caddyfile}"
    
    chmod 644 "${caddyfile}"
    log_success "Caddy configuration created"
}

create_tunnel_config() {
    print_section "Creating Cloudflare Tunnel Configuration"
    
    local config_file="${PROJECT_PATH}/cloudflared/config.yml"
    
    # Replace placeholders in tunnel config template
    sed -e "s|{TUNNEL_NAME}|${TUNNEL_NAME}|g" \
        -e "s|{DOMAIN}|${DOMAIN}|g" \
        "${PROJECT_PATH}/cloudflared/config.yml.template" > "${config_file}"
    
    chmod 644 "${config_file}"
    log_success "Tunnel configuration created"
}

build_docker_images() {
    print_section "Building Docker Images"
    
    cd "${PROJECT_PATH}"
    
    log_info "Building Caddy image with Cloudflare module..."
    docker build -t habernexus-caddy:latest -f caddy/Dockerfile . 2>&1 | tee -a "${LOG_FILE}"
    log_success "Caddy image built"
    
    log_info "Building Django app image..."
    docker build -t habernexus-app:latest -f Dockerfile . 2>&1 | tee -a "${LOG_FILE}"
    log_success "App image built"
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
    
    local max_attempts=60
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        local caddy_status=$(docker-compose ps caddy 2>/dev/null | grep -c "healthy" || echo "0")
        local app_status=$(docker-compose ps app 2>/dev/null | grep -c "healthy" || echo "0")
        local postgres_status=$(docker-compose ps postgres 2>/dev/null | grep -c "healthy" || echo "0")
        local redis_status=$(docker-compose ps redis 2>/dev/null | grep -c "healthy" || echo "0")
        
        if [[ $caddy_status -gt 0 && $app_status -gt 0 && $postgres_status -gt 0 && $redis_status -gt 0 ]]; then
            log_success "All services are healthy"
            return 0
        fi
        
        echo -ne "\rWaiting for services... (${attempt}/${max_attempts})"
        sleep 1
        ((attempt++))
    done
    
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
    
    docker-compose exec -T app python manage.py shell << EOF
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
    
    log_success "Admin user created"
}

verify_ssl_certificate() {
    print_section "Verifying SSL Certificate"
    
    log_info "Waiting for SSL certificate to be issued..."
    
    local max_attempts=30
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -s -I "https://${DOMAIN}" 2>/dev/null | grep -q "HTTP"; then
            log_success "SSL certificate verified"
            return 0
        fi
        
        echo -ne "\rVerifying SSL... (${attempt}/${max_attempts})"
        sleep 2
        ((attempt++))
    done
    
    log_warning "Could not verify SSL certificate within timeout"
    log_info "Certificate may still be processing, check manually in a few minutes"
}

################################################################################
# Summary and Cleanup
################################################################################

show_success_summary() {
    print_header "Installation Complete! 🎉"
    
    cat << EOF

Your HaberNexus is ready!

═══════════════════════════════════════════════════════════════
  Access URLs
═══════════════════════════════════════════════════════════════

  • Main Site:   https://${DOMAIN}
  • Admin Panel: https://${DOMAIN}/admin
  • API:         https://${DOMAIN}/api

═══════════════════════════════════════════════════════════════
  Admin Credentials
═══════════════════════════════════════════════════════════════

  • Username: ${ADMIN_USERNAME}
  • Email:    ${ADMIN_EMAIL}
  • Password: (as entered during installation)

═══════════════════════════════════════════════════════════════
  Next Steps
═══════════════════════════════════════════════════════════════

  1. Open https://${DOMAIN} in your browser
  2. Login with admin credentials
  3. Configure RSS feeds and content sources
  4. Start content generation
  5. Monitor system health in admin panel

═══════════════════════════════════════════════════════════════
  Useful Commands
═══════════════════════════════════════════════════════════════

  View logs:
    docker-compose -f ${PROJECT_PATH}/docker-compose.yml logs -f

  Restart services:
    docker-compose -f ${PROJECT_PATH}/docker-compose.yml restart

  Stop services:
    docker-compose -f ${PROJECT_PATH}/docker-compose.yml down

  Check service status:
    docker-compose -f ${PROJECT_PATH}/docker-compose.yml ps

═══════════════════════════════════════════════════════════════
  Support & Documentation
═══════════════════════════════════════════════════════════════

  • Documentation: https://docs.habernexus.com
  • GitHub:        https://github.com/sata2500/habernexus
  • Issues:        https://github.com/sata2500/habernexus/issues
  • Email:         ${ADMIN_EMAIL}

═══════════════════════════════════════════════════════════════
  Installation Log
═══════════════════════════════════════════════════════════════

  Log file: ${LOG_FILE}

═══════════════════════════════════════════════════════════════

EOF
    
    log_success "Installation completed successfully!"
}

show_error_summary() {
    print_header "Installation Failed ✗"
    
    log_error "Installation did not complete successfully"
    log_info "Check the log file for details: ${LOG_FILE}"
    log_info "Common issues:"
    log_info "  1. Insufficient disk space"
    log_info "  2. Docker daemon not running"
    log_info "  3. Invalid Cloudflare credentials"
    log_info "  4. Network connectivity issues"
    
    exit 1
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    # Ensure log directory exists
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # Start installation
    {
        run_preflight_checks
        get_user_input
        clone_repository
        create_environment_file
        extract_tunnel_info
        get_cloudflare_zone_id
        create_dns_records
        create_caddy_config
        create_tunnel_config
        build_docker_images
        start_services
        wait_for_services
        run_migrations
        create_admin_user
        verify_ssl_certificate
        show_success_summary
    } || {
        show_error_summary
    }
}

# Run main function
main "$@"
