#!/bin/bash
# =============================================================================
# HaberNexus - Manuel Kurulum Rehberi v11.0.0
# =============================================================================
#
# Bu script, HaberNexus'u adım adım manuel olarak kurmanızı sağlar.
# Her adımda ne yapıldığını açıklar ve onayınızı alır.
#
# KULLANIM:
#   sudo bash scripts/manual-setup.sh
#
# =============================================================================

set -e

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
ARROW="→"
BULLET="•"

# =============================================================================
# GLOBAL VARIABLES
# =============================================================================

INSTALL_DIR="/opt/habernexus"
CURRENT_STEP=0
TOTAL_STEPS=10

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

print_header() {
    clear
    echo ""
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
  ╔══════════════════════════════════════════════════════════════╗
  ║         HaberNexus Manuel Kurulum Rehberi v11.0.0            ║
  ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${DIM}Her adımda ne yapıldığını görecek ve onaylayacaksınız.${NC}"
    echo ""
}

print_step() {
    local step_num="$1"
    local step_title="$2"
    local step_desc="$3"
    
    CURRENT_STEP=$step_num
    
    echo ""
    echo -e "${MAGENTA}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}${BOLD}  ADIM $step_num/$TOTAL_STEPS: $step_title${NC}"
    echo -e "${MAGENTA}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${DIM}$step_desc${NC}"
    echo ""
}

print_command() {
    echo -e "${CYAN}${ARROW} Çalıştırılacak komut:${NC}"
    echo -e "   ${YELLOW}$1${NC}"
    echo ""
}

print_commands() {
    echo -e "${CYAN}${ARROW} Çalıştırılacak komutlar:${NC}"
    for cmd in "$@"; do
        echo -e "   ${YELLOW}$cmd${NC}"
    done
    echo ""
}

print_explanation() {
    echo -e "${BLUE}${BULLET} Açıklama:${NC}"
    echo -e "   $1"
    echo ""
}

success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

info() {
    echo -e "${BLUE}${BULLET} $1${NC}"
}

confirm() {
    local prompt="$1"
    local response
    
    echo -n -e "${BOLD}$prompt [E/h/a]: ${NC}"
    read -r response
    
    case "$response" in
        [aA])
            echo ""
            warning "Kurulum iptal edildi."
            exit 0
            ;;
        [hH])
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

wait_for_enter() {
    echo ""
    echo -n -e "${DIM}Devam etmek için Enter'a basın...${NC}"
    read -r
}

run_command() {
    local cmd="$1"
    local desc="$2"
    
    info "$desc"
    if eval "$cmd"; then
        success "Tamamlandı"
        return 0
    else
        error "Hata oluştu"
        return 1
    fi
}

# =============================================================================
# STEP 1: SYSTEM CHECK
# =============================================================================

step_system_check() {
    print_step 1 "Sistem Gereksinimleri Kontrolü" \
        "Bu adımda sunucunuzun HaberNexus için uygun olup olmadığı kontrol edilir."
    
    print_explanation "Kontrol edilecekler:
   • Root yetkisi
   • İşletim sistemi (Ubuntu 20.04/22.04/24.04 önerilir)
   • Bellek (minimum 1GB, önerilen 2GB)
   • Disk alanı (minimum 10GB)
   • İnternet bağlantısı"
    
    if ! confirm "Sistem kontrolü yapılsın mı?"; then
        warning "Sistem kontrolü atlandı"
        return 0
    fi
    
    echo ""
    
    # Root kontrolü
    if [[ $EUID -eq 0 ]]; then
        success "Root yetkisi: OK"
    else
        error "Root yetkisi gerekli!"
        echo "   Çözüm: 'sudo bash $0' ile çalıştırın"
        exit 1
    fi
    
    # İşletim sistemi
    if [[ -r /etc/os-release ]]; then
        local distro=$(. /etc/os-release && echo "$ID")
        local version=$(. /etc/os-release && echo "$VERSION_ID")
        success "İşletim sistemi: $distro $version"
    fi
    
    # Bellek
    local mem_mb=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
    if [[ $mem_mb -ge 1024 ]]; then
        success "Bellek: ${mem_mb}MB"
    else
        warning "Bellek: ${mem_mb}MB (minimum 1024MB önerilir)"
    fi
    
    # Disk
    local disk_gb=$(df -BG / | awk 'NR==2 {gsub("G",""); print $4}')
    if [[ $disk_gb -ge 10 ]]; then
        success "Disk alanı: ${disk_gb}GB boş"
    else
        warning "Disk alanı: ${disk_gb}GB (minimum 10GB önerilir)"
    fi
    
    # İnternet
    if curl -fsSL --connect-timeout 5 https://github.com > /dev/null 2>&1; then
        success "İnternet bağlantısı: OK"
    else
        error "İnternet bağlantısı yok!"
        exit 1
    fi
    
    wait_for_enter
}

