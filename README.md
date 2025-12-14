# Haber Nexus - Next-Gen AI News Agency

![Haber Nexus Banner](https://img.shields.io/badge/Status-Production%20Ready-success?style=for-the-badge)
![Django](https://img.shields.io/badge/Django-5.0-green?style=for-the-badge&logo=django)
![Python](https://img.shields.io/badge/Python-3.11-blue?style=for-the-badge&logo=python)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue?style=for-the-badge&logo=postgresql)
![Elasticsearch](https://img.shields.io/badge/Elasticsearch-8.0-yellow?style=for-the-badge&logo=elasticsearch)
![Docker](https://img.shields.io/badge/Docker-Ready-blue?style=for-the-badge&logo=docker)

**Haber Nexus** is an automated, AI-powered news agency platform that leverages Google Gemini AI to generate professional, SEO-optimized news content from RSS feeds 24/7.

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

---

## 🛠️ Quick Start

### Prerequisites
- Ubuntu 22.04/24.04 LTS
- Docker & Docker Compose (v2)
- Root privileges

### 1. One-Click Installation
We provide a unified setup script that handles dependencies, configuration, and SSL setup.

```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/scripts/setup_v3.sh
sudo bash setup_v3.sh
```

### 2. Server Migration
Moving to a new server? Use our migration utility.

```bash
# On old server
sudo bash scripts/migrate_server.sh backup

# On new server
sudo bash scripts/migrate_server.sh restore <path_to_archive>
```

---

## 🏗️ Architecture

The system is built on a robust microservices architecture:

- **Web Layer:** Nginx (Reverse Proxy), Django (App Server)
- **Data Layer:** PostgreSQL (Primary DB), Elasticsearch (Search Engine)
- **Async Layer:** Redis (Broker), Celery (Workers), Celery Beat (Scheduler)
- **Monitoring:** Prometheus (Metrics), Grafana (Visualization)

---

## 📚 Documentation

Detailed documentation is available in the `docs/` directory:

- **[Installation Guide](docs/INSTALLATION.md)** - Detailed setup instructions
- **[Architecture Overview](docs/ARCHITECTURE.md)** - System design deep dive
- **[Content System](docs/CONTENT_SYSTEM.md)** - How the AI pipeline works
- **[Monitoring Guide](docs/MONITORING.md)** - Setting up dashboards

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is proprietary software. See [LICENSE](LICENSE) for details.

**Developer:** Salih TANRISEVEN  
**Contact:** salihtanriseven25@gmail.com

## 📦 New Interactive Installer

Try our new TUI-based installer for an even easier experience!

```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install.sh
sudo bash install.sh
```

Features:
- **Interactive Menu:** No more editing config files manually.
- **Smart Migration:** Transfer data from another server with a single token.
- **Auto-Updates:** Keep your system fresh with one click.

See [USER_GUIDE.md](docs/USER_GUIDE.md) for details.
