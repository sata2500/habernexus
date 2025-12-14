#!/bin/bash

################################################################################
# Haber Nexus - Professional Setup Script v3.0
# Optimized for Ubuntu 22.04/24.04 LTS
# Features: Modular design, Idempotency, Enhanced Error Handling, Migration Support
# Developer: Salih TANRISEVEN & Manus AI
################################################################################

set -eo pipefail

# --- Configuration & Constants ---
LOG_FILE="/var/log/habernexus_setup_$(date +%Y%m%d_%H%M%S).log"
DEFAULT_PROJECT_PATH="/opt/habernexus"
REPO_URL="https://github.com/sata2500/habernexus.git"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Logging Functions ---
log_info() { echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; exit 1; }
log_step() { echo -e "\n${BLUE}==>${NC} $1" | tee -a "$LOG_FILE"; }
log_header() { echo -e "\n${CYAN}=== $1 ===${NC}\n" | tee -a "$LOG_FILE"; }

# --- Error Handling ---
trap 'log_error "Command failed at line $LINENO: $BASH_COMMAND"' ERR

# --- Helper Functions ---

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root. Please use 'sudo bash setup_v3.sh'."
    fi
}

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]]; then
            log_error "This script is optimized for Ubuntu. Detected: $ID"
        fi
    else
        log_error "Cannot detect OS. /etc/os-release not found."
    fi
}

install_dependencies() {
    log_step "Installing system dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq curl wget git nano htop net-tools build-essential python3-dev python3-pip python3-venv openssl jq
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        log_step "Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
    fi

    # Install Docker Compose Plugin (v2)
    if ! docker compose version &> /dev/null; then
        log_step "Installing Docker Compose Plugin..."
        apt-get install -y -qq docker-compose-plugin
    fi
}

setup_project_directory() {
    log_step "Setting up project directory..."
    
    # Prompt for project path if not set via env var
    if [ -z "$PROJECT_PATH" ]; then
        read -p "Project Directory [$DEFAULT_PROJECT_PATH]: " -r INPUT_PATH
        PROJECT_PATH=${INPUT_PATH:-$DEFAULT_PROJECT_PATH}
    fi

    if [ -d "$PROJECT_PATH/.git" ]; then
        log_info "Project exists. Pulling latest changes..."
        cd "$PROJECT_PATH" && git pull origin main
    else
        log_info "Cloning repository..."
        git clone "$REPO_URL" "$PROJECT_PATH"
    fi
    
    cd "$PROJECT_PATH"
}

configure_environment() {
    log_step "Configuring environment variables..."
    
    if [ -f .env ]; then
        log_warn ".env file already exists. Skipping generation to preserve settings."
        return
    fi

    read -p "Domain Name (e.g., habernexus.com): " -r DOMAIN
    [[ -z "$DOMAIN" ]] && log_error "Domain name is required."

    read -p "Admin Email: " -r ADMIN_EMAIL
    [[ -z "$ADMIN_EMAIL" ]] && log_error "Admin email is required."

    read -sp "Database Password (min 12 chars): " -r DB_PASSWORD
    echo ""
    [[ ${#DB_PASSWORD} -lt 12 ]] && log_error "Password too short."

    SECRET_KEY=$(openssl rand -base64 50 | tr -d '\n/+' | head -c 50)
    
    cat > .env <<EOF
DEBUG=False
DJANGO_SECRET_KEY=$SECRET_KEY
ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN,localhost,127.0.0.1
DB_ENGINE=django.db.backends.postgresql
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=$DB_PASSWORD
DB_HOST=postgres
DB_PORT=5432
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/1
GOOGLE_GEMINI_API_KEY=${GOOGLE_API_KEY:-""}
DOMAIN=$DOMAIN
ADMIN_EMAIL=$ADMIN_EMAIL
EOF
    log_info ".env file generated successfully."
}

deploy_containers() {
    log_step "Deploying Docker containers..."
    
    # Use docker compose (v2) instead of docker-compose (v1)
    docker compose -f docker-compose.prod.yml down --remove-orphans || true
    docker compose -f docker-compose.prod.yml up -d --build

    log_step "Waiting for database..."
    timeout 60s bash -c 'until docker compose -f docker-compose.prod.yml exec -T postgres pg_isready -U habernexus_user; do sleep 2; done' || log_error "Database failed to start."

    log_step "Running migrations..."
    docker compose -f docker-compose.prod.yml exec -T web python manage.py migrate --noinput

    log_step "Collecting static files..."
    docker compose -f docker-compose.prod.yml exec -T web python manage.py collectstatic --noinput
}

setup_ssl() {
    log_step "Setting up SSL with Let's Encrypt..."
    
    if [ -z "$DOMAIN" ] || [ "$DOMAIN" == "localhost" ]; then
        log_warn "Skipping SSL setup for localhost or empty domain."
        return
    fi

    # Check if cert already exists
    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        log_info "SSL certificate already exists for $DOMAIN."
        return
    fi

    apt-get install -y -qq certbot
    
    # Stop Nginx temporarily to allow certbot standalone mode
    docker compose -f docker-compose.prod.yml stop nginx
    
    certbot certonly --standalone -d "$DOMAIN" -d "www.$DOMAIN" --email "$ADMIN_EMAIL" --agree-tos --no-eff-email -n
    
    docker compose -f docker-compose.prod.yml start nginx
    log_info "SSL setup complete."
}

# --- Main Execution ---

clear
log_header "HABER NEXUS SETUP v3.0"

check_root
check_os
install_dependencies
setup_project_directory
configure_environment
deploy_containers
setup_ssl

log_header "INSTALLATION COMPLETE"
echo -e "Project installed at: $PROJECT_PATH"
echo -e "Access your site at: https://$DOMAIN"
echo -e "Log file: $LOG_FILE"
echo -e "\nTo create a superuser, run:"
echo -e "cd $PROJECT_PATH && docker compose -f docker-compose.prod.yml exec web python manage.py createsuperuser"