# =============================================================================
# STEP 2: EXISTING INSTALLATION CHECK
# =============================================================================

step_existing_check() {
    print_step 2 "Mevcut Kurulum Kontrolü" \
        "Daha önce yapılmış bir HaberNexus kurulumu olup olmadığı kontrol edilir."
    
    print_explanation "Kontrol edilecekler:
   • $INSTALL_DIR dizini
   • Docker container'ları
   • Docker volume'ları"
    
    if ! confirm "Mevcut kurulum kontrolü yapılsın mı?"; then
        warning "Kontrol atlandı"
        return 0
    fi
    
    echo ""
    
    local has_existing=false
    
    # Dizin kontrolü
    if [[ -d "$INSTALL_DIR" ]]; then
        warning "Mevcut kurulum dizini bulundu: $INSTALL_DIR"
        has_existing=true
    else
        success "Kurulum dizini temiz"
    fi
    
    # Docker container kontrolü
    if command -v docker &> /dev/null; then
        local containers=$(docker ps -a --filter "name=habernexus" --format '{{.Names}}' 2>/dev/null | wc -l)
        if [[ $containers -gt 0 ]]; then
            warning "HaberNexus container'ları bulundu: $containers adet"
            has_existing=true
        else
            success "HaberNexus container'ı yok"
        fi
    fi
    
    if [[ "$has_existing" == true ]]; then
        echo ""
        warning "Mevcut kurulum tespit edildi!"
        echo ""
        echo "Seçenekler:"
        echo "  1) Mevcut kurulumu temizle ve yeniden kur"
        echo "  2) Mevcut kurulumu koru (güncelleme)"
        echo "  3) Kurulumu iptal et"
        echo ""
        echo -n "Seçiminiz [1/2/3]: "
        read -r choice
        
        case "$choice" in
            1)
                info "Mevcut kurulum temizlenecek..."
                if confirm "Önce yedek almak ister misiniz?"; then
                    bash "$INSTALL_DIR/setup.sh" --backup 2>/dev/null || true
                fi
                docker compose -f "$INSTALL_DIR/docker-compose.prod.yml" down -v 2>/dev/null || true
                rm -rf "$INSTALL_DIR"
                success "Mevcut kurulum temizlendi"
                ;;
            2)
                info "Mevcut kurulum korunacak"
                ;;
            3)
                warning "Kurulum iptal edildi"
                exit 0
                ;;
        esac
    fi
    
    wait_for_enter
}

# =============================================================================
# STEP 3: INSTALL DEPENDENCIES
# =============================================================================

step_install_dependencies() {
    print_step 3 "Bağımlılıkların Kurulumu" \
        "HaberNexus için gerekli sistem paketleri ve Docker kurulur."
    
    print_explanation "Kurulacak paketler:
   • curl, wget, git - Temel araçlar
   • Docker - Container platformu
   • Docker Compose - Çoklu container yönetimi
   • jq - JSON işleme aracı
   • whiptail - TUI arayüzü"
    
    print_commands \
        "apt-get update" \
        "apt-get install -y curl wget git jq whiptail" \
        "curl -fsSL https://get.docker.com | sh"
    
    if ! confirm "Bağımlılıklar kurulsun mu?"; then
        warning "Bağımlılık kurulumu atlandı"
        return 0
    fi
    
    echo ""
    
    # Paket listesi güncelle
    run_command "apt-get update -qq" "Paket listesi güncelleniyor..."
    
    # Temel paketler
    run_command "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl wget git jq whiptail ca-certificates gnupg lsb-release" \
        "Temel paketler kuruluyor..."
    
    # Docker
    if ! command -v docker &> /dev/null; then
        run_command "curl -fsSL https://get.docker.com | sh" "Docker kuruluyor..."
    else
        success "Docker zaten kurulu"
    fi
    
    # Docker servisini başlat
    run_command "systemctl enable docker && systemctl start docker" "Docker servisi başlatılıyor..."
    
    # Docker versiyonları göster
    echo ""
    info "Kurulu versiyonlar:"
    docker --version
    docker compose version
    
    wait_for_enter
}

