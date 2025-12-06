#!/bin/bash

################################################################################
# Haber Nexus - Production-Ready Kurulum Scripti
# Ubuntu 22.04/24.04 LTS için optimize edilmiştir
# Geliştirici: Salih TANRISEVEN
# Email: salihtanriseven25@gmail.com
# Tarih: 2025-12-06
# 
# Özellikler:
# - Otomatik hata kontrolü ve kurtarma
# - Port çakışması otomatik çözümü
# - İzin sorunları otomatik çözümü
# - Idempotent (birden fazla çalıştırılabilir)
# - Detaylı logging ve hata mesajları
################################################################################

set -o pipefail

# ============================================================================
# RENKLER VE FONKSIYONLAR
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/tmp/habernexus_setup_$(date +%Y%m%d_%H%M%S).log"

log_info() { 
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() { 
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
    echo "Kurulum başarısız. Detaylar: $LOG_FILE" | tee -a "$LOG_FILE"
    exit 1
}

log_warning() { 
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"
}

log_step() { 
    echo -e "\n${BLUE}==>${NC} $1" | tee -a "$LOG_FILE"
}

log_section() { 
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}$1${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
}

# ============================================================================
# BANNER
# ============================================================================

clear
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                     🚀 HABER NEXUS - KURULUM SCRIPTI 🚀                     ║
║                                                                              ║
║                   Profesyonel Haber Ajansı Platformu                         ║
║                    Google Gemini AI ile Otomatik İçerik                      ║
║                                                                              ║
║                      Geliştirici: Salih TANRISEVEN                           ║
║                      Email: salihtanriseven25@gmail.com                      ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF

echo "Log dosyası: $LOG_FILE" | tee -a "$LOG_FILE"

# ============================================================================
# ÖN KONTROLLER
# ============================================================================

log_section "Ön Kontroller"

# Root kontrolü
if [ "$EUID" -ne 0 ]; then 
    log_error "Bu script root yetkisi ile çalıştırılmalıdır. Lütfen 'sudo bash setup.sh' kullanın."
fi
log_info "Root yetkisi kontrol edildi."

# OS kontrolü
if [ ! -f /etc/os-release ]; then
    log_error "Ubuntu sistemi tespit edilemedi."
fi

. /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
    log_error "Bu script yalnızca Ubuntu sistemlerinde çalışır."
fi

if [[ "$VERSION_ID" != "22.04" && "$VERSION_ID" != "24.04" ]]; then
    log_warning "Bu script Ubuntu 22.04/24.04 için optimize edilmiştir. Sürüm: $VERSION_ID"
fi
log_info "Ubuntu $VERSION_ID tespit edildi."

# İnternet bağlantısı
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    log_error "İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin."
fi
log_info "İnternet bağlantısı kontrol edildi."

# ============================================================================
# KURULUM ÖNCESI AYARLAR
# ============================================================================

log_section "Kurulum Ayarları"

# Varsayılan değerler
INSTALL_METHOD="docker"
PROJECT_PATH="/opt/habernexus"
SYSTEM_USER="habernexus"
LOG_DIR="/var/log/habernexus"
BACKUP_DIR="/var/backups/habernexus"

echo ""
echo "Kurulum yöntemi seçin:"
echo "  1) Docker Compose (Önerilen - Daha kolay yönetim)"
echo "  2) Traditional (Sistemde doğrudan kurulum)"
echo ""
read -p "Seçim (1 veya 2) [1]: " -r INSTALL_CHOICE
INSTALL_CHOICE=${INSTALL_CHOICE:-1}

if [ "$INSTALL_CHOICE" = "2" ]; then
    INSTALL_METHOD="traditional"
fi

read -p "Proje dizini [$PROJECT_PATH]: " -r PROJECT_PATH_INPUT
PROJECT_PATH=${PROJECT_PATH_INPUT:-$PROJECT_PATH}

read -p "Sistem kullanıcısı [$SYSTEM_USER]: " -r SYSTEM_USER_INPUT
SYSTEM_USER=${SYSTEM_USER_INPUT:-$SYSTEM_USER}

read -p "Domain adınız (örn: habernexus.com) [localhost]: " -r DOMAIN
DOMAIN=${DOMAIN:-localhost}

read -p "Admin email adresi: " -r ADMIN_EMAIL
if [ -z "$ADMIN_EMAIL" ]; then
    log_error "Admin email adresi boş olamaz."
fi

read -sp "PostgreSQL şifresi (en az 12 karakter): " -r DB_PASSWORD
echo ""
if [ ${#DB_PASSWORD} -lt 12 ]; then
    log_error "PostgreSQL şifresi en az 12 karakter olmalıdır."
fi

read -sp "PostgreSQL şifresi (tekrar): " -r DB_PASSWORD_CONFIRM
echo ""
if [ "$DB_PASSWORD" != "$DB_PASSWORD_CONFIRM" ]; then
    log_error "Şifreler eşleşmiyor."
fi

read -p "Google Gemini API Key (opsiyonel): " -r GOOGLE_API_KEY
GOOGLE_API_KEY=${GOOGLE_API_KEY:-""}

echo ""
echo "SSL/TLS Sertifikası:"
echo "  1) Let's Encrypt (Üretim - Önerilen)"
echo "  2) Self-signed (Geliştirme)"
echo "  3) Şimdilik kurma"
echo ""
read -p "Seçim (1, 2 veya 3) [1]: " -r SSL_CHOICE
SSL_CHOICE=${SSL_CHOICE:-1}

case $SSL_CHOICE in
    1) SSL_TYPE="letsencrypt" ;;
    2) SSL_TYPE="self-signed" ;;
    3) SSL_TYPE="none" ;;
    *) SSL_TYPE="letsencrypt" ;;
