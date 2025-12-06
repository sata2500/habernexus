#!/bin/bash

################################################################################
# Haber Nexus - Kapsamlı Kurulum Scripti
# Ubuntu 22.04/24.04 LTS için optimize edilmiştir
# Geliştirici: Salih TANRISEVEN
# Email: salihtanriseven25@gmail.com
# Tarih: 2025-12-06
################################################################################

set -e

# ============================================================================
# RENKLER VE FONKSIYONLAR
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_step() { echo -e "\n${BLUE}==>${NC} $1"; }
log_section() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${CYAN}$1${NC}\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

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
INSTALL_METHOD="docker"  # docker veya traditional
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
    log_info "Traditional kurulum seçildi."
else
    INSTALL_METHOD="docker"
    log_info "Docker Compose kurulum seçildi."
fi

echo ""
read -p "Proje dizini [$PROJECT_PATH]: " -r PROJECT_PATH_INPUT
PROJECT_PATH=${PROJECT_PATH_INPUT:-$PROJECT_PATH}
log_info "Proje dizini: $PROJECT_PATH"

echo ""
read -p "Sistem kullanıcısı [$SYSTEM_USER]: " -r SYSTEM_USER_INPUT
SYSTEM_USER=${SYSTEM_USER_INPUT:-$SYSTEM_USER}
log_info "Sistem kullanıcısı: $SYSTEM_USER"

# ============================================================================
# KULLANICILARDAN BİLGİ ALMA
# ============================================================================

log_section "Gerekli Bilgileri Girin"

# Domain
echo ""
read -p "Domain adınız (örn: habernexus.com) [localhost]: " -r DOMAIN
DOMAIN=${DOMAIN:-localhost}
log_info "Domain: $DOMAIN"

# Email
echo ""
read -p "Admin email adresi: " -r ADMIN_EMAIL
if [ -z "$ADMIN_EMAIL" ]; then
    log_error "Email adresi boş olamaz!"
fi
log_info "Admin email: $ADMIN_EMAIL"

# PostgreSQL şifresi
echo ""
while true; do
    read -p "PostgreSQL şifresi (en az 12 karakter, özel karakter içermemeli): " -s DB_PASSWORD
    echo ""
    if [ ${#DB_PASSWORD} -lt 12 ]; then
        log_warning "Şifre en az 12 karakter olmalıdır!"
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
log_info "PostgreSQL şifresi ayarlandı."

# Google Gemini API Key
echo ""
read -p "Google Gemini API Key: " -s GOOGLE_API_KEY
echo ""
if [ -z "$GOOGLE_API_KEY" ]; then
    log_warning "Google API Key boş bırakıldı. Daha sonra .env dosyasında ayarlayabilirsiniz."
else
    log_info "Google API Key ayarlandı."
fi

# SSL sertifikası
echo ""
echo "SSL/TLS Sertifikası:"
echo "  1) Let's Encrypt (Üretim - Önerilen)"
echo "  2) Self-signed (Geliştirme)"
echo "  3) Şimdilik kurma"
echo ""
read -p "Seçim (1, 2 veya 3) [1]: " -r SSL_CHOICE
SSL_CHOICE=${SSL_CHOICE:-1}

case $SSL_CHOICE in
    1)
        SSL_TYPE="letsencrypt"
        log_info "Let's Encrypt sertifikası kurulacak."
        ;;
    2)
        SSL_TYPE="self-signed"
        log_info "Self-signed sertifikası kurulacak."
        ;;
    *)
        SSL_TYPE="none"
        log_info "SSL sertifikası kurulmayacak."
        ;;
esac

# ============================================================================
# KURULUM ÖZETI
# ============================================================================

log_section "Kurulum Özeti"

echo "Kurulum Yöntemi: $INSTALL_METHOD"
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
apt-get update -qq
apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
log_info "Sistem paketleri güncellendi."

log_step "Temel paketler kuruluyor..."
apt-get install -y -qq \
    curl wget git nano htop net-tools \
    build-essential python3-dev python3-pip python3-venv \
    postgresql postgresql-contrib \
    redis-server \
    nginx \
    ufw \
    certbot python3-certbot-nginx \
    openssl

log_info "Temel paketler kuruldu."

if [ "$INSTALL_METHOD" = "docker" ]; then
    log_step "Docker kuruluyor..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    
    # Docker Compose kurulumu
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    log_info "Docker ve Docker Compose kuruldu."
fi

