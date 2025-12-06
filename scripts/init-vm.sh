#!/bin/bash

#############################################################################
# Haber Nexus VM Initialization Script
# Sets up a fresh Ubuntu VM with all dependencies and the application
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

log_section "Haber Nexus VM Initialization"

# Update system
log_section "Updating System"
log_info "Updating package lists..."
apt-get update
apt-get upgrade -y

# Install Docker
log_section "Installing Docker"
log_info "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Install Docker Compose
log_section "Installing Docker Compose"
log_info "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install essential tools
log_section "Installing Essential Tools"
log_info "Installing curl, git, wget, htop, nano..."
apt-get install -y curl git wget htop nano net-tools

# Install Certbot for Let's Encrypt
log_section "Installing Certbot (Let's Encrypt)"
log_info "Installing Certbot..."
apt-get install -y certbot python3-certbot-nginx

# Create application directory
log_section "Creating Application Directory"
APP_DIR="/opt/habernexus"
log_info "Creating directory: ${APP_DIR}"
mkdir -p "${APP_DIR}"
cd "${APP_DIR}"

# Clone repository
log_section "Cloning Repository"
log_info "Cloning Haber Nexus repository..."
git clone https://github.com/sata2500/habernexus.git .
git fetch origin
git reset --hard origin/main

# Create necessary directories
log_section "Creating Directories"
mkdir -p .backup
mkdir -p nginx/ssl
mkdir -p nginx/logs
chmod 755 scripts/*.sh

# Create .env file
log_section "Creating Environment Configuration"
if [ ! -f ".env" ]; then
    log_info "Creating .env file..."
    cp .env.example .env
    
    # Generate secure secret key
    SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
    sed -i "s/DJANGO_SECRET_KEY=.*/DJANGO_SECRET_KEY=${SECRET_KEY}/" .env
    
    # Set database password
    DB_PASSWORD=$(openssl rand -base64 32)
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env
    
    # Set Redis password
    REDIS_PASSWORD=$(openssl rand -base64 32)
    sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=${REDIS_PASSWORD}/" .env
    
    log_info "✅ .env file created with secure passwords"
else
    log_warn ".env file already exists - skipping creation"
fi

# Create systemd service for Docker Compose
log_section "Creating Systemd Service"
log_info "Creating habernexus.service..."
cat > /etc/systemd/system/habernexus.service << 'EOF'
[Unit]
Description=Haber Nexus Application
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
WorkingDirectory=/opt/habernexus
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
RemainAfterExit=yes
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable habernexus.service

log_info "✅ Systemd service created"

# Create backup cron job
log_section "Setting Up Automated Backups"
log_info "Creating daily backup cron job..."
cat > /etc/cron.d/habernexus-backup << 'EOF'
# Daily backup at 2 AM
0 2 * * * root cd /opt/habernexus && ./scripts/backup.sh >> /var/log/habernexus-backup.log 2>&1
EOF

log_info "✅ Backup cron job created"

# Create log rotation
log_section "Setting Up Log Rotation"
log_info "Creating logrotate configuration..."
cat > /etc/logrotate.d/habernexus << 'EOF'
/opt/habernexus/nginx/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        docker-compose -f /opt/habernexus/docker-compose.prod.yml exec -T nginx nginx -s reload > /dev/null 2>&1 || true
    endscript
}
EOF

log_info "✅ Log rotation configured"

# Create monitoring script
log_section "Setting Up Monitoring"
log_info "Creating health check script..."
cat > /usr/local/bin/habernexus-health-check << 'EOF'
#!/bin/bash
# Simple health check script
HEALTH_URL="http://localhost:8000/health/"
TIMEOUT=5

if curl -f --max-time $TIMEOUT "$HEALTH_URL" > /dev/null 2>&1; then
    echo "✅ Haber Nexus is healthy"
    exit 0
else
    echo "❌ Haber Nexus is not responding"
    exit 1
fi
EOF

chmod +x /usr/local/bin/habernexus-health-check

log_info "✅ Health check script created"

# Create monitoring cron job
cat > /etc/cron.d/habernexus-health-check << 'EOF'
# Health check every 5 minutes
*/5 * * * * root /usr/local/bin/habernexus-health-check >> /var/log/habernexus-health.log 2>&1
EOF

log_info "✅ Health check cron job created"

# Final instructions
log_section "Initialization Complete!"
log_info "✅ VM has been successfully initialized"
log_info ""
log_info "Next steps:"
log_info ""
log_info "1. Configure environment variables:"
log_info "   nano /opt/habernexus/.env"
log_info ""
log_info "2. Set up SSL certificates (Let's Encrypt):"
log_info "   certbot certonly --standalone -d habernexus.com -d www.habernexus.com"
log_info "   sudo cp /etc/letsencrypt/live/habernexus.com/fullchain.pem /opt/habernexus/nginx/ssl/"
log_info "   sudo cp /etc/letsencrypt/live/habernexus.com/privkey.pem /opt/habernexus/nginx/ssl/"
log_info ""
log_info "3. Start the application:"
log_info "   systemctl start habernexus"
log_info ""
log_info "4. Check application status:"
log_info "   systemctl status habernexus"
log_info "   /usr/local/bin/habernexus-health-check"
log_info ""
log_info "5. View logs:"
log_info "   journalctl -u habernexus -f"
log_info "   cd /opt/habernexus && docker-compose -f docker-compose.prod.yml logs -f"
log_info ""
log_info "6. Useful commands:"
log_info "   docker-compose -f docker-compose.prod.yml ps          # View containers"
log_info "   docker-compose -f docker-compose.prod.yml restart    # Restart services"
log_info "   ./scripts/backup.sh                                   # Manual backup"
log_info "   ./scripts/restore.sh .backup/habernexus_backup_*      # Restore from backup"
log_info ""
