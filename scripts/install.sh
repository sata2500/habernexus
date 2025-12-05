#!/bin/bash
# Haber Nexus - Otomatik Kurulum Scripti
# Ubuntu 22.04 LTS için optimize edilmiştir.

set -e

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonksiyonlar
log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_step() { echo -e "\n${BLUE}==>${NC} $1"; }

# Banner
clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Haber Nexus - Otomatik Kurulum Scripti              ║"
echo "╚════════════════════════════════════════════════════════════╝"

# Root kontrolü
if [ "$EUID" -ne 0 ]; then log_error "Bu script root yetkisi ile çalıştırılmalıdır. Lütfen \'sudo\' kullanın."; fi

# Kullanıcıdan bilgi alma
log_step "Kurulum Bilgileri"
read -p "Domain adınız (opsiyonel, SSL için): " DOMAIN
read -p "PostgreSQL şifresi: " -s DB_PASSWORD; echo
read -p "Google Gemini API Key: " -s GOOGLE_API_KEY; echo

# Otomatik değerler
SECRET_KEY=$(openssl rand -base64 50 | tr -d '\n')
VM_IP=$(curl -s ifconfig.me)
DB_USER="habernexus_user"
DB_NAME="habernexus"
PROJECT_PATH="/var/www/habernexus"
SYSTEM_USER="habernexus_user"

# Onay
log_warning "Aşağıdaki ayarlarla kurulum yapılacak:"
echo "  - Domain: ${DOMAIN:-Belirtilmedi}"
echo "  - VM IP: $VM_IP"
echo "  - DB Kullanıcı: $DB_USER"
echo "  - Sistem Kullanıcı: $SYSTEM_USER"
read -p "Devam etmek istiyor musunuz? (y/n): " -n 1 -r; echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then log_error "Kurulum iptal edildi."; fi

# 1. Sistem Hazırlığı
log_step "Adım 1/9: Sistem güncelleniyor ve paketler kuruluyor..."
apt update -qq && apt upgrade -y -qq
apt install -y -qq build-essential python3-dev python3-pip python3-venv git nginx redis-server postgresql postgresql-contrib curl ufw
log_info "Sistem hazır."

# 2. Kullanıcı ve Dizinler
log_step "Adım 2/9: Sistem kullanıcısı ve dizinler oluşturuluyor..."
if ! id -u $SYSTEM_USER > /dev/null 2>&1; then useradd -m -s /bin/bash $SYSTEM_USER; fi
mkdir -p $PROJECT_PATH /var/log/habernexus /var/backups
chown -R $SYSTEM_USER:$SYSTEM_USER $PROJECT_PATH /var/log/habernexus
log_info "Kullanıcı ve dizinler hazır."

# 3. PostgreSQL
log_step "Adım 3/9: PostgreSQL veritabanı yapılandırılıyor..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;" -c "DROP USER IF EXISTS $DB_USER;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD \'$DB_PASSWORD\';" -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
log_info "PostgreSQL hazır."

# 4. Proje Klonlama ve Kurulum
log_step "Adım 4/9: Proje klonlanıyor ve bağımlılıklar yükleniyor..."
if [ -d "$PROJECT_PATH/.git" ]; then cd $PROJECT_PATH && sudo -u $SYSTEM_USER git pull origin main; else sudo -u $SYSTEM_USER git clone https://github.com/sata2500/habernexus.git $PROJECT_PATH; fi
cd $PROJECT_PATH
sudo -u $SYSTEM_USER python3 -m venv venv
sudo -u $SYSTEM_USER venv/bin/pip install --upgrade pip -q
sudo -u $SYSTEM_USER venv/bin/pip install -r requirements.txt -q
log_info "Proje hazır."

# 5. .env Dosyası
log_step "Adım 5/9: Ortam değişkenleri yapılandırılıyor..."
cat > $PROJECT_PATH/.env <<EOF
DEBUG=False
DJANGO_SECRET_KEY=\'$SECRET_KEY\'
ALLOWED_HOSTS=$VM_IP,${DOMAIN:-$VM_IP}
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=\'$DB_PASSWORD\'
DB_HOST=localhost
DB_PORT=5432
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0
GOOGLE_API_KEY=\'$GOOGLE_API_KEY\'
DOMAIN=${DOMAIN:-$VM_IP}
EOF
chown $SYSTEM_USER:$SYSTEM_USER $PROJECT_PATH/.env && chmod 600 $PROJECT_PATH/.env
log_info ".env dosyası oluşturuldu."

# 6. Django Kurulum
log_step "Adım 6/9: Django uygulaması yapılandırılıyor..."
sudo -u $SYSTEM_USER $PROJECT_PATH/venv/bin/python manage.py migrate --noinput
sudo -u $SYSTEM_USER $PROJECT_PATH/venv/bin/python manage.py collectstatic --noinput
log_info "Django hazır."

# 7. Systemd Servisleri
log_step "Adım 7/9: Systemd servisleri oluşturuluyor..."
cp $PROJECT_PATH/config/habernexus*.service /etc/systemd/system/
systemctl daemon-reload
log_info "Systemd servisleri hazır."

# 8. Nginx
log_step "Adım 8/9: Nginx yapılandırılıyor..."
cp $PROJECT_PATH/config/nginx_production.conf /etc/nginx/sites-available/habernexus
ln -sf /etc/nginx/sites-available/habernexus /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
log_info "Nginx hazır."

# 9. Servisleri Başlatma
log_step "Adım 9/9: Servisler başlatılıyor..."
systemctl enable --now redis-server habernexus habernexus-celery habernexus-celery-beat
ufw --force enable && ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp
log_info "Tüm servisler çalışıyor."

# Tamamlandı
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              🎉 KURULUM BAŞARIYLA TAMAMLANDI! 🎉          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_info "Web sitesi: http://$VM_IP"
log_info "Admin paneli: http://$VM_IP/admin/"
echo ""
log_warning "ÖNEMLİ SONRAKI ADIMLAR:"
echo "1. Admin kullanıcısı oluşturun: sudo -u $SYSTEM_USER $PROJECT_PATH/venv/bin/python manage.py createsuperuser"
if [ -n "$DOMAIN" ]; then echo "2. SSL sertifikası alın: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"; fi
echo "3. Servis durumlarını kontrol edin: sudo systemctl status habernexus habernexus-celery"
