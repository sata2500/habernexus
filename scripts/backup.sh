#!/bin/bash
# =============================================================================
# HaberNexus - Professional Backup System v11.0.0
# =============================================================================
#
# Kapsamlı yedekleme ve geri yükleme sistemi.
#
# KULLANIM:
#   Yedek Al:
#     sudo bash scripts/backup.sh
#     sudo bash scripts/backup.sh --full
#     sudo bash scripts/backup.sh --database-only
#
#   Yedekleri Listele:
#     sudo bash scripts/backup.sh --list
#
#   Geri Yükle:
#     sudo bash scripts/backup.sh --restore backup_20251218_120000
#
#   Eski Yedekleri Temizle:
#     sudo bash scripts/backup.sh --cleanup
#
# Geliştirici: Salih TANRISEVEN
# =============================================================================

set -eo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly SCRIPT_VERSION="11.0.0"
readonly INSTALL_DIR="${INSTALL_DIR:-/opt/habernexus}"
readonly BACKUP_DIR="${BACKUP_DIR:-/var/backups/habernexus}"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
readonly MAX_BACKUPS="${MAX_BACKUPS:-10}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# LOGGING
# =============================================================================

info() { echo -e "${BLUE}•${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }
fatal() { error "$*"; exit 1; }
step() { echo -e "\n${CYAN}==>${NC} ${BOLD}$*${NC}"; }

# Hata Yakalama
trap 'error "Satır $LINENO: Komut başarısız oldu: $BASH_COMMAND"' ERR

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

check_root() {
    [[ $EUID -eq 0 ]] || fatal "Bu script root yetkisi gerektirir."
}

get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$(cd -P "$(dirname "$source")/.." && pwd)"
}

check_installation() {
    local script_dir
    script_dir=$(get_script_dir)
    
    # Önce script dizinini kontrol et
    if [[ -f "$script_dir/.env" ]]; then
        INSTALL_DIR="$script_dir"
    elif [[ -d "$INSTALL_DIR" ]] && [[ -f "$INSTALL_DIR/.env" ]]; then
        : # INSTALL_DIR zaten doğru
    elif [[ -f ".env" ]]; then
        INSTALL_DIR="$(pwd)"
    else
        fatal "HaberNexus kurulumu bulunamadı. Lütfen kurulum dizininde çalıştırın."
    fi
}

load_env() {
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        set -a
        source "$INSTALL_DIR/.env"
        set +a
    fi
}

get_container_name() {
    local service="$1"
    docker ps --format '{{.Names}}' 2>/dev/null | grep -E "habernexus.*${service}|${service}" | head -1 || true
}

format_size() {
    local size=$1
    if [[ $size -ge 1073741824 ]]; then
        echo "$(echo "scale=2; $size/1073741824" | bc)GB"
    elif [[ $size -ge 1048576 ]]; then
        echo "$(echo "scale=2; $size/1048576" | bc)MB"
    elif [[ $size -ge 1024 ]]; then
        echo "$(echo "scale=2; $size/1024" | bc)KB"
    else
        echo "${size}B"
    fi
}

get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# =============================================================================
# BACKUP FUNCTIONS
# =============================================================================

backup_database() {
    local backup_path="$1"
    local db_container
    db_container=$(get_container_name "postgres")
    
    if [[ -z "$db_container" ]]; then
        warning "PostgreSQL container'ı bulunamadı"
        return 1
    fi
    
    info "Veritabanı yedekleniyor..."
    
    local db_name="${DB_NAME:-habernexus}"
    local db_user="${DB_USER:-habernexus_user}"
    
    # Custom format ile yedekle (daha hızlı geri yükleme)
    if docker exec "$db_container" pg_dump -U "$db_user" -Fc "$db_name" > "${backup_path}/database.dump" 2>/dev/null; then
        gzip -f "${backup_path}/database.dump"
        local size=$(get_file_size "${backup_path}/database.dump.gz")
        success "Veritabanı yedeği alındı ($(format_size $size))"
        return 0
    else
        # Plain text formatını dene
        if docker exec "$db_container" pg_dump -U "$db_user" "$db_name" 2>/dev/null | gzip > "${backup_path}/database.sql.gz"; then
            local size=$(get_file_size "${backup_path}/database.sql.gz")
            success "Veritabanı yedeği alındı ($(format_size $size))"
            return 0
        fi
    fi
    
    warning "Veritabanı yedeği alınamadı"
    return 1
}