# ============================================================================
# KULLANICI VE DİZİNLER
# ============================================================================

log_section "Adım 2: Kullanıcı ve Dizinler"

log_step "Sistem kullanıcısı oluşturuluyor..."
if ! id -u $SYSTEM_USER > /dev/null 2>&1; then 
    useradd -m -s /bin/bash $SYSTEM_USER
    log_info "Kullanıcı $SYSTEM_USER oluşturuldu."
else
    log_info "Kullanıcı $SYSTEM_USER zaten mevcut."
fi

log_step "Dizinler oluşturuluyor..."
mkdir -p $PROJECT_PATH $LOG_DIR $BACKUP_DIR
chown -R $SYSTEM_USER:$SYSTEM_USER $PROJECT_PATH $LOG_DIR $BACKUP_DIR
chmod 755 $LOG_DIR $BACKUP_DIR
log_info "Dizinler oluşturuldu."

# ============================================================================
# PROJE KLONLAMA
# ============================================================================

log_section "Adım 3: Proje Klonlama"

log_step "GitHub deposu klonlanıyor..."
if [ -d "$PROJECT_PATH/.git" ]; then
    log_warning "Proje zaten mevcut, güncelleniyor..."
    cd $PROJECT_PATH
    sudo -u $SYSTEM_USER git pull origin main
