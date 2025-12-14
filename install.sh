#!/bin/bash

################################################################################
# Haber Nexus - Ultimate Installer & Manager v3.1
# Features: TUI, One-Click Install, Smart Migration, Cloudflare Tunnel, Auto-Admin
################################################################################

# --- Configuration ---
PROJECT_PATH="/opt/habernexus"
REPO_URL="https://github.com/sata2500/habernexus.git"
LOG_FILE="/var/log/habernexus_installer.log"

# --- Helper Functions ---

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

show_msg() {
    whiptail --title "Haber Nexus Installer" --msgbox "$1" 12 70
}

show_error() {
    whiptail --title "Error" --msgbox "$1" 10 60
    log "ERROR: $1"
    exit 1
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        show_error "Please run as root (sudo)."
    fi
}

cleanup_environment() {
    if (whiptail --title "Cleanup Environment" --yesno "Do you want to clean up any existing installation? This will DELETE ALL DATA in $PROJECT_PATH." 10 60); then
        {
            echo 10
            if [ -d "$PROJECT_PATH" ]; then
                cd "$PROJECT_PATH" || exit
                if command -v docker &> /dev/null; then
                    # Stop all containers including cloudflared
                    docker compose down -v --remove-orphans >/dev/null 2>&1
                    # Force remove cloudflared if it persists
                    docker rm -f cloudflared >/dev/null 2>&1 || true
                    # Prune unused networks and volumes to ensure clean slate
                    docker network prune -f >/dev/null 2>&1
                fi
            fi
            echo 50
            rm -rf "$PROJECT_PATH"
            echo 100
        } | whiptail --gauge "Cleaning up environment..." 10 60 0
        log "Environment cleaned up."
    fi
}

install_dependencies() {
    {
        echo 10
        apt-get update -qq >/dev/null 2>&1
        echo 30
        apt-get install -y -qq curl wget git whiptail net-tools build-essential python3-dev python3-pip jq >/dev/null 2>&1
        echo 60
        if ! command -v docker &> /dev/null; then
            curl -fsSL https://get.docker.com | sh >/dev/null 2>&1
        fi
        echo 90
        if ! docker compose version &> /dev/null; then
            apt-get install -y -qq docker-compose-plugin >/dev/null 2>&1
        fi
        echo 100
    } | whiptail --gauge "Installing system dependencies..." 10 60 0
}

setup_cloudflare_tunnel() {
    if (whiptail --title "Cloudflare Tunnel Setup" --yesno "Do you want to use Cloudflare Tunnel?\n\nThis allows you to expose your site securely WITHOUT opening ports (80/443) or managing SSL certificates manually.\n\nRecommended for most users." 15 70); then
        
        INSTRUCTIONS="HOW TO GET YOUR TOKEN:\n\n"
        INSTRUCTIONS+="1. Go to https://one.dash.cloudflare.com\n"
        INSTRUCTIONS+="2. Navigate to Networks > Tunnels\n"
        INSTRUCTIONS+="3. Click 'Create a Tunnel' -> Select 'Cloudflared'\n"
        INSTRUCTIONS+="4. Name it (e.g., 'habernexus') and Save\n"
        INSTRUCTIONS+="5. Copy the token from the 'Install and run a connector' section\n"
        INSTRUCTIONS+="   (It looks like: eyJhIjoi...)\n\n"
        INSTRUCTIONS+="6. In the 'Public Hostnames' tab, add your domain:\n"
        INSTRUCTIONS+="   - Subdomain: (leave empty or www)\n"
        INSTRUCTIONS+="   - Domain: yourdomain.com\n"
        INSTRUCTIONS+="   - Service: http://nginx:80\n"
        
        whiptail --title "Cloudflare Token Guide" --msgbox "$INSTRUCTIONS" 20 75
        
        TUNNEL_TOKEN=$(whiptail --inputbox "Paste your Cloudflare Tunnel Token here:" 10 70 3>&1 1>&2 2>&3)
        
        if [ -n "$TUNNEL_TOKEN" ]; then
            # Create override file to use tunnel configuration
            cat > "$PROJECT_PATH/docker-compose.override.yml" <<EOF
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: always
    command: tunnel --no-autoupdate run --token $TUNNEL_TOKEN
    networks:
      - habernexus_network

  nginx:
    ports: [] # Disable public ports
    expose:
      - 80
    volumes:
      - ./nginx/conf.d/habernexus_tunnel.conf:/etc/nginx/conf.d/default.conf:ro
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - static_volume:/app/staticfiles
      - media_volume:/app/media
EOF
            log "Cloudflare Tunnel configured."
            return 0
        else
            show_msg "No token provided. Falling back to standard installation (Direct Port 80/443)."
            return 1
        fi
    else
        return 1
    fi
}