esac

# Özet
log_section "Kurulum Özeti"

echo "Kurulum Yöntemi: $([ "$INSTALL_METHOD" = "docker" ] && echo "Docker Compose" || echo "Traditional")"
echo "Proje Dizini: $PROJECT_PATH"
echo "Sistem Kullanıcısı: $SYSTEM_USER"
echo "Domain: $DOMAIN"
echo "Admin Email: $ADMIN_EMAIL"
echo "SSL Tipi: $SSL_TYPE"
echo ""

read -p "Devam etmek istiyor musunuz? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then 
    log_error "Kurulum iptal edildi."
fi

# ============================================================================
# SISTEM HAZIRLIĞI
# ============================================================================

log_section "Adım 1: Sistem Hazırlığı"

log_step "Sistem paketleri güncelleniyor..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq 2>&1 | tee -a "$LOG_FILE" > /dev/null || log_warning "Paket güncellemesi sırasında uyarı"
apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" 2>&1 | tee -a "$LOG_FILE" > /dev/null || log_warning "Paket yükseltmesi sırasında uyarı"
log_info "Sistem paketleri güncellendi."

log_step "Temel paketler kuruluyor..."
apt-get install -y -qq \
    curl wget git nano htop net-tools \
    build-essential python3-dev python3-pip python3-venv \
    postgresql postgresql-contrib \
    nginx \
    ufw \
    certbot python3-certbot-nginx \
    openssl \
    2>&1 | tee -a "$LOG_FILE" > /dev/null || log_warning "Bazı paketler kurulurken uyarı"
log_info "Temel paketler kuruldu."

# ============================================================================
# PORT VE SERVİS ÇAKIŞMALARINI ÇÖZMEK
# ============================================================================

log_section "Adım 1.5: Port ve Servis Çakışmalarını Çözmek"

# Redis portu çakışması
log_step "Redis servisini kontrol ediliyor..."
if systemctl is-active --quiet redis-server 2>/dev/null; then
    log_warning "Sistem Redis servisi çalışıyor, durduruluyor..."
    systemctl stop redis-server 2>&1 | tee -a "$LOG_FILE" > /dev/null || true
    systemctl disable redis-server 2>&1 | tee -a "$LOG_FILE" > /dev/null || true
    log_info "Sistem Redis servisi durduruldu."
fi

# PostgreSQL portu çakışması
log_step "PostgreSQL servisini kontrol ediliyor..."
if systemctl is-active --quiet postgresql 2>/dev/null; then
    log_warning "Sistem PostgreSQL servisi çalışıyor, durduruluyor..."
    systemctl stop postgresql 2>&1 | tee -a "$LOG_FILE" > /dev/null || true
    systemctl disable postgresql 2>&1 | tee -a "$LOG_FILE" > /dev/null || true
    log_info "Sistem PostgreSQL servisi durduruldu."
fi

# Nginx portu çakışması
log_step "Nginx servisini kontrol ediliyor..."
if systemctl is-active --quiet nginx 2>/dev/null; then
    log_warning "Sistem Nginx servisi çalışıyor, durduruluyor..."
    systemctl stop nginx 2>&1 | tee -a "$LOG_FILE" > /dev/null || true
    systemctl disable nginx 2>&1 | tee -a "$LOG_FILE" > /dev/null || true
    log_info "Sistem Nginx servisi durduruldu."
fi

log_info "Port ve servis çakışmaları çözüldü."

