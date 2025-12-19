#!/bin/bash
# =============================================================================
# HaberNexus - Akıllı Diagnostics & Health Check System v11.0.0
# =============================================================================
#
# Kurulum sonrası otomatik sağlık kontrolü, hata tespiti ve çözüm önerileri.
#
# KULLANIM:
#   sudo bash scripts/diagnostics.sh           # Tam diagnostik
#   sudo bash scripts/diagnostics.sh --quick   # Hızlı kontrol
#   sudo bash scripts/diagnostics.sh --fix     # Otomatik düzeltme dene
#   sudo bash scripts/diagnostics.sh --report  # Detaylı rapor oluştur
#
# GELİŞTİRİCİ: Salih TANRISEVEN
# =============================================================================

set +e

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly SCRIPT_VERSION="11.0.0"
readonly INSTALL_DIR="${INSTALL_DIR:-/opt/habernexus}"
readonly LOG_DIR="/var/log/habernexus"
readonly REPORT_FILE="${LOG_DIR}/diagnostics_$(date +%Y%m%d_%H%M%S).txt"

# Timeouts
readonly HEALTH_CHECK_TIMEOUT=10
readonly SERVICE_START_TIMEOUT=60

# =============================================================================
# COLORS & SYMBOLS
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

CHECK="✓"
CROSS="✗"
WARN="⚠"
ARROW="→"
BULLET="•"
WRENCH="🔧"
MAGNIFY="🔍"
LIGHTBULB="💡"
ROCKET="🚀"

# =============================================================================
# GLOBAL STATE
# =============================================================================

declare -a ERRORS=()
declare -a WARNINGS=()
declare -a FIXES=()
declare -A CHECK_RESULTS=()

QUICK_MODE=false
FIX_MODE=false
REPORT_MODE=false
VERBOSE=false

# =============================================================================
# LOGGING
# =============================================================================

info() { echo -e "${BLUE}${BULLET}${NC}  $*"; }
success() { echo -e "${GREEN}${CHECK}${NC}  $*"; }
warning() { 
    echo -e "${YELLOW}${WARN}${NC}  $*"
    WARNINGS+=("$*")
}
error() { 
    echo -e "${RED}${CROSS}${NC}  $*"
    ERRORS+=("$*")
}
fix_suggestion() {
    FIXES+=("$*")
}

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║     ${MAGNIFY} HaberNexus Diagnostics System v${SCRIPT_VERSION}              ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${MAGENTA}${BOLD}━━━ $1 ━━━${NC}"
    echo ""
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

get_container_status() {
    local container="$1"
    docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "not_found"
}

get_container_health() {
    local container="$1"
    docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$container" 2>/dev/null || echo "unknown"
}

get_container_logs() {
    local container="$1"
    local lines="${2:-50}"
    docker logs --tail "$lines" "$container" 2>&1
}

check_port() {
    local host="$1"
    local port="$2"
    timeout 5 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null
}

http_check() {
    local url="$1"
    local expected_code="${2:-200}"
    local actual_code
    actual_code=$(curl -fsSL -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null)
    [[ "$actual_code" == "$expected_code" ]] || [[ "$actual_code" == "301" ]] || [[ "$actual_code" == "302" ]]
}

# =============================================================================
# DIAGNOSTIC CHECKS
# =============================================================================

check_docker() {
    print_section "Docker Durumu"
    
    # Docker daemon
    if docker info > /dev/null 2>&1; then
        success "Docker daemon çalışıyor"
        CHECK_RESULTS["docker_daemon"]="OK"
        
        # Docker version
        local docker_version
        docker_version=$(docker --version 2>/dev/null | head -1)
        info "Versiyon: $docker_version"
    else
        error "Docker daemon çalışmıyor"
        CHECK_RESULTS["docker_daemon"]="FAIL"
        fix_suggestion "Docker servisini başlatın: sudo systemctl start docker"
        return 1
    fi
    
    # Docker Compose
    if docker compose version > /dev/null 2>&1; then
        success "Docker Compose mevcut"
        CHECK_RESULTS["docker_compose"]="OK"
    else
        error "Docker Compose bulunamadı"
        CHECK_RESULTS["docker_compose"]="FAIL"
        fix_suggestion "Docker Compose kurun: sudo apt-get install docker-compose-plugin"
    fi
    
    # Disk space
    local docker_root
    docker_root=$(docker info 2>/dev/null | grep "Docker Root Dir" | awk '{print $4}')
    if [[ -n "$docker_root" ]]; then
        local disk_free
        disk_free=$(df -BG "$docker_root" 2>/dev/null | awk 'NR==2 {gsub("G",""); print $4}')
        if [[ "$disk_free" -lt 5 ]]; then
            warning "Docker disk alanı düşük: ${disk_free}GB"
            fix_suggestion "Kullanılmayan Docker kaynaklarını temizleyin: docker system prune -a"
        else
            success "Docker disk alanı yeterli: ${disk_free}GB"
        fi
    fi
}

