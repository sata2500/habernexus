#!/bin/bash

################################################################################
# HaberNexus Management & Maintenance Script
#
# Purpose: Manage, monitor, and maintain HaberNexus installation
# Usage: bash manage_habernexus.sh [COMMAND] [OPTIONS]
#
# Author: Salih TANRISEVEN
# Date: December 15, 2025
################################################################################

set -euo pipefail

# Configuration
PROJECT_PATH="${PROJECT_PATH:-/opt/habernexus}"
LOG_DIR="/var/log/habernexus"
BACKUP_DIR="${PROJECT_PATH}/.backups"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $@${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo -e "${BLUE}→ $@${NC}"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $@"
}

log_error() {
    echo -e "${RED}[✗]${NC} $@"
}

log_info() {
    echo -e "${BLUE}[ℹ]${NC} $@"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $@"
}

check_project_path() {
    if [[ ! -d "$PROJECT_PATH" ]]; then
        log_error "Project path not found: $PROJECT_PATH"
        exit 1
    fi
}

# ============================================================================
# STATUS & MONITORING
# ============================================================================

status() {
    print_header "HaberNexus Status"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    print_section "Docker Services"
    docker-compose ps
    
    echo ""
    print_section "Service Health"
    
    local services=("postgres" "redis" "app" "caddy" "celery" "celery_beat" "flower")
    
    for service in "${services[@]}"; do
        local status=$(docker-compose ps "$service" 2>/dev/null | grep -c "Up" || echo "0")
        if [[ $status -gt 0 ]]; then
            log_success "$service is running"
        else
            log_error "$service is not running"
        fi
    done
    
    echo ""
    print_section "Disk Usage"
    docker system df
}

logs() {
    local service=${1:-app}
    local lines=${2:-100}
    
    print_header "HaberNexus Logs - $service (last $lines lines)"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    docker-compose logs --tail="$lines" -f "$service"
}

health_check() {
    print_header "HaberNexus Health Check"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    print_section "Container Health"
    docker-compose ps --format "table {{.Service}}\t{{.Status}}"
    
    echo ""
    print_section "Database Connectivity"
    docker-compose exec -T postgres pg_isready -U habernexus && log_success "Database OK" || log_error "Database connection failed"
    
    echo ""
    print_section "Redis Connectivity"
    docker-compose exec -T redis redis-cli ping && log_success "Redis OK" || log_error "Redis connection failed"
    
    echo ""
    print_section "Application Health"
    docker-compose exec -T app curl -s http://localhost:8000/health && log_success "Application OK" || log_warning "Health endpoint not available"
}

# ============================================================================
# SERVICE MANAGEMENT
# ============================================================================

start_services() {
    print_header "Starting HaberNexus Services"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    log_info "Starting containers..."
    docker-compose up -d
    
    log_success "Services started"
    
    echo ""
    print_section "Waiting for services to be ready..."
    sleep 5
    
    status
}

stop_services() {
    print_header "Stopping HaberNexus Services"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    log_info "Stopping containers..."
    docker-compose down
    
    log_success "Services stopped"
}

restart_services() {
    print_header "Restarting HaberNexus Services"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    log_info "Restarting containers..."
    docker-compose restart
    
    log_success "Services restarted"
    
    echo ""
    print_section "Waiting for services to be ready..."
    sleep 5
    
    status
}

restart_service() {
    local service=$1
    
    print_header "Restarting Service: $service"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    log_info "Restarting $service..."
    docker-compose restart "$service"
    
    log_success "$service restarted"
}

# ============================================================================
# DATABASE MANAGEMENT
# ============================================================================

backup_database() {
    print_header "Backing Up Database"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    local backup_file="${BACKUP_DIR}/habernexus_db_$(date +%Y%m%d_%H%M%S).sql"
    mkdir -p "$BACKUP_DIR"
    
    log_info "Creating database backup..."
    docker-compose exec -T postgres pg_dump -U habernexus habernexus > "$backup_file"
    
    log_success "Database backed up to $backup_file"
    log_info "Backup size: $(du -h "$backup_file" | cut -f1)"
}

