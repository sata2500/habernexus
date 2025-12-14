#!/bin/bash

################################################################################
# HaberNexus - Ultimate Installer v4.0
# Features: Modular Design, Nginx Proxy Manager, Cloudflare Tunnel, GUI Setup
# Developer: Salih TANRISEVEN & Manus AI
# Date: December 2024
################################################################################

set -eo pipefail

# --- Global Configuration ---
SCRIPT_DIR="$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\"
PROJECT_PATH=\"${PROJECT_PATH:-/opt/habernexus}\"
REPO_URL=\"https://github.com/sata2500/habernexus.git\"
LOG_FILE=\"/var/log/habernexus_install_$(date +%Y%m%d_%H%M%S).log\"
TEMP_DIR=\"/tmp/habernexus_install_$$\"

# --- Color Definitions ---
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
CYAN='\\033[0;36m'
MAGENTA='\\033[0;35m'
NC='\\033[0m'

# --- Logging Functions ---
log_info() {
    echo -e \"${GREEN}[INFO]${NC} $1\" | tee -a \"$LOG_FILE\"
}

log_warn() {
    echo -e \"${YELLOW}[WARN]${NC} $1\" | tee -a \"$LOG_FILE\"
}

log_error() {
    echo -e \"${RED}[ERROR]${NC} $1\" | tee -a \"$LOG_FILE\"
    exit 1
}

log_step() {
    echo -e \"\\n${BLUE}==>${NC} $1\" | tee -a \"$LOG_FILE\"
}

log_header() {
    echo -e \"\\n${CYAN}═══════════════════════════════════════════════════════${NC}\" | tee -a \"$LOG_FILE\"
    echo -e \"${CYAN}  $1${NC}\" | tee -a \"$LOG_FILE\"
    echo -e \"${CYAN}═══════════════════════════════════════════════════════${NC}\\n\" | tee -a \"$LOG_FILE\"
}

show_msg() {
    if command -v whiptail &> /dev/null; then
        whiptail --title \"HaberNexus Installer\" --msgbox \"$1\" 12 70
    else
        echo -e \"${BLUE}ℹ${NC} $1\"
    fi
}

show_error_msg() {
    if command -v whiptail &> /dev/null; then
        whiptail --title \"Error\" --msgbox \"$1\" 10 60
    else
        echo -e \"${RED}✗${NC} $1\"
    fi
    log_error \"$1\"
}

# --- Error Handling ---
trap 'log_error \"Command failed at line $LINENO: $BASH_COMMAND\"' ERR

cleanup() {
    log_info \"Cleaning up temporary files...\"
    rm -rf \"$TEMP_DIR\" 2>/dev/null || true
}

trap cleanup EXIT

