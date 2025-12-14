#!/bin/bash

################################################################################
# Haber Nexus - Ultimate Installer & Manager v3.0
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
                    docker compose down -v --remove-orphans >/dev/null 2>&1
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
    if (whiptail --title "Cloudflare Tunnel" --yesno "Do you want to set up Cloudflare Tunnel for secure remote access without opening ports?" 10 60); then
        TUNNEL_TOKEN=$(whiptail --inputbox "Enter your Cloudflare Tunnel Token:" 10 60 3>&1 1>&2 2>&3)
        if [ -n "$TUNNEL_TOKEN" ]; then
            # Add cloudflared service to docker-compose override
            cat > "$PROJECT_PATH/docker-compose.override.yml" <<EOF
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    command: tunnel --no-autoupdate run --token $TUNNEL_TOKEN
    restart: always
    networks:
      - habernexus_network
EOF
            log "Cloudflare Tunnel configured."
        fi
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
    SUMMARY+="1. Configure DNS: Point A record for $DOMAIN to $(curl -s ifconfig.me)\n"
    if [ -n "$TUNNEL_TOKEN" ]; then
        SUMMARY+="2. Cloudflare Tunnel is ACTIVE. Manage it at dash.cloudflare.com\n"
    else
        SUMMARY+="2. Ensure ports 80 and 443 are open in your firewall.\n"
    fi
    SUMMARY+="3. Login to Admin Panel and configure settings.\n"
    
    whiptail --title "Post-Installation Summary" --msgbox "$SUMMARY" 20 70
}

main_menu() {
    CHOICE=$(whiptail --title "Haber Nexus Manager v3.0" --menu "Choose an option:" 15 60 4 \
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