check_containers() {
    print_section "Container Durumları"
    
    local containers=(
        "habernexus-web:Django Web Uygulaması"
        "habernexus-postgres:PostgreSQL Veritabanı"
        "habernexus-redis:Redis Cache"
        "habernexus-caddy:Caddy Web Sunucusu"
        "habernexus-celery:Celery Worker"
    )
    
    local all_running=true
    
    for entry in "${containers[@]}"; do
        local container="${entry%%:*}"
        local description="${entry#*:}"
        local status
        status=$(get_container_status "$container")
        
        case "$status" in
            "running")
                success "$container: Çalışıyor"
                CHECK_RESULTS["container_$container"]="OK"
                
                # Health check varsa kontrol et
                local health
                health=$(get_container_health "$container")
                if [[ "$health" == "unhealthy" ]]; then
                    warning "  └─ Sağlık durumu: unhealthy"
                    CHECK_RESULTS["health_$container"]="WARN"
                fi
                ;;
            "exited")
                error "$container: Durmuş"
                CHECK_RESULTS["container_$container"]="FAIL"
                all_running=false
                
                # Exit code ve son logları göster
                local exit_code
                exit_code=$(docker inspect --format='{{.State.ExitCode}}' "$container" 2>/dev/null)
                info "  └─ Exit code: $exit_code"
                
                # Hata analizi
                analyze_container_error "$container"
                ;;
            "restarting")
                warning "$container: Yeniden başlatılıyor"
                CHECK_RESULTS["container_$container"]="WARN"
                
                # Restart loop kontrolü
                local restart_count
                restart_count=$(docker inspect --format='{{.RestartCount}}' "$container" 2>/dev/null)
                if [[ "$restart_count" -gt 5 ]]; then
                    error "  └─ Restart döngüsünde: $restart_count kez yeniden başlatıldı"
                    analyze_container_error "$container"
                fi
                ;;
            "not_found")
                error "$container: Bulunamadı"
                CHECK_RESULTS["container_$container"]="MISSING"
                all_running=false
                fix_suggestion "Container'ları başlatın: cd $INSTALL_DIR && docker compose -f docker-compose.prod.yml up -d"
                ;;
            *)
                warning "$container: Bilinmeyen durum ($status)"
                CHECK_RESULTS["container_$container"]="UNKNOWN"
                ;;
        esac
    done
    
    return $([[ "$all_running" == true ]] && echo 0 || echo 1)
}

analyze_container_error() {
    local container="$1"
    local logs
    logs=$(get_container_logs "$container" 30)
    
    # Yaygın hata kalıpları
    if echo "$logs" | grep -qi "permission denied"; then
        error "  └─ İzin hatası tespit edildi"
        fix_suggestion "Dosya izinlerini düzeltin: sudo chown -R 1000:1000 $INSTALL_DIR"
    fi
    
    if echo "$logs" | grep -qi "connection refused\|could not connect"; then
        error "  └─ Bağlantı hatası tespit edildi"
        fix_suggestion "Bağımlı servislerin çalıştığından emin olun"
    fi
    
    if echo "$logs" | grep -qi "out of memory\|oom"; then
        error "  └─ Bellek yetersizliği tespit edildi"
        fix_suggestion "Sistem belleğini artırın veya swap ekleyin"
    fi
    
    if echo "$logs" | grep -qi "database.*does not exist\|relation.*does not exist"; then
        error "  └─ Veritabanı hatası tespit edildi"
        fix_suggestion "Migration'ları çalıştırın: docker exec habernexus-web python manage.py migrate"
    fi
    
    if echo "$logs" | grep -qi "secret_key\|secretkey"; then
        error "  └─ Secret key hatası tespit edildi"
        fix_suggestion ".env dosyasında DJANGO_SECRET_KEY değerini kontrol edin"
    fi
    
    if echo "$logs" | grep -qi "module.*not found\|no module named"; then
        error "  └─ Python modül hatası tespit edildi"
        fix_suggestion "Container'ı yeniden build edin: docker compose -f docker-compose.prod.yml build --no-cache"
    fi
}