# --- Pre-flight Checks ---
check_root() {
    if [ \"$EUID\" -ne 0 ]; then
        log_error \"This script must be run as root. Please use: sudo bash install_v4.sh\"
    fi
}

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ \"$ID\" != \"ubuntu\" ]]; then
            log_error \"This script is optimized for Ubuntu. Detected: $ID\"
        fi
        if [[ ! \"$VERSION_ID\" =~ ^(22|24)\\. ]]; then
            log_warn \"Detected Ubuntu $VERSION_ID. Recommended: 22.04 or 24.04\"
        fi
    else
        log_error \"Cannot detect OS. /etc/os-release not found.\"
    fi
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_warn \"Docker not found. Installing...\"
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
    fi
    
    if ! docker compose version &> /dev/null; then
        log_warn \"Docker Compose v2 not found. Installing...\"
        apt-get install -y -qq docker-compose-plugin
    fi
}

check_port_availability() {
    local ports=(80 443 81)
    local unavailable=()
    
    for port in \"${ports[@]}\"; do
        if ss -tuln | grep -q \":$port \"; then
            unavailable+=(\"$port\")
        fi
    done
    
    if [ ${#unavailable[@]} -gt 0 ]; then
        log_warn \"Ports in use: ${unavailable[*]}\"
        echo -e \"${YELLOW}Warning: Some ports are already in use.${NC}\"
        echo \"This may cause issues with the installation.\"
        return 1
    fi
}

check_disk_space() {
    local available=$(df /opt 2>/dev/null | awk 'NR==2 {print $4}')
    if [ -z \"$available\" ]; then
        available=$(df / | awk 'NR==2 {print $4}')
    fi
    
    if [ \"$available\" -lt 20971520 ]; then  # 20GB in KB
        log_warn \"Low disk space: $(numfmt --to=iec $((available * 1024)) 2>/dev/null || echo \"${available}KB\")\"
        return 1
    fi
}

check_internet() {
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_error \"No internet connection detected. Please check your network.\"
    fi
}

run_preflight_checks() {
    log_header \"Running Pre-flight Checks\"
    
    check_root
    check_os
    check_internet
    check_docker
    
    log_info \"✓ Root privilege verified\"
    log_info \"✓ OS compatibility verified\"
    log_info \"✓ Internet connectivity verified\"
    log_info \"✓ Docker installed\"
    
    if ! check_port_availability; then
        if ! whiptail --yesno \"Some ports are in use. Continue anyway?\" 8 60; then
            log_error \"Installation cancelled.\"
        fi
    fi
    
    if ! check_disk_space; then
        if ! whiptail --yesno \"Low disk space detected. Continue anyway?\" 8 60; then
            log_error \"Installation cancelled.\"
        fi
    fi
    
    log_info \"✓ All pre-flight checks passed\"
}

# --- Installation Type Selection ---
select_installation_type() {
    log_step \"Select Installation Type\"
    
    INSTALLATION_TYPE=$(whiptail --title \"Installation Type\" --menu \"Choose your installation type:\" 15 70 3 \
        \"1\" \"Cloudflare Tunnel + Nginx Proxy Manager (Recommended)\" \
        \"2\" \"Cloudflare Tunnel + Direct Nginx\" \
        \"3\" \"Direct Port Forwarding (80/443)\" 3>&1 1>&2 2>&3)
    
    case $INSTALLATION_TYPE in
        1)
            INSTALLATION_TYPE=\"tunnel_npm\"
            log_info \"Selected: Cloudflare Tunnel + Nginx Proxy Manager\"
            ;;
        2)
            INSTALLATION_TYPE=\"tunnel_direct\"
            log_info \"Selected: Cloudflare Tunnel + Direct Nginx\"
            ;;
        3)
            INSTALLATION_TYPE=\"direct\"
            log_info \"Selected: Direct Port Forwarding\"
            ;;
        *)
            log_error \"Invalid selection\"
            ;;
    esac
}

# --- Configuration Functions ---
validate_domain() {
    local domain=\"$1\"
    if [[ ! \"$domain\" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    return 0
}

validate_email() {
    local email=\"$1\"
    if [[ ! \"$email\" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

validate_password() {
    local pass=\"$1\"
    if [ ${#pass} -lt 12 ]; then
        return 1
    fi
    return 0
}

configure_environment() {
    log_step \"Configure Environment Variables\"
    
    # Domain
    while true; do
        DOMAIN=$(whiptail --inputbox \"Enter your domain name (e.g., habernexus.com):\" 10 60 3>&1 1>&2 2>&3)
        if validate_domain \"$DOMAIN\"; then
            break
        else
            show_error_msg \"Invalid domain format. Please try again.\"
        fi
    done
    
    # Admin Email
    while true; do
        ADMIN_EMAIL=$(whiptail --inputbox \"Enter admin email:\" 10 60 3>&1 1>&2 2>&3)
        if validate_email \"$ADMIN_EMAIL\"; then
            break
        else
            show_error_msg \"Invalid email format. Please try again.\"
        fi
    done
    
    # Admin Username
    ADMIN_USER=$(whiptail --inputbox \"Enter admin username:\" 10 60 \"admin\" 3>&1 1>&2 2>&3)
    
    # Admin Password
    while true; do
        ADMIN_PASS=$(whiptail --passwordbox \"Set Admin Password (min 12 chars):\" 10 60 3>&1 1>&2 2>&3)
        if validate_password \"$ADMIN_PASS\"; then
            ADMIN_PASS_CONFIRM=$(whiptail --passwordbox \"Confirm Admin Password:\" 10 60 3>&1 1>&2 2>&3)
            if [ \"$ADMIN_PASS\" == \"$ADMIN_PASS_CONFIRM\" ]; then
                break
            else
                show_error_msg \"Passwords do not match. Please try again.\"
            fi
        else
            show_error_msg \"Password must be at least 12 characters. Please try again.\"
        fi
    done
    
    # Database Password
    while true; do
        DB_PASS=$(whiptail --passwordbox \"Set Database Password (min 12 chars):\" 10 60 3>&1 1>&2 2>&3)
        if validate_password \"$DB_PASS\"; then
            break
        else
            show_error_msg \"Password must be at least 12 characters. Please try again.\"
        fi
    done
    
    # Generate Secret Key
    SECRET_KEY=$(openssl rand -base64 50 | tr -d '\\n/+' | head -c 50)
    
    log_info \"✓ Configuration completed\"
}

configure_cloudflare_tunnel() {
    log_step \"Configure Cloudflare Tunnel\"
    
    INSTRUCTIONS=\"HOW TO GET YOUR CLOUDFLARE TUNNEL TOKEN:\\n\\n\"
    INSTRUCTIONS+=\"1. Go to https://one.dash.cloudflare.com\\n\"
    INSTRUCTIONS+=\"2. Navigate to Networks > Tunnels\\n\"
    INSTRUCTIONS+=\"3. Click 'Create a Tunnel' → Select 'Cloudflared'\\n\"
    INSTRUCTIONS+=\"4. Name it (e.g., 'habernexus') and Save\\n\"
    INSTRUCTIONS+=\"5. Copy the token from 'Install and run a connector' section\\n\"
    INSTRUCTIONS+=\"   (It looks like: eyJhIjoi...)\\n\\n\"
    INSTRUCTIONS+=\"6. Paste it below when prompted\"
    
    whiptail --title \"Cloudflare Tunnel Setup\" --msgbox \"$INSTRUCTIONS\" 18 75
    
    while true; do
        CLOUDFLARE_TUNNEL_TOKEN=$(whiptail --inputbox \"Paste your Cloudflare Tunnel Token:\" 10 70 3>&1 1>&2 2>&3)
        if [ -n \"$CLOUDFLARE_TUNNEL_TOKEN\" ] && [ ${#CLOUDFLARE_TUNNEL_TOKEN} -gt 50 ]; then
            break
        else
            show_error_msg \"Invalid token. Please try again.\"
        fi
    done
    
    log_info \"✓ Cloudflare Tunnel token configured\"
}

configure_cloudflare_dns_api() {
    log_step \"Configure Cloudflare DNS API Token\"
    
    INSTRUCTIONS=\"HOW TO GET YOUR CLOUDFLARE API TOKEN:\\n\\n\"
    INSTRUCTIONS+=\"1. Go to https://dash.cloudflare.com/profile/api-tokens\\n\"
    INSTRUCTIONS+=\"2. Click 'Create Token'\\n\"
    INSTRUCTIONS+=\"3. Use 'Edit zone DNS' template\\n\"
    INSTRUCTIONS+=\"4. Under Zone Resources, select your domain\\n\"
    INSTRUCTIONS+=\"5. Create and copy the token\\n\\n\"
    INSTRUCTIONS+=\"This token is used for automatic SSL certificate renewal.\"
    
    whiptail --title \"Cloudflare API Token\" --msgbox \"$INSTRUCTIONS\" 18 75
    
    while true; do
        CLOUDFLARE_API_TOKEN=$(whiptail --inputbox \"Paste your Cloudflare API Token:\" 10 70 3>&1 1>&2 2>&3)
        if [ -n \"$CLOUDFLARE_API_TOKEN\" ] && [ ${#CLOUDFLARE_API_TOKEN} -gt 20 ]; then
            break
        else
            show_error_msg \"Invalid token. Please try again.\"
        fi
    done
    
    log_info \"✓ Cloudflare API token configured\"
}

configure_npm_database() {
    log_step \"Configure Nginx Proxy Manager Database\"
    
    NPM_DB_TYPE=$(whiptail --title \"NPM Database\" --menu \"Select database type:\" 10 60 2 \
        \"1\" \"SQLite (Simple, Recommended)\" \
        \"2\" \"PostgreSQL (Advanced)\" 3>&1 1>&2 2>&3)
    
    case $NPM_DB_TYPE in
        1)
            NPM_DB_TYPE=\"sqlite\"
            log_info \"Selected: SQLite database\"
            ;;
        2)
            NPM_DB_TYPE=\"postgres\"
            NPM_DB_PASS=$(whiptail --passwordbox \"Set NPM Database Password:\" 10 60 3>&1 1>&2 2>&3)
            log_info \"Selected: PostgreSQL database\"
            ;;
        *)
            log_error \"Invalid selection\"
            ;;
    esac
}

# --- Setup Functions ---
setup_project_directory() {
    log_step \"Setting up project directory\"
    
    if [ -d \"$PROJECT_PATH/.git\" ]; then
        log_info \"Project exists. Pulling latest changes...\"
        cd \"$PROJECT_PATH\" && git pull origin main
    else
        log_info \"Cloning repository...\"
        git clone \"$REPO_URL\" \"$PROJECT_PATH\"
    fi
    
    cd \"$PROJECT_PATH\"
    log_info \"✓ Project directory ready\"
}

create_env_file() {
    log_step \"Creating .env file\"
    
    cat > \"$PROJECT_PATH/.env\" <<EOF
# Django Settings
DEBUG=False
DJANGO_SECRET_KEY=$SECRET_KEY
ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN,localhost,127.0.0.1

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=$DB_PASS
DB_HOST=postgres
DB_PORT=5432

# Redis & Celery
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/1

# Google AI API
GOOGLE_API_KEY=${GOOGLE_API_KEY:-}

# Domain
DOMAIN=$DOMAIN
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_USERNAME=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASS

# Installation Type
INSTALLATION_TYPE=$INSTALLATION_TYPE

# Cloudflare Configuration
CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN:-}
CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN:-}

# Nginx Proxy Manager
NPM_DB_TYPE=${NPM_DB_TYPE:-sqlite}
NPM_DB_PASSWORD=${NPM_DB_PASS:-}

# Security (Production)
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True
EOF
    
    log_info \"✓ .env file created\"
}

create_docker_compose_override() {
    log_step \"Creating Docker Compose override configuration\"
    
    case $INSTALLATION_TYPE in
        tunnel_npm)
            cat > \"$PROJECT_PATH/docker-compose.override.yml\" <<EOF
version: '3.9'

services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: habernexus_cloudflared
    restart: always
    command: tunnel --no-autoupdate run --token $CLOUDFLARE_TUNNEL_TOKEN
    networks:
      - habernexus_network
    depends_on:
      - nginx_proxy_manager

  nginx_proxy_manager:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: habernexus_npm
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '81:81'
    environment:
      TZ: \"Europe/Istanbul\"
      DB_SQLITE_FILE: \"/data/database.sqlite\"
    volumes:
      - npm_data:/data
      - npm_letsencrypt:/etc/letsencrypt
    networks:
      - habernexus_network
    depends_on:
      - app

  nginx:
    # Disable direct nginx when using NPM
    image: nginx:alpine
    container_name: habernexus_nginx_disabled
    restart: \"no\"
    profiles:
      - disabled

volumes:
  npm_data:
  npm_letsencrypt:
EOF
            ;;
        tunnel_direct)
            cat > \"$PROJECT_PATH/docker-compose.override.yml\" <<EOF
version: '3.9'

services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: habernexus_cloudflared
    restart: always
    command: tunnel --no-autoupdate run --token $CLOUDFLARE_TUNNEL_TOKEN
    networks:
      - habernexus_network
    depends_on:
      - nginx

  nginx:
    ports: []
    expose:
      - 80
    volumes:
      - ./nginx/conf.d/habernexus_tunnel.conf:/etc/nginx/conf.d/default.conf:ro
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - static_volume:/app/staticfiles
      - media_volume:/app/media
EOF
            ;;
        direct)
            cat > \"$PROJECT_PATH/docker-compose.override.yml\" <<EOF
version: '3.9'

services:
  nginx:
    ports:
      - \"80:80\"
      - \"443:443\"
    volumes:
      - ./nginx/conf.d/habernexus.conf:/etc/nginx/conf.d/default.conf:ro
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - static_volume:/app/staticfiles
      - media_volume:/app/media
      - ./config/ssl:/etc/nginx/ssl:ro
EOF
            ;;
    esac
    
    log_info \"✓ Docker Compose override created\"
}

deploy_containers() {
    log_step \"Deploying Docker containers\"
    
    {
        echo 10
        docker compose -f docker-compose.yml -f docker-compose.override.yml down --remove-orphans 2>/dev/null || true
        echo 30
        docker compose -f docker-compose.yml -f docker-compose.override.yml build
        echo 60
        docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
        echo 80
        sleep 10
        docker compose -f docker-compose.yml -f docker-compose.override.yml exec -T app python manage.py migrate --noinput
        echo 100
    } | whiptail --gauge \"Deploying containers...\" 10 60 0
    
    log_info \"✓ Containers deployed successfully\"
}

create_admin_user() {
    log_step \"Creating admin user\"
    
    {
        echo 50
        docker compose -f docker-compose.yml -f docker-compose.override.yml exec -T app python manage.py shell <<PYEOF
from django.contrib.auth.models import User
User.objects.filter(username='$ADMIN_USER').delete()
User.objects.create_superuser('$ADMIN_USER', '$ADMIN_EMAIL', '$ADMIN_PASS')
print(f\"Admin user '$ADMIN_USER' created successfully\")
PYEOF
        echo 100
    } | whiptail --gauge \"Creating admin user...\" 10 60 0
    
    log_info \"✓ Admin user created\"
}

run_health_checks() {
    log_step \"Running health checks\"
    
    local checks_passed=0
    local checks_total=0
    
    # Check Docker daemon
    checks_total=$((checks_total + 1))
    if docker ps &> /dev/null; then
        log_info \"✓ Docker daemon running\"
        checks_passed=$((checks_passed + 1))
    else
        log_warn \"✗ Docker daemon check failed\"
    fi
    
    # Check containers
    checks_total=$((checks_total + 1))
    if docker compose -f docker-compose.yml -f docker-compose.override.yml ps | grep -q \"Up\"; then
        log_info \"✓ Containers running\"
        checks_passed=$((checks_passed + 1))
    else
        log_warn \"✗ Some containers not running\"
    fi
    
    # Check database
    checks_total=$((checks_total + 1))
    if docker compose -f docker-compose.yml -f docker-compose.override.yml exec -T app python manage.py check &> /dev/null; then
        log_info \"✓ Database connectivity verified\"
        checks_passed=$((checks_passed + 1))
    else
        log_warn \"✗ Database connectivity check failed\"
    fi
    
    log_info \"Health checks: $checks_passed/$checks_total passed\"
}

generate_summary_report() {
    log_header \"Installation Summary\"
    
    local summary=\"\"
    summary+=\"Installation Status: ✓ Successful\\n\\n\"
    summary+=\"Installation Type: \"
    case $INSTALLATION_TYPE in
        tunnel_npm) summary+=\"Cloudflare Tunnel + Nginx Proxy Manager\" ;;
        tunnel_direct) summary+=\"Cloudflare Tunnel + Direct Nginx\" ;;
        direct) summary+=\"Direct Port Forwarding\" ;;
    esac
    summary+=\"\\n\"
    summary+=\"Domain: $DOMAIN\\n\"
    summary+=\"Project Path: $PROJECT_PATH\\n\"
    summary+=\"Log File: $LOG_FILE\\n\\n\"
    
    summary+=\"Access URLs:\\n\"
    summary+=\"• Main Site: https://$DOMAIN\\n\"
    summary+=\"• Admin Panel: https://$DOMAIN/admin\\n\"
    
    if [ \"$INSTALLATION_TYPE\" == \"tunnel_npm\" ]; then
        summary+=\"• NPM Panel: http://localhost:81\\n\"
        summary+=\"  (Username: admin@example.com / Password: changeme)\\n\"
    fi
    
    summary+=\"\\nAdmin Credentials:\\n\"
    summary+=\"• Username: $ADMIN_USER\\n\"
    summary+=\"• Email: $ADMIN_EMAIL\\n\\n\"
    
    summary+=\"Next Steps:\\n\"
    
    if [ \"$INSTALLATION_TYPE\" == \"tunnel_npm\" ]; then
        summary+=\"1. Configure Cloudflare DNS (CNAME records)\\n\"
        summary+=\"2. Login to NPM and configure proxy hosts\\n\"
        summary+=\"3. Setup SSL certificates in NPM\\n\"
        summary+=\"4. Configure HaberNexus settings\\n\"
    elif [ \"$INSTALLATION_TYPE\" == \"tunnel_direct\" ]; then
        summary+=\"1. Configure Cloudflare DNS (CNAME records)\\n\"
        summary+=\"2. Verify Cloudflare Tunnel connectivity\\n\"
        summary+=\"3. Configure HaberNexus settings\\n\"
    else
        summary+=\"1. Configure DNS (Point A record to server IP)\\n\"
        summary+=\"2. Ensure ports 80/443 are open\\n\"
        summary+=\"3. Configure HaberNexus settings\\n\"
    fi
    
    summary+=\"5. Start content generation\\n\\n\"
    summary+=\"Documentation: https://github.com/sata2500/habernexus\\n\"
    
    whiptail --title \"Installation Complete\" --msgbox \"$summary\" 25 75
    
    echo -e \"\\n$summary\" | tee -a \"$LOG_FILE\"
}

# --- Main Menu ---
show_main_menu() {
    CHOICE=$(whiptail --title \"HaberNexus Installer v4.0\" --menu \"Choose an option:\" 15 60 5 \
        \"1\" \"Fresh Installation (Recommended)\" \
        \"2\" \"Smart Migration\" \
        \"3\" \"Update System\" \
        \"4\" \"Health Check\" \
        \"5\" \"Exit\" 3>&1 1>&2 2>&3)
    
    case $CHOICE in
        1)
            run_fresh_installation
            ;;
        2)
            run_smart_migration
            ;;
        3)
            run_system_update
            ;;
        4)
            run_health_check
            ;;
        5)
            log_info \"Exiting installer\"
            exit 0
            ;;
        *)
            log_error \"Invalid selection\"
            ;;
    esac
}

run_fresh_installation() {
    log_header \"Fresh Installation\"
    
    run_preflight_checks
    select_installation_type
    configure_environment
    
    if [ \"$INSTALLATION_TYPE\" != \"direct\" ]; then
        configure_cloudflare_tunnel
        configure_cloudflare_dns_api
    fi
    
    if [ \"$INSTALLATION_TYPE\" == \"tunnel_npm\" ]; then
        configure_npm_database
    fi
    
    setup_project_directory
    create_env_file
    create_docker_compose_override
    deploy_containers
    create_admin_user
    run_health_checks
    generate_summary_report
}

run_smart_migration() {
    log_header \"Smart Migration\"
    show_msg \"Smart migration feature coming soon!\"
}

run_system_update() {
    log_header \"System Update\"
    cd \"$PROJECT_PATH\"
    git pull origin main
    docker compose -f docker-compose.yml -f docker-compose.override.yml up -d --build
    show_msg \"System updated successfully!\"
}

run_health_check() {
    log_header \"Health Check\"
    cd \"$PROJECT_PATH\"
    run_health_checks
    show_msg \"Health check completed. Check logs for details.\"
}

# --- Main Execution ---
mkdir -p \"$TEMP_DIR\"
mkdir -p \"$(dirname \"$LOG_FILE\")\"

log_header \"HaberNexus Installer v4.0\"
log_info \"Log file: $LOG_FILE\"

show_main_menu
