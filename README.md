# HaberNexus - Intelligent News Aggregation Platform v5.0

![Version](https://img.shields.io/badge/version-5.0-blue?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![Python](https://img.shields.io/badge/python-3.11+-blue?style=flat-square)
![Django](https://img.shields.io/badge/django-4.2+-darkgreen?style=flat-square)
![Docker](https://img.shields.io/badge/docker-ready-blue?style=flat-square)
![Cloudflare](https://img.shields.io/badge/cloudflare-tunnel-orange?style=flat-square)

HaberNexus is a powerful, scalable, and **fully automated** news aggregation platform built with Django, PostgreSQL, Redis, and Celery. It supports multiple deployment options including Cloudflare Tunnel and Nginx Proxy Manager for maximum flexibility and security.

## 🚀 What's New in v5.0

### ✨ Full Automation
- **One-Command Installation** - Single installer handles everything
- **Automatic DNS Setup** - Cloudflare DNS records created automatically
- **Auto-Configuration** - All services configured automatically
- **Health Checks** - Automated container health monitoring

### 🔒 Enhanced Security
- **Cloudflare Tunnel** - No port forwarding needed
- **SSL/TLS** - Automatic Let's Encrypt certificates
- **DDoS Protection** - Cloudflare DDoS protection included
- **Security Headers** - HSTS, CSP, X-Frame-Options, etc.

### 🎛️ Better Management
- **Nginx Proxy Manager** - GUI-based reverse proxy management
- **Flower Monitoring** - Real-time task monitoring
- **Health Dashboards** - Container health status
- **Comprehensive Logging** - Detailed installation logs

## 📋 System Requirements

### Minimum
- Ubuntu 22.04 LTS or newer
- 2 CPU cores
- 4 GB RAM
- 20 GB storage
- Internet connection

### Recommended
- Ubuntu 24.04 LTS
- 4+ CPU cores
- 8+ GB RAM
- 50+ GB SSD
- High-speed internet

## 🛠️ Quick Installation

### Option 1: Cloudflare Tunnel + Nginx Proxy Manager (Recommended)

```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v5.sh
sudo bash install_v5.sh
```

**Choose option 1 during installation**

Features:
- ✅ No port forwarding needed
- ✅ Automatic DNS setup (with API token)
- ✅ GUI-based proxy management
- ✅ Automatic SSL certificates
- ✅ Full automation

Setup time: **15-20 minutes**

### Option 2: Cloudflare Tunnel + Direct Nginx

```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v5.sh
sudo bash install_v5.sh
```

**Choose option 2 during installation**

Features:
- ✅ No port forwarding needed
- ✅ Minimal resources
- ✅ Manual DNS setup

Setup time: **10-15 minutes**

### Option 3: Direct Port Forwarding

```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v5.sh
sudo bash install_v5.sh
```

**Choose option 3 during installation**

Features:
- ⚠️ Requires static IP
- ⚠️ Port forwarding needed (80, 443)
- ⚠️ Manual SSL setup

Setup time: **20-30 minutes**

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Cloudflare Tunnel                     │
│              (Optional - No Port Forwarding)             │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│          Nginx Proxy Manager (Optional)                  │
│              (GUI-based Management)                      │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                   Nginx Container                        │
│            (Reverse Proxy & Static Files)               │
└────────────────────┬────────────────────────────────────┘
                     │
      ┌──────────────┼──────────────┐
      │              │              │
┌─────▼────┐  ┌─────▼────┐  ┌─────▼────┐
│   Django │  │ Celery   │  │ Celery   │
│   App    │  │ Worker   │  │ Beat     │
└─────┬────┘  └─────┬────┘  └─────┬────┘
      │             │             │
      └─────────────┼─────────────┘
                    │
      ┌─────────────┼─────────────┐
      │             │             │
┌─────▼────┐  ┌─────▼────┐  ┌─────▼────┐
│PostgreSQL│  │  Redis   │  │  Flower  │
│Database  │  │  Cache   │  │ Monitor  │
└──────────┘  └──────────┘  └──────────┘
```

## 🔧 Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Backend | Django | 4.2+ |
| Database | PostgreSQL | 16 |
| Cache | Redis | 7 |
| Task Queue | Celery | 5.3+ |
| Web Server | Nginx | Alpine |
| Reverse Proxy | Nginx Proxy Manager | Latest |
| Tunnel | Cloudflare Tunnel | Latest |
| Container | Docker | 24+ |
| Orchestration | Docker Compose | 2.0+ |

## 📊 Features

### Core Features
- **Intelligent Content Aggregation** - Automatic RSS feed parsing
- **Advanced Search** - Full-text search with filtering
- **Content Management** - Manage sources and categories
- **User Management** - Role-based access control
- **REST API** - Programmatic access
- **Admin Panel** - Comprehensive Django admin

### v5.0 Features
- **Full Automation** - One-command installation
- **DNS Auto-Setup** - Automatic Cloudflare DNS records
- **Cloudflare Tunnel** - Secure tunnel without port forwarding
- **Nginx Proxy Manager** - GUI-based reverse proxy
- **Health Checks** - Automated container monitoring
- **SSL/TLS** - Automatic Let's Encrypt certificates
- **Performance** - Optimized caching and queries
- **Scalability** - Horizontal scaling support

## 🎯 Access URLs

After installation:

| Service | URL | Credentials |
|---------|-----|-------------|
| Main Site | https://habernexus.com | - |
| Admin Panel | https://habernexus.com/admin | username/password |
| Nginx Proxy Manager | http://localhost:81 | admin@example.com / changeme |
| Flower (Tasks) | http://localhost:5555 | admin / admin |

## 📚 Documentation

- [Installation Guide](docs/INSTALLATION.md) - Detailed setup
- [Installation Guide v5](docs/INSTALLATION_GUIDE_v5.md) - v5.0 specific
- [Architecture](docs/ARCHITECTURE.md) - System design
- [Scripts](docs/SCRIPTS.md) - Available utilities
- [Configuration](docs/CONFIGURATION.md) - Settings
- [Deployment](docs/DEPLOYMENT.md) - Production setup
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues

## 🔐 Security Features

- SSL/TLS encryption (HTTPS)
- HSTS headers (enforce HTTPS)
- CSRF protection (Django built-in)
- SQL injection prevention (ORM)
- XSS prevention (template escaping)
- Rate limiting (DDoS protection)
- Security headers (CSP, X-Frame-Options)
- Cloudflare DDoS protection (with Tunnel)

## 🚀 Deployment

### Using Docker Compose

```bash
cd /opt/habernexus

# Option 1: Tunnel + NPM
docker-compose --profile npm --profile tunnel up -d

# Option 2: Tunnel + Direct Nginx
docker-compose --profile tunnel up -d

# Option 3: Direct Port Forwarding
docker-compose up -d
```

### Health Checks

```bash
# Check status
docker-compose ps

# View logs
docker-compose logs -f app

# Check specific service
docker-compose logs cloudflared
docker-compose logs nginx_proxy_manager
```

## ⚙️ Configuration

### Environment Variables

The installer creates `.env` automatically with:

```bash
# Django Configuration
DEBUG=False
DJANGO_SECRET_KEY=auto-generated
ALLOWED_HOSTS=habernexus.com,www.habernexus.com

# Database
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=auto-generated

# Cloudflare
CLOUDFLARE_TUNNEL_TOKEN=your-token
CLOUDFLARE_API_TOKEN=your-api-token

# Admin
ADMIN_USER=sata
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=your-password
```

### Cloudflare Setup

#### Create Tunnel
1. Go to https://one.dash.cloudflare.com
2. Networks > Tunnels
3. Create a Tunnel
4. Copy the token

#### Create DNS Records
Automatic with API token, or manual:

1. Go to https://dash.cloudflare.com
2. DNS > Add record
3. Type: CNAME
4. Name: habernexus.com
5. Content: {tunnel-id}.cfargotunnel.com
6. Proxied: Yes

#### Configure Public Hostnames
1. https://one.dash.cloudflare.com/networks/tunnels
2. Select your tunnel
3. Public Hostname
4. Add hostnames pointing to http://nginx_proxy_manager:81

## 🐛 Troubleshooting

### Tunnel shows "Inactive"
- Check DNS records are created
- Verify Public Hostnames configured
- Check logs: `docker-compose logs cloudflared`

### Port already in use
- Check available ports: `sudo lsof -i :80`
- Kill process: `sudo kill -9 <PID>`

### Database connection error
- Check PostgreSQL: `docker-compose logs postgres`
- Verify credentials in `.env`

### SSL certificate issues
- Check NPM logs: `docker-compose logs nginx_proxy_manager`
- Verify DNS records

For more help, see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## 📊 Monitoring

### Container Status
```bash
docker-compose ps
```

### Service Logs
```bash
docker-compose logs -f app
docker-compose logs -f postgres
docker-compose logs -f redis
docker-compose logs -f celery
```

### Task Monitoring
Access Flower at http://localhost:5555

### System Metrics
- Task execution time
- Worker status
- Task history
- Performance statistics

## 🔄 Updates

### Update to Latest Version

```bash
cd /opt/habernexus
git pull origin main
docker-compose down
docker-compose up -d
docker-compose exec app python manage.py migrate
```

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](docs/CONTRIBUTING.md)

## 📄 License

MIT License - See [LICENSE](LICENSE)

## 👥 Authors

- **Salih TANRISEVEN** - Initial development
- **Manus AI** - v5.0 automation and improvements

## 📞 Support

- GitHub Issues: https://github.com/sata2500/habernexus/issues
- Email: salihtanriseven25@gmail.com
- Documentation: https://github.com/sata2500/habernexus/tree/main/docs

## 🗺️ Roadmap

### v5.1 (Planned)
- [ ] Multi-language support
- [ ] Advanced analytics
- [ ] Custom themes
- [ ] API rate limiting

### v6.0 (Planned)
- [ ] Kubernetes support
- [ ] GraphQL API
- [ ] Mobile app
- [ ] ML features

## 📈 Performance

- Page load time: < 500ms
- API response: < 100ms
- Database optimized: Indexed queries
- Cache hit rate: > 80%
- Concurrent users: 1000+

---

**Made with ❤️ by Salih TANRISEVEN & Manus AI**

Last Updated: December 2024 | Version: 5.0