else
    rm -rf $PROJECT_PATH/*
    rm -rf $PROJECT_PATH/.[!.]*
    sudo -u $SYSTEM_USER git clone https://github.com/sata2500/habernexus.git $PROJECT_PATH
fi
log_info "Proje klonlandı."

cd $PROJECT_PATH

# ============================================================================
# ORTAM DEĞIŞKENLERI
# ============================================================================

log_section "Adım 4: Ortam Değişkenleri"

log_step ".env dosyası oluşturuluyor..."

# Secret Key oluştur
SECRET_KEY=$(openssl rand -base64 50 | tr -d '\n' | tr -d '/' | tr -d '+' | head -c 50)

# VM IP adresini al
VM_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

# Veritabanı değişkenleri
DB_USER="habernexus_user"
DB_NAME="habernexus"

if [ "$INSTALL_METHOD" = "docker" ]; then
    # Docker için .env
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
    # Traditional için .env
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

chown $SYSTEM_USER:$SYSTEM_USER $PROJECT_PATH/.env
chmod 600 $PROJECT_PATH/.env
log_info ".env dosyası oluşturuldu."

# ============================================================================
# KURULUM YÖNTEMINI SEÇE
# ============================================================================

if [ "$INSTALL_METHOD" = "docker" ]; then
    source <(cat << 'DOCKER_INSTALL'

# ============================================================================
# DOCKER KURULUMU
# ============================================================================

log_section "Adım 5: Docker Kurulumu"

log_step "Docker servisi başlatılıyor..."
systemctl start docker
systemctl enable docker
log_info "Docker servisi başlatıldı."

log_step "Docker Compose ile uygulamalar başlatılıyor..."
cd $PROJECT_PATH

# docker-compose.prod.yml dosyasını kontrol et
if [ ! -f "docker-compose.prod.yml" ]; then
    log_error "docker-compose.prod.yml dosyası bulunamadı!"
fi

# Docker Compose başlat
docker-compose -f docker-compose.prod.yml up -d --build

log_info "Docker Compose başlatıldı."

log_step "Veritabanı migrasyonları çalıştırılıyor..."
sleep 10
docker-compose -f docker-compose.prod.yml exec -T app python manage.py migrate --noinput
log_info "Veritabanı migrasyonları tamamlandı."

log_step "Statik dosyalar toplanıyor..."
docker-compose -f docker-compose.prod.yml exec -T app python manage.py collectstatic --noinput
log_info "Statik dosyalar toplandı."

# ============================================================================
# DOCKER SYSTEMD SERVİSİ
# ============================================================================

log_section "Adım 6: Systemd Servisi"

log_step "Docker Compose systemd servisi oluşturuluyor..."

cat > /etc/systemd/system/habernexus.service <<'SYSTEMD_EOF'
[Unit]
Description=Haber Nexus Application
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
WorkingDirectory=$PROJECT_PATH
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
RemainAfterExit=yes
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

sed -i "s|\$PROJECT_PATH|$PROJECT_PATH|g" /etc/systemd/system/habernexus.service

systemctl daemon-reload
systemctl enable habernexus.service
log_info "Systemd servisi oluşturuldu."

DOCKER_INSTALL
)
else
    source <(cat << 'TRADITIONAL_INSTALL'

# ============================================================================
# TRADITIONAL KURULUMU
# ============================================================================

log_section "Adım 5: Traditional Kurulumu"

log_step "PostgreSQL veritabanı yapılandırılıyor..."

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

log_info "PostgreSQL veritabanı oluşturuldu."

log_step "Redis servisi başlatılıyor..."
systemctl start redis-server
systemctl enable redis-server
log_info "Redis servisi başlatıldı."

log_step "Python sanal ortamı oluşturuluyor..."
cd $PROJECT_PATH
sudo -u $SYSTEM_USER python3 -m venv venv
sudo -u $SYSTEM_USER venv/bin/pip install --upgrade pip -q
log_info "Python sanal ortamı oluşturuldu."

log_step "Python bağımlılıkları yükleniyor..."
sudo -u $SYSTEM_USER venv/bin/pip install -r requirements.txt -q
log_info "Python bağımlılıkları yüklendi."

log_step "Django veritabanı migrasyonları çalıştırılıyor..."
cd $PROJECT_PATH
sudo -u $SYSTEM_USER venv/bin/python manage.py migrate --noinput
log_info "Veritabanı migrasyonları tamamlandı."

log_step "Statik dosyalar toplanıyor..."
sudo -u $SYSTEM_USER venv/bin/python manage.py collectstatic --noinput
log_info "Statik dosyalar toplandı."

# ============================================================================
# SYSTEMD SERVİSLERİ
# ============================================================================

log_section "Adım 6: Systemd Servisleri"

log_step "Systemd servisleri oluşturuluyor..."

# Django Uygulaması Servisi
cat > /etc/systemd/system/habernexus.service <<SYSTEMD_EOF
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
    --workers 4 \\
    --bind 127.0.0.1:8000 \\
    --timeout 120 \\
    --access-logfile $LOG_DIR/gunicorn-access.log \\
    --error-logfile $LOG_DIR/gunicorn-error.log \\
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
SYSTEMD_EOF

# Celery Worker Servisi
cat > /etc/systemd/system/habernexus-celery.service <<SYSTEMD_EOF
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
SYSTEMD_EOF

# Celery Beat Servisi
cat > /etc/systemd/system/habernexus-celery-beat.service <<SYSTEMD_EOF
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
SYSTEMD_EOF

systemctl daemon-reload
log_info "Systemd servisleri oluşturuldu."

log_step "Servisleri başlatılıyor..."
systemctl enable postgresql redis-server nginx
systemctl restart postgresql redis-server

systemctl enable habernexus habernexus-celery habernexus-celery-beat
systemctl start habernexus
sleep 2
systemctl start habernexus-celery
sleep 1
systemctl start habernexus-celery-beat

log_info "Tüm servisleri başlatıldı."

TRADITIONAL_INSTALL
)
fi

# ============================================================================
# NGINX YAPILANDI
# ============================================================================

log_section "Adım 7: Nginx Yapılandırması"

log_step "Nginx yapılandırılıyor..."

if [ "$INSTALL_METHOD" = "docker" ]; then
    # Docker için Nginx yapılandırması (Docker Compose tarafından yönetilir)
    log_info "Nginx Docker Compose tarafından yönetiliyor."
else
    # Traditional için Nginx yapılandırması
    cat > /etc/nginx/sites-available/habernexus <<EOF
server {
    listen 80;
    server_name $VM_IP $DOMAIN;

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
        log_info "Nginx yapılandırıldı."
    else
        log_warning "Nginx yapılandırma hatası, ancak devam ediliyor..."
    fi
fi

# ============================================================================
# SSL/TLS SERTIFIKASI
# ============================================================================

log_section "Adım 8: SSL/TLS Sertifikası"

if [ "$SSL_TYPE" = "letsencrypt" ]; then
    log_step "Let's Encrypt sertifikası alınıyor..."
    
    if [ "$DOMAIN" = "localhost" ]; then
        log_warning "Localhost için Let's Encrypt sertifikası alınamaz. Self-signed sertifikası kullanılacak."
        SSL_TYPE="self-signed"
    else
        certbot certonly --standalone -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m $ADMIN_EMAIL
        
        if [ "$INSTALL_METHOD" = "docker" ]; then
            mkdir -p $PROJECT_PATH/nginx/ssl
            cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $PROJECT_PATH/nginx/ssl/
            cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $PROJECT_PATH/nginx/ssl/
            chown -R $SYSTEM_USER:$SYSTEM_USER $PROJECT_PATH/nginx/ssl
        fi
        
        log_info "Let's Encrypt sertifikası alındı."
    fi
fi

if [ "$SSL_TYPE" = "self-signed" ]; then
    log_step "Self-signed sertifikası oluşturuluyor..."
    
    if [ "$INSTALL_METHOD" = "docker" ]; then
        mkdir -p $PROJECT_PATH/nginx/ssl
        openssl req -x509 -newkey rsa:4096 -keyout $PROJECT_PATH/nginx/ssl/privkey.pem -out $PROJECT_PATH/nginx/ssl/fullchain.pem -days 365 -nodes -subj "/CN=$DOMAIN"
        chown -R $SYSTEM_USER:$SYSTEM_USER $PROJECT_PATH/nginx/ssl
    else
        mkdir -p /etc/nginx/ssl
        openssl req -x509 -newkey rsa:4096 -keyout /etc/nginx/ssl/privkey.pem -out /etc/nginx/ssl/fullchain.pem -days 365 -nodes -subj "/CN=$DOMAIN"
    fi
    
    log_info "Self-signed sertifikası oluşturuldu."
fi

if [ "$SSL_TYPE" = "none" ]; then
    log_info "SSL sertifikası kurulmadı."
fi

# ============================================================================
# FIREWALL
# ============================================================================

log_section "Adım 9: Firewall Yapılandırması"

log_step "Firewall kuralları ayarlanıyor..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
log_info "Firewall kuralları ayarlandı."

# ============================================================================
# YEDEKLEME SISTEMI
# ============================================================================

log_section "Adım 10: Yedekleme Sistemi"

log_step "Yedekleme cron job'u oluşturuluyor..."

if [ "$INSTALL_METHOD" = "docker" ]; then
    BACKUP_CMD="cd $PROJECT_PATH && docker-compose -f docker-compose.prod.yml exec -T postgres pg_dump -U $DB_USER $DB_NAME | gzip > $BACKUP_DIR/backup_\$(date +%Y%m%d_%H%M%S).sql.gz"
else
    BACKUP_CMD="cd $PROJECT_PATH && pg_dump -U $DB_USER -h localhost $DB_NAME | gzip > $BACKUP_DIR/backup_\$(date +%Y%m%d_%H%M%S).sql.gz"
fi

cat > /etc/cron.d/habernexus-backup <<EOF
# Günlük yedekleme saat 02:00'de
0 2 * * * root $BACKUP_CMD
EOF

log_info "Yedekleme cron job'u oluşturuldu."

# ============================================================================
# MONITORING
# ============================================================================

log_section "Adım 11: Monitoring"

log_step "Health check scripti oluşturuluyor..."

cat > /usr/local/bin/habernexus-health-check <<'HEALTH_EOF'
#!/bin/bash
HEALTH_URL="http://localhost/admin/"
TIMEOUT=5

if curl -f --max-time $TIMEOUT "$HEALTH_URL" > /dev/null 2>&1; then
    echo "✅ Haber Nexus sağlıklı"
    exit 0
else
    echo "❌ Haber Nexus yanıt vermiyor"
    exit 1
fi
HEALTH_EOF

chmod +x /usr/local/bin/habernexus-health-check

log_info "Health check scripti oluşturuldu."

log_step "Health check cron job'u oluşturuluyor..."

cat > /etc/cron.d/habernexus-health-check <<EOF
# Her 5 dakikada bir health check
*/5 * * * * root /usr/local/bin/habernexus-health-check >> /var/log/habernexus-health.log 2>&1
EOF

