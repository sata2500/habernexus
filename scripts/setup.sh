#!/bin/bash

################################################################################
# Haber Nexus - Basit ve Güvenilir Kurulum Scripti
# Ubuntu 22.04/24.04 LTS için
# Geliştirici: Salih TANRISEVEN
################################################################################

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/tmp/habernexus_setup_$(date +%Y%m%d_%H%M%S).log"

# Logging fonksiyonları
log_info() { echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"; exit 1; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
log_step() { echo -e "\n${BLUE}==>${NC} $1" | tee -a "$LOG_FILE"; }
log_section() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${CYAN}$1${NC}\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n" | tee -a "$LOG_FILE"; }

# Banner
clear
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                     🚀 HABER NEXUS - KURULUM SCRIPTI 🚀                     ║
║                                                                              ║
║                   Profesyonel Haber Ajansı Platformu                         ║
║                    Google Gemini AI ile Otomatik İçerik                      ║
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
log_info "Ubuntu $VERSION_ID tespit edildi."

# İnternet bağlantısı
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    log_error "İnternet bağlantısı yok."
fi
log_info "İnternet bağlantısı kontrol edildi."

# ============================================================================
# KURULUM AYARLARI
# ============================================================================

log_section "Kurulum Ayarları"

PROJECT_PATH="/opt/habernexus"
LOG_DIR="/var/log/habernexus"
BACKUP_DIR="/var/backups/habernexus"

read -p "Proje dizini [$PROJECT_PATH]: " -r PROJECT_PATH_INPUT
PROJECT_PATH=${PROJECT_PATH_INPUT:-$PROJECT_PATH}

read -p "Domain adınız (örn: habernexus.com): " -r DOMAIN
if [ -z "$DOMAIN" ]; then
    log_error "Domain adı boş olamaz."
fi

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

# Özet
log_section "Kurulum Özeti"
echo "Proje Dizini: $PROJECT_PATH"
echo "Domain: $DOMAIN"
echo "Admin Email: $ADMIN_EMAIL"
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
apt-get update -qq 2>&1 | tail -5 | tee -a "$LOG_FILE"
apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" 2>&1 | tail -5 | tee -a "$LOG_FILE"
log_info "Sistem paketleri güncellendi."

log_step "Temel paketler kuruluyor..."
apt-get install -y -qq curl wget git nano htop net-tools build-essential python3-dev python3-pip python3-venv postgresql postgresql-contrib redis-server nginx ufw certbot python3-certbot-nginx openssl 2>&1 | tail -5 | tee -a "$LOG_FILE"
log_info "Temel paketler kuruldu."

log_step "Docker kuruluyor..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh 2>&1 | tee -a "$LOG_FILE"
    bash /tmp/get-docker.sh 2>&1 | tail -10 | tee -a "$LOG_FILE"
    rm -f /tmp/get-docker.sh
    log_info "Docker kuruldu."
else
    log_info "Docker zaten kurulu."
fi

log_step "Docker Compose kuruluyor..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4 2>/dev/null || echo "v2.20.0")
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 2>&1 | tee -a "$LOG_FILE"
    chmod +x /usr/local/bin/docker-compose
    log_info "Docker Compose kuruldu."
else
    log_info "Docker Compose zaten kurulu."
fi

log_step "Docker servisi başlatılıyor..."
systemctl start docker 2>&1 | tee -a "$LOG_FILE"
systemctl enable docker 2>&1 | tee -a "$LOG_FILE"
log_info "Docker servisi başlatıldı."

# ============================================================================
# SERVİS ÇAKIŞMALARINI ÇÖZMEK
# ============================================================================

log_section "Adım 2: Servis Çakışmalarını Çözmek"

log_step "Sistem servislerini kontrol ediliyor..."
for service in redis-server postgresql nginx; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        log_warning "$service servisi çalışıyor, durduruluyor..."
        systemctl stop $service 2>&1 | tee -a "$LOG_FILE"
        systemctl disable $service 2>&1 | tee -a "$LOG_FILE"
    fi
done
log_info "Servis çakışmaları çözüldü."

# ============================================================================
# DİZİNLER VE DOSYALAR
# ============================================================================

log_section "Adım 3: Dizinler ve Dosyalar"

log_step "Dizinler oluşturuluyor..."
mkdir -p $PROJECT_PATH $LOG_DIR $BACKUP_DIR 2>&1 | tee -a "$LOG_FILE"
chmod 755 $LOG_DIR $BACKUP_DIR 2>&1 | tee -a "$LOG_FILE"
log_info "Dizinler oluşturuldu."

# ============================================================================
# PROJE KLONLAMA
# ============================================================================

log_section "Adım 4: Proje Klonlama"

log_step "GitHub deposu klonlanıyor..."
if [ -d "$PROJECT_PATH/.git" ]; then
    log_step "Proje zaten klonlanmış, güncelleniyor..."
    cd $PROJECT_PATH
    git pull origin main 2>&1 | tee -a "$LOG_FILE"
else
    git clone https://github.com/sata2500/habernexus.git $PROJECT_PATH 2>&1 | tee -a "$LOG_FILE" || log_error "Proje klonlama başarısız oldu."
fi
log_info "Proje klonlandı."

# ============================================================================
# ORTAM DEĞİŞKENLERİ
# ============================================================================

log_section "Adım 5: Ortam Değişkenleri"

log_step ".env dosyası oluşturuluyor..."
SECRET_KEY=$(openssl rand -base64 50 | tr -d '\n' | tr -d '/' | tr -d '+' | head -c 50)
VM_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
DB_USER="habernexus_user"
DB_NAME="habernexus"

cat > $PROJECT_PATH/.env <<EOF
DEBUG=False
DJANGO_SECRET_KEY=$SECRET_KEY
ALLOWED_HOSTS=$VM_IP,$DOMAIN,localhost,127.0.0.1
DB_ENGINE=django.db.backends.postgresql
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=postgres
DB_PORT=5432
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/1
GOOGLE_GEMINI_API_KEY=$GOOGLE_API_KEY
DOMAIN=$DOMAIN
EOF

chmod 644 $PROJECT_PATH/.env 2>&1 | tee -a "$LOG_FILE"
log_info ".env dosyası oluşturuldu."

# ============================================================================
# DOCKER CONTAINER'LARINI BAŞLAT
# ============================================================================

log_section "Adım 6: Docker Container'larını Başlatma"

cd $PROJECT_PATH

log_step "Eski container'ları temizleniyor..."
docker-compose -f docker-compose.prod.yml down -v 2>&1 | tail -5 | tee -a "$LOG_FILE" || true
log_info "Eski container'lar temizlendi."

log_step "Container'lar başlatılıyor..."
docker-compose -f docker-compose.prod.yml up -d 2>&1 | tee -a "$LOG_FILE" || log_error "Container'lar başlatılamadı."
log_info "Container'lar başlatıldı."

log_step "PostgreSQL'in başlamasını bekleniyor..."
MAX_ATTEMPTS=60
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if docker-compose -f docker-compose.prod.yml exec -T postgres pg_isready -U $DB_USER &>/dev/null; then
        log_info "PostgreSQL hazır."
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        log_error "PostgreSQL başlamadı. Logları kontrol edin: docker-compose -f docker-compose.prod.yml logs postgres"
    fi
    sleep 1
done

log_step "Web container'ın başlamasını bekleniyor..."
sleep 30
log_info "Web container başlatıldı."

# ============================================================================
# KURULUM TAMAMLANDI
# ============================================================================

log_section "🎉 KURULUM BAŞARIYLA TAMAMLANDI! 🎉"

echo ""
echo "Kurulum Bilgileri:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Proje Dizini: $PROJECT_PATH"
echo "  Domain: $DOMAIN"
echo "  Admin Email: $ADMIN_EMAIL"
echo "  VM IP: $VM_IP"
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
echo "4. Web sitesine erişim:"
echo "   https://$DOMAIN/admin/"
echo ""

log_info "Kurulum tamamlandı!"
