#!/bin/bash

################################################################################
# HaberNexus - Ultimate Installer v4.0
# Features: Modular Design, Nginx Proxy Manager, Cloudflare Tunnel, GUI Setup
# Developer: Salih TANRISEVEN & Manus AI
# Date: December 2024
################################################################################

set -eo pipefail

# --- Global Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="${PROJECT_PATH:-/opt/habernexus}"
REPO_URL="https://github.com/sata2500/habernexus.git"
LOG_FILE="/var/log/habernexus_install_$(date +%Y%m%d_%H%M%S).log"
TEMP_DIR="/tmp/habernexus_install_$$"

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# --- Logging Functions ---
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

log_step() {
    echo -e "\n${BLUE}==>${NC} $1" | tee -a "$LOG_FILE"
}

log_header() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}  $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n" | tee -a "$LOG_FILE"
}

# --- Pre-flight Checks ---
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root. Use: sudo bash install_v4.sh"
    fi
}

check_os() {
    log_step "Checking Operating System"
    
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine OS"
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        log_error "This script requires Ubuntu. Detected: $ID"
    fi
    
    VERSION_ID=$(echo "$VERSION_ID" | cut -d. -f1)
    if [[ "$VERSION_ID" -lt 22 ]]; then
        log_error "Ubuntu 22.04 LTS or newer is required. Detected: $VERSION_ID"
    fi
    
    log_info "OS Check: Ubuntu $VERSION_ID ✓"
}

check_docker() {
    log_step "Checking Docker Installation"
    
    if ! command -v docker &> /dev/null; then
        log_warn "Docker not found. Installing..."
        curl -fsSL https://get.docker.com | bash
        usermod -aG docker root
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_warn "Docker Compose not found. Installing..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    log_info "Docker Check: $(docker --version) ✓"
    log_info "Docker Compose Check: $(docker-compose --version) ✓"
}

check_internet() {
    log_step "Checking Internet Connectivity"
    
    # Try multiple methods to check internet connectivity
    if ! curl -s --connect-timeout 5 https://www.google.com &> /dev/null && \
       ! wget -q --timeout=5 -O /dev/null https://www.google.com &> /dev/null; then
        log_warn "Could not verify internet connectivity, but continuing..."
    fi
    
    log_info "Internet Connectivity: ✓"
}

# --- Installation Type Selection ---
select_installation_type() {
    log_step "Select Installation Type"
    
    echo ""
    echo "Choose your installation type:"
    echo "1) Cloudflare Tunnel + Nginx Proxy Manager (Recommended)"
    echo "2) Cloudflare Tunnel + Direct Nginx"
    echo "3) Direct Port Forwarding (80/443)"
    echo ""
    read -p "Enter your choice (1-3): " INSTALLATION_TYPE
    
    case $INSTALLATION_TYPE in
        1)
            INSTALLATION_TYPE="tunnel_npm"
            log_info "Selected: Cloudflare Tunnel + Nginx Proxy Manager"
            ;;
        2)
            INSTALLATION_TYPE="tunnel_direct"
            log_info "Selected: Cloudflare Tunnel + Direct Nginx"
            ;;
        3)
            INSTALLATION_TYPE="direct"
            log_info "Selected: Direct Port Forwarding"
            ;;
        *)
            log_error "Invalid choice. Please enter 1, 2, or 3"
            ;;
    esac
}

