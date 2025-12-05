#!/bin/bash
# Haber Nexus - Otomatik Kurulum Scripti
# Ubuntu 22.04/24.04 LTS için optimize edilmiştir.
# Geliştirici: Salih TANRISEVEN
# E-posta: salihtanriseven25@gmail.com

set -e

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonksiyonlar
log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_step() { echo -e "\n${BLUE}==>${NC} $1"; }

# Banner
clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Haber Nexus - Otomatik Kurulum Scripti              ║"
echo "║              Profesyonel Haber Ajansı Platformu             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Root kontrolü
if [ "$EUID" -ne 0 ]; then 
    log_error "Bu script root yetkisi ile çalıştırılmalıdır. Lütfen 'sudo bash install.sh' kullanın."
fi

# Kullanıcıdan bilgi alma
log_step "Kurulum Bilgileri"
echo "Not: Boş bırakılan alanlar için varsayılan değerler kullanılacaktır."
echo ""

read -p "Domain adınız (opsiyonel, boş bırakabilirsiniz): " DOMAIN
echo ""

while true; do
    read -p "PostgreSQL şifresi (özel karakter kullanmayın): " -s DB_PASSWORD
    echo ""
    if [ -z "$DB_PASSWORD" ]; then
        log_warning "Şifre boş olamaz!"
        continue
    fi
    read -p "PostgreSQL şifresi (tekrar): " -s DB_PASSWORD_CONFIRM
    echo ""
    if [ "$DB_PASSWORD" = "$DB_PASSWORD_CONFIRM" ]; then
        break
    else
        log_warning "Şifreler eşleşmiyor! Tekrar deneyin."
    fi
done

while true; do
    read -p "Google Gemini API Key: " -s GOOGLE_API_KEY
    echo ""
    if [ -z "$GOOGLE_API_KEY" ]; then
        log_warning "API Key boş olamaz!"
        continue
    fi
    break
done

# Otomatik değerler
SECRET_KEY=$(openssl rand -base64 50 | tr -d '\n' | tr -d '/' | tr -d '+' | head -c 50)
VM_IP=$(curl -s ifconfig.me || echo "localhost")
DB_USER="habernexus_user"
DB_NAME="habernexus"
PROJECT_PATH="/var/www/habernexus"
SYSTEM_USER="habernexus_user"
LOG_DIR="/var/log/habernexus"
RUN_DIR="/var/run/habernexus"

# Onay
echo ""
log_warning "Aşağıdaki ayarlarla kurulum yapılacak:"
echo "  - Domain: ${DOMAIN:-Belirtilmedi (IP kullanılacak)}"
echo "  - VM IP: $VM_IP"
echo "  - DB Kullanıcı: $DB_USER"
echo "  - DB Adı: $DB_NAME"
echo "  - Sistem Kullanıcı: $SYSTEM_USER"
echo "  - Proje Dizini: $PROJECT_PATH"
echo ""
read -p "Devam etmek istiyor musunuz? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then 
    log_error "Kurulum iptal edildi."
fi

# 1. Sistem Hazırlığı
log_step "Adım 1/11: Sistem güncelleniyor ve paketler kuruluyor..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt-get install -y -qq build-essential python3-dev python3-pip python3-venv git nginx redis-server postgresql postgresql-contrib curl ufw
log_info "Sistem hazır."

# 2. Kullanıcı ve Dizinler
log_step "Adım 2/11: Sistem kullanıcısı ve dizinler oluşturuluyor..."
if ! id -u $SYSTEM_USER > /dev/null 2>&1; then 
    useradd -m -s /bin/bash $SYSTEM_USER
    log_info "Kullanıcı $SYSTEM_USER oluşturuldu."
else
    log_info "Kullanıcı $SYSTEM_USER zaten mevcut."
fi

mkdir -p $PROJECT_PATH $LOG_DIR $RUN_DIR /var/backups/habernexus
chown -R $SYSTEM_USER:$SYSTEM_USER $PROJECT_PATH $LOG_DIR $RUN_DIR
log_info "Dizinler hazır."

# 3. PostgreSQL
log_step "Adım 3/11: PostgreSQL veritabanı yapılandırılıyor..."

# Mevcut veritabanı ve kullanıcıyı temizle
sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
sudo -u postgres psql -c "DROP USER IF EXISTS $DB_USER;" 2>/dev/null || true

# Yeni veritabanı ve kullanıcı oluştur
sudo -u postgres psql <<EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
EOF

log_info "PostgreSQL hazır."

