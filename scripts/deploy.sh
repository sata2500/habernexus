#!/bin/bash
# Haber Nexus Deployment Script
# Production ortamında uygulamayı kurması için kullanılır

set -e

echo "================================"
echo "Haber Nexus Deployment Script"
echo "================================"

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Kontrol fonksiyonları
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 1. Sistem Güncellemesi
log_info "Sistem güncellemesi yapılıyor..."
sudo apt update
sudo apt upgrade -y

# 2. Gerekli Paketlerin Kurulması
log_info "Gerekli paketler kurulıyor..."
sudo apt install -y build-essential python3-dev python3-pip python3-venv
sudo apt install -y postgresql postgresql-contrib
sudo apt install -y redis-server
sudo apt install -y nginx
sudo apt install -y git curl wget
sudo apt install -y certbot python3-certbot-nginx

# 3. Kullanıcı Oluşturma
log_info "www-data kullanıcısı yapılandırılıyor..."
if ! id -u www-data > /dev/null 2>&1; then
    sudo useradd -m -s /bin/bash www-data
fi

# 4. Dizin Yapısı
log_info "Dizin yapısı oluşturuluyor..."
sudo mkdir -p /var/www/habernexus
sudo mkdir -p /var/log/habernexus
sudo mkdir -p /var/run/habernexus
sudo mkdir -p /var/backups
sudo chown -R www-data:www-data /var/www/habernexus
sudo chown -R www-data:www-data /var/log/habernexus
sudo chown -R www-data:www-data /var/run/habernexus

# 5. Proje Klonlama
log_info "Proje klonlanıyor..."
if [ ! -d "/var/www/habernexus/.git" ]; then
    sudo git clone https://github.com/sata2500/habernexus.git /tmp/habernexus_temp
    sudo cp -r /tmp/habernexus_temp/* /var/www/habernexus/
    sudo rm -rf /tmp/habernexus_temp
fi

# 6. Virtual Environment
log_info "Virtual environment oluşturuluyor..."
sudo -u www-data python3 -m venv /var/www/habernexus/venv
sudo -u www-data /var/www/habernexus/venv/bin/pip install --upgrade pip setuptools wheel
sudo -u www-data /var/www/habernexus/venv/bin/pip install -r /var/www/habernexus/requirements.txt
sudo -u www-data /var/www/habernexus/venv/bin/pip install gunicorn

# 7. PostgreSQL Veritabanı
log_info "PostgreSQL veritabanı oluşturuluyor..."
sudo -u postgres psql <<EOF
CREATE USER IF NOT EXISTS habernexus WITH PASSWORD 'habernexus_password';
CREATE DATABASE IF NOT EXISTS habernexus OWNER habernexus;
ALTER ROLE habernexus SET client_encoding TO 'utf8';
ALTER ROLE habernexus SET default_transaction_isolation TO 'read committed';
ALTER ROLE habernexus SET default_transaction_deferrable TO on;
ALTER ROLE habernexus SET default_transaction_level TO 'read committed';
GRANT ALL PRIVILEGES ON DATABASE habernexus TO habernexus;
EOF

# 8. Django Migrasyonları
log_info "Django migrasyonları uygulanıyor..."
cd /var/www/habernexus
sudo -u www-data venv/bin/python manage.py migrate --settings=habernexus_config.settings
sudo -u www-data venv/bin/python manage.py collectstatic --noinput --settings=habernexus_config.settings

# 9. Systemd Servisleri
log_info "Systemd servisleri kurulıyor..."
sudo cp /var/www/habernexus/config/habernexus.service /etc/systemd/system/
sudo cp /var/www/habernexus/config/habernexus-celery.service /etc/systemd/system/
sudo cp /var/www/habernexus/config/habernexus-celery-beat.service /etc/systemd/system/
sudo systemctl daemon-reload

# 10. Nginx Yapılandırması
log_info "Nginx yapılandırması kurulıyor..."
sudo cp /var/www/habernexus/config/nginx_production.conf /etc/nginx/sites-available/habernexus
sudo ln -sf /etc/nginx/sites-available/habernexus /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# 11. Servisleri Başlat
log_info "Servisleri başlatıyor..."
sudo systemctl enable habernexus
sudo systemctl start habernexus
sudo systemctl enable habernexus-celery
sudo systemctl start habernexus-celery
sudo systemctl enable habernexus-celery-beat
sudo systemctl start habernexus-celery-beat
sudo systemctl enable redis-server
sudo systemctl start redis-server

# 12. Firewall
log_info "Firewall yapılandırılıyor..."
sudo ufw enable --force
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

echo ""
echo "================================"
echo -e "${GREEN}Deployment Tamamlandı!${NC}"
echo "================================"
echo ""
echo "Sonraki Adımlar:"
echo "1. .env dosyasını yapılandırın: sudo nano /var/www/habernexus/.env"
echo "2. SSL sertifikası oluşturun: sudo certbot certonly --webroot -w /var/www/certbot -d habernexus.com"
echo "3. Admin paneline gidin: https://habernexus.com/admin/"
echo ""
echo "Hizmetleri kontrol etmek için:"
echo "  sudo systemctl status habernexus"
echo "  sudo systemctl status habernexus-celery"
echo "  sudo systemctl status habernexus-celery-beat"
echo ""