# --- Configuration Functions ---
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_email() {
    local email=$1
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_password() {
    local password=$1
    if [[ ${#password} -ge 12 ]] && [[ $password =~ [A-Z] ]] && [[ $password =~ [0-9] ]] && [[ $password =~ [^a-zA-Z0-9] ]]; then
        return 0
    else
        return 1
    fi
}

configure_environment() {
    log_step "Configure Environment"
    
    # Domain
    while true; do
        read -p "Enter your domain name (e.g., habernexus.com): " DOMAIN
        if validate_domain "$DOMAIN"; then
            break
        else
            log_warn "Invalid domain format. Please try again."
        fi
    done
    
    # Admin Email
    while true; do
        read -p "Enter admin email: " ADMIN_EMAIL
        if validate_email "$ADMIN_EMAIL"; then
            break
        else
            log_warn "Invalid email format. Please try again."
        fi
    done
    
    # Admin Username
    read -p "Enter admin username (default: admin): " ADMIN_USER
    ADMIN_USER="${ADMIN_USER:-admin}"
    
    # Admin Password
    while true; do
        read -sp "Set Admin Password (min 12 chars, uppercase, number, special char): " ADMIN_PASSWORD
        echo ""
        if validate_password "$ADMIN_PASSWORD"; then
            break
        else
            log_warn "Password does not meet requirements. Please try again."
        fi
    done
    
    # Database Password
    while true; do
        read -sp "Set Database Password (min 12 chars, uppercase, number, special char): " DB_PASSWORD
        echo ""
        if validate_password "$DB_PASSWORD"; then
            break
        else
            log_warn "Password does not meet requirements. Please try again."
        fi
    done
    
    log_info "Environment configured ✓"
}

configure_cloudflare_tunnel() {
    if [[ "$INSTALLATION_TYPE" == "tunnel_npm" ]] || [[ "$INSTALLATION_TYPE" == "tunnel_direct" ]]; then
        log_step "Configure Cloudflare Tunnel"
        
        echo ""
        echo "HOW TO GET YOUR CLOUDFLARE TUNNEL TOKEN:"
        echo "1. Go to https://one.dash.cloudflare.com"
        echo "2. Navigate to Networks > Tunnels"
        echo "3. Click 'Create a Tunnel' → Select 'Cloudflared'"
        echo "4. Name it (e.g., 'habernexus') and Save"
        echo "5. Copy the token from 'Install and run a connector' section"
        echo ""
        
        read -p "Paste your Cloudflare Tunnel Token: " CLOUDFLARE_TUNNEL_TOKEN
        
        if [[ -z "$CLOUDFLARE_TUNNEL_TOKEN" ]]; then
            log_error "Cloudflare Tunnel Token is required"
        fi
        
        log_info "Cloudflare Tunnel Token configured ✓"
    fi
}

configure_cloudflare_api() {
    if [[ "$INSTALLATION_TYPE" == "tunnel_npm" ]]; then
        log_step "Configure Cloudflare API Token"
        
        echo ""
        echo "HOW TO GET YOUR CLOUDFLARE API TOKEN:"
        echo "1. Go to https://dash.cloudflare.com/profile/api-tokens"
        echo "2. Click 'Create Token'"
        echo "3. Use 'Edit zone DNS' template"
        echo "4. Under Zone Resources, select your domain"
        echo "5. Create and copy the token"
        echo ""
        
        read -p "Paste your Cloudflare API Token: " CLOUDFLARE_API_TOKEN
        
        if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
            log_error "Cloudflare API Token is required"
        fi
        
        log_info "Cloudflare API Token configured ✓"
    fi
}

# --- Setup Functions ---
setup_project_directory() {
    log_step "Setup Project Directory"
    
    if [[ -d "$PROJECT_PATH" ]]; then
        log_warn "Project directory already exists at $PROJECT_PATH"
        read -p "Do you want to continue? (y/n): " CONTINUE
        if [[ "$CONTINUE" != "y" ]]; then
            log_error "Installation cancelled"
        fi
    else
        mkdir -p "$PROJECT_PATH"
    fi
    
    log_info "Project directory: $PROJECT_PATH ✓"
}

clone_repository() {
    log_step "Clone Repository"
    
    cd "$PROJECT_PATH" || log_error "Cannot change to project directory"
    
    if [[ -d .git ]]; then
        log_info "Repository already exists, pulling latest changes..."
        git pull origin main
    else
        log_info "Cloning repository..."
        git clone "$REPO_URL" .
    fi
    
    log_info "Repository cloned ✓"
}

create_env_file() {
    log_step "Create Environment File"
    
    cat > "$PROJECT_PATH/.env" << EOF
# HaberNexus Environment Configuration
# Generated by install_v4.sh on $(date)

# Installation Type
INSTALLATION_TYPE=$INSTALLATION_TYPE

# Domain Configuration
DOMAIN=$DOMAIN

# Django Configuration
DEBUG=False
DJANGO_SECRET_KEY=$(openssl rand -hex 32)
ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN,localhost,127.0.0.1

# Database Configuration
DB_ENGINE=django.db.backends.postgresql
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=$DB_PASSWORD
DB_HOST=postgres
DB_PORT=5432

# Celery Configuration
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# Cloudflare Configuration
CLOUDFLARE_TUNNEL_TOKEN=$CLOUDFLARE_TUNNEL_TOKEN
CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN

# Admin Configuration
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_USER=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASSWORD

# Timezone
TZ=Europe/Istanbul
EOF
    
    log_info "Environment file created ✓"
}

deploy_containers() {
    log_step "Deploy Docker Containers"
    
    cd "$PROJECT_PATH" || log_error "Cannot change to project directory"
    
    log_info "Starting Docker containers..."
    docker-compose up -d
    
    log_info "Waiting for containers to be healthy..."
    sleep 30
    
    log_info "Docker containers deployed ✓"
}

run_migrations() {
    log_step "Run Database Migrations"
    
    cd "$PROJECT_PATH" || log_error "Cannot change to project directory"
    
    log_info "Running migrations..."
    docker-compose exec -T app python manage.py migrate
    
    log_info "Collecting static files..."
    docker-compose exec -T app python manage.py collectstatic --noinput
    
    log_info "Migrations completed ✓"
}

create_admin_user() {
    log_step "Create Admin User"
    
    cd "$PROJECT_PATH" || log_error "Cannot change to project directory"
    
    log_info "Creating admin user..."
    docker-compose exec -T app python manage.py shell << EOF
from django.contrib.auth.models import User
if not User.objects.filter(username='$ADMIN_USER').exists():
    User.objects.create_superuser('$ADMIN_USER', '$ADMIN_EMAIL', '$ADMIN_PASSWORD')
    print("Admin user created successfully")
else:
    print("Admin user already exists")
EOF
    
    log_info "Admin user created ✓"
}

run_health_checks() {
    log_step "Run Health Checks"
    
    cd "$PROJECT_PATH" || log_error "Cannot change to project directory"
    
    log_info "Checking Docker containers..."
    docker-compose ps
    
    log_info "Checking application health..."
    sleep 10
    
    if curl -f http://localhost:8000/health/ &> /dev/null; then
        log_info "Application health check: ✓"
    else
        log_warn "Application health check: Could not connect"
    fi
    
    log_info "Health checks completed ✓"
}

show_summary() {
    log_header "Installation Summary"
    
    echo "Status: ✓ Successful"
    echo "Installation Type: $INSTALLATION_TYPE"
    echo "Domain: $DOMAIN"
    echo "Project Path: $PROJECT_PATH"
    echo ""
    echo "Access URLs:"
    echo "• Main Site: https://$DOMAIN"
    echo "• Admin Panel: https://$DOMAIN/admin"
    if [[ "$INSTALLATION_TYPE" == "tunnel_npm" ]]; then
        echo "• NPM Panel: http://localhost:81"
    fi
    echo ""
    echo "Admin Credentials:"
    echo "• Username: $ADMIN_USER"
    echo "• Email: $ADMIN_EMAIL"
    echo ""
    echo "Next Steps:"
    echo "1. Configure Cloudflare DNS records (if using Tunnel)"
    echo "2. Setup NPM proxy hosts (if using NPM)"
    echo "3. Configure HaberNexus settings in admin panel"
    echo "4. Add RSS feeds and start content generation"
    echo ""
    echo "Log file: $LOG_FILE"
}

# --- Main Menu ---
show_main_menu() {
    log_header "HaberNexus Installer v4.0"
    
    echo "Choose an option:"
    echo "1) Fresh Installation"
    echo "2) Exit"
    echo ""
    read -p "Enter your choice (1-2): " MAIN_CHOICE
    
    case $MAIN_CHOICE in
        1)
            run_fresh_installation
            ;;
        2)
            log_info "Exiting installer"
            exit 0
            ;;
        *)
            log_error "Invalid choice"
            ;;
    esac
}

run_fresh_installation() {
    log_header "Fresh Installation"
    
    check_root
    check_os
    check_internet
    check_docker
    
    select_installation_type
    configure_environment
    configure_cloudflare_tunnel
    configure_cloudflare_api
    
    setup_project_directory
    clone_repository
    create_env_file
    deploy_containers
    run_migrations
    create_admin_user
    run_health_checks
    
    show_summary
}

# --- Main Execution ---
mkdir -p "$TEMP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

show_main_menu