configure_env() {
    DOMAIN=$(whiptail --inputbox "Enter your domain name (e.g., habernexus.com):" 10 60 3>&1 1>&2 2>&3)
    ADMIN_EMAIL=$(whiptail --inputbox "Enter admin email:" 10 60 3>&1 1>&2 2>&3)
    ADMIN_USER=$(whiptail --inputbox "Enter admin username:" 10 60 "admin" 3>&1 1>&2 2>&3)
    ADMIN_PASS=$(whiptail --passwordbox "Set Admin Password:" 10 60 3>&1 1>&2 2>&3)
    DB_PASS=$(whiptail --passwordbox "Set Database Password:" 10 60 3>&1 1>&2 2>&3)
    
    SECRET_KEY=$(openssl rand -base64 50 | tr -d '\n/+' | head -c 50)
    
    cat > "$PROJECT_PATH/.env" <<EOF
DEBUG=False
DJANGO_SECRET_KEY=$SECRET_KEY
ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN,localhost,127.0.0.1
DB_ENGINE=django.db.backends.postgresql
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=$DB_PASS
DB_HOST=postgres
DB_PORT=5432
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/1
DOMAIN=$DOMAIN
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_USERNAME=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASS
EOF
}

create_admin_user() {
    {
        echo 50
        docker compose exec -T web python3 scripts/create_admin.py
        echo 100
    } | whiptail --gauge "Creating admin user..." 10 60 0
}

smart_migration() {
    SOURCE_URL=$(whiptail --inputbox "Enter Source Server URL (e.g., https://old-server.com):" 10 60 3>&1 1>&2 2>&3)
    MIGRATION_TOKEN=$(whiptail --inputbox "Enter Migration Token from Source Server:" 10 60 3>&1 1>&2 2>&3)
    
    if [ -z "$SOURCE_URL" ] || [ -z "$MIGRATION_TOKEN" ]; then
        show_error "Migration aborted. Missing URL or Token."
    fi

    {
        echo 10
        mkdir -p "$PROJECT_PATH/restore_temp"
        echo 20
        # Download backup stream
        curl -X POST -d "token=$MIGRATION_TOKEN" -o "$PROJECT_PATH/restore_temp/backup.tar.gz" "$SOURCE_URL/core/api/migration/stream/" --fail
        
        if [ $? -ne 0 ]; then
             show_error "Failed to download backup. Check URL and Token."
        fi
        
        echo 50
        # Extract
        tar -xzf "$PROJECT_PATH/restore_temp/backup.tar.gz" -C "$PROJECT_PATH/restore_temp"
        
        echo 70
        # Restore DB
        docker compose up -d postgres
        sleep 10
        cat "$PROJECT_PATH/restore_temp/db.dump" | docker compose exec -T postgres pg_restore -U habernexus_user -d habernexus --clean --if-exists
        
        echo 90
        # Restore Media
        cp -r "$PROJECT_PATH/restore_temp/media" "$PROJECT_PATH/"
        
        rm -rf "$PROJECT_PATH/restore_temp"
        echo 100
    } | whiptail --gauge "Migrating data from source server..." 10 60 0
    
    show_msg "Migration completed successfully!"
}

post_install_summary() {
    SUMMARY="INSTALLATION SUCCESSFUL!\n\n"
    SUMMARY+="URL: https://$DOMAIN\n"
    SUMMARY+="Admin Panel: https://$DOMAIN/admin\n"
    SUMMARY+="Username: $ADMIN_USER\n"
    SUMMARY+="Password: (hidden)\n\n"
    SUMMARY+="Next Steps:\n"
    
    if [ -n "$TUNNEL_TOKEN" ]; then
        SUMMARY+="1. Cloudflare Tunnel is ACTIVE.\n"
        SUMMARY+="2. Ensure you configured the Public Hostname in Cloudflare Dashboard:\n"
        SUMMARY+="   - Service: http://nginx:80\n"
    else
        SUMMARY+="1. Configure DNS: Point A record for $DOMAIN to $(curl -s ifconfig.me)\n"
        SUMMARY+="2. Ensure ports 80 and 443 are open in your firewall.\n"
    fi
    SUMMARY+="3. Login to Admin Panel and configure settings.\n"
    
    whiptail --title "Post-Installation Summary" --msgbox "$SUMMARY" 20 70
}

main_menu() {
    CHOICE=$(whiptail --title "Haber Nexus Manager v3.1" --menu "Choose an option:" 15 60 4 \
    "1" "Fresh Installation (Recommended)" \
    "2" "Smart Migration (Transfer from another server)" \
    "3" "Update System" \
    "4" "Exit" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1)
            cleanup_environment
            install_dependencies
            mkdir -p "$PROJECT_PATH"
            if [ ! -d "$PROJECT_PATH/.git" ]; then
                git clone "$REPO_URL" "$PROJECT_PATH"
            fi
            cd "$PROJECT_PATH" || exit
            configure_env
            setup_cloudflare_tunnel
            
            # Start services
            {
                echo 20
                docker compose build
                echo 60
                docker compose up -d
                echo 80
                docker compose exec -T web python manage.py migrate --noinput
                echo 100
            } | whiptail --gauge "Starting services..." 10 60 0
            
            create_admin_user
            post_install_summary
            ;;
        2)
            cleanup_environment
            install_dependencies
            mkdir -p "$PROJECT_PATH"
            if [ ! -d "$PROJECT_PATH/.git" ]; then
                git clone "$REPO_URL" "$PROJECT_PATH"
            fi
            cd "$PROJECT_PATH" || exit
            configure_env
            setup_cloudflare_tunnel
            smart_migration
            docker compose up -d --build
            post_install_summary
            ;;
        3)
            cd "$PROJECT_PATH" || exit
            git pull
            docker compose up -d --build
            show_msg "System Updated!"
            ;;
        4)
            exit 0
            ;;
    esac
}

# --- Main Execution ---
check_root
main_menu