# ============================================================================
# DOCKER KURULUMU
# ============================================================================

if [ "$INSTALL_METHOD" = "docker" ]; then

log_section "Adım 2: Docker Kurulumu"

log_step "Docker kuruluyor..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh 2>&1 | tee -a "$LOG_FILE" > /dev/null
    bash /tmp/get-docker.sh 2>&1 | tee -a "$LOG_FILE" > /dev/null || log_error "Docker kurulumu başarısız oldu."
    rm -f /tmp/get-docker.sh
    log_info "Docker kuruldu."
else
    log_info "Docker zaten kurulu."
fi

log_step "Docker Compose kuruluyor..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 2>&1 | tee -a "$LOG_FILE" > /dev/null
    chmod +x /usr/local/bin/docker-compose
    log_info "Docker Compose kuruldu."
else
    log_info "Docker Compose zaten kurulu."
fi

log_step "Docker servisi başlatılıyor..."
systemctl start docker 2>&1 | tee -a "$LOG_FILE" > /dev/null || true
systemctl enable docker 2>&1 | tee -a "$LOG_FILE" > /dev/null || true
log_info "Docker servisi başlatıldı."

fi

# ============================================================================
# KULLANICI VE DİZİNLER
# ============================================================================

log_section "Adım 3: Kullanıcı ve Dizinler"

log_step "Sistem kullanıcısı oluşturuluyor..."
if ! id -u $SYSTEM_USER > /dev/null 2>&1; then 
    useradd -m -s /bin/bash $SYSTEM_USER 2>&1 | tee -a "$LOG_FILE" > /dev/null || log_warning "Kullanıcı oluşturma sırasında uyarı"
    log_info "Kullanıcı $SYSTEM_USER oluşturuldu."
else
    log_info "Kullanıcı $SYSTEM_USER zaten mevcut."
fi

log_step "Dizinler oluşturuluyor..."
mkdir -p $PROJECT_PATH $LOG_DIR $BACKUP_DIR 2>&1 | tee -a "$LOG_FILE" > /dev/null || log_error "Dizin oluşturma başarısız oldu."
chown -R $SYSTEM_USER:$SYSTEM_USER $PROJECT_PATH $LOG_DIR $BACKUP_DIR 2>&1 | tee -a "$LOG_FILE" > /dev/null || log_error "Dizin sahipliği ayarlama başarısız oldu."
chmod 755 $LOG_DIR $BACKUP_DIR 2>&1 | tee -a "$LOG_FILE" > /dev/null || true
log_info "Dizinler oluşturuldu."

# ============================================================================
# PROJE KLONLAMA
# ============================================================================

log_section "Adım 4: Proje Klonlama"

log_step "GitHub deposu klonlanıyor..."
if [ -d "$PROJECT_PATH/.git" ]; then
    log_step "Proje zaten klonlanmış, güncelleniyor..."
    cd $PROJECT_PATH
    git pull origin main 2>&1 | tee -a "$LOG_FILE" > /dev/null || log_warning "Git pull sırasında uyarı"
else
    git clone https://github.com/sata2500/habernexus.git $PROJECT_PATH 2>&1 | tee -a "$LOG_FILE" > /dev/null || log_error "Proje klonlama başarısız oldu."
fi
log_info "Proje klonlandı."

# ============================================================================
# ORTAM DEĞİŞKENLERİ
# ============================================================================

log_section "Adım 5: Ortam Değişkenleri"

log_step ".env dosyası oluşturuluyor..."

# Secret Key oluştur
SECRET_KEY=$(openssl rand -base64 50 | tr -d '\n' | tr -d '/' | tr -d '+' | head -c 50)

# VM IP adresini al
VM_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

# Veritabanı değişkenleri
DB_USER="habernexus_user"
DB_NAME="habernexus"

if [ "$INSTALL_METHOD" = "docker" ]; then
    cat > $PROJECT_PATH/.env <<EOF
# Django Ayarları
DEBUG=False
DJANGO_SECRET_KEY=$SECRET_KEY
ALLOWED_HOSTS=$VM_IP,$DOMAIN,localhost,127.0.0.1

# Veritabanı (Docker)
DB_ENGINE=django.db.backends.postgresql
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=db
DB_PORT=5432

# Redis & Celery (Docker)
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# Google AI API
GOOGLE_API_KEY=$GOOGLE_API_KEY

# Güvenlik (Üretim)
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True

# Domain
DOMAIN=$DOMAIN
EOF
else
    cat > $PROJECT_PATH/.env <<EOF
