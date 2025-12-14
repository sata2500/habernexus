#!/bin/bash

################################################################################
# Haber Nexus - Ultimate Installer & Manager
# Features: TUI (Whiptail), One-Click Install, Smart Migration
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
    whiptail --title "Haber Nexus Installer" --msgbox "$1" 10 60
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

configure_env() {
    DOMAIN=$(whiptail --inputbox "Enter your domain name (e.g., habernexus.com):" 10 60 3>&1 1>&2 2>&3)
    EMAIL=$(whiptail --inputbox "Enter admin email for SSL:" 10 60 3>&1 1>&2 2>&3)
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
ADMIN_EMAIL=$EMAIL
EOF
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
        docker compose -f docker-compose.prod.yml up -d postgres
        sleep 10
        cat "$PROJECT_PATH/restore_temp/db.dump" | docker compose -f docker-compose.prod.yml exec -T postgres pg_restore -U habernexus_user -d habernexus --clean --if-exists
        
        echo 90
        # Restore Media
        cp -r "$PROJECT_PATH/restore_temp/media" "$PROJECT_PATH/"
        
        rm -rf "$PROJECT_PATH/restore_temp"
        echo 100
    } | whiptail --gauge "Migrating data from source server..." 10 60 0
    
    show_msg "Migration completed successfully!"
}

main_menu() {
    CHOICE=$(whiptail --title "Haber Nexus Manager" --menu "Choose an option:" 15 60 4 \
    "1" "Fresh Installation" \
    "2" "Smart Migration (Transfer from another server)" \
    "3" "Update System" \
    "4" "Exit" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1)
            install_dependencies
            mkdir -p "$PROJECT_PATH"
            if [ ! -d "$PROJECT_PATH/.git" ]; then
                git clone "$REPO_URL" "$PROJECT_PATH"
            fi
            cd "$PROJECT_PATH"
            configure_env
            docker compose -f docker-compose.prod.yml up -d --build
            show_msg "Installation Complete! Access at https://$DOMAIN"
            ;;
        2)
            install_dependencies
            mkdir -p "$PROJECT_PATH"
            if [ ! -d "$PROJECT_PATH/.git" ]; then
                git clone "$REPO_URL" "$PROJECT_PATH"
            fi
            cd "$PROJECT_PATH"
            configure_env
            smart_migration
            docker compose -f docker-compose.prod.yml up -d --build
            show_msg "Migration & Installation Complete!"
            ;;
        3)
            cd "$PROJECT_PATH"
            git pull
            docker compose -f docker-compose.prod.yml up -d --build
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