backup_redis() {
    local backup_path="$1"
    local redis_container
    redis_container=$(get_container_name "redis")
    
    if [[ -z "$redis_container" ]]; then
        warning "Redis container'ı bulunamadı"
        return 1
    fi
    
    info "Redis yedekleniyor..."
    
    # BGSAVE tetikle
    docker exec "$redis_container" redis-cli BGSAVE > /dev/null 2>&1 || true
    sleep 2
    
    # dump.rdb'yi kopyala
    if docker cp "${redis_container}:/data/dump.rdb" "${backup_path}/redis.rdb" 2>/dev/null; then
        success "Redis yedeği alındı"
        return 0
    else
        warning "Redis yedeği alınamadı"
        return 1
    fi
}

backup_config() {
    local backup_path="$1"
    
    info "Yapılandırma dosyaları yedekleniyor..."
    
    mkdir -p "${backup_path}/config"
    
    # .env dosyası
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        cp "$INSTALL_DIR/.env" "${backup_path}/config/.env"
    fi
    
    # Caddyfile
    if [[ -f "$INSTALL_DIR/caddy/Caddyfile" ]]; then
        cp "$INSTALL_DIR/caddy/Caddyfile" "${backup_path}/config/Caddyfile"
    fi
    
    # docker-compose override
    if [[ -f "$INSTALL_DIR/docker-compose.override.yml" ]]; then
        cp "$INSTALL_DIR/docker-compose.override.yml" "${backup_path}/config/docker-compose.override.yml"
    fi
    
    # CREDENTIALS.txt
    if [[ -f "$INSTALL_DIR/CREDENTIALS.txt" ]]; then
        cp "$INSTALL_DIR/CREDENTIALS.txt" "${backup_path}/config/CREDENTIALS.txt"
    fi
    
    success "Yapılandırma dosyaları yedeklendi"
}

backup_media() {
    local backup_path="$1"
    local media_dir=""
    
    # Media dizinini bul
    for dir in "$INSTALL_DIR/media" "$INSTALL_DIR/mediafiles"; do
        if [[ -d "$dir" ]] && [[ "$(ls -A $dir 2>/dev/null)" ]]; then
            media_dir="$dir"
            break
        fi
    done
    
    if [[ -z "$media_dir" ]]; then
        info "Media dizini boş veya bulunamadı, atlanıyor"
        return 0
    fi
    
    info "Media dosyaları yedekleniyor..."
    
    if tar -czf "${backup_path}/media.tar.gz" -C "$(dirname $media_dir)" "$(basename $media_dir)" 2>/dev/null; then
        local size=$(get_file_size "${backup_path}/media.tar.gz")
        success "Media dosyaları yedeklendi ($(format_size $size))"
        return 0
    else
        warning "Media dosyaları yedeklenemedi"
        return 1
    fi
}

create_metadata() {
    local backup_path="$1"
    local backup_type="$2"
    
    cat > "${backup_path}/backup.info" << EOF
HaberNexus Backup Information
=============================
Version: $SCRIPT_VERSION
Type: $backup_type
Date: $(date)
Timestamp: $TIMESTAMP
Hostname: $(hostname)
Install Directory: $INSTALL_DIR

System Info:
  OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Unknown")
  Kernel: $(uname -r)
  Docker: $(docker --version 2>/dev/null | head -1 || echo "Not installed")

Database:
  Name: ${DB_NAME:-habernexus}
  User: ${DB_USER:-habernexus_user}

Container Status:
$(docker ps --filter "name=habernexus" --format "  {{.Names}}: {{.Status}}" 2>/dev/null || echo "  No containers found")

Backup Contents:
$(ls -la "$backup_path" 2>/dev/null | tail -n +2)
EOF
}

# =============================================================================
# MAIN BACKUP FUNCTION
# =============================================================================

