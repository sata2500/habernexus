# Haber Nexus - Installation Guide

**Version:** 2.0  
**Last Updated:** December 11, 2025  
**Author:** Salih TANRISEVEN

---

## Table of Contents

1. [Quick Start (5 Minutes)](#quick-start-5-minutes)
2. [Local Development Setup](#local-development-setup)
3. [Docker Setup (Recommended)](#docker-setup-recommended)
4. [Production Deployment](#production-deployment)
5. [Troubleshooting](#troubleshooting)
6. [Post-Installation Checklist](#post-installation-checklist)

---

## Quick Start (5 Minutes)

### For Local Development

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

# 5. Run migrations
python manage.py migrate

# 6. Create superuser
python manage.py createsuperuser

# 7. Start development server
python manage.py runserver
```

**Access:** http://localhost:8000

### For Docker (Recommended)

```bash
# 1. Clone repository
git clone https://github.com/sata2500/habernexus.git
cd habernexus

# 2. Configure environment
cp .env.example .env
nano .env  # Edit with your settings

# 3. Start with Docker Compose
docker-compose up -d --build

# 4. Create superuser
docker-compose exec app python manage.py createsuperuser

# 5. Access application
# Web: http://localhost
# Admin: http://localhost/admin
```

---

## Local Development Setup

### Prerequisites

- Python 3.11+
- PostgreSQL 14+ (or use Docker)
- Redis 6+ (or use Docker)
- Git
- Virtual environment support

### Step 1: Clone Repository

```bash
git clone https://github.com/sata2500/habernexus.git
cd habernexus
```

### Step 2: Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### Step 3: Install Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### Step 4: Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```ini
# Django Settings
DEBUG=True
DJANGO_SECRET_KEY=your-development-secret-key
ALLOWED_HOSTS=localhost,127.0.0.1,habernexus.local

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=5432

# Redis
REDIS_URL=redis://localhost:6379/0

# Google Gemini API
GOOGLE_GEMINI_API_KEY=your_api_key_here
```

### Step 5: Database Setup

#### Option A: Using PostgreSQL (Local)

```bash
# Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE habernexus;
CREATE USER habernexus_user WITH PASSWORD 'your_password';
ALTER ROLE habernexus_user SET client_encoding TO 'utf8';
ALTER ROLE habernexus_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE habernexus_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE habernexus TO habernexus_user;
EOF
```

#### Option B: Using SQLite (Development Only)

```ini
# In .env
DB_ENGINE=django.db.backends.sqlite3
DB_NAME=db.sqlite3
```

### Step 6: Run Migrations

```bash
python manage.py migrate
```

### Step 7: Create Superuser

```bash
python manage.py createsuperuser
```

### Step 8: Start Services

**Terminal 1 - Django Development Server:**
```bash
python manage.py runserver
```

**Terminal 2 - Celery Worker:**
```bash
celery -A habernexus_config worker -l info
```

**Terminal 3 - Celery Beat:**
```bash
celery -A habernexus_config beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
```

**Access:**
- Web: http://localhost:8000
- Admin: http://localhost:8000/admin

---

## Docker Setup (Recommended)

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Git

### Step 1: Clone Repository

```bash
git clone https://github.com/sata2500/habernexus.git
cd habernexus
```

### Step 2: Configure Environment

```bash
cp .env.example .env
nano .env
```

Key variables:

```ini
DEBUG=True
DJANGO_SECRET_KEY=your-secret-key
ALLOWED_HOSTS=localhost,127.0.0.1

DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=your_secure_password

REDIS_PASSWORD=your_redis_password

GOOGLE_GEMINI_API_KEY=your_gemini_api_key
```

### Step 3: Build and Start

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# Check status
docker-compose ps
```

### Step 4: Initialize Database

```bash
# Run migrations
docker-compose exec app python manage.py migrate

# Create superuser
docker-compose exec app python manage.py createsuperuser

# Collect static files
docker-compose exec app python manage.py collectstatic --noinput
```

### Step 5: Access Application

- **Web:** http://localhost
- **Admin:** http://localhost/admin
- **API:** http://localhost/api/ (if enabled)

### Useful Docker Commands

```bash
# View logs
docker-compose logs -f app
docker-compose logs -f celery
docker-compose logs -f postgres

# Execute commands
docker-compose exec app python manage.py shell
docker-compose exec postgres psql -U habernexus_user -d habernexus

# Stop services
docker-compose down

# Remove volumes (WARNING: deletes data)
docker-compose down -v
```

---

## Production Deployment

### Prerequisites

- Google Cloud VM (Ubuntu 24.04 LTS) or similar Linux server
- Domain name pointing to server IP
- SSH access to server
- GitHub Personal Access Token (PAT)

### Step 1: SSH into Server

```bash
ssh -i ~/.ssh/your_key ubuntu@your.server.ip
```

### Step 2: Run Initialization Script

```bash
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/scripts/init-vm.sh -o init-vm.sh
sudo bash init-vm.sh
```

This script will:
- Update system packages
- Install Docker and Docker Compose
- Install Certbot for SSL certificates
- Clone the repository
- Create systemd service
- Configure automated backups
- Set up log rotation

### Step 3: Configure Environment

```bash
sudo nano /opt/habernexus/.env
```

Production settings:

```ini
DEBUG=False
DJANGO_SECRET_KEY=your_very_secure_key_here
ALLOWED_HOSTS=habernexus.com,www.habernexus.com,your.server.ip

# Database
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=your_very_secure_password

# Redis
REDIS_PASSWORD=your_very_secure_redis_password

# Google Gemini API
GOOGLE_GEMINI_API_KEY=your_gemini_api_key

# Security
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

### Step 4: Start Application

```bash
# Using systemd (recommended)
sudo systemctl start habernexus
sudo systemctl status habernexus

# Or manually
cd /opt/habernexus
sudo docker-compose -f docker-compose.prod.yml up -d
```

### Step 5: Configure SSL Certificate

```bash
# Request certificate
sudo certbot certonly --standalone -d habernexus.com -d www.habernexus.com

# Copy to nginx directory
sudo cp /etc/letsencrypt/live/habernexus.com/fullchain.pem /opt/habernexus/nginx/ssl/
sudo cp /etc/letsencrypt/live/habernexus.com/privkey.pem /opt/habernexus/nginx/ssl/
sudo chown -R 1000:1000 /opt/habernexus/nginx/ssl/

# Reload nginx
sudo docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload
```

### Step 6: Verify Deployment

```bash
# Check containers
sudo docker-compose -f docker-compose.prod.yml ps

# Check logs
sudo docker-compose -f docker-compose.prod.yml logs -f

# Test application
curl https://habernexus.com
```

---

## Troubleshooting

### Common Issues

#### 1. Database Connection Error

```bash
# Check PostgreSQL container
docker-compose logs postgres

# Verify connection string in .env
# Restart database
docker-compose restart postgres
```

#### 2. Redis Connection Error

```bash
# Check Redis container
docker-compose logs redis

# Test connection
docker-compose exec redis redis-cli ping
```

#### 3. Celery Tasks Not Running

```bash
# Check worker logs
docker-compose logs celery

# Check beat logs
docker-compose logs celery_beat

# Restart services
docker-compose restart celery celery_beat
```

#### 4. Static Files Not Loading

```bash
# Collect static files
docker-compose exec app python manage.py collectstatic --noinput

# Check file permissions
ls -la staticfiles/

# Restart nginx
docker-compose restart nginx
```

#### 5. Port Already in Use

```bash
# Find process using port
lsof -i :8000

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

#### 6. Out of Memory

```bash
# Check memory usage
free -h

# Clean Docker system
docker system prune -a

# Remove old backups
find /opt/habernexus/.backup -name "*.tar.gz" -mtime +7 -delete
```

### Debug Mode

Enable debug logging:

```bash
# In .env
DEBUG=True
LOGGING_LEVEL=DEBUG

# View detailed logs
docker-compose logs -f --tail=100
```

### Database Issues

```bash
# Connect to database
docker-compose exec postgres psql -U habernexus_user -d habernexus

# Check tables
\dt

# Check database size
SELECT pg_size_pretty(pg_database_size('habernexus'));

# Reset database (WARNING: deletes all data)
docker-compose exec postgres dropdb -U habernexus_user habernexus
docker-compose exec postgres createdb -U habernexus_user habernexus
docker-compose exec app python manage.py migrate
```

---

## Post-Installation Checklist

### Verification Steps

- [ ] Web application accessible at configured URL
- [ ] Admin panel accessible and login works
- [ ] Database migrations completed successfully
- [ ] Celery worker running and processing tasks
- [ ] Celery Beat scheduler running
- [ ] Redis cache working
- [ ] Static files loaded correctly
- [ ] Email configuration working (if configured)
- [ ] Google Gemini API key valid
- [ ] SSL certificate installed (production)

### Security Checks

- [ ] DEBUG=False in production
- [ ] DJANGO_SECRET_KEY changed from example
- [ ] Database password is strong
- [ ] Redis password is strong
- [ ] SSH key-based authentication enabled
- [ ] Firewall configured (only ports 80, 443 open)
- [ ] Regular backups scheduled
- [ ] SSL certificate auto-renewal configured

### Performance Checks

- [ ] Application response time acceptable
- [ ] Database queries optimized
- [ ] Static files cached properly
- [ ] Celery tasks completing successfully
- [ ] Memory usage within limits
- [ ] Disk space available

### Monitoring Setup

- [ ] Log files configured
- [ ] Error notifications enabled
- [ ] Health checks running
- [ ] Backup verification working
- [ ] Monitoring dashboard accessible

---

## Next Steps

1. **Configure RSS Sources:** Add RSS feeds in admin panel
2. **Configure Authors:** Create author profiles
3. **Set Up Celery Tasks:** Configure RSS fetching schedule
4. **Test Content Generation:** Verify AI content generation works
5. **Monitor Logs:** Check application logs regularly
6. **Plan Backups:** Set up automated backup schedule

---

## Support

For issues or questions:

- **Email:** salihtanriseven25@gmail.com
- **GitHub Issues:** https://github.com/sata2500/habernexus/issues
- **Documentation:** See `docs/` folder

---

## Additional Resources

- [Architecture Documentation](ARCHITECTURE.md)
- [Development Guide](DEVELOPMENT.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Production Deployment](../PRODUCTION_DEPLOYMENT_GUIDE.md)
- [Configuration Guide](CONFIGURATION.md)