# =============================================================================
# STEP 4: CLONE REPOSITORY
# =============================================================================

step_clone_repository() {
    print_step 4 "Proje Dosyalarının İndirilmesi" \
        "HaberNexus kaynak kodları GitHub'dan indirilir."
    
    print_explanation "İşlem:
   • GitHub'dan proje klonlanır
   • Hedef dizin: $INSTALL_DIR"
    
    print_command "git clone https://github.com/sata2500/habernexus.git $INSTALL_DIR"
    
    if ! confirm "Proje dosyaları indirilsin mi?"; then
        warning "İndirme atlandı"
        return 0
    fi
    
    echo ""
    
    if [[ -d "$INSTALL_DIR" ]]; then
        info "Mevcut dizin güncelleniyor..."
        cd "$INSTALL_DIR"
        run_command "git pull" "Güncellemeler alınıyor..."
    else
        run_command "git clone --depth 1 https://github.com/sata2500/habernexus.git $INSTALL_DIR" \
            "Proje indiriliyor..."
    fi
    
    success "Proje dosyaları hazır: $INSTALL_DIR"
    
    wait_for_enter
}

# =============================================================================
# STEP 5: CONFIGURE ENVIRONMENT
# =============================================================================

step_configure_environment() {
    print_step 5 "Ortam Değişkenlerinin Yapılandırılması" \
        ".env dosyası oluşturulur ve yapılandırma değerleri girilir."
    
    print_explanation "Yapılandırılacaklar:
   • Domain adı
   • Admin kullanıcı bilgileri
   • Veritabanı şifreleri
   • Secret key
   • Cloudflare (opsiyonel)
   • Google AI API (opsiyonel)"
    
    if ! confirm "Ortam değişkenleri yapılandırılsın mı?"; then
        warning "Yapılandırma atlandı"
        return 0
    fi
    
    echo ""
    cd "$INSTALL_DIR"
    
    # Domain
    echo -n "Domain adı [localhost]: "
    read -r DOMAIN
    DOMAIN=${DOMAIN:-localhost}
    
    # Admin bilgileri
    echo -n "Admin kullanıcı adı [admin]: "
    read -r ADMIN_USERNAME
    ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
    
    echo -n "Admin e-posta [admin@$DOMAIN]: "
    read -r ADMIN_EMAIL
    ADMIN_EMAIL=${ADMIN_EMAIL:-admin@$DOMAIN}
    
    echo -n "Admin şifresi (boş = otomatik): "
    read -rs ADMIN_PASSWORD
    echo ""
    
    if [[ -z "$ADMIN_PASSWORD" ]]; then
        ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
        info "Otomatik şifre oluşturuldu: $ADMIN_PASSWORD"
    fi
    
    # Otomatik değerler
    DB_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 24)
    SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))' 2>/dev/null || openssl rand -base64 50)
    
    # DEBUG
    local DEBUG="False"
    if [[ "$DOMAIN" == "localhost" ]]; then
        if confirm "Geliştirici modu (DEBUG=True) aktif edilsin mi?"; then
            DEBUG="True"
        fi
    fi
    
    # Cloudflare
    local USE_CLOUDFLARE="false"
    local CLOUDFLARE_TOKEN=""
    if [[ "$DOMAIN" != "localhost" ]]; then
        if confirm "Cloudflare Tunnel kullanmak ister misiniz?"; then
            USE_CLOUDFLARE="true"
            echo -n "Cloudflare Tunnel Token: "
            read -r CLOUDFLARE_TOKEN
        fi
    fi
    
    # Google AI
    local GOOGLE_API_KEY=""
    if confirm "Google AI API kullanmak ister misiniz?"; then
        echo -n "Google AI API Key: "
        read -r GOOGLE_API_KEY
    fi
    
    # SSL ayarları
    local SSL_REDIRECT="True"
    local COOKIE_SECURE="True"
    if [[ "$DOMAIN" == "localhost" ]]; then
        SSL_REDIRECT="False"
        COOKIE_SECURE="False"
    fi
    
    # .env dosyası oluştur
    cat > .env << ENVEOF