check_database() {
    print_section "Veritabanı Bağlantısı"
    
    local db_container="habernexus-postgres"
    
    if [[ "$(get_container_status $db_container)" != "running" ]]; then
        error "PostgreSQL container çalışmıyor"
        CHECK_RESULTS["database"]="FAIL"
        return 1
    fi
    
    # PostgreSQL bağlantı testi
    if docker exec "$db_container" pg_isready -U habernexus_user -d habernexus > /dev/null 2>&1; then
        success "PostgreSQL bağlantısı başarılı"
        CHECK_RESULTS["database"]="OK"
        
        # Veritabanı boyutu
        local db_size
        db_size=$(docker exec "$db_container" psql -U habernexus_user -d habernexus -t -c "SELECT pg_size_pretty(pg_database_size('habernexus'));" 2>/dev/null | tr -d ' ')
        if [[ -n "$db_size" ]]; then
            info "Veritabanı boyutu: $db_size"
        fi
        
        # Bağlantı sayısı
        local connections
        connections=$(docker exec "$db_container" psql -U habernexus_user -d habernexus -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | tr -d ' ')
        if [[ -n "$connections" ]]; then
            info "Aktif bağlantılar: $connections"
            if [[ "$connections" -gt 90 ]]; then
                warning "Bağlantı sayısı yüksek, limit kontrolü yapın"
            fi
        fi
    else
        error "PostgreSQL bağlantısı başarısız"
        CHECK_RESULTS["database"]="FAIL"
        
        # Detaylı hata analizi
        local db_logs
        db_logs=$(get_container_logs "$db_container" 20)
        
        if echo "$db_logs" | grep -qi "password authentication failed"; then
            fix_suggestion ".env dosyasındaki DB_PASSWORD değerini kontrol edin"
        fi
        
        if echo "$db_logs" | grep -qi "database.*does not exist"; then
            fix_suggestion "Veritabanını oluşturun: docker exec $db_container createdb -U habernexus_user habernexus"
        fi
    fi
}