log_info "Health check cron job'u oluşturuldu."

# ============================================================================
# SERVIS DURUMLARINI KONTROL ET
# ============================================================================

log_section "Adım 12: Servis Durumları"

log_step "Servislerin başlatılmasını bekleniyor..."
sleep 5

echo ""
echo "Servis Durumları:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$INSTALL_METHOD" = "docker" ]; then
    echo ""
    docker-compose -f $PROJECT_PATH/docker-compose.prod.yml ps
    echo ""
else
    DJANGO_STATUS=$(systemctl is-active habernexus 2>/dev/null || echo "inactive")
    CELERY_STATUS=$(systemctl is-active habernexus-celery 2>/dev/null || echo "inactive")
    BEAT_STATUS=$(systemctl is-active habernexus-celery-beat 2>/dev/null || echo "inactive")
    NGINX_STATUS=$(systemctl is-active nginx 2>/dev/null || echo "inactive")
    
    echo "  Django App: $DJANGO_STATUS"
    echo "  Celery Worker: $CELERY_STATUS"
    echo "  Celery Beat: $BEAT_STATUS"
    echo "  Nginx: $NGINX_STATUS"
    echo ""
fi

# ============================================================================
# KURULUM TAMAMLANDI
# ============================================================================

log_section "🎉 KURULUM BAŞARIYLA TAMAMLANDI! 🎉"

