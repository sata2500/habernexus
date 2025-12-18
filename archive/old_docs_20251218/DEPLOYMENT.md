# Haber Nexus - Production Deployment Guide

**Version:** 1.0  
**Date:** December 6, 2025  
**Author:** Manus AI  
**Domain:** habernexus.com  
**VM:** Google Cloud Platform (Ubuntu 24.04 LTS)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Initial VM Setup](#initial-vm-setup)
4. [Docker Deployment](#docker-deployment)
5. [SSL/TLS Configuration](#ssltls-configuration)
6. [GitHub Actions CI/CD](#github-actions-cicd)
7. [Backup and Restore](#backup-and-restore)
8. [VM Migration](#vm-migration)
9. [Monitoring and Maintenance](#monitoring-and-maintenance)
10. [Troubleshooting](#troubleshooting)

---

## Overview

Haber Nexus is now deployed as a containerized application using Docker and Docker Compose. This setup provides:

- **Full containerization** of all services (Django, Celery, PostgreSQL, Redis, Nginx)
- **Automated CI/CD pipeline** via GitHub Actions
- **Zero-downtime deployments** with health checks
- **Easy backup and restore** functionality
- **Simple VM migration** capabilities
- **Production-grade security** with SSL/TLS, rate limiting, and security headers

### System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Google Cloud VM                       │
│              (Ubuntu 24.04 LTS, 4 CPU, 16GB RAM)        │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │              Docker Network Bridge                  │ │
│  │                                                     │ │
│  │  ┌──────────────┐  ┌──────────────┐              │ │
│  │  │   Nginx      │  │  PostgreSQL  │              │ │
│  │  │  (Port 80,   │  │  (Port 5432) │              │ │
│  │  │   443)       │  │              │              │ │
│  │  └──────────────┘  └──────────────┘              │ │
│  │         │                                         │ │
│  │         ▼                                         │ │
│  │  ┌──────────────┐  ┌──────────────┐              │ │
│  │  │   Django     │  │    Redis     │              │ │
│  │  │  (Port 8000) │  │ (Port 6379)  │              │ │
│  │  └──────────────┘  └──────────────┘              │ │
│  │         ▲                                         │ │
│  │         │                                         │ │
│  │  ┌──────────────┐  ┌──────────────┐              │ │
│  │  │   Celery     │  │  Celery      │              │ │
│  │  │   Worker     │  │   Beat       │              │ │
│  │  └──────────────┘  └──────────────┘              │ │
│  │                                                     │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
└─────────────────────────────────────────────────────────┘
                           ▲
                           │ HTTPS (habernexus.com)
                           │
                    Internet Users
```

---

## Initial VM Setup

### Prerequisites

- Google Cloud VM with Ubuntu 24.04 LTS
- SSH access to the VM
- Domain name (habernexus.com) pointing to VM's IP
- GitHub Personal Access Token (PAT)

### Step 1: Connect to VM via SSH

```bash
ssh -i ~/.ssh/google_cloud_key ubuntu@34.185.172.35
```

### Step 2: Run Initialization Script

The initialization script will install Docker, Docker Compose, and all necessary dependencies:

```bash
# Download and run the initialization script
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/scripts/init-vm.sh -o init-vm.sh
sudo bash init-vm.sh
```

This script will:
- Update system packages
- Install Docker and Docker Compose
- Install Certbot for SSL certificates
- Clone the repository
- Create systemd service
- Set up automated backups
- Configure log rotation
- Set up health monitoring

### Step 3: Configure Environment Variables

Edit the `.env` file with your specific settings:

```bash
sudo nano /opt/habernexus/.env
```

Key variables to configure:

```ini
# Django Settings
DEBUG=False
DJANGO_SECRET_KEY=your_secure_key_here
ALLOWED_HOSTS=habernexus.com,www.habernexus.com,34.185.172.35

# Database
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=your_secure_password

# Redis
REDIS_PASSWORD=your_secure_password

# Google Gemini API
GOOGLE_GEMINI_API_KEY=your_gemini_api_key
```

---

## Docker Deployment

### Starting the Application

```bash
cd /opt/habernexus

# Using systemd (recommended)
sudo systemctl start habernexus
sudo systemctl status habernexus

# Or manually with Docker Compose
sudo docker-compose -f docker-compose.prod.yml up -d
```

### Checking Container Status

```bash
cd /opt/habernexus
sudo docker-compose -f docker-compose.prod.yml ps
```

Expected output:

```
NAME                    STATUS
habernexus-postgres     Up 2 minutes (healthy)
habernexus-redis        Up 2 minutes (healthy)
habernexus-web          Up 2 minutes (healthy)
habernexus-celery-worker    Up 2 minutes
habernexus-celery-beat  Up 2 minutes
habernexus-nginx        Up 2 minutes
```

### Viewing Logs

```bash
# All containers
sudo docker-compose -f docker-compose.prod.yml logs -f

# Specific service
sudo docker-compose -f docker-compose.prod.yml logs -f web
sudo docker-compose -f docker-compose.prod.yml logs -f celery_worker

# System logs
sudo journalctl -u habernexus -f
```

### Stopping the Application

```bash
sudo systemctl stop habernexus
# or
sudo docker-compose -f docker-compose.prod.yml down
```

---

## SSL/TLS Configuration

### Obtaining SSL Certificate with Let's Encrypt

```bash
# Request certificate
sudo certbot certonly --standalone -d habernexus.com -d www.habernexus.com

# Copy certificates to nginx directory
sudo cp /etc/letsencrypt/live/habernexus.com/fullchain.pem /opt/habernexus/nginx/ssl/
sudo cp /etc/letsencrypt/live/habernexus.com/privkey.pem /opt/habernexus/nginx/ssl/
sudo chown -R 1000:1000 /opt/habernexus/nginx/ssl/

# Reload Nginx
sudo docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload
```

### Auto-Renewal Setup

```bash
# Test renewal process
sudo certbot renew --dry-run

# Certbot automatically sets up renewal via systemd timer
sudo systemctl status certbot.timer
```

---

## GitHub Actions CI/CD

### Setting Up Automatic Deployment

1. **Add GitHub Secrets** to your repository:

   Go to: Settings → Secrets and variables → Actions

   Add the following secrets:

   ```
   VM_HOST: 34.185.172.35
   VM_USER: ubuntu
   VM_SSH_KEY: (your private SSH key)
   ```

2. **How it Works:**

   - Every push to `main` branch triggers the deploy workflow
   - GitHub Actions connects to your VM via SSH
   - Pulls latest code from GitHub
   - Rebuilds Docker images
   - Restarts containers
   - Runs migrations
   - Performs health checks

3. **Monitoring Deployments:**

   - Go to GitHub repository → Actions tab
   - View deployment progress in real-time
   - Check logs if deployment fails

---

## Backup and Restore

### Automatic Backups

Backups run automatically every day at 2 AM (configured in cron):

```bash
# View backup cron job
sudo cat /etc/cron.d/habernexus-backup

# View backup logs
sudo tail -f /var/log/habernexus-backup.log
```

### Manual Backup

```bash
cd /opt/habernexus
sudo ./scripts/backup.sh
```

Backup includes:
- PostgreSQL database dump (compressed)
- Redis data snapshot
- Media files
- Environment configuration

Backups are stored in `.backup/` directory.

### Restore from Backup

```bash
cd /opt/habernexus

# List available backups
ls -la .backup/

# Restore from specific backup
sudo ./scripts/restore.sh .backup/habernexus_backup_20231206_120000
```

The restore script will:
1. Stop running containers
2. Restore PostgreSQL database
3. Restore Redis data
4. Restore media files
5. Restore environment configuration
6. Start all containers
7. Run migrations
8. Perform health checks

---

## VM Migration

### Migrate to a New VM

This is the easiest way to move the entire application to a new VM:

```bash
cd /opt/habernexus

# Create backup first
sudo ./scripts/backup.sh

# Migrate to new VM
sudo ./scripts/migrate-vm.sh .backup/habernexus_backup_20231206_120000 ubuntu@new.vm.ip
```

The migration script will:
1. Prepare backup archive
2. Test SSH connection to new VM
3. Install Docker and Docker Compose on new VM
4. Transfer backup to new VM
5. Clone repository on new VM
6. Extract and restore backup
7. Verify deployment

### Post-Migration Steps

1. **Update DNS records** to point to new VM IP
2. **Configure SSL certificates** on new VM
3. **Test the application** at https://habernexus.com
4. **Update GitHub Actions secrets** if needed
5. **Decommission old VM** (after verification)

---

## Monitoring and Maintenance

### Health Checks

```bash
# Manual health check
/usr/local/bin/habernexus-health-check

# View health check logs
sudo tail -f /var/log/habernexus-health.log
```

### Database Maintenance

```bash
# Connect to PostgreSQL
sudo docker-compose -f docker-compose.prod.yml exec postgres psql -U habernexus_user -d habernexus

# Common commands
\dt                    # List tables
\du                    # List users
SELECT COUNT(*) FROM news_article;  # Count articles
```

### Redis Monitoring

```bash
# Connect to Redis
sudo docker-compose -f docker-compose.prod.yml exec redis redis-cli -a your_redis_password

# Common commands
PING                   # Test connection
INFO                   # Server info
KEYS *                 # List all keys
FLUSHDB                # Clear database (be careful!)
```

### System Resources

```bash
# Check disk usage
df -h

# Check memory usage
free -h

# Check Docker disk usage
docker system df

# Clean up unused Docker resources
docker system prune -a
```

---

## Troubleshooting

### Application Not Responding

```bash
# Check container status
sudo docker-compose -f docker-compose.prod.yml ps

# Check logs
sudo docker-compose -f docker-compose.prod.yml logs web

# Restart containers
sudo docker-compose -f docker-compose.prod.yml restart web

# Full restart
sudo systemctl restart habernexus
```

### Database Connection Issues

```bash
# Check PostgreSQL container
sudo docker-compose -f docker-compose.prod.yml logs postgres

# Test database connection
sudo docker-compose -f docker-compose.prod.yml exec web python manage.py dbshell

# Check database size
sudo docker-compose -f docker-compose.prod.yml exec postgres psql -U habernexus_user -d habernexus -c "SELECT pg_size_pretty(pg_database_size('habernexus'));"
```

### Celery Tasks Not Running

```bash
# Check Celery worker logs
sudo docker-compose -f docker-compose.prod.yml logs celery_worker

# Check Celery Beat logs
sudo docker-compose -f docker-compose.prod.yml logs celery_beat

# Restart Celery services
sudo docker-compose -f docker-compose.prod.yml restart celery_worker celery_beat
```

### Nginx Issues

```bash
# Check Nginx logs
sudo tail -f /opt/habernexus/nginx/logs/error.log
sudo tail -f /opt/habernexus/nginx/logs/access.log

# Test Nginx configuration
sudo docker-compose -f docker-compose.prod.yml exec nginx nginx -t

# Reload Nginx
sudo docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload
```

### SSL Certificate Issues

```bash
# Check certificate validity
sudo certbot certificates

# Renew certificate manually
sudo certbot renew --force-renewal

# Check certificate expiration
echo | openssl s_client -servername habernexus.com -connect habernexus.com:443 2>/dev/null | openssl x509 -noout -dates
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean up old backups
sudo find /opt/habernexus/.backup -name "*.tar.gz" -mtime +7 -delete

# Clean Docker system
sudo docker system prune -a --volumes
```

---

## Useful Commands Reference

| Command | Purpose |
|---------|---------|
| `sudo systemctl start habernexus` | Start application |
| `sudo systemctl stop habernexus` | Stop application |
| `sudo systemctl restart habernexus` | Restart application |
| `sudo systemctl status habernexus` | Check status |
| `sudo docker-compose -f docker-compose.prod.yml ps` | List containers |
| `sudo docker-compose -f docker-compose.prod.yml logs -f` | View logs |
| `sudo docker-compose -f docker-compose.prod.yml exec web bash` | Shell into web container |
| `./scripts/backup.sh` | Create backup |
| `./scripts/restore.sh .backup/backup_name` | Restore from backup |
| `./scripts/migrate-vm.sh .backup/backup_name user@host` | Migrate to new VM |
| `/usr/local/bin/habernexus-health-check` | Check application health |

---

## Support and Documentation

- **GitHub Repository:** https://github.com/sata2500/habernexus
- **Issues:** https://github.com/sata2500/habernexus/issues
- **Documentation:** See README.md and other docs in repository

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-06 | Initial production deployment guide |

---

**Last Updated:** December 6, 2025
