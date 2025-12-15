# HaberNexus v7.0 Installation Guide

**Version:** 7.0  
**Last Updated:** December 15, 2025  
**Author:** Salih TANRISEVEN

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Quick Start](#quick-start)
3. [Installation Modes](#installation-modes)
4. [Step-by-Step Installation](#step-by-step-installation)
5. [Post-Installation](#post-installation)
6. [Troubleshooting](#troubleshooting)
7. [Management Commands](#management-commands)

---

## System Requirements

### Minimum Requirements
- **OS:** Ubuntu 20.04 LTS, 22.04 LTS, or 24.04 LTS
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
- Port 80 (HTTP)
- Port 443 (HTTPS)
- Port 5432 (PostgreSQL - internal)
- Port 6379 (Redis - internal)
- Port 8000 (Django - internal)

---

## Quick Start

### 1. Pre-Installation Check

```bash
# Verify system compatibility
sudo bash pre_install_check.sh
```

This will check:
- Root privileges
- Operating system
- CPU cores
- RAM memory
- Disk space
- Internet connectivity
- Required commands
- Docker installation
- Port availability

### 2. Clone Repository

```bash
git clone https://github.com/sata2500/habernexus.git
cd habernexus
```

### 3. Run Installation

```bash
# Quick setup (recommended)
sudo bash install_v7.sh --quick

# OR custom configuration
sudo bash install_v7.sh --custom

# OR development mode
sudo bash install_v7.sh --dev
```

### 4. Verify Installation

```bash
# Check service status
bash manage_habernexus.sh status

# Check system health
bash manage_habernexus.sh health
```

**Installation time:** ~5-10 minutes

---

## Installation Modes

### Quick Mode (--quick)

**Recommended for:** Production environments, standard setup

**Characteristics:**
- Uses default values
- Minimum user interaction
- Fully automated
- Estimated time: 5-10 minutes

**Default Values:**
- Domain: `habernexus.local`
- Admin username: `admin`
- Database password: Auto-generated
- Cloudflare tokens: Demo tokens

**Usage:**
```bash
sudo bash install_v7.sh --quick
```

### Custom Mode (--custom)

**Recommended for:** Custom configurations, specific requirements

**Characteristics:**
- Interactive prompts
- Full control over settings
- Validation for each input
- Estimated time: 10-15 minutes

**Prompts:**
1. Domain name
2. Admin email
3. Admin username
4. Admin password
5. Cloudflare API Token
6. Cloudflare Tunnel Token

**Usage:**
```bash
sudo bash install_v7.sh --custom
```

### Development Mode (--dev)

**Recommended for:** Development and testing

**Characteristics:**
- Debug mode enabled
- Default values used
- Detailed logging
- Estimated time: 10-15 minutes

**Usage:**
```bash
sudo bash install_v7.sh --dev
```

---

## Step-by-Step Installation

### Step 1: System Preparation

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Clone repository
git clone https://github.com/sata2500/habernexus.git
cd habernexus
```

### Step 2: Pre-Installation Check

```bash
# Verify system compatibility
sudo bash pre_install_check.sh

# If all checks pass, continue to Step 3
# If any checks fail, fix the issues and retry
```

### Step 3: Run Installation

```bash
# Quick installation (recommended)
sudo bash install_v7.sh --quick

# Watch the installation progress
# The script will:
# - Check system requirements
# - Install dependencies
# - Install Docker (if needed)
# - Clone/update repository
# - Create environment configuration
# - Build Docker images
# - Start services
# - Run database migrations
# - Create admin user
# - Verify installation
```

### Step 4: Verify Installation

```bash
# Check service status
bash manage_habernexus.sh status

# Check system health
bash manage_habernexus.sh health

# View logs
bash manage_habernexus.sh logs app
```

### Step 5: Access Application

```
Main Site:   https://habernexus.local
Admin Panel: https://habernexus.local/admin
API:         https://habernexus.local/api

Admin Credentials:
  Username: admin
  Password: (as entered during installation)
```

---

## Post-Installation

### 1. Change Admin Password

```bash
# Change admin password
bash manage_habernexus.sh change-password admin new_password
```

### 2. Create Additional Admin Users

```bash
# Create new admin user
bash manage_habernexus.sh create-user newadmin admin@example.com password
```

### 3. Configure RSS Feeds

1. Login to admin panel
2. Go to "Content Sources"
3. Add RSS feed URLs
4. Configure update frequency
5. Start content generation

### 4. Set Up Backups

```bash
# Create full backup
bash manage_habernexus.sh full-backup

# Schedule automatic daily backups
crontab -e

# Add this line for daily backup at 2 AM
0 2 * * * bash /opt/habernexus/manage_habernexus.sh full-backup
```

### 5. Configure Domain

If using a custom domain:

1. Update DNS records to point to your server
2. Update DOMAIN in .env file
3. Restart services: `bash manage_habernexus.sh restart`

### 6. Security Hardening

```bash
# Setup firewall
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Check SSL certificate
curl -I https://your-domain.com

# View security headers
curl -I https://your-domain.com | grep -i "strict\|x-frame\|x-content"
```

---

## Troubleshooting

### Pre-Installation Issues

#### System Not Compatible

```bash
# Run pre-installation check
sudo bash pre_install_check.sh

# Fix issues based on report
# Common fixes:
# - Install Docker: curl -fsSL https://get.docker.com | sh
# - Free disk space: rm -rf /tmp/*
# - Enable ports: sudo ufw allow 80/tcp
```

#### Insufficient Disk Space

```bash
# Check disk usage
df -h

# Free up space
sudo apt-get clean
sudo apt-get autoclean
docker system prune -f
```

#### Docker Not Running

```bash
# Start Docker
sudo systemctl start docker

# Enable Docker on boot
sudo systemctl enable docker

# Verify Docker
docker ps
```

### Installation Issues

#### Installation Fails

```bash
# Check installation log
tail -f /var/log/habernexus/install_v7_*.log

# Run with debug mode
sudo bash install_v7.sh --custom

# Check Docker logs
docker-compose logs
```

#### Services Not Starting

```bash
# Check service status
bash manage_habernexus.sh status

# View logs
bash manage_habernexus.sh logs app

# Restart services
bash manage_habernexus.sh restart

# Check Docker
docker ps
docker-compose ps
```

### Runtime Issues

#### Database Connection Error

```bash
# Check PostgreSQL
bash manage_habernexus.sh logs postgres

# Verify database is running
docker-compose ps postgres

# Check database connectivity
docker-compose exec postgres pg_isready -U habernexus

# Restart database
bash manage_habernexus.sh restart postgres

# Run migrations
bash manage_habernexus.sh migrate
```

#### Redis Connection Error

```bash
# Check Redis
bash manage_habernexus.sh logs redis

# Verify Redis is running
docker-compose ps redis

# Check Redis connectivity
docker-compose exec redis redis-cli ping

# Restart Redis
bash manage_habernexus.sh restart redis
```

#### Application Not Responding

```bash
# Check application logs
bash manage_habernexus.sh logs app

# Check application health
bash manage_habernexus.sh health

# Restart application
bash manage_habernexus.sh restart app

# Check disk space
df -h

# Check memory
free -h
```

#### SSL Certificate Issues

```bash
# Check Caddy logs
bash manage_habernexus.sh logs caddy

# Verify domain DNS
nslookup your-domain.com

# Check certificate
curl -I https://your-domain.com

# Restart Caddy
bash manage_habernexus.sh restart caddy
```

#### Cloudflare Tunnel Not Connecting

```bash
# Check tunnel logs
bash manage_habernexus.sh logs cloudflared

# Verify tunnel token
echo $CLOUDFLARE_TUNNEL_TOKEN

# Restart tunnel
bash manage_habernexus.sh restart cloudflared

# Check tunnel status
cloudflared tunnel list
```

### Diagnostic Tools

#### Run Full System Diagnostics

```bash
# Run troubleshooting diagnostics
bash manage_habernexus.sh troubleshoot

# This will check:
# - System information
# - Docker status
# - Container health
# - Recent errors
# - Disk usage
# - Memory usage
# - Docker system info
```

#### View Logs

```bash
# View application logs
bash manage_habernexus.sh logs app

# View database logs
bash manage_habernexus.sh logs postgres

# View Redis logs
bash manage_habernexus.sh logs redis

# View Caddy logs
bash manage_habernexus.sh logs caddy

# View Cloudflare Tunnel logs
bash manage_habernexus.sh logs cloudflared

# View all logs
docker-compose logs
```

---

## Management Commands

### Status & Monitoring

```bash
# View service status
bash manage_habernexus.sh status

# View logs
bash manage_habernexus.sh logs [SERVICE]

# Check system health
bash manage_habernexus.sh health

# Run diagnostics
bash manage_habernexus.sh troubleshoot
```

### Service Management

```bash
# Start all services
bash manage_habernexus.sh start

# Stop all services
bash manage_habernexus.sh stop

# Restart all services
bash manage_habernexus.sh restart

# Restart specific service
bash manage_habernexus.sh restart [SERVICE]
```

### Database Management

```bash
# Backup database
bash manage_habernexus.sh backup-db

# Restore database
bash manage_habernexus.sh restore-db /path/to/backup.sql

# Run migrations
bash manage_habernexus.sh migrate
```

### User Management

```bash
# Create admin user
bash manage_habernexus.sh create-user admin admin@example.com password

# Change password
bash manage_habernexus.sh change-password admin new_password

# List all users
bash manage_habernexus.sh list-users
```

### Maintenance

```bash
# Clean up old logs
bash manage_habernexus.sh cleanup-logs

# Clean Docker resources
bash manage_habernexus.sh cleanup-docker

# Update project
bash manage_habernexus.sh update
```

### Backup & Restore

```bash
# Create full backup
bash manage_habernexus.sh full-backup

# List available backups
bash manage_habernexus.sh list-backups
```

---

## File Locations

| File/Directory | Location |
|---|---|
| Installation Log | `/var/log/habernexus/install_v7_*.log` |
| Configuration Log | `/var/log/habernexus/installation_config_*.conf` |
| Environment File | `/opt/habernexus/.env` |
| Backups | `/opt/habernexus/.backups/` |
| Project Directory | `/opt/habernexus/` |
| Docker Compose | `/opt/habernexus/docker-compose.yml` |
| Caddy Config | `/opt/habernexus/caddy/Caddyfile` |

---

## Useful Commands

### Docker Commands

```bash
# View running containers
docker ps

# View all containers
docker ps -a

# View container logs
docker logs [CONTAINER_ID]

# Execute command in container
docker exec -it [CONTAINER_ID] bash

# View container stats
docker stats
```

### Docker Compose Commands

```bash
# View service status
docker-compose ps

# View logs
docker-compose logs -f [SERVICE]

# Execute command
docker-compose exec [SERVICE] [COMMAND]

# Rebuild images
docker-compose build

# Restart services
docker-compose restart
```

### System Commands

```bash
# Check disk usage
df -h

# Check memory usage
free -h

# Check CPU usage
top

# View network connections
netstat -tuln

# Check open ports
lsof -i -P -n
```

---

## Best Practices

### 1. Regular Backups

```bash
# Create backup before major changes
bash manage_habernexus.sh full-backup

# Schedule automatic backups
0 2 * * * bash /opt/habernexus/manage_habernexus.sh full-backup
```

### 2. Monitor System Health

```bash
# Check health regularly
bash manage_habernexus.sh health

# Schedule health checks
0 */4 * * * bash /opt/habernexus/manage_habernexus.sh health
```

### 3. Keep Logs

```bash
# View recent logs
tail -50 /var/log/habernexus_*.log

# Archive old logs
tar -czf /opt/habernexus/.backups/logs_$(date +%Y%m%d).tar.gz /var/log/habernexus/
```

### 4. Update Regularly

```bash
# Update project
bash manage_habernexus.sh update

# Check for updates
cd /opt/habernexus && git status
```

### 5. Test Restore Procedure

```bash
# Periodically test restore
bash manage_habernexus.sh restore-db /path/to/test_backup.sql
```

---

## Support

- **GitHub Issues:** https://github.com/sata2500/habernexus/issues
- **Email:** salihtanriseven25@gmail.com
- **Documentation:** https://github.com/sata2500/habernexus/tree/main/docs

---

**Last Updated:** December 15, 2025  
**Version:** 7.0