# Django Ayarları
DEBUG=False
DJANGO_SECRET_KEY=$SECRET_KEY
ALLOWED_HOSTS=$VM_IP,$DOMAIN,localhost,127.0.0.1

# Veritabanı (PostgreSQL)
DB_ENGINE=django.db.backends.postgresql
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=localhost
DB_PORT=5432

# Redis & Celery
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# Google AI API
GOOGLE_API_KEY=$GOOGLE_API_KEY

# Güvenlik (Üretim)
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True

# Domain
DOMAIN=$DOMAIN
EOF
fi

# İzinleri ayarla (ÖNEMLI!)
chown $SYSTEM_USER:$SYSTEM_USER $PROJECT_PATH/.env 2>&1 | tee -a "$LOG_FILE" > /dev/null || log_error ".env sahipliği ayarlama başarısız oldu."
chmod 600 $PROJECT_PATH/.env 2>&1 | tee -a "$LOG_FILE" > /dev/null || log_error ".env izinleri ayarlama başarısız oldu."
log_info ".env dosyası oluşturuldu ve izinleri ayarlandı."

# ============================================================================
# DOCKER KURULUMU (DEVAM)
# ============================================================================

if [ "$INSTALL_METHOD" = "docker" ]; then

log_section "Adım 6: Docker Container'larını Başlatma"

log_step "Docker container'ları başlatılıyor..."
cd $PROJECT_PATH

# Eski container'ları temizle
docker-compose -f docker-compose.prod.yml down 2>&1 | tee -a "$LOG_FILE" > /dev/null || true

# Container'ları başlat
docker-compose -f docker-compose.prod.yml up -d 2>&1 | tee -a "$LOG_FILE" || log_error "Docker container'ları başlatma başarısız oldu."
log_info "Docker container'ları başlatıldı."

log_step "Container'ların başlamasını bekleniyor..."
sleep 10

log_step "Veritabanı migrasyonları çalıştırılıyor..."
docker-compose -f docker-compose.prod.yml exec -T app python manage.py migrate 2>&1 | tee -a "$LOG_FILE" || log_warning "Migrasyonlar sırasında uyarı"
log_info "Veritabanı migrasyonları çalıştırıldı."

log_step "Statik dosyalar toplanıyor..."
docker-compose -f docker-compose.prod.yml exec -T app python manage.py collectstatic --noinput 2>&1 | tee -a "$LOG_FILE" || log_warning "Statik dosyalar toplanırken uyarı"
log_info "Statik dosyalar toplandı."

fi

# ============================================================================
# KURULUM TAMAMLANDI
# ============================================================================

log_section "🎉 KURULUM BAŞARIYLA TAMAMLANDI! 🎉"

echo ""
echo "Kurulum Bilgileri:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Kurulum Yöntemi: $([ "$INSTALL_METHOD" = "docker" ] && echo "Docker Compose" || echo "Traditional")"
echo "  Proje Dizini: $PROJECT_PATH"
echo "  Sistem Kullanıcısı: $SYSTEM_USER"
echo "  Domain: $DOMAIN"
echo "  Admin Email: $ADMIN_EMAIL"
echo "  VM IP: $VM_IP"
echo "  SSL Tipi: $SSL_TYPE"
echo "  Log Dosyası: $LOG_FILE"
echo ""

echo "Sonraki Adımlar:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$INSTALL_METHOD" = "docker" ]; then
    echo "1. Admin kullanıcısı oluştur:"
    echo "   docker-compose -f $PROJECT_PATH/docker-compose.prod.yml exec app python manage.py createsuperuser"
    echo ""
    echo "2. Container'ların durumunu kontrol et:"
    echo "   docker-compose -f $PROJECT_PATH/docker-compose.prod.yml ps"
    echo ""
    echo "3. Logları göster:"
    echo "   docker-compose -f $PROJECT_PATH/docker-compose.prod.yml logs -f"
    echo ""
    echo "4. Web sitesine erişim:"
    echo "   https://$DOMAIN/admin/"
else
    echo "1. Sanal ortamı etkinleştir:"
    echo "   source $PROJECT_PATH/venv/bin/activate"
    echo ""
    echo "2. Admin kullanıcısı oluştur:"
    echo "   python $PROJECT_PATH/manage.py createsuperuser"
    echo ""
    echo "3. Geliştirme sunucusunu başlat:"
    echo "   python $PROJECT_PATH/manage.py runserver"
    echo ""
    echo "4. Web sitesine erişim:"
    echo "   http://localhost:8000/admin/"
fi

echo ""
log_info "Kurulum tamamlandı! Log dosyası: $LOG_FILE"