restore_database() {
    local backup_file=$1
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_header "Restoring Database"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    log_warning "This will overwrite the current database!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        log_info "Restore cancelled"
        return
    fi
    
    log_info "Restoring database from $backup_file..."
    docker-compose exec -T postgres psql -U habernexus habernexus < "$backup_file"
    
    log_success "Database restored"
}

migrate_database() {
    print_header "Running Database Migrations"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    log_info "Running migrations..."
    docker-compose exec -T app python manage.py migrate
    
    log_success "Migrations completed"
}

# ============================================================================
# USER MANAGEMENT
# ============================================================================

create_admin_user() {
    local username=$1
    local email=$2
    local password=$3
    
    print_header "Creating Admin User"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    log_info "Creating user: $username"
    
    docker-compose exec -T app python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()

if User.objects.filter(username='$username').exists():
    print(f"User already exists: $username")
else:
    User.objects.create_superuser(
        username='$username',
        email='$email',
        password='$password'
    )
    print(f"Admin user created: $username")
EOF
    
    log_success "User created"
}

change_admin_password() {
    local username=$1
    local new_password=$2
    
    print_header "Changing Admin Password"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    log_info "Changing password for: $username"
    
    docker-compose exec -T app python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()

try:
    user = User.objects.get(username='$username')
    user.set_password('$new_password')
    user.save()
    print(f"Password changed for: $username")
except User.DoesNotExist:
    print(f"User not found: $username")
EOF
    
    log_success "Password changed"
}

list_users() {
    print_header "List All Users"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    docker-compose exec -T app python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()

print("\nAll Users:")
print("=" * 60)
for user in User.objects.all():
    print(f"Username: {user.username}")
    print(f"Email:    {user.email}")
    print(f"Staff:    {user.is_staff}")
    print(f"Admin:    {user.is_superuser}")
    print("-" * 60)
EOF
}

# ============================================================================
# MAINTENANCE
# ============================================================================

cleanup_logs() {
    print_header "Cleaning Up Old Logs"
    
    log_info "Removing logs older than 30 days..."
    find "$LOG_DIR" -name "*.log" -type f -mtime +30 -delete
    
    log_success "Old logs removed"
}

cleanup_docker() {
    print_header "Cleaning Up Docker"
    
    log_info "Removing unused Docker resources..."
    docker system prune -f
    
    log_success "Docker cleanup completed"
}

update_project() {
    print_header "Updating HaberNexus"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    log_info "Fetching latest changes..."
    git fetch origin
    
    log_info "Pulling latest code..."
    git pull origin main
    
    log_info "Building Docker images..."
    docker-compose build
    
    log_info "Restarting services..."
    docker-compose up -d
    
    log_success "Update completed"
}

# ============================================================================
# BACKUP & RESTORE
# ============================================================================

full_backup() {
    print_header "Creating Full Backup"
    
    check_project_path
    
    local backup_dir="${BACKUP_DIR}/full_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    log_info "Backing up database..."
    cd "$PROJECT_PATH"
    docker-compose exec -T postgres pg_dump -U habernexus habernexus > "${backup_dir}/database.sql"
    
    log_info "Backing up project files..."
    cp -r "${PROJECT_PATH}/app" "${backup_dir}/"
    cp "${PROJECT_PATH}/.env" "${backup_dir}/.env.backup"
    cp "${PROJECT_PATH}/docker-compose.yml" "${backup_dir}/"
    
    log_info "Creating archive..."
    tar -czf "${backup_dir}.tar.gz" -C "${BACKUP_DIR}" "$(basename "$backup_dir")" 2>/dev/null
    rm -rf "$backup_dir"
    
    log_success "Full backup created: ${backup_dir}.tar.gz"
    log_info "Backup size: $(du -h "${backup_dir}.tar.gz" | cut -f1)"
}

list_backups() {
    print_header "Available Backups"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_info "No backups found"
        return
    fi
    
    echo ""
    ls -lh "$BACKUP_DIR" | grep -v "^total" | awk '{print $9, "(" $5 ")"}'
}

