# Haber Nexus - Quick Start Guide

## 🚀 Quick Start (5 minutes)

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

Visit: http://localhost:8000

### For Production (Docker)

```bash
# 1. SSH into VM
ssh ubuntu@your.vm.ip

# 2. Initialize VM (first time only)
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/scripts/init-vm.sh -o init-vm.sh
sudo bash init-vm.sh

# 3. Configure environment
sudo nano /opt/habernexus/.env

# 4. Start application
sudo systemctl start habernexus

# 5. Check status
sudo systemctl status habernexus
```

Visit: https://habernexus.com

---

## 📋 Common Tasks

### Development

```bash
# Run tests
python manage.py test news

# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic

# Access Django shell
python manage.py shell
```

### Production

```bash
# View logs
sudo docker-compose -f docker-compose.prod.yml logs -f

# Restart services
sudo docker-compose -f docker-compose.prod.yml restart

# Create backup
sudo ./scripts/backup.sh

# Restore from backup
sudo ./scripts/restore.sh .backup/backup_name

# SSH into container
sudo docker-compose -f docker-compose.prod.yml exec web bash
```

### Deployment

```bash
# Push to main branch (auto-deploys)
git push origin main

# Manual deployment
cd /opt/habernexus
git pull origin main
sudo docker-compose -f docker-compose.prod.yml build
sudo docker-compose -f docker-compose.prod.yml up -d
```

---

## 🔗 Important Links

- **Admin Panel:** https://habernexus.com/admin/
- **GitHub:** https://github.com/sata2500/habernexus
- **Documentation:** See PRODUCTION_DEPLOYMENT_GUIDE.md

---

## ⚠️ Troubleshooting

**Application not responding?**
```bash
sudo systemctl restart habernexus
sudo docker-compose -f docker-compose.prod.yml logs web
```

**Database issues?**
```bash
sudo docker-compose -f docker-compose.prod.yml logs postgres
```

**Celery tasks not running?**
```bash
sudo docker-compose -f docker-compose.prod.yml logs celery_worker
```

---

For detailed documentation, see:
- `PRODUCTION_DEPLOYMENT_GUIDE.md` - Full deployment guide
- `CONTENT_SYSTEM_IMPROVEMENT_REPORT.md` - Content generation system
- `README.md` - Project overview
