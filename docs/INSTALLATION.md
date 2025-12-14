# Installation Guide

**Version:** 4.0  
**Last Updated:** December 14, 2024  
**Author:** Salih TANRISEVEN

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation Options](#installation-options)
3. [Quick Start](#quick-start)
4. [Detailed Installation](#detailed-installation)
5. [Cloudflare Setup](#cloudflare-setup)
6. [Nginx Proxy Manager Setup](#nginx-proxy-manager-setup)
7. [Local Development](#local-development)
8. [Post-Installation](#post-installation)
9. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Minimum Requirements
- **OS:** Ubuntu 22.04 LTS or 24.04 LTS
- **RAM:** 4 GB (8 GB recommended)
- **Disk:** 20 GB free space
- **CPU:** 2 cores (4 cores recommended)
- **Internet:** Stable connection

### Software Requirements
- Docker (auto-installed)
- Docker Compose v2 (auto-installed)
- Git (auto-installed)
- Bash 4.0+

### Network Requirements

| Option | Port 80 | Port 443 | Port 81 |
|--------|---------|---------|---------|
| Tunnel + NPM | ❌ | ❌ | ✅ |
| Tunnel + Direct | ❌ | ❌ | ❌ |
| Direct | ✅ | ✅ | ❌ |

---

## Installation Options

### Option 1: Cloudflare Tunnel + Nginx Proxy Manager ⭐ (Recommended)

**Best for:** Users without static IP, those who can't open ports, need GUI management

**Advantages:**
- No port forwarding required
- GUI-based proxy management
- Automatic SSL certificates
- Cloudflare DDoS protection
- Wildcard domain support

**Installation time:** 15-20 minutes

### Option 2: Cloudflare Tunnel + Direct Nginx

**Best for:** Simple setup, minimal resources

**Advantages:**
- No port forwarding required
- Minimal resource usage
- Cloudflare protection

**Installation time:** 10-15 minutes

### Option 3: Direct Port Forwarding

**Best for:** Advanced users with static IP

**Advantages:**
- Direct control
- No Cloudflare dependency
- Simple architecture

**Installation time:** 20-30 minutes

---

## Quick Start

### 1. Download Installer

```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v4.sh
chmod +x install_v4.sh
```

### 2. Run Installer

```bash
sudo bash install_v4.sh
```

### 3. Follow Prompts

The installer will guide you through:
- System checks
- Installation type selection
- Configuration input
- Cloudflare setup (if applicable)
- Deployment

### 4. Access Your Site

After installation, you'll receive:
- Main site URL: `https://your-domain.com`
- Admin panel: `https://your-domain.com/admin`
- NPM panel (if applicable): `http://localhost:81`

---

## Detailed Installation

### Step 1: Connect to Server

```bash
ssh root@your-server-ip
```

### Step 2: Download and Run Installer

```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v4.sh
sudo bash install_v4.sh
```

### Step 3: Select Installation Type

```
Choose an option:
1. Fresh Installation (Recommended)
2. Smart Migration
3. Update System
4. Health Check
5. Exit
```

Select **1** for fresh installation.

### Step 4: Choose Deployment Option

```
Select Installation Type:
1. Cloudflare Tunnel + Nginx Proxy Manager (Recommended)
2. Cloudflare Tunnel + Direct Nginx
3. Direct Port Forwarding
```

Select **1** for recommended option.

### Step 5: Configure Environment

Provide the following information:

**Domain Name:**
```
Enter your domain name (e.g., habernexus.com):
```

**Admin Email:**
```
Enter admin email:
```

**Admin Username:**
```
Enter admin username: (default: admin)
```

**Admin Password:**
```
Set Admin Password (min 12 chars):
```

Requirements:
- Minimum 12 characters
- At least 1 uppercase letter
- At least 1 number
- At least 1 special character

**Database Password:**
```
Set Database Password (min 12 chars):
```

### Step 6: Cloudflare Tunnel Setup

The installer will show instructions:

1. Go to https://one.dash.cloudflare.com
2. Navigate to Networks > Tunnels
3. Click "Create a Tunnel" → Select "Cloudflared"
4. Name it (e.g., "habernexus")
5. Copy the token from "Install and run a connector" section
6. Paste it in the installer

### Step 7: Cloudflare API Token Setup

The installer will show instructions:

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use "Edit zone DNS" template
4. Select your domain under Zone Resources
5. Create and copy the token
6. Paste it in the installer

### Step 8: NPM Database Selection

```
Select database type:
1. SQLite (Simple, Recommended)
2. PostgreSQL (Advanced)
```

Select **1** for SQLite (recommended for most users).

### Step 9: Wait for Deployment

The installer will:
- Download Docker images
- Start containers
- Run database migrations
- Create admin user
- Run health checks

**Estimated time:** 10-15 minutes

### Step 10: Installation Complete

You'll receive a summary with:
- Installation status
- Access URLs
- Admin credentials
- Next steps

---

## Cloudflare Setup

### DNS Configuration

In Cloudflare Dashboard, add these CNAME records:

**Main Domain:**
```
Type: CNAME
Name: habernexus.com
Target: <tunnel-id>.cfargotunnel.com
Proxied: Yes (Orange cloud)
```

**Wildcard (for subdomains):**
```
Type: CNAME
Name: *.habernexus.com
Target: <tunnel-id>.cfargotunnel.com
Proxied: Yes (Orange cloud)
```

### Public Hostname Configuration

In Cloudflare Dashboard:

1. Go to Networks > Tunnels
2. Select your tunnel
3. Go to Public Hostnames tab
4. Add public hostname:

```
Subdomain: (leave empty)
Domain: habernexus.com
Path: (leave empty)
Service Type: HTTP
URL: http://nginx_proxy_manager:81
```

---

## Nginx Proxy Manager Setup

### Access Admin Panel

1. Open browser: `http://your-server-ip:81`
2. Default login:
   - **Email:** `admin@example.com`
   - **Password:** `changeme`

### Change Admin Password

1. Click profile icon (top right)
2. Click "Settings"
3. Click "Change Password"
4. Enter new password and save

### Create Proxy Host

1. Click "Proxy Hosts" tab
2. Click "Add Proxy Host"
3. Configure:

```
Domain Names: habernexus.com, www.habernexus.com
Scheme: http
Forward Hostname/IP: app
Forward Port: 8000
Block Common Exploits: ON
Websockets Support: ON
```

4. Go to "SSL" tab
5. Select "Request a new SSL Certificate"
6. Enable "Use a DNS Challenge"
7. Select "Cloudflare" as DNS Provider
8. Enter Cloudflare API Token
9. Click "Save"

---

## Local Development

### Prerequisites

- Python 3.11+
- PostgreSQL 16+ (optional, can use SQLite)
- Redis (optional, for Celery)

### Setup

```bash
# 1. Clone repository
git clone https://github.com/sata2500/habernexus.git
cd habernexus

# 2. Create virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Create .env file
cp .env.example .env

# 5. Edit .env for development
nano .env
```

**Development .env:**
```
DEBUG=True
DJANGO_SECRET_KEY=dev-secret-key-change-in-production
ALLOWED_HOSTS=localhost,127.0.0.1
DB_ENGINE=django.db.backends.sqlite3
DB_NAME=db.sqlite3
```

### Run Development Server

```bash
# 1. Run migrations
python manage.py migrate

# 2. Create superuser
python manage.py createsuperuser

# 3. Start development server
python manage.py runserver
```

**Access:** http://localhost:8000

### Run with Docker

```bash
# 1. Build images
docker compose build

# 2. Start services
docker compose up -d

# 3. Run migrations
docker compose exec app python manage.py migrate

# 4. Create superuser
docker compose exec app python manage.py createsuperuser

# 5. Access
# Main: http://localhost:8000
# Admin: http://localhost:8000/admin
```

---

## Post-Installation

### 1. Configure HaberNexus Settings

1. Go to `https://your-domain.com/admin`
2. Login with admin credentials
3. Configure:
   - Site title
   - Site description
   - Logo and favicon
   - Google Gemini API key
   - RSS feed sources

### 2. Add RSS Feeds

1. Go to Admin Panel
2. Click "RSS Feeds"
3. Click "Add Feed"
4. Enter feed URL
5. Click "Save"

### 3. Start Content Generation

1. Go to Admin Panel
2. Click "Content Generation"
3. Click "Start Generation"
4. System will automatically create news

### 4. Setup Monitoring

1. Access Grafana: `https://your-domain.com:3000`
2. Default login:
   - **Username:** `admin`
   - **Password:** `admin`
3. Configure dashboards

### 5. Setup Backups

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /opt/habernexus/scripts/backup.sh
```

---

## Troubleshooting

### Installation Issues

#### Docker not found
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
```

#### Port already in use
```bash
# Check which process is using the port
sudo lsof -i :80
sudo lsof -i :443
sudo lsof -i :81

# Stop the process
sudo kill -9 <PID>
```

#### Insufficient disk space
```bash
# Check disk space
df -h

# Clean Docker
docker system prune -a
```

### Runtime Issues

#### Containers not starting
```bash
# Check container status
docker compose ps

# View logs
docker compose logs app

# Restart containers
docker compose restart
```

#### Database connection error
```bash
# Check database container
docker compose logs postgres

# Reset database
docker compose down -v
docker compose up -d
```

#### SSL certificate error
```bash
# In NPM Dashboard:
# 1. Go to SSL Certificates
# 2. Delete the certificate
# 3. Create new certificate with DNS Challenge
```

#### Cloudflare Tunnel disconnected
```bash
# Check tunnel container
docker logs habernexus_cloudflared

# Restart tunnel
docker restart habernexus_cloudflared

# Verify token
echo $CLOUDFLARE_TUNNEL_TOKEN
```

### Common Solutions

| Problem | Solution |
|---------|----------|
| Connection refused | Check container status, restart containers |
| DNS not resolving | Check Cloudflare DNS records, wait for propagation |
| SSL certificate error | Regenerate certificate with DNS Challenge |
| Database error | Check database container, reset if needed |
| Admin panel inaccessible | Check NPM container, verify port 81 |

---

## Useful Commands

### Container Management
```bash
# List containers
docker compose ps

# Start containers
docker compose up -d

# Stop containers
docker compose down

# Restart containers
docker compose restart

# View logs
docker compose logs -f app
```

### Database Management
```bash
# Connect to database
docker compose exec postgres psql -U habernexus_user -d habernexus

# Backup database
docker compose exec postgres pg_dump -U habernexus_user habernexus > backup.sql

# Restore database
cat backup.sql | docker compose exec -T postgres psql -U habernexus_user -d habernexus
```

### Django Management
```bash
# Run migrations
docker compose exec app python manage.py migrate

# Collect static files
docker compose exec app python manage.py collectstatic --noinput

# Open Django shell
docker compose exec app python manage.py shell

# Create superuser
docker compose exec app python manage.py createsuperuser
```

---

## Support

- **GitHub Issues:** https://github.com/sata2500/habernexus/issues
- **Email:** salihtanriseven25@gmail.com
- **Documentation:** https://github.com/sata2500/habernexus/tree/main/docs

---

**Last Updated:** December 14, 2024  
**Version:** 4.0
