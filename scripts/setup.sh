#!/bin/bash

################################################################################
# Haber Nexus - Gelişmiş Kurulum Scripti v2.0
# Ubuntu 22.04/24.04 LTS için optimize edilmiştir.
# Geliştirici: Salih TANRISEVEN & Manus AI
################################################################################

set -eo pipefail

# Renkler ve Loglama
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/var/log/habernexus_setup_$(date +%Y%m%d_%H%M%S).log"

log_info() { echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"; exit 1; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
log_step() { echo -e "\n${BLUE}==>${NC} $1" | tee -a "$LOG_FILE"; }
log_section() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${CYAN}$1${NC}\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n" | tee -a "$LOG_FILE"; }

# Hata Yakalama
trap 'log_error "Satır $LINENO: Komut başarısız oldu: $BASH_COMMAND"' ERR

# Banner
clear
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                     🚀 HABER NEXUS - KURULUM SCRIPTI v2.0 🚀                   ║
║                                                                              ║
║                   Profesyonel Haber Ajansı Platformu                         ║
║                    Google Gemini AI ile Otomatik İçerik                      ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF

echo "Log dosyası: $LOG_FILE"

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
if ! . /etc/os-release; then log_error "Ubuntu sistemi tespit edilemedi."; fi
if [[ "$ID" != "ubuntu" ]]; then log_error "Bu script yalnızca Ubuntu sistemlerinde çalışır."; fi
log_info "Ubuntu $VERSION_ID tespit edildi."

# İnternet bağlantısı
if ! ping -c 1 8.8.8.8 &> /dev/null; then log_error "İnternet bağlantısı yok."; fi
log_info "İnternet bağlantısı kontrol edildi."

# ============================================================================
# KURULUM AYARLARI
# ============================================================================

log_section "Kurulum Ayarları"

PROJECT_PATH="/opt/habernexus"

read -p "Proje dizini [$PROJECT_PATH]: " -r PROJECT_PATH_INPUT
PROJECT_PATH=${PROJECT_PATH_INPUT:-$PROJECT_PATH}

read -p "Domain adınız (örn: habernexus.com): " -r DOMAIN
[[ -z "$DOMAIN" ]] && log_error "Domain adı boş olamaz."

read -p "Admin email adresi: " -r ADMIN_EMAIL
[[ -z "$ADMIN_EMAIL" ]] && log_error "Admin email adresi boş olamaz."

read -sp "PostgreSQL şifresi (en az 12 karakter): " -r DB_PASSWORD
echo ""
[[ ${#DB_PASSWORD} -lt 12 ]] && log_error "PostgreSQL şifresi en az 12 karakter olmalıdır."

read -sp "PostgreSQL şifresi (tekrar): " -r DB_PASSWORD_CONFIRM
echo ""
[[ "$DB_PASSWORD" != "$DB_PASSWORD_CONFIRM" ]] && log_error "Şifreler eşleşmiyor."

read -p "Google Gemini API Key (opsiyonel): " -r GOOGLE_API_KEY

# Özet
log_section "Kurulum Özeti"
echo "Proje Dizini: $PROJECT_PATH"
echo "Domain: $DOMAIN"
echo "Admin Email: $ADMIN_EMAIL"
read -p "Devam etmek istiyor musunuz? (y/n): " -n 1 -r
echo ""
[[ ! $REPLY =~ ^[Yy]$ ]] && log_error "Kurulum iptal edildi."

# ============================================================================
# SISTEM HAZIRLIĞI
# ============================================================================

log_section "Adım 1: Sistem Hazırlığı"

log_step "Sistem paketleri güncelleniyor..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
log_info "Sistem paketleri güncellendi."

log_step "Temel paketler kuruluyor..."
apt-get install -y -qq curl wget git nano htop net-tools build-essential python3-dev python3-pip python3-venv openssl
log_info "Temel paketler kuruldu."

log_step "Docker ve Docker Compose kuruluyor..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
fi
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4 || echo "v2.20.0")
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi
systemctl start docker && systemctl enable docker
log_info "Docker ve Docker Compose hazır."

# ============================================================================
# PROJE KURULUMU
# ============================================================================

log_section "Adım 2: Proje Kurulumu"

log_step "Dizinler oluşturuluyor..."
mkdir -p "$PROJECT_PATH"

log_step "GitHub deposu klonlanıyor..."
if [ -d "$PROJECT_PATH/.git" ]; then
    log_step "Proje zaten klonlanmış, güncelleniyor..."
    cd "$PROJECT_PATH" && git pull origin main
else
    git clone https://github.com/sata2500/habernexus.git "$PROJECT_PATH"
fi
log_info "Proje klonlandı."

log_step ".env dosyası oluşturuluyor..."
SECRET_KEY=$(openssl rand -base64 50 | tr -d '\n/+' | head -c 50)
VM_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

cat > "$PROJECT_PATH/.env" <<EOF
DEBUG=False
DJANGO_SECRET_KEY=$SECRET_KEY
ALLOWED_HOSTS=$VM_IP,$DOMAIN,localhost,127.0.0.1
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
EOF
log_info ".env dosyası oluşturuldu."

# ============================================================================
# DOCKER CONTAINER'LARINI BAŞLAT
# ============================================================================

log_section "Adım 3: Docker Container'larını Başlatma"

cd "$PROJECT_PATH"

log_step "Eski container'lar temizleniyor..."
docker-compose -f docker-compose.prod.yml down -v --remove-orphans 2>/dev/null || true
log_info "Eski container'lar temizlendi."

log_step "Container'lar başlatılıyor..."
docker-compose -f docker-compose.prod.yml up -d --build
log_info "Container'lar başlatıldı."

log_step "PostgreSQL'in başlaması bekleniyor..."
MAX_ATTEMPTS=60
for (( i=1; i<=$MAX_ATTEMPTS; i++ )); do
    if docker-compose -f docker-compose.prod.yml exec -T postgres pg_isready -U habernexus_user &>/dev/null; then
        log_info "PostgreSQL hazır."
        break
    fi
    [[ $i -eq $MAX_ATTEMPTS ]] && log_error "PostgreSQL başlamadı."
    sleep 1
done

log_step "Django migrasyonları çalıştırılıyor..."
docker-compose -f docker-compose.prod.yml exec web python manage.py migrate --noinput

log_step "Statik dosyalar toplanıyor..."
docker-compose -f docker-compose.prod.yml exec web python manage.py collectstatic --noinput

# ============================================================================
# SSL VE NGINX
# ============================================================================

log_section "Adım 4: SSL ve Nginx Yapılandırması"

log_step "Nginx yapılandırması güncelleniyor..."
sed -i "s/server_name _;/server_name $DOMAIN www.$DOMAIN;/g" "$PROJECT_PATH/config/nginx_production.conf"

log_step "Certbot ile SSL sertifikası alınıyor..."
apt-get install -y -qq certbot python3-certbot-nginx
docker-compose -f docker-compose.prod.yml stop nginx
certbot certonly --standalone -d "$DOMAIN" -d "www.$DOMAIN" --email "$ADMIN_EMAIL" --agree-tos --no-eff-email -n
docker-compose -f docker-compose.prod.yml up -d nginx
log_info "SSL sertifikası alındı ve Nginx yapılandırıldı."

# ============================================================================
# KURULUM TAMAMLANDI
# ============================================================================

log_section "🎉 KURULUM BAŞARIYLA TAMAMLANDI! 🎉"

echo ""
echo "Kurulum Bilgileri:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Proje Dizini: $PROJECT_PATH"
echo "  Domain: https://$DOMAIN"
echo "  Admin Email: $ADMIN_EMAIL"
echo "  Log Dosyası: $LOG_FILE"
echo ""

echo "Sonraki Adımlar:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Admin kullanıcısı oluştur:"
echo "   cd $PROJECT_PATH"
echo "   sudo docker-compose -f docker-compose.prod.yml exec web python manage.py createsuperuser"
echo ""
echo "2. Container'ların durumunu kontrol et:"
echo "   cd $PROJECT_PATH"
echo "   sudo docker-compose -f docker-compose.prod.yml ps"
echo ""
echo "3. Logları göster:"
echo "   cd $PROJECT_PATH"
echo "   sudo docker-compose -f docker-compose.prod.yml logs -f web"
echo ""

log_info "Kurulum tamamlandı!"