# HaberNexus Environment Configuration
# Generated: $(date)

DEBUG=$DEBUG
DJANGO_SECRET_KEY=$SECRET_KEY
ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN,localhost,127.0.0.1

DB_ENGINE=django.db.backends.postgresql
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=$DB_PASSWORD
DB_HOST=postgres
DB_PORT=5432

REDIS_URL=redis://redis:6379/0
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

DOMAIN=$DOMAIN
SECURE_SSL_REDIRECT=$SSL_REDIRECT
SESSION_COOKIE_SECURE=$COOKIE_SECURE
CSRF_COOKIE_SECURE=$COOKIE_SECURE

ADMIN_USERNAME=$ADMIN_USERNAME
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD

GOOGLE_GEMINI_API_KEY=$GOOGLE_API_KEY
AI_MODEL=gemini-2.5-flash

USE_CLOUDFLARE=$USE_CLOUDFLARE
CLOUDFLARE_TUNNEL_TOKEN=$CLOUDFLARE_TOKEN
ENVEOF
    
    chmod 600 .env
    success ".env dosyası oluşturuldu"
    
    # Giriş bilgilerini kaydet
    cat > CREDENTIALS.txt << CREDEOF
HaberNexus Giriş Bilgileri
==========================
Tarih: $(date)

Domain: $DOMAIN
Admin Kullanıcı: $ADMIN_USERNAME
Admin Şifre: $ADMIN_PASSWORD
Admin E-posta: $ADMIN_EMAIL

Veritabanı Şifresi: $DB_PASSWORD
CREDEOF
    chmod 600 CREDENTIALS.txt
    success "Giriş bilgileri kaydedildi: CREDENTIALS.txt"
    
    wait_for_enter
}

# =============================================================================
# STEP 6: CONFIGURE CADDY
# =============================================================================