echo ""
echo "Kurulum Bilgileri:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Kurulum Yöntemi: $INSTALL_METHOD"
echo "  Proje Dizini: $PROJECT_PATH"
echo "  Domain: $DOMAIN"
echo "  VM IP: $VM_IP"
echo "  Admin Email: $ADMIN_EMAIL"
echo "  SSL Tipi: $SSL_TYPE"
echo ""

echo "Web Sitesine Erişim:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Web Sitesi: http://$DOMAIN"
echo "  Admin Paneli: http://$DOMAIN/admin/"
echo ""

echo "Sonraki Adımlar:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Admin kullanıcısı oluşturun:"

if [ "$INSTALL_METHOD" = "docker" ]; then
    echo "   docker-compose -f $PROJECT_PATH/docker-compose.prod.yml exec app python manage.py createsuperuser"
else
    echo "   sudo -u $SYSTEM_USER $PROJECT_PATH/venv/bin/python $PROJECT_PATH/manage.py createsuperuser"
fi

echo ""
echo "2. Servis durumlarını kontrol edin:"

if [ "$INSTALL_METHOD" = "docker" ]; then
    echo "   docker-compose -f $PROJECT_PATH/docker-compose.prod.yml ps"
    echo "   docker-compose -f $PROJECT_PATH/docker-compose.prod.yml logs -f"
else
    echo "   sudo systemctl status habernexus"
    echo "   sudo systemctl status habernexus-celery"
    echo "   sudo systemctl status habernexus-celery-beat"
    echo "   sudo journalctl -u habernexus -f"
fi

echo ""
echo "3. Logları görüntüleyin:"

if [ "$INSTALL_METHOD" = "docker" ]; then
    echo "   docker-compose -f $PROJECT_PATH/docker-compose.prod.yml logs -f app"
else
    echo "   sudo tail -f $LOG_DIR/gunicorn-error.log"
    echo "   sudo tail -f $LOG_DIR/celery-worker.log"
fi

echo ""
echo "4. Yapılandırma dosyasını düzenleyin:"
echo "   nano $PROJECT_PATH/.env"
echo ""

echo "Önemli Komutlar:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$INSTALL_METHOD" = "docker" ]; then
    echo "  # Servisleri yeniden başlat"
    echo "  docker-compose -f $PROJECT_PATH/docker-compose.prod.yml restart"
    echo ""
    echo "  # Veritabanı migrasyonları çalıştır"
    echo "  docker-compose -f $PROJECT_PATH/docker-compose.prod.yml exec app python manage.py migrate"
    echo ""
    echo "  # Statik dosyaları topla"
    echo "  docker-compose -f $PROJECT_PATH/docker-compose.prod.yml exec app python manage.py collectstatic"
else
    echo "  # Servisleri yeniden başlat"
    echo "  sudo systemctl restart habernexus habernexus-celery habernexus-celery-beat"
    echo ""
    echo "  # Veritabanı migrasyonları çalıştır"
    echo "  sudo -u $SYSTEM_USER $PROJECT_PATH/venv/bin/python $PROJECT_PATH/manage.py migrate"
    echo ""
    echo "  # Statik dosyaları topla"
    echo "  sudo -u $SYSTEM_USER $PROJECT_PATH/venv/bin/python $PROJECT_PATH/manage.py collectstatic"
fi

echo ""
echo "Yardım ve Destek:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  GitHub: https://github.com/sata2500/habernexus"
echo "  Email: salihtanriseven25@gmail.com"
echo ""

log_info "Kurulum tamamlandı! Keyifli kullanımlar."
