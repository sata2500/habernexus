# Haber Nexus - Next-Gen AI News Agency

![Haber Nexus Banner](https://img.shields.io/badge/Status-Production%20Ready-success?style=for-the-badge)
![Django](https://img.shields.io/badge/Django-5.0-green?style=for-the-badge&logo=django)
![Python](https://img.shields.io/badge/Python-3.11-blue?style=for-the-badge&logo=python)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue?style=for-the-badge&logo=postgresql)
![Docker](https://img.shields.io/badge/Docker-Ready-blue?style=for-the-badge&logo=docker)
![Cloudflare](https://img.shields.io/badge/Cloudflare-Tunnel-orange?style=for-the-badge&logo=cloudflare)
![Nginx](https://img.shields.io/badge/Nginx-Proxy%20Manager-green?style=for-the-badge&logo=nginx)

**Haber Nexus** is an automated, AI-powered news agency platform that leverages Google Gemini AI to generate professional, SEO-optimized news content from RSS feeds 24/7. Now with **Nginx Proxy Manager** and **Cloudflare Tunnel** support for easy deployment!

---

## 🚀 Key Features

| Feature | Description | Status |
|---|---|---|
| **AI Content Generation** | Automated news writing using Google Gemini 1.5 Flash | ✅ |
| **Smart Search** | Full-text search powered by Elasticsearch | ✅ |
| **Advanced Monitoring** | Real-time metrics with Prometheus & Grafana | ✅ |
| **Auto-Scaling** | Dockerized microservices architecture | ✅ |
| **SEO Optimization** | Automatic slug generation, meta tags, and sitemaps | ✅ |
| **Visual Intelligence** | AI-generated featured images for articles | ✅ |
| **Nginx Proxy Manager** | GUI-based reverse proxy and SSL management | ✨ NEW |
| **Cloudflare Tunnel** | Secure tunnel without port forwarding | ✨ NEW |
| **Multiple Deployment Options** | Tunnel+NPM, Tunnel+Direct, or Direct Port Forwarding | ✨ NEW |

---

## 🛠️ Quick Start

### Prerequisites
- **OS:** Ubuntu 22.04 LTS or 24.04 LTS
- **Docker & Docker Compose v2** (auto-installed)
- **Root privileges** (for installation)
- **Internet connection** (for Cloudflare/updates)

### Installation Options

We provide **three flexible installation options** to suit your needs:

#### Option 1: Cloudflare Tunnel + Nginx Proxy Manager ⭐ (Recommended)
**Best for:** Users without static IP, those who can't open ports, need GUI management

```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v4.sh
sudo bash install_v4.sh
```

**Features:**
- ✅ No port forwarding required
- ✅ GUI-based proxy management
- ✅ Automatic SSL certificates
- ✅ Cloudflare DDoS protection
- ✅ Wildcard domain support

#### Option 2: Cloudflare Tunnel + Direct Nginx
**Best for:** Simple setup, minimal resources

```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v4.sh
sudo bash install_v4.sh
# Select: 2 (Cloudflare Tunnel + Direct Nginx)
```

#### Option 3: Direct Port Forwarding
**Best for:** Advanced users with static IP

```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v4.sh
sudo bash install_v4.sh
# Select: 3 (Direct Port Forwarding)
```

### What the Installer Does

The `install_v4.sh` script handles:
- ✓ System dependency installation
- ✓ Docker & Docker Compose setup
- ✓ Repository cloning
- ✓ Environment configuration
- ✓ Cloudflare Tunnel setup (if selected)
- ✓ Nginx Proxy Manager setup (if selected)
- ✓ Database migrations
- ✓ Admin user creation
- ✓ Health checks
- ✓ Installation summary

**Installation time:** 15-20 minutes

---

## 🏗️ Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLOUDFLARE (Optional)                    │
│  - Tunnel (No port forwarding needed)                       │
│  - DNS Management (CNAME records)                           │
│  - SSL Termination (Cloudflare SSL)                         │
│  - DDoS Protection                                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓ (Tunnel)
┌─────────────────────────────────────────────────────────────┐
│              DOCKER HOST (Ubuntu 22.04/24.04)               │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Nginx Proxy Manager (Port 81 - Admin)                │ │
│  │  - Reverse Proxy management (GUI)                     │ │
│  │  - SSL certificate management                         │ │
│  │  - Database: SQLite/PostgreSQL/MySQL                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                       ↓                                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  HaberNexus Stack                                      │ │
│  │  - Django App (Port 8000)                             │ │
│  │  - PostgreSQL (Port 5432)                             │ │
│  │  - Redis (Port 6379)                                  │ │
│  │  - Celery Workers                                     │ │
│  │  - Celery Beat (Scheduler)                            │ │
│  │  - Flower (Monitoring - Port 5555)                    │ │
│  │  - Prometheus/Grafana (Monitoring)                    │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Cloudflared (Tunnel Connector - if using Tunnel)     │ │
│  │  - Cloudflare Tunnel connection                       │ │
│  │  - Traffic routing to Nginx Proxy Manager             │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Framework** | Django | 5.0 |
| **Language** | Python | 3.11 |
| **Database** | PostgreSQL | 16 |
| **Cache** | Redis | 7 |
| **Task Queue** | Celery | 5.4 |
| **Scheduler** | Celery Beat | 2.6 |
| **Web Server** | Nginx | Alpine |
| **App Server** | Gunicorn | 22.0 |
| **Reverse Proxy** | Nginx Proxy Manager | Latest |
| **Tunnel** | Cloudflare Tunnel | Latest |
| **Monitoring** | Prometheus + Grafana | Latest |
| **Search** | Elasticsearch | 8.0 |
| **Containerization** | Docker & Compose | Latest |

---

## 📚 Documentation

Comprehensive documentation is available in the `docs/` directory:

### Getting Started
- **[Installation Guide v4](docs/INSTALLATION_GUIDE_v4.md)** - New installer with screenshots
- **[Quick Start](docs/QUICK_START.md)** - Get up and running in 5 minutes
- **[Installation](docs/INSTALLATION.md)** - Detailed setup instructions

### Configuration & Deployment
- **[Architecture Overview](docs/ARCHITECTURE.md)** - System design deep dive
- **[Configuration](docs/CONFIGURATION.md)** - Environment variables and settings
- **[Deployment](docs/DEPLOYMENT.md)** - Production deployment guide

### Development & Operations
- **[Development Guide](docs/DEVELOPMENT.md)** - Local development setup
- **[Content System](docs/CONTENT_SYSTEM.md)** - How the AI pipeline works
- **[Monitoring Guide](docs/MONITORING.md)** - Setting up dashboards
- **[Scripts Guide](docs/SCRIPTS.md)** - Utility scripts documentation

### Support
- **[FAQ](docs/FAQ.md)** - Frequently asked questions
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[API Documentation](docs/API.md)** - REST API reference

---

## 🔄 Server Migration

Need to move to a new server? Use our migration utility:

```bash
# On old server - Create backup
sudo bash scripts/migrate_server.sh backup

# On new server - Restore backup
sudo bash scripts/migrate_server.sh restore <path_to_archive>
```

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📊 Monitoring & Observability

HaberNexus includes comprehensive monitoring:

- **Prometheus:** Metrics collection
- **Grafana:** Visualization dashboards
- **Flower:** Celery task monitoring
- **Health Checks:** Built-in health endpoints

Access monitoring dashboards:
- Grafana: `https://your-domain.com:3000`
- Flower: `https://your-domain.com:5555`
- Prometheus: `https://your-domain.com:9090`

---

## 🔐 Security

HaberNexus implements multiple security layers:

- **SSL/TLS:** Let's Encrypt with automatic renewal
- **Cloudflare DDoS:** Optional Cloudflare Tunnel protection
- **Rate Limiting:** Built-in rate limiting
- **Security Headers:** HSTS, CSP, X-Frame-Options, etc.
- **Database Encryption:** PostgreSQL with strong passwords
- **Input Validation:** Comprehensive input validation

---

## 📄 License

This project is proprietary software. See [LICENSE](LICENSE) for details.

**Developer:** Salih TANRISEVEN  
**Contact:** salihtanriseven25@gmail.com  
**Domain:** habernexus.com

---

## 🆘 Support & Issues

- **GitHub Issues:** https://github.com/sata2500/habernexus/issues
- **Email:** salihtanriseven25@gmail.com
- **Documentation:** https://github.com/sata2500/habernexus/tree/main/docs

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

### Latest Version: v4.0 (December 2024)

**Major Features:**
- ✨ Nginx Proxy Manager integration
- ✨ Cloudflare Tunnel support
- ✨ install_v4.sh (new universal installer)
- ✨ Three deployment options
- ✨ GUI-based configuration
- ✨ Enhanced error handling
- ✨ Health check system
- ✨ Comprehensive logging

---

## 🎯 Roadmap

### Planned Features
- [ ] Multi-language support
- [ ] Advanced analytics dashboard
- [ ] API rate limiting dashboard
- [ ] Automated backups to S3
- [ ] Multi-server deployment
- [ ] Kubernetes support
- [ ] Advanced AI models support

---

## 📈 Performance

HaberNexus is optimized for performance:

- **Content Generation:** ~30 seconds per article
- **Search:** <100ms response time
- **API Response:** <200ms average
- **Database:** Optimized queries with indexing
- **Caching:** Redis-based caching layer
- **CDN:** Cloudflare CDN support

---

## 🙏 Acknowledgments

- **Google Gemini AI** - For powerful AI content generation
- **Django Community** - For the excellent web framework
- **Docker** - For containerization
- **Cloudflare** - For tunnel and DDoS protection
- **Nginx Proxy Manager** - For easy reverse proxy management

---

**Made with ❤️ by Salih TANRISEVEN**

Last Updated: December 14, 2024