step_configure_caddy() {
    print_step 6 "Caddy Web Sunucusu Yapılandırması" \
        "Caddy reverse proxy yapılandırması oluşturulur."
    
    print_explanation "Caddy özellikleri:
   • Otomatik HTTPS (Let's Encrypt)
   • Reverse proxy
   • Gzip sıkıştırma
   • Güvenlik başlıkları"
    
    if ! confirm "Caddy yapılandırılsın mı?"; then
        warning "Caddy yapılandırması atlandı"
        return 0
    fi
    
    echo ""
    cd "$INSTALL_DIR"
    
    # .env'den domain oku
    source .env
    
    mkdir -p caddy
    
    if [[ "$DOMAIN" == "localhost" || "$DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # HTTP modu
        cat > caddy/Caddyfile << 'CADDYEOF'
:80 {
    encode gzip
    
    handle_path /static/* {
        root * /app/staticfiles
        file_server
    }
    
    handle_path /media/* {
        root * /app/media
        file_server
    }
    
    handle {
        reverse_proxy web:8000
    }
}
CADDYEOF
        success "Caddyfile oluşturuldu (HTTP modu)"
    else
        # HTTPS modu
        cat > caddy/Caddyfile << CADDYEOF
{
    email $ADMIN_EMAIL
}

$DOMAIN {
    encode gzip
    
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
    }
    
    handle_path /static/* {
        root * /app/staticfiles
        file_server
    }
    
    handle_path /media/* {
        root * /app/media
        file_server
    }
    
    handle {
        reverse_proxy web:8000
    }
}

www.$DOMAIN {
    redir https://$DOMAIN{uri} permanent
}
CADDYEOF
        success "Caddyfile oluşturuldu (HTTPS modu)"
    fi
    
    # Cloudflare override
    if [[ "$USE_CLOUDFLARE" == "true" ]] && [[ -n "$CLOUDFLARE_TUNNEL_TOKEN" ]]; then
        cat > docker-compose.override.yml << 'OVERRIDEEOF'
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: habernexus-cloudflared
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
    networks:
      - habernexus-network
    depends_on:
      - caddy
OVERRIDEEOF
        success "Cloudflare override dosyası oluşturuldu"
    fi
    
    wait_for_enter
}

# =============================================================================
# STEP 7: BUILD DOCKER IMAGES
# =============================================================================

step_build_images() {
    print_step 7 "Docker İmajlarının Oluşturulması" \
        "HaberNexus Docker imajları build edilir."
    
    print_explanation "Build edilecek imajlar:
   • web - Django uygulaması
   • celery - Arka plan görevleri
   
   Bu işlem birkaç dakika sürebilir."
    
    print_command "docker compose -f docker-compose.prod.yml build"
    
    if ! confirm "Docker imajları build edilsin mi?"; then
        warning "Build atlandı"
        return 0
    fi
    
    echo ""
    cd "$INSTALL_DIR"
    
    info "Docker imajları build ediliyor (bu birkaç dakika sürebilir)..."
    
    local compose_cmd="docker compose -f docker-compose.prod.yml"
    if [[ -f "docker-compose.override.yml" ]]; then
        compose_cmd="$compose_cmd -f docker-compose.override.yml"
    fi
    
    if $compose_cmd build; then
        success "Docker imajları başarıyla build edildi"
    else
        error "Build sırasında hata oluştu"
        return 1
    fi
    
    wait_for_enter
}

# =============================================================================
# STEP 8: START SERVICES
# =============================================================================

step_start_services() {
    print_step 8 "Servislerin Başlatılması" \
        "Tüm Docker container'ları başlatılır."
    
    print_explanation "Başlatılacak servisler:
   • postgres - PostgreSQL veritabanı
   • redis - Önbellek ve mesaj kuyruğu
   • web - Django uygulaması
   • celery - Arka plan görevleri
   • caddy - Web sunucusu
   • cloudflared (opsiyonel) - Cloudflare Tunnel"
    
    print_command "docker compose -f docker-compose.prod.yml up -d"
    
    if ! confirm "Servisler başlatılsın mı?"; then
        warning "Servis başlatma atlandı"
        return 0
    fi
    
    echo ""
    cd "$INSTALL_DIR"
    
    local compose_cmd="docker compose -f docker-compose.prod.yml"
    if [[ -f "docker-compose.override.yml" ]]; then
        compose_cmd="$compose_cmd -f docker-compose.override.yml"
    fi
    
    info "Container'lar başlatılıyor..."
    if $compose_cmd up -d; then
        success "Container'lar başlatıldı"
    else
        error "Container başlatma hatası"
        return 1
    fi
    
    # Veritabanı bağlantısını bekle
    info "Veritabanı bağlantısı bekleniyor..."
    local max_attempts=30
    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        if docker exec habernexus-postgres pg_isready -U habernexus_user -d habernexus > /dev/null 2>&1; then
            success "Veritabanı hazır"
            break
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    echo ""
    
    # Container durumlarını göster
    echo ""
    info "Container durumları:"
    docker ps --filter "name=habernexus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    wait_for_enter
}

# =============================================================================
# STEP 9: DATABASE SETUP
# =============================================================================

step_database_setup() {
    print_step 9 "Veritabanı Kurulumu" \
        "Django migration'ları çalıştırılır ve admin kullanıcı oluşturulur."
    
    print_explanation "Yapılacaklar:
   • Veritabanı tablolarının oluşturulması
   • Static dosyaların toplanması
   • Admin kullanıcının oluşturulması"
    
    print_commands \
        "docker exec habernexus-web python manage.py migrate" \
        "docker exec habernexus-web python manage.py collectstatic --noinput" \
        "docker exec habernexus-web python manage.py createsuperuser"
    
    if ! confirm "Veritabanı kurulumu yapılsın mı?"; then
        warning "Veritabanı kurulumu atlandı"
        return 0
    fi
    
    echo ""
    cd "$INSTALL_DIR"
    
    # Migration
    info "Migration'lar çalıştırılıyor..."
    if docker exec habernexus-web python manage.py migrate --noinput; then
        success "Migration'lar tamamlandı"
    else
        error "Migration hatası"
    fi
    
    # Static files
    info "Static dosyalar toplanıyor..."
    if docker exec habernexus-web python manage.py collectstatic --noinput; then
        success "Static dosyalar hazır"
    else
        warning "Static dosya toplama hatası"
    fi
    
    # Admin kullanıcı
    source .env
    info "Admin kullanıcı oluşturuluyor..."
    docker exec habernexus-web python manage.py shell << PYTHONEOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='${ADMIN_USERNAME}').exists():
    user = User.objects.create_superuser(
        username='${ADMIN_USERNAME}',
        email='${ADMIN_EMAIL}',
        password='${ADMIN_PASSWORD}'
    )
    print(f'Admin user created: {user.username}')
else:
    print('Admin user already exists')
PYTHONEOF
    success "Admin kullanıcı hazır"
    
    wait_for_enter
}

# =============================================================================
# STEP 10: VERIFICATION
# =============================================================================

step_verification() {
    print_step 10 "Kurulum Doğrulama" \
        "Kurulumun başarılı olup olmadığı kontrol edilir."
    
    if ! confirm "Kurulum doğrulaması yapılsın mı?"; then
        warning "Doğrulama atlandı"
        return 0
    fi
    
    echo ""
    cd "$INSTALL_DIR"
    source .env
    
    local all_ok=true
    
    # Container durumları
    info "Container durumları kontrol ediliyor..."
    for container in habernexus-web habernexus-postgres habernexus-redis habernexus-caddy; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            local status=$(docker inspect --format='{{.State.Status}}' "$container")
            if [[ "$status" == "running" ]]; then
                success "$container: Çalışıyor"
            else
                warning "$container: $status"
                all_ok=false
            fi
        else
            warning "$container: Bulunamadı"
            all_ok=false
        fi
    done
    
    # Web erişimi
    echo ""
    info "Web servisi kontrol ediliyor..."
    sleep 3
    if curl -fsSL --connect-timeout 5 "http://localhost/" > /dev/null 2>&1; then
        success "Web servisi erişilebilir"
    else
        warning "Web servisi henüz erişilebilir değil"
    fi
    
    # Sonuç
    echo ""
    if [[ "$all_ok" == true ]]; then
        echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}${BOLD}  ✨ KURULUM BAŞARIYLA TAMAMLANDI! ✨${NC}"
        echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    else
        echo -e "${YELLOW}${BOLD}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}${BOLD}  ⚠ Kurulum tamamlandı ancak bazı sorunlar var${NC}"
        echo -e "${YELLOW}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    fi
    
    echo ""
    echo -e "${BOLD}Erişim Bilgileri:${NC}"
    echo -e "  Web Arayüzü: http://$DOMAIN"
    echo -e "  Admin Panel: http://$DOMAIN/admin/"
    echo ""
    echo -e "${BOLD}Giriş Bilgileri:${NC}"
    echo -e "  Kullanıcı: $ADMIN_USERNAME"
    echo -e "  Şifre: $ADMIN_PASSWORD"
    echo ""
    echo -e "${YELLOW}⚠ Giriş bilgileri: $INSTALL_DIR/CREDENTIALS.txt${NC}"
    echo ""
    
    echo -e "${BOLD}Faydalı Komutlar:${NC}"
    echo "  Logları görüntüle: docker compose -f docker-compose.prod.yml logs -f"
    echo "  Servisleri yeniden başlat: docker compose -f docker-compose.prod.yml restart"
    echo "  Yedek al: sudo bash setup.sh --backup"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    print_header
    
    echo "Bu rehber sizi HaberNexus kurulumu boyunca adım adım yönlendirecek."
    echo ""
    echo "Her adımda:"
    echo "  • Ne yapılacağı açıklanır"
    echo "  • Çalıştırılacak komutlar gösterilir"
    echo "  • Onayınız istenir"
    echo ""
    echo "Seçenekler:"
    echo "  E - Evet, bu adımı çalıştır"
    echo "  H - Hayır, bu adımı atla"
    echo "  A - Kurulumu iptal et"
    echo ""
    
    if ! confirm "Kuruluma başlamak istiyor musunuz?"; then
        exit 0
    fi
    
    step_system_check
    step_existing_check
    step_install_dependencies
    step_clone_repository
    step_configure_environment
    step_configure_caddy
    step_build_images
    step_start_services
    step_database_setup
    step_verification
}

# Çalıştır
main "$@"