# 4. Proje Klonlama
log_step "Adım 4/11: Proje klonlanıyor..."

# Eğer dizin varsa ve boş değilse yedekle
if [ -d "$PROJECT_PATH/.git" ]; then
    log_warning "Proje zaten mevcut, güncelleniyor..."
    cd $PROJECT_PATH
    sudo -u $SYSTEM_USER git pull origin main
else
    # Dizini temizle ve klonla
    rm -rf $PROJECT_PATH/*
    rm -rf $PROJECT_PATH/.[!.]*
    sudo -u $SYSTEM_USER git clone https://github.com/sata2500/habernexus.git $PROJECT_PATH
fi

log_info "Proje klonlandı."

# 5. Python Virtual Environment
log_step "Adım 5/11: Python sanal ortamı oluşturuluyor..."
cd $PROJECT_PATH
sudo -u $SYSTEM_USER python3 -m venv venv
sudo -u $SYSTEM_USER venv/bin/pip install --upgrade pip -q
log_info "Virtual environment hazır."

# 6. Python Bağımlılıkları
log_step "Adım 6/11: Python bağımlılıkları yükleniyor (bu birkaç dakika sürebilir)..."
sudo -u $SYSTEM_USER venv/bin/pip install -r requirements.txt -q
log_info "Bağımlılıklar yüklendi."

# 7. .env Dosyası
log_step "Adım 7/11: Ortam değişkenleri yapılandırılıyor..."
cat > $PROJECT_PATH/.env <<EOF
DEBUG=False
DJANGO_SECRET_KEY=$SECRET_KEY
ALLOWED_HOSTS=$VM_IP,${DOMAIN:-$VM_IP},localhost,127.0.0.1
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=localhost
DB_PORT=5432
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0
GOOGLE_API_KEY=$GOOGLE_API_KEY
DOMAIN=${DOMAIN:-$VM_IP}
EOF

chown $SYSTEM_USER:$SYSTEM_USER $PROJECT_PATH/.env
chmod 600 $PROJECT_PATH/.env
log_info ".env dosyası oluşturuldu."

# 8. Django Kurulum
log_step "Adım 8/11: Django uygulaması yapılandırılıyor..."
cd $PROJECT_PATH
sudo -u $SYSTEM_USER venv/bin/python manage.py migrate --noinput
sudo -u $SYSTEM_USER venv/bin/python manage.py collectstatic --noinput
log_info "Django hazır."

# 9. Systemd Servisleri
log_step "Adım 9/11: Systemd servisleri oluşturuluyor..."

# Django Uygulaması Servisi
cat > /etc/systemd/system/habernexus.service <<EOF
[Unit]
Description=Haber Nexus Django Application
After=network.target postgresql.service redis-server.service

[Service]
Type=exec
User=$SYSTEM_USER
Group=$SYSTEM_USER
WorkingDirectory=$PROJECT_PATH

Environment="PATH=$PROJECT_PATH/venv/bin"
Environment="DJANGO_SETTINGS_MODULE=habernexus_config.settings"

ExecStart=$PROJECT_PATH/venv/bin/gunicorn \\
    --config $PROJECT_PATH/config/gunicorn_config.py \\
    --workers 4 \\
    --bind 127.0.0.1:8000 \\
    habernexus_config.wsgi:application

ExecReload=/bin/kill -s HUP \$MAINPID
KillMode=mixed
KillSignal=SIGQUIT

Restart=on-failure
RestartSec=5s

StandardOutput=journal
StandardError=journal
SyslogIdentifier=habernexus

[Install]
WantedBy=multi-user.target
EOF

# Celery Worker Servisi
cat > /etc/systemd/system/habernexus-celery.service <<EOF
[Unit]
Description=Haber Nexus Celery Worker
After=network.target redis-server.service postgresql.service
Wants=habernexus.service

[Service]
Type=simple
User=$SYSTEM_USER
Group=$SYSTEM_USER
WorkingDirectory=$PROJECT_PATH

Environment="PATH=$PROJECT_PATH/venv/bin"
Environment="DJANGO_SETTINGS_MODULE=habernexus_config.settings"

ExecStart=$PROJECT_PATH/venv/bin/celery -A habernexus_config worker \\
    --loglevel=info \\
    --concurrency=4 \\
    --logfile=$LOG_DIR/celery-worker.log

ExecStop=$PROJECT_PATH/venv/bin/celery -A habernexus_config control shutdown

Restart=on-failure
RestartSec=10s

StandardOutput=journal
StandardError=journal
SyslogIdentifier=habernexus-celery

[Install]
WantedBy=multi-user.target
EOF

# Celery Beat Servisi
cat > /etc/systemd/system/habernexus-celery-beat.service <<EOF
[Unit]
Description=Haber Nexus Celery Beat Scheduler
After=network.target redis-server.service postgresql.service
Wants=habernexus.service

[Service]
Type=simple
User=$SYSTEM_USER
Group=$SYSTEM_USER
WorkingDirectory=$PROJECT_PATH

Environment="PATH=$PROJECT_PATH/venv/bin"
Environment="DJANGO_SETTINGS_MODULE=habernexus_config.settings"

ExecStart=$PROJECT_PATH/venv/bin/celery -A habernexus_config beat \\
    --loglevel=info \\
    --logfile=$LOG_DIR/celery-beat.log \\
    --scheduler django_celery_beat.schedulers:DatabaseScheduler

Restart=on-failure
RestartSec=10s

StandardOutput=journal
StandardError=journal
SyslogIdentifier=habernexus-celery-beat

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
log_info "Systemd servisleri hazır."

# 10. Nginx
log_step "Adım 10/11: Nginx yapılandırılıyor..."

cat > /etc/nginx/sites-available/habernexus <<EOF
server {
    listen 80;
    server_name $VM_IP ${DOMAIN:-$VM_IP};

    client_max_body_size 100M;

    location /static/ {
        alias $PROJECT_PATH/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias $PROJECT_PATH/media/;
        expires 7d;
        add_header Cache-Control "public";
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
    }
}
EOF

ln -sf /etc/nginx/sites-available/habernexus /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

if nginx -t 2>/dev/null; then
    systemctl restart nginx
    log_info "Nginx hazır."
else
    log_warning "Nginx yapılandırma hatası, ancak devam ediliyor..."
fi

# 11. Servisleri Başlatma
log_step "Adım 11/11: Servisler başlatılıyor..."

# Temel servisleri etkinleştir
systemctl enable redis-server postgresql nginx

# Habernexus servislerini etkinleştir
systemctl enable habernexus habernexus-celery habernexus-celery-beat

# Servisleri başlat
systemctl restart redis-server postgresql nginx

# Django uygulamasını başlat
systemctl start habernexus
sleep 2

# Celery servislerini başlat
systemctl start habernexus-celery
sleep 1
systemctl start habernexus-celery-beat

log_info "Tüm servisler başlatıldı."

# Firewall
log_step "Firewall yapılandırılıyor..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
log_info "Firewall hazır."

# Servis durumlarını kontrol et
log_step "Servis durumları kontrol ediliyor..."
sleep 3

DJANGO_STATUS=$(systemctl is-active habernexus)
CELERY_STATUS=$(systemctl is-active habernexus-celery)
BEAT_STATUS=$(systemctl is-active habernexus-celery-beat)
NGINX_STATUS=$(systemctl is-active nginx)

echo ""
echo "Servis Durumları:"
echo "  - Django App: $DJANGO_STATUS"
echo "  - Celery Worker: $CELERY_STATUS"
echo "  - Celery Beat: $BEAT_STATUS"
echo "  - Nginx: $NGINX_STATUS"
echo ""

# Tamamlandı
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              🎉 KURULUM BAŞARIYLA TAMAMLANDI! 🎉          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_info "Web sitesi: http://$VM_IP"
log_info "Admin paneli: http://$VM_IP/admin/"
echo ""
log_warning "ÖNEMLİ SONRAKI ADIMLAR:"
echo ""
echo "1. Admin kullanıcısı oluşturun:"
echo "   sudo -u $SYSTEM_USER $PROJECT_PATH/venv/bin/python $PROJECT_PATH/manage.py createsuperuser"
echo ""
if [ -n "$DOMAIN" ]; then 
    echo "2. SSL sertifikası alın:"
    echo "   sudo apt install certbot python3-certbot-nginx -y"
    echo "   sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    echo ""
fi
echo "3. Servis durumlarını kontrol edin:"
echo "   sudo systemctl status habernexus"
echo "   sudo systemctl status habernexus-celery"
echo "   sudo systemctl status habernexus-celery-beat"
echo ""
echo "4. Logları görüntüleyin:"
echo "   sudo journalctl -u habernexus -f"
echo "   sudo tail -f $LOG_DIR/celery-worker.log"
echo ""
log_info "Kurulum tamamlandı! Keyifli kullanımlar."