check_redis() {
    print_section "Redis Cache"
    
    local redis_container="habernexus-redis"
    
    if [[ "$(get_container_status $redis_container)" != "running" ]]; then
        error "Redis container çalışmıyor"
        CHECK_RESULTS["redis"]="FAIL"
        return 1
    fi
    
    # Redis ping testi
    if docker exec "$redis_container" redis-cli ping 2>/dev/null | grep -q "PONG"; then
        success "Redis bağlantısı başarılı"
        CHECK_RESULTS["redis"]="OK"
        
        # Redis bellek kullanımı
        local redis_memory
        redis_memory=$(docker exec "$redis_container" redis-cli info memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
        if [[ -n "$redis_memory" ]]; then
            info "Redis bellek kullanımı: $redis_memory"
        fi
        
        # Key sayısı
        local key_count
        key_count=$(docker exec "$redis_container" redis-cli dbsize 2>/dev/null | awk '{print $2}')
        if [[ -n "$key_count" ]]; then
            info "Toplam key sayısı: $key_count"
        fi
    else
        error "Redis bağlantısı başarısız"
        CHECK_RESULTS["redis"]="FAIL"
        fix_suggestion "Redis container'ını yeniden başlatın: docker restart $redis_container"
    fi
}

check_web_service() {
    print_section "Web Servisi"
    
    local web_container="habernexus-web"
    
    if [[ "$(get_container_status $web_container)" != "running" ]]; then
        error "Web container çalışmıyor"
        CHECK_RESULTS["web_service"]="FAIL"
        return 1
    fi
    
    # Gunicorn process kontrolü
    if docker exec "$web_container" pgrep -f gunicorn > /dev/null 2>&1; then
        success "Gunicorn çalışıyor"
        CHECK_RESULTS["gunicorn"]="OK"
        
        # Worker sayısı
        local worker_count
        worker_count=$(docker exec "$web_container" pgrep -f "gunicorn.*worker" 2>/dev/null | wc -l)
        info "Gunicorn worker sayısı: $worker_count"
    else
        warning "Gunicorn process bulunamadı"
        CHECK_RESULTS["gunicorn"]="WARN"
    fi
    
    # Django health check
    if docker exec "$web_container" python manage.py check > /dev/null 2>&1; then
        success "Django sistem kontrolü başarılı"
        CHECK_RESULTS["django_check"]="OK"
    else
        warning "Django sistem kontrolünde uyarılar var"
        CHECK_RESULTS["django_check"]="WARN"
        
        # Detaylı Django check
        local django_issues
        django_issues=$(docker exec "$web_container" python manage.py check 2>&1)
        if echo "$django_issues" | grep -qi "error"; then
            error "Django hataları:"
            echo "$django_issues" | grep -i "error" | head -5 | sed 's/^/    /'
        fi
    fi
    
    # Internal HTTP check (container içinden)
    if docker exec "$web_container" curl -fsSL --connect-timeout 5 http://localhost:8000/health/ > /dev/null 2>&1; then
        success "Internal HTTP check başarılı"
        CHECK_RESULTS["internal_http"]="OK"
    else
        warning "Internal HTTP check başarısız"
        CHECK_RESULTS["internal_http"]="WARN"
    fi
}

check_caddy() {
    print_section "Caddy Web Sunucusu"
    
    local caddy_container="habernexus-caddy"
    
    if [[ "$(get_container_status $caddy_container)" != "running" ]]; then
        error "Caddy container çalışmıyor"
        CHECK_RESULTS["caddy"]="FAIL"
        return 1
    fi
    
    success "Caddy çalışıyor"
    CHECK_RESULTS["caddy"]="OK"
    
    # Caddyfile kontrolü
    if docker exec "$caddy_container" caddy validate --config /etc/caddy/Caddyfile > /dev/null 2>&1; then
        success "Caddyfile yapılandırması geçerli"
    else
        warning "Caddyfile yapılandırmasında sorun olabilir"
        fix_suggestion "Caddyfile'ı kontrol edin: cat $INSTALL_DIR/caddy/Caddyfile"
    fi
    
    # SSL sertifika kontrolü
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        local domain
        domain=$(grep -E '^DOMAIN=' "$INSTALL_DIR/.env" | cut -d'=' -f2)
        
        if [[ -n "$domain" ]] && [[ "$domain" != "localhost" ]]; then
            # HTTPS erişim testi
            if curl -fsSL --connect-timeout 10 "https://$domain" > /dev/null 2>&1; then
                success "HTTPS erişimi başarılı: $domain"
                CHECK_RESULTS["https"]="OK"
                
                # SSL sertifika bilgisi
                local ssl_info
                ssl_info=$(echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
                if [[ -n "$ssl_info" ]]; then
                    local not_after
                    not_after=$(echo "$ssl_info" | grep "notAfter" | cut -d= -f2)
                    info "SSL sertifika bitiş: $not_after"
                fi
            else
                warning "HTTPS erişimi başarısız"
                CHECK_RESULTS["https"]="WARN"
                fix_suggestion "DNS ayarlarını ve port yönlendirmelerini kontrol edin"
            fi
        fi
    fi
}

check_celery() {
    print_section "Celery Worker"
    
    local celery_container="habernexus-celery"
    
    if [[ "$(get_container_status $celery_container)" != "running" ]]; then
        warning "Celery container çalışmıyor (opsiyonel)"
        CHECK_RESULTS["celery"]="WARN"
        return 0
    fi
    
    success "Celery çalışıyor"
    CHECK_RESULTS["celery"]="OK"
    
    # Celery inspect
    local celery_status
    celery_status=$(docker exec "$celery_container" celery -A habernexus_config inspect ping 2>&1)
    
    if echo "$celery_status" | grep -q "pong"; then
        success "Celery worker yanıt veriyor"
        
        # Aktif görev sayısı
        local active_tasks
        active_tasks=$(docker exec "$celery_container" celery -A habernexus_config inspect active 2>/dev/null | grep -c "id" || echo "0")
        info "Aktif görevler: $active_tasks"
    else
        warning "Celery worker yanıt vermiyor"
        fix_suggestion "Celery container'ını yeniden başlatın: docker restart $celery_container"
    fi
}

check_network() {
    print_section "Ağ Bağlantıları"
    
    # Docker network
    if docker network ls | grep -q "habernexus"; then
        success "Docker network mevcut"
        CHECK_RESULTS["docker_network"]="OK"
    else
        warning "HaberNexus Docker network bulunamadı"
        CHECK_RESULTS["docker_network"]="WARN"
    fi
    
    # Port kontrolü
    local ports=("80:HTTP" "443:HTTPS" "5432:PostgreSQL" "6379:Redis")
    
    for entry in "${ports[@]}"; do
        local port="${entry%%:*}"
        local service="${entry#*:}"
        
        if check_port "localhost" "$port"; then
            success "Port $port ($service) açık"
        else
            if [[ "$port" == "80" ]] || [[ "$port" == "443" ]]; then
                warning "Port $port ($service) erişilebilir değil"
                fix_suggestion "Firewall ayarlarını kontrol edin: sudo ufw allow $port"
            fi
        fi
    done
    
    # DNS çözümleme
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        local domain
        domain=$(grep -E '^DOMAIN=' "$INSTALL_DIR/.env" | cut -d'=' -f2)
        
        if [[ -n "$domain" ]] && [[ "$domain" != "localhost" ]]; then
            local resolved_ip
            resolved_ip=$(dig +short "$domain" 2>/dev/null | head -1)
            
            if [[ -n "$resolved_ip" ]]; then
                success "DNS çözümleme başarılı: $domain → $resolved_ip"
                
                # IP karşılaştırma
                local server_ip
                server_ip=$(curl -fsSL --connect-timeout 5 https://api.ipify.org 2>/dev/null)
                
                if [[ "$resolved_ip" == "$server_ip" ]]; then
                    success "DNS doğru sunucuya yönlendirilmiş"
                else
                    warning "DNS farklı bir IP'ye yönlendirilmiş"
                    info "  DNS IP: $resolved_ip"
                    info "  Sunucu IP: $server_ip"
                    fix_suggestion "DNS kaydını $server_ip olarak güncelleyin"
                fi
            else
                warning "DNS çözümlenemedi: $domain"
                fix_suggestion "DNS kaydı oluşturun veya propagasyon için bekleyin"
            fi
        fi
    fi
}

check_disk_space() {
    print_section "Disk Alanı"
    
    local disk_usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    local disk_free
    disk_free=$(df -BG / | awk 'NR==2 {gsub("G",""); print $4}')
    
    if [[ "$disk_usage" -gt 90 ]]; then
        error "Disk kullanımı kritik: %$disk_usage"
        CHECK_RESULTS["disk"]="FAIL"
        fix_suggestion "Disk alanı açın: docker system prune -a"
    elif [[ "$disk_usage" -gt 80 ]]; then
        warning "Disk kullanımı yüksek: %$disk_usage"
        CHECK_RESULTS["disk"]="WARN"
    else
        success "Disk kullanımı normal: %$disk_usage (${disk_free}GB boş)"
        CHECK_RESULTS["disk"]="OK"
    fi
    
    # Docker volume boyutları
    info "Docker volume boyutları:"
    docker system df -v 2>/dev/null | grep -E "habernexus|postgres|redis" | head -5 | sed 's/^/  /'
}

check_memory() {
    print_section "Bellek Durumu"
    
    local mem_total
    mem_total=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
    local mem_available
    mem_available=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
    local mem_used=$((mem_total - mem_available))
    local mem_percent=$((mem_used * 100 / mem_total))
    
    if [[ "$mem_percent" -gt 90 ]]; then
        error "Bellek kullanımı kritik: %$mem_percent"
        CHECK_RESULTS["memory"]="FAIL"
        fix_suggestion "Bellek yetersiz. Swap ekleyin veya RAM artırın."
    elif [[ "$mem_percent" -gt 80 ]]; then
        warning "Bellek kullanımı yüksek: %$mem_percent"
        CHECK_RESULTS["memory"]="WARN"
    else
        success "Bellek kullanımı normal: %$mem_percent (${mem_available}MB boş)"
        CHECK_RESULTS["memory"]="OK"
    fi
    
    # Container bellek kullanımı
    info "Container bellek kullanımı:"
    docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}" 2>/dev/null | grep habernexus | sed 's/^/  /'
}

check_logs_for_errors() {
    print_section "Log Analizi"
    
    local containers=("habernexus-web" "habernexus-postgres" "habernexus-celery")
    
    for container in "${containers[@]}"; do
        if [[ "$(get_container_status $container)" == "running" ]]; then
            local error_count
            error_count=$(docker logs --since 1h "$container" 2>&1 | grep -ci "error\|exception\|critical" || echo "0")
            
            if [[ "$error_count" -gt 10 ]]; then
                warning "$container: Son 1 saatte $error_count hata"
                
                # En son hataları göster
                info "  Son hatalar:"
                docker logs --since 1h "$container" 2>&1 | grep -i "error\|exception" | tail -3 | sed 's/^/    /'
            elif [[ "$error_count" -gt 0 ]]; then
                info "$container: Son 1 saatte $error_count hata (normal seviye)"
            else
                success "$container: Hata yok"
            fi
        fi
    done
}

# =============================================================================
# AUTO-FIX FUNCTIONS
# =============================================================================

auto_fix() {
    print_section "${WRENCH} Otomatik Düzeltme"
    
    local fixed=0
    
    # Container'ları yeniden başlat
    for container in habernexus-web habernexus-postgres habernexus-redis habernexus-caddy habernexus-celery; do
        local status
        status=$(get_container_status "$container")
        
        if [[ "$status" == "exited" ]] || [[ "$status" == "restarting" ]]; then
            info "Yeniden başlatılıyor: $container"
            if docker restart "$container" > /dev/null 2>&1; then
                success "  $container yeniden başlatıldı"
                ((fixed++))
            fi
        fi
    done
    
    # Tüm container'lar durduysa, compose up dene
    local running_count
    running_count=$(docker ps --filter "name=habernexus" --format '{{.Names}}' 2>/dev/null | wc -l)
    
    if [[ "$running_count" -lt 3 ]]; then
        info "Servisler başlatılıyor..."
        if cd "$INSTALL_DIR" && docker compose -f docker-compose.prod.yml up -d > /dev/null 2>&1; then
            success "Servisler başlatıldı"
            ((fixed++))
        fi
    fi
    
    # Migration kontrolü
    if docker exec habernexus-web python manage.py showmigrations 2>&1 | grep -q "\[ \]"; then
        info "Bekleyen migration'lar uygulanıyor..."
        if docker exec habernexus-web python manage.py migrate --noinput > /dev/null 2>&1; then
            success "Migration'lar uygulandı"
            ((fixed++))
        fi
    fi
    
    # Static files
    if [[ ! -d "$INSTALL_DIR/staticfiles" ]] || [[ -z "$(ls -A $INSTALL_DIR/staticfiles 2>/dev/null)" ]]; then
        info "Static dosyalar toplanıyor..."
        if docker exec habernexus-web python manage.py collectstatic --noinput > /dev/null 2>&1; then
            success "Static dosyalar toplandı"
            ((fixed++))
        fi
    fi
    
    echo ""
    if [[ $fixed -gt 0 ]]; then
        success "$fixed düzeltme uygulandı"
    else
        info "Otomatik düzeltme gerekmiyor"
    fi
}

# =============================================================================
# REPORT GENERATION
# =============================================================================

generate_report() {
    mkdir -p "$LOG_DIR"
    
    {
        echo "HaberNexus Diagnostics Report"
        echo "=============================="
        echo "Tarih: $(date)"
        echo "Hostname: $(hostname)"
        echo "Versiyon: $SCRIPT_VERSION"
        echo ""
        echo "ÖZET"
        echo "----"
        echo "Hatalar: ${#ERRORS[@]}"
        echo "Uyarılar: ${#WARNINGS[@]}"
        echo ""
        
        if [[ ${#ERRORS[@]} -gt 0 ]]; then
            echo "HATALAR"
            echo "-------"
            for err in "${ERRORS[@]}"; do
                echo "• $err"
            done
            echo ""
        fi
        
        if [[ ${#WARNINGS[@]} -gt 0 ]]; then
            echo "UYARILAR"
            echo "--------"
            for warn in "${WARNINGS[@]}"; do
                echo "• $warn"
            done
            echo ""
        fi
        
        if [[ ${#FIXES[@]} -gt 0 ]]; then
            echo "ÖNERİLEN DÜZELTMELER"
            echo "--------------------"
            for fix in "${FIXES[@]}"; do
                echo "→ $fix"
            done
            echo ""
        fi
        
        echo "DETAYLI KONTROL SONUÇLARI"
        echo "-------------------------"
        for key in "${!CHECK_RESULTS[@]}"; do
            echo "$key: ${CHECK_RESULTS[$key]}"
        done
        echo ""
        
        echo "SİSTEM BİLGİLERİ"
        echo "----------------"
        echo "OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)"
        echo "Kernel: $(uname -r)"
        echo "Docker: $(docker --version 2>/dev/null)"
        echo "Bellek: $(awk '/MemTotal/ {print int($2/1024)"MB"}' /proc/meminfo)"
        echo "Disk: $(df -h / | awk 'NR==2 {print $4 " boş"}')"
        
    } > "$REPORT_FILE"
    
    success "Rapor oluşturuldu: $REPORT_FILE"
}

# =============================================================================
# SUMMARY
# =============================================================================

print_summary() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║                      SONUÇ ÖZETİ                             ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local total_checks=${#CHECK_RESULTS[@]}
    local ok_count=0
    local warn_count=0
    local fail_count=0
    
    for result in "${CHECK_RESULTS[@]}"; do
        case "$result" in
            "OK") ((ok_count++)) ;;
            "WARN") ((warn_count++)) ;;
            "FAIL"|"MISSING") ((fail_count++)) ;;
        esac
    done
    
    echo -e "  ${GREEN}${CHECK} Başarılı:${NC} $ok_count"
    echo -e "  ${YELLOW}${WARN} Uyarı:${NC}    $warn_count"
    echo -e "  ${RED}${CROSS} Hata:${NC}     $fail_count"
    echo ""
    
    if [[ $fail_count -eq 0 ]] && [[ $warn_count -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}${ROCKET} Tüm kontroller başarılı! Sistem sağlıklı.${NC}"
    elif [[ $fail_count -eq 0 ]]; then
        echo -e "  ${YELLOW}${BOLD}Sistem çalışıyor ancak bazı uyarılar var.${NC}"
    else
        echo -e "  ${RED}${BOLD}Kritik sorunlar tespit edildi!${NC}"
    fi
    
    # Düzeltme önerileri
    if [[ ${#FIXES[@]} -gt 0 ]]; then
        echo ""
        echo -e "${MAGENTA}${BOLD}${LIGHTBULB} Önerilen Düzeltmeler:${NC}"
        echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"
        
        local i=1
        for fix in "${FIXES[@]}"; do
            echo -e "  ${CYAN}$i.${NC} $fix"
            ((i++))
        done
        
        echo ""
        echo -e "${DIM}Otomatik düzeltme denemek için: sudo bash scripts/diagnostics.sh --fix${NC}"
    fi
    
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quick|-q)
                QUICK_MODE=true
                shift
                ;;
            --fix|-f)
                FIX_MODE=true
                shift
                ;;
            --report|-r)
                REPORT_MODE=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                echo "Kullanım: sudo bash scripts/diagnostics.sh [SEÇENEKLER]"
                echo ""
                echo "Seçenekler:"
                echo "  --quick, -q    Hızlı kontrol (sadece kritik servisler)"
                echo "  --fix, -f      Otomatik düzeltme dene"
                echo "  --report, -r   Detaylı rapor oluştur"
                echo "  --verbose, -v  Ayrıntılı çıktı"
                echo "  --help, -h     Bu yardım mesajı"
                exit 0
                ;;
            *)
                echo "Bilinmeyen parametre: $1"
                exit 1
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    
    print_header
    
    # Temel kontroller
    check_docker
    check_containers
    
    if [[ "$QUICK_MODE" != true ]]; then
        check_database
        check_redis
        check_web_service
        check_caddy
        check_celery
        check_network
        check_disk_space
        check_memory
        check_logs_for_errors
    fi
    
    # Otomatik düzeltme
    if [[ "$FIX_MODE" == true ]]; then
        auto_fix
    fi
    
    # Rapor oluştur
    if [[ "$REPORT_MODE" == true ]]; then
        generate_report
    fi
    
    # Özet
    print_summary
    
    # Exit code
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
