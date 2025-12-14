# HaberNexus v6.0

**Modern, Fully Automated News Aggregation & Content Generation Platform**

> Single-click installation • Automatic HTTPS • Cloudflare Tunnel • Zero Configuration • Production Ready

![Version](https://img.shields.io/badge/version-6.0-brightgreen?style=flat-square)
![Python](https://img.shields.io/badge/python-3.11+-blue?style=flat-square)
![Django](https://img.shields.io/badge/django-4.2+-darkgreen?style=flat-square)
![Docker](https://img.shields.io/badge/docker-ready-blue?style=flat-square)
![Caddy](https://img.shields.io/badge/caddy-reverse%20proxy-orange?style=flat-square)
![Cloudflare](https://img.shields.io/badge/cloudflare-tunnel-blue?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

HaberNexus is a powerful, scalable, and **fully automated** news aggregation platform built with Django, PostgreSQL, Redis, and Celery. v6.0 features Caddy for automatic HTTPS, Cloudflare Tunnel for secure connectivity, and complete automation requiring zero manual configuration.

## 🚀 What's New in v6.0

### ✨ Complete Automation
- **5-Minute Setup** - Single command installation
- **Zero Configuration** - Everything automated
- **Automatic HTTPS** - Caddy with Cloudflare DNS challenge
- **Automatic DNS** - Cloudflare records created automatically
- **Automatic Tunnel** - Cloudflare Tunnel configured automatically
- **Health Checks** - Automated container monitoring and recovery

### 🔒 Enhanced Security
- **Caddy Reverse Proxy** - Automatic HTTPS by default
- **Cloudflare Tunnel** - No port forwarding needed
- **DDoS Protection** - Cloudflare protection included
- **SSL/TLS** - Let's Encrypt certificates (auto-renewal)
- **Security Headers** - HSTS, CSP, X-Frame-Options
- **Secure by Default** - No manual security setup

### 🎛️ Modern Architecture
- **Caddy** - Modern reverse proxy with automatic HTTPS
- **Cloudflare Tunnel** - Secure tunnel without port forwarding
- **Docker Compose** - Simplified, unified configuration
- **Optimized** - Minimal resource usage
- **Production Ready** - Enterprise-grade setup

## 📋 System Requirements

### Minimum
- Ubuntu 22.04 LTS or 24.04 LTS
- 2 CPU cores
- 4 GB RAM
- 20 GB disk space
- Internet connection

### Recommended
- Ubuntu 24.04 LTS
- 4 CPU cores
- 8 GB RAM
- 50 GB SSD
- High-speed internet

## 🛠️ Quick Installation

### One-Command Setup (Recommended)

```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v6.sh
sudo bash install_v6.sh
```

That's it! The installer will:
1. ✅ Check system requirements
2. ✅ Install Docker and dependencies
3. ✅ Clone the repository
4. ✅ Create environment configuration
5. ✅ Build Docker images
6. ✅ Create Cloudflare DNS records
7. ✅ Configure Cloudflare Tunnel
8. ✅ Start all services
9. ✅ Create admin user
10. ✅ Verify SSL certificate

**Total time: ~5 minutes**

### Manual Installation

```bash
git clone https://github.com/sata2500/habernexus.git
cd habernexus
cp .env.example .env
# Edit .env with your settings
docker-compose up -d
```

## 🏗️ Architecture

```
┌──────────────────────────────────────────────┐
│         Cloudflare Tunnel                    │
│  (DDoS Protection, No Port Forwarding)       │
└────────────────┬─────────────────────────────┘
                 │
┌────────────────▼─────────────────────────────┐
│    Caddy Reverse Proxy                       │
│  (Automatic HTTPS, Load Balancing)           │
└────────────────┬─────────────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
┌───▼──┐  ┌─────▼────┐  ┌───▼────┐
│Django│  │ Celery   │  │Flower  │
│ App  │  │ Workers  │  │Monitor │
└───┬──┘  └─────┬────┘  └────────┘
    │           │
┌───▼───────────▼────┐
│PostgreSQL + Redis  │
│(Data & Cache)      │
└────────────────────┘
```

## 🔧 Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Backend | Django | 4.2+ |
| Database | PostgreSQL | 16 |
| Cache | Redis | 7 |
| Task Queue | Celery | 5.3+ |
| Reverse Proxy | Caddy | 2.7+ |
| Tunnel | Cloudflare Tunnel | Latest |
| Container | Docker | 24+ |
| Orchestration | Docker Compose | 2.0+ |

## 📊 Features

### Core Features
- **Intelligent Aggregation** - Automatic RSS feed parsing
- **Advanced Search** - Full-text search with filtering
- **Content Management** - Manage sources and categories
- **User Management** - Role-based access control
- **REST API** - Programmatic access
- **Admin Panel** - Comprehensive Django admin

### v6.0 Features
- **Complete Automation** - One-command setup
- **Automatic HTTPS** - Caddy with Cloudflare DNS
- **Cloudflare Tunnel** - Secure connectivity
- **Zero Configuration** - Everything automated
- **Health Monitoring** - Real-time system status
- **Service Management** - Start/stop from UI
- **Log Viewer** - Live application logs
- **Performance Optimized** - Minimal resource usage

## 🎯 Access URLs

After installation:

| Service | URL | Credentials |
|---------|-----|-------------|
| Main Site | https://your-domain.com | - |
| Admin Panel | https://your-domain.com/admin | username/password |
| API | https://your-domain.com/api | - |
| Flower (Tasks) | https://your-domain.com/flower | admin/admin |

## ⚙️ Configuration

### Environment Variables

The installer creates `.env` automatically with:

```bash
# Domain
DOMAIN=your-domain.com

# Admin User
ADMIN_EMAIL=admin@example.com
ADMIN_USERNAME=admin
ADMIN_PASSWORD=SecurePassword123!

# Cloudflare
CLOUDFLARE_API_TOKEN=your_token
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token

# Database
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=auto-generated

# Django
SECRET_KEY=auto-generated
DEBUG=False
```

## 🔐 Security Features

- **Automatic HTTPS** - Caddy with Let's Encrypt
- **DDoS Protection** - Cloudflare Tunnel
- **Security Headers** - HSTS, CSP, X-Frame-Options
- **CSRF Protection** - Django built-in
- **SQL Injection Prevention** - ORM
- **XSS Prevention** - Template escaping
- **Rate Limiting** - Built-in throttling
- **Secure by Default** - No manual setup

## 🚀 Deployment

### Start Services

```bash
cd /opt/habernexus
docker-compose up -d
```

### Check Status

```bash
docker-compose ps
```

### View Logs

```bash
docker-compose logs -f app
```

### Stop Services

```bash
docker-compose down
```

## 🧪 Testing

Run the test suite:

```bash
bash tests/test_v6.sh
```

## 📚 Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Architecture](docs/ARCHITECTURE.md)
- [API Documentation](docs/API.md)
- [Scripts Reference](docs/SCRIPTS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Configuration](docs/CONFIGURATION.md)

## 🐛 Troubleshooting

### Site not accessible
1. Check DNS: `nslookup your-domain.com`
2. Check Tunnel: `docker-compose logs cloudflared`
3. Check Caddy: `docker-compose logs caddy`

### SSL certificate not issued
1. Verify domain DNS is set
2. Check Caddy logs: `docker-compose logs caddy`
3. Wait 5-10 minutes

### Services not starting
1. Check Docker: `docker ps`
2. Check logs: `docker-compose logs`
3. Verify disk space: `df -h`

### Database connection error
1. Check PostgreSQL: `docker-compose logs postgres`
2. Verify DATABASE_URL in .env
3. Check network: `docker network ls`

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/sata2500/habernexus/issues)
- **Email**: salihtanriseven25@gmail.com
- **Documentation**: [docs/](docs/)

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - See [LICENSE](LICENSE)

## 🙏 Acknowledgments

- [Django](https://www.djangoproject.com/) - Web framework
- [Caddy](https://caddyserver.com/) - Reverse proxy
- [Cloudflare](https://www.cloudflare.com/) - DNS & Tunnel
- [Docker](https://www.docker.com/) - Containerization
- [Celery](https://docs.celeryproject.io/) - Task queue
- [PostgreSQL](https://www.postgresql.org/) - Database
- [Redis](https://redis.io/) - Cache

## 📈 Roadmap

- [ ] Web-based installer UI
- [ ] Multi-language support
- [ ] Advanced analytics
- [ ] Mobile app
- [ ] API rate limiting UI
- [ ] Custom themes
- [ ] Plugin system

## ⭐ Show Your Support

If you find HaberNexus useful, please star the repository!

---

**Made with ❤️ by Salih TANRISEVEN**

v6.0 • December 2025 • Production Ready • Fully Automated