# ============================================================================
# TROUBLESHOOTING
# ============================================================================

troubleshoot() {
    print_header "HaberNexus Troubleshooting"
    
    check_project_path
    cd "$PROJECT_PATH"
    
    echo ""
    print_section "System Information"
    echo "OS: $(uname -s) $(uname -r)"
    echo "Docker: $(docker --version)"
    echo "Docker Compose: $(docker-compose --version)"
    
    echo ""
    print_section "Docker Services Status"
    docker-compose ps
    
    echo ""
    print_section "Recent Errors in Logs"
    docker-compose logs --tail=50 | grep -i "error\|exception\|failed" || log_info "No recent errors found"
    
    echo ""
    print_section "Disk Space"
    df -h | grep -E "^/dev|^Filesystem"
    
    echo ""
    print_section "Memory Usage"
    free -h
    
    echo ""
    print_section "Docker System Info"
    docker system df
}

# ============================================================================
# HELP
# ============================================================================

show_help() {
    cat << EOF

${CYAN}HaberNexus Management Script${NC}

${BLUE}Usage:${NC}
  bash manage_habernexus.sh [COMMAND] [OPTIONS]

${BLUE}Commands:${NC}

  ${CYAN}Status & Monitoring:${NC}
    status              Show service status
    logs [SERVICE]      View service logs (default: app)
    health              Run health check
    troubleshoot        Run troubleshooting diagnostics

  ${CYAN}Service Management:${NC}
    start               Start all services
    stop                Stop all services
    restart             Restart all services
    restart [SERVICE]   Restart specific service

  ${CYAN}Database:${NC}
    backup-db           Backup database
    restore-db [FILE]   Restore database from backup
    migrate             Run database migrations

  ${CYAN}User Management:${NC}
    create-user [U] [E] [P]  Create admin user
    change-password [U] [P]   Change user password
    list-users          List all users

  ${CYAN}Maintenance:${NC}
    cleanup-logs        Remove old logs
    cleanup-docker      Clean up Docker resources
    update              Update HaberNexus to latest version

  ${CYAN}Backup & Restore:${NC}
    full-backup         Create full backup
    list-backups        List available backups

  ${CYAN}Other:${NC}
    help                Show this help message

${BLUE}Examples:${NC}
  bash manage_habernexus.sh status
  bash manage_habernexus.sh logs app
  bash manage_habernexus.sh backup-db
  bash manage_habernexus.sh create-user admin admin@example.com password123
  bash manage_habernexus.sh restart postgres

${BLUE}Support:${NC}
  GitHub: https://github.com/sata2500/habernexus
  Issues: https://github.com/sata2500/habernexus/issues

EOF
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local command=${1:-help}
    
    case "$command" in
        # Status & Monitoring
        status)
            status
            ;;
        logs)
            logs "${2:-app}" "${3:-100}"
            ;;
        health)
            health_check
            ;;
        troubleshoot)
            troubleshoot
            ;;
        
        # Service Management
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            if [[ -z "${2:-}" ]]; then
                restart_services
            else
                restart_service "$2"
            fi
            ;;
        
        # Database
        backup-db)
            backup_database
            ;;
        restore-db)
            restore_database "${2:-.}"
            ;;
        migrate)
            migrate_database
            ;;
        
        # User Management
        create-user)
            create_admin_user "${2:-}" "${3:-}" "${4:-}"
            ;;
        change-password)
            change_admin_password "${2:-}" "${3:-}"
            ;;
        list-users)
            list_users
            ;;
        
        # Maintenance
        cleanup-logs)
            cleanup_logs
            ;;
        cleanup-docker)
            cleanup_docker
            ;;
        update)
            update_project
            ;;
        
        # Backup & Restore
        full-backup)
            full_backup
            ;;
        list-backups)
            list_backups
            ;;
        
        # Help
        help|--help|-h)
            show_help
            ;;
        
        *)
            log_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