create_backup() {
    local backup_type="${1:-full}"
    
    echo ""
    echo -e "${CYAN}${BOLD}HaberNexus Yedekleme Sistemi v${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
    echo ""
    
    check_installation
    load_env
    
    # Yedek dizini oluştur
    mkdir -p "$BACKUP_DIR"
    local backup_path="${BACKUP_DIR}/backup_${TIMESTAMP}"
    mkdir -p "$backup_path"
    
    info "Yedekleme başlatılıyor: $backup_type"
    info "Kaynak: $INSTALL_DIR"
    info "Hedef: $backup_path"
    echo ""
    
    local success_count=0
    local total_count=0
    
    # Veritabanı
    if [[ "$backup_type" != "config-only" ]]; then
        ((total_count++))
        backup_database "$backup_path" && ((success_count++)) || true
    fi
    
    # Redis
    if [[ "$backup_type" == "full" ]]; then
        ((total_count++))
        backup_redis "$backup_path" && ((success_count++)) || true
    fi
    
    # Yapılandırma
    ((total_count++))
    backup_config "$backup_path" && ((success_count++)) || true
    
    # Media
    if [[ "$backup_type" == "full" ]]; then
        ((total_count++))
        backup_media "$backup_path" && ((success_count++)) || true
    fi
    
    # Metadata
    create_metadata "$backup_path" "$backup_type"
    
    # Arşivle
    echo ""
    info "Yedek arşivleniyor..."
    local archive_name="backup_${TIMESTAMP}.tar.gz"
    tar -czf "${BACKUP_DIR}/${archive_name}" -C "$BACKUP_DIR" "backup_${TIMESTAMP}"
    rm -rf "$backup_path"
    
    local archive_size=$(get_file_size "${BACKUP_DIR}/${archive_name}")
    
    echo ""
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  ✓ Yedekleme Tamamlandı${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Dosya: ${CYAN}${BACKUP_DIR}/${archive_name}${NC}"
    echo -e "  Boyut: ${CYAN}$(format_size $archive_size)${NC}"
    echo -e "  Başarılı: ${GREEN}${success_count}/${total_count}${NC}"
    echo ""
    
    # Eski yedekleri temizle
    cleanup_old_backups
}

# =============================================================================
# RESTORE FUNCTIONS
# =============================================================================

restore_backup() {
    local backup_name="$1"
    
    echo ""
    echo -e "${CYAN}${BOLD}HaberNexus Geri Yükleme Sistemi v${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
    echo ""
    
    check_installation
    load_env
    
    # Yedek dosyasını bul
    local backup_file=""
    if [[ -f "${BACKUP_DIR}/${backup_name}.tar.gz" ]]; then
        backup_file="${BACKUP_DIR}/${backup_name}.tar.gz"
    elif [[ -f "${BACKUP_DIR}/${backup_name}" ]]; then
        backup_file="${BACKUP_DIR}/${backup_name}"
    elif [[ -f "$backup_name" ]]; then
        backup_file="$backup_name"
    else
        fatal "Yedek dosyası bulunamadı: $backup_name"
    fi
    
    info "Yedek dosyası: $backup_file"
    
    # Geçici dizine aç
    local temp_dir="/tmp/habernexus_restore_$$"
    mkdir -p "$temp_dir"
    trap "rm -rf $temp_dir" EXIT
    
    info "Yedek dosyası açılıyor..."
    tar -xzf "$backup_file" -C "$temp_dir"
    
    local restore_dir
    restore_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -1)
    
    if [[ ! -d "$restore_dir" ]]; then
        fatal "Geçersiz yedek dosyası"
    fi
    
    # Metadata göster
    if [[ -f "${restore_dir}/backup.info" ]]; then
        echo ""
        echo -e "${BOLD}Yedek Bilgileri:${NC}"
        grep -E "^(Date|Type|Hostname):" "${restore_dir}/backup.info" | sed 's/^/  /' || true
        echo ""
    fi
    
    # Onay al
    echo -e "${YELLOW}⚠ Bu işlem mevcut verilerin üzerine yazacak!${NC}"
    echo -n "Devam etmek istiyor musunuz? [e/H]: "
    read -r response
    [[ "$response" =~ ^[eEyY]$ ]] || fatal "İşlem iptal edildi"
    
    echo ""
    
    # Veritabanı geri yükle
    local db_file=""
    [[ -f "${restore_dir}/database.dump.gz" ]] && db_file="${restore_dir}/database.dump.gz"
    [[ -f "${restore_dir}/database.sql.gz" ]] && db_file="${restore_dir}/database.sql.gz"
    
    if [[ -n "$db_file" ]]; then
        info "Veritabanı geri yükleniyor..."
        
        local db_container
        db_container=$(get_container_name "postgres")
        
        if [[ -n "$db_container" ]]; then
            local db_name="${DB_NAME:-habernexus}"
            local db_user="${DB_USER:-habernexus_user}"
            
            if [[ "$db_file" == *".dump.gz" ]]; then
                gunzip -c "$db_file" | docker exec -i "$db_container" pg_restore -U "$db_user" -d "$db_name" --clean --if-exists 2>/dev/null || true
            else
                gunzip -c "$db_file" | docker exec -i "$db_container" psql -U "$db_user" -d "$db_name" 2>/dev/null || true
            fi
            success "Veritabanı geri yüklendi"
        else
            warning "PostgreSQL container'ı bulunamadı"
        fi
    fi
    
    # Redis geri yükle
    if [[ -f "${restore_dir}/redis.rdb" ]]; then
        info "Redis geri yükleniyor..."
        
        local redis_container
        redis_container=$(get_container_name "redis")
        
        if [[ -n "$redis_container" ]]; then
            docker cp "${restore_dir}/redis.rdb" "${redis_container}:/data/dump.rdb" 2>/dev/null || true
            docker exec "$redis_container" redis-cli DEBUG RELOAD 2>/dev/null || true
            success "Redis geri yüklendi"
        else
            warning "Redis container'ı bulunamadı"
        fi
    fi
    
    # Yapılandırma geri yükle
    if [[ -d "${restore_dir}/config" ]]; then
        echo ""
        echo -n "Yapılandırma dosyalarını da geri yüklemek ister misiniz? [e/H]: "
        read -r response
        
        if [[ "$response" =~ ^[eEyY]$ ]]; then
            info "Yapılandırma dosyaları geri yükleniyor..."
            
            [[ -f "${restore_dir}/config/.env" ]] && cp "${restore_dir}/config/.env" "$INSTALL_DIR/.env"
            [[ -f "${restore_dir}/config/Caddyfile" ]] && mkdir -p "$INSTALL_DIR/caddy" && cp "${restore_dir}/config/Caddyfile" "$INSTALL_DIR/caddy/Caddyfile"
            [[ -f "${restore_dir}/config/docker-compose.override.yml" ]] && cp "${restore_dir}/config/docker-compose.override.yml" "$INSTALL_DIR/"
            
            success "Yapılandırma dosyaları geri yüklendi"
        fi
    fi
    
    # Media geri yükle
    if [[ -f "${restore_dir}/media.tar.gz" ]]; then
        echo ""
        echo -n "Media dosyalarını da geri yüklemek ister misiniz? [e/H]: "
        read -r response
        
        if [[ "$response" =~ ^[eEyY]$ ]]; then
            info "Media dosyaları geri yükleniyor..."
            tar -xzf "${restore_dir}/media.tar.gz" -C "$INSTALL_DIR"
            success "Media dosyaları geri yüklendi"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  ✓ Geri Yükleme Tamamlandı${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Servisleri yeniden başlatmanız önerilir:"
    echo "  cd $INSTALL_DIR && docker compose -f docker-compose.prod.yml restart"
    echo ""
}

# =============================================================================
# LIST & CLEANUP
# =============================================================================

list_backups() {
    echo ""
    echo -e "${CYAN}${BOLD}Mevcut Yedekler${NC}"
    echo -e "${CYAN}$(printf '%.0s─' {1..60})${NC}"
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        info "Yedek dizini bulunamadı: $BACKUP_DIR"
        return 0
    fi
    
    local count=0
    local total_size=0
    
    printf "%-35s %12s %20s\n" "İsim" "Boyut" "Tarih"
    printf "%-35s %12s %20s\n" "$(printf '%.0s─' {1..35})" "$(printf '%.0s─' {1..12})" "$(printf '%.0s─' {1..20})"
    
    for backup in "$BACKUP_DIR"/backup_*.tar.gz "$BACKUP_DIR"/habernexus_backup_*.tar.gz; do
        if [[ -f "$backup" ]]; then
            local name=$(basename "$backup" .tar.gz)
            local size=$(get_file_size "$backup")
            local date_str=$(echo "$name" | grep -oE '[0-9]{8}_[0-9]{6}' | head -1)
            local formatted_date=""
            
            if [[ -n "$date_str" ]]; then
                formatted_date=$(echo "$date_str" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5/')
            fi
            
            printf "%-35s %12s %20s\n" "$name" "$(format_size $size)" "$formatted_date"
            
            ((count++))
            ((total_size+=size))
        fi
    done
    
    echo ""
    echo -e "Toplam: ${BOLD}$count${NC} yedek, ${BOLD}$(format_size $total_size)${NC}"
    echo ""
    
    if [[ $count -gt 0 ]]; then
        echo "Geri yüklemek için:"
        echo "  sudo bash scripts/backup.sh --restore <yedek_ismi>"
        echo ""
    fi
}

cleanup_old_backups() {
    local deleted=0
    
    # Tarihe göre temizle
    if [[ -d "$BACKUP_DIR" ]]; then
        while IFS= read -r backup; do
            if [[ -f "$backup" ]]; then
                rm -f "$backup"
                ((deleted++))
            fi
        done < <(find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS 2>/dev/null || true)
        
        while IFS= read -r backup; do
            if [[ -f "$backup" ]]; then
                rm -f "$backup"
                ((deleted++))
            fi
        done < <(find "$BACKUP_DIR" -name "habernexus_backup_*.tar.gz" -mtime +$RETENTION_DAYS 2>/dev/null || true)
    fi
    
    # Sayıya göre temizle
    if [[ -d "$BACKUP_DIR" ]]; then
        local backup_count=$(ls -1 "$BACKUP_DIR"/*backup_*.tar.gz 2>/dev/null | wc -l || echo "0")
        
        if [[ $backup_count -gt $MAX_BACKUPS ]]; then
            local to_delete=$((backup_count - MAX_BACKUPS))
            
            ls -1t "$BACKUP_DIR"/*backup_*.tar.gz 2>/dev/null | tail -n $to_delete | while read backup; do
                rm -f "$backup"
                ((deleted++))
            done
        fi
    fi
    
    if [[ $deleted -gt 0 ]]; then
        info "$deleted eski yedek temizlendi"
    fi
}

force_cleanup() {
    echo ""
    echo -e "${CYAN}${BOLD}Eski Yedekleri Temizleme${NC}"
    echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        info "Yedek dizini bulunamadı"
        return 0
    fi
    
    local backup_count=$(ls -1 "$BACKUP_DIR"/*backup_*.tar.gz 2>/dev/null | wc -l || echo "0")
    
    if [[ $backup_count -eq 0 ]]; then
        info "Temizlenecek yedek yok"
        return 0
    fi
    
    echo "Mevcut yedekler: $backup_count"
    echo "Saklama süresi: $RETENTION_DAYS gün"
    echo "Maksimum yedek: $MAX_BACKUPS"
    echo ""
    
    # Silinecekleri göster
    echo "Silinecek yedekler (${RETENTION_DAYS} günden eski):"
    find "$BACKUP_DIR" -name "*backup_*.tar.gz" -mtime +$RETENTION_DAYS 2>/dev/null | while read backup; do
        echo "  - $(basename $backup)"
    done
    
    echo ""
    echo -n "Devam etmek istiyor musunuz? [e/H]: "
    read -r response
    [[ "$response" =~ ^[eEyY]$ ]] || return 0
    
    cleanup_old_backups
    success "Temizlik tamamlandı"
}

# =============================================================================
# HELP
# =============================================================================

show_help() {
    cat << EOF
HaberNexus Yedekleme Sistemi v${SCRIPT_VERSION}

KULLANIM:
  sudo bash scripts/backup.sh [SEÇENEK]

SEÇENEKLER:
  (varsayılan)        Tam yedek al
  --full              Tam yedek al (veritabanı, redis, media, config)
  --database-only     Sadece veritabanı yedeği al
  --config-only       Sadece yapılandırma dosyalarını yedekle
  --list              Mevcut yedekleri listele
  --restore <isim>    Belirtilen yedeği geri yükle
  --cleanup           Eski yedekleri temizle
  --help              Bu yardım mesajını göster

ÖRNEKLER:
  # Tam yedek al
  sudo bash scripts/backup.sh

  # Yedekleri listele
  sudo bash scripts/backup.sh --list

  # Geri yükle
  sudo bash scripts/backup.sh --restore backup_20251218_120000

ORTAM DEĞİŞKENLERİ:
  BACKUP_DIR              Yedek dizini (varsayılan: /var/backups/habernexus)
  BACKUP_RETENTION_DAYS   Saklama süresi (varsayılan: 7 gün)
  MAX_BACKUPS             Maksimum yedek sayısı (varsayılan: 10)

EOF
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    case "${1:-}" in
        --full)
            create_backup "full"
            ;;
        --database-only)
            create_backup "database-only"
            ;;
        --config-only)
            create_backup "config-only"
            ;;
        --list)
            list_backups
            ;;
        --restore)
            [[ -n "${2:-}" ]] || fatal "Yedek ismi belirtilmedi"
            restore_backup "$2"
            ;;
        --cleanup)
            force_cleanup
            ;;
        --help|-h)
            show_help
            ;;
        "")
            create_backup "full"
            ;;
        *)
            error "Bilinmeyen seçenek: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
