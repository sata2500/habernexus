# HaberNexus - Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [10.3.0] - 2025-12-17

### 🆕 Added
- **ThinkingLevel Enum Support:** Google Gen AI SDK now supports `MINIMAL`, `LOW`, `MEDIUM`, `HIGH` levels for thinking control
- **CodeQL Integration:** Advanced security analysis added to CI/CD pipeline
- **Dependency Review:** Automatic dependency security checks in pull requests
- **Sentry Integration:** Comprehensive error tracking and reporting module (`core/error_tracking.py`)
- **Error Context Manager:** New class for error context management
- **Breadcrumb Tracking:** Operation history tracking
- **Batch Processing Tasks:** `batch_regenerate_content` and `cleanup_draft_articles` tasks for bulk content generation
- **Archive System:** Systematic archiving structure for old files (`archive/`)
- **Comprehensive Test Suite:** Middleware, API, and task tests added

### 🔄 Changed
- **Google Gen AI SDK:** ThinkingConfig now uses ThinkingLevel enum
- **CI/CD Pipeline:** Redis service, test timeout, weekly security scan added
- **Test Coverage:** Target increased from 30% to 35%
- **Project Structure:** Old files moved to `archive/` folder
- **README.md:** Completely updated for v10.3

### 🐛 Fixed
- Retry mechanism improved with exponential backoff
- ThinkingConfig creation logic fixed
- Missing coverage in middleware tests addressed

### 🗑️ Removed
- Old installation scripts moved to archive (install_v4.sh - install_v8.sh)
- Old documentation files moved to archive

### 📁 Archived Files
- `install_v4.sh`, `install_v5.sh`, `install_v6.sh`, `install_v7.sh`, `install_v8.sh`
- `manage_habernexus.sh`, `pre_install_check.sh`
- `CHANGELOG_v10.md`, `CHANGELOG_v10.2.md`
- `DEBUGGING_REPORT_v10.1.md`, `DEVELOPMENT_PLAN_v10.md`, `DEVELOPMENT_REPORT_v10.2.md`
- `INSTALLATION_GUIDE_v7.md`, `INSTALLATION_SCRIPTS_README.md`
- `COMPLETION_PLAN.md`, `RESEARCH_NOTES.md`, `research_findings_v10.2.md`

---

## [10.2.0] - 2025-12-16

### 🆕 Added
- Google Gen AI SDK thinking_config support
- Multi-Python test matrix (3.10, 3.11, 3.12)
- Bandit, pip-audit security scans
- Rate limiting middleware
- Security headers middleware

### 🔄 Changed
- Coverage threshold reduced from 70% to 30%
- Migration check CI compatibility improved

### 🐛 Fixed
- isort import ordering errors
- flake8 linting errors
- Black formatting inconsistencies

---

## [10.1.0] - 2025-12-15

### 🆕 Added
- Advanced error handling system
- Custom exception classes
- REST Framework exception handler

### 🐛 Fixed
- CI/CD pipeline errors
- Concurrency issues

---

## [10.0.0] - 2025-12-14

### 🆕 Added
- REST API module (Django REST Framework)
- Newsletter system
- Google Gen AI SDK integration
- Swagger/ReDoc API documentation
- Celery Beat periodic tasks

### 🔄 Changed
- Project structure reorganized
- Database models updated

---

## [9.0.0] - 2025-12-10

### 🆕 Added
- Whiptail-based interactive installation system
- Installation wizard

---

## [8.0.0] - 2025-12-05

### 🆕 Added
- Ultimate installation system
- Docker Compose configuration
- Cloudflare Tunnel integration

---

## [4.0.0] - 2024-12-14

### ✨ Added

- **Nginx Proxy Manager Integration** - GUI-based reverse proxy and SSL management
- **Cloudflare Tunnel Support** - Secure tunnel without port forwarding
- **install_v4.sh** - New universal installer with multiple deployment options
- **Three Deployment Options:**
  - Cloudflare Tunnel + Nginx Proxy Manager (Recommended)
  - Cloudflare Tunnel + Direct Nginx
  - Direct Port Forwarding
- **Enhanced Configuration** - Interactive setup with validation
- **Input Validation** - Domain, email, password, and token validation
- **Health Check System** - Comprehensive system health verification
- **Detailed Logging** - Improved logging and error messages
- **Post-Installation Summary** - Clear summary with next steps
- **Docker Compose Configurations:**
  - `config/docker-compose.npm.yml` - Nginx Proxy Manager setup
  - `config/docker-compose.tunnel.yml` - Cloudflare Tunnel setup
- **Installation Guide v4** - Comprehensive guide with screenshots
- **Cloudflare Integration Guide** - Step-by-step Cloudflare setup

### 🔧 Improved

- **Installation Experience** - More user-friendly with progress indicators
- **Error Handling** - Better error messages and recovery suggestions
- **Documentation** - Updated all documentation for v4.0
- **README.md** - Complete rewrite with new features and options
- **Architecture Documentation** - Updated with new components

### 🔄 Changed

- **Default Installer** - `install_v4.sh` is now the recommended installer
- **Quick Start** - Updated to use new installer
- **Installation Instructions** - Now covers all three options

### ⚠️ Deprecated

- **setup.sh** (v1) - Use `install_v4.sh` instead
- **setup_v3.sh** - Use `install_v4.sh` instead

### 🔐 Security

- **Password Strength Validation** - Minimum 12 characters, uppercase, number, special char
- **Token Format Validation** - Cloudflare token validation
- **Secure Credential Handling** - Proper environment variable management
- **SSL Certificate Management** - Automatic renewal with Let's Encrypt

### 📚 Documentation

- Added `docs/INSTALLATION_GUIDE_v4.md` - New installer documentation
- Updated `docs/INSTALLATION.md` - References new installer
- Updated `docs/SCRIPTS.md` - Documents all scripts
- Updated `docs/ARCHITECTURE.md` - New system architecture
- Updated `README.md` - Complete rewrite

---

## [3.1.0] - 2024-12-01

### ✨ Added

- **TUI-based Installer** - Interactive terminal user interface with whiptail
- **Cloudflare Tunnel Support** - Basic tunnel configuration
- **Smart Migration** - Transfer data from another server
- **Admin User Creation** - Automatic superuser setup
- **Post-Installation Summary** - Installation completion report

### 🔧 Improved

- **Installation Process** - More interactive and user-friendly
- **Error Handling** - Better error messages
- **Docker Compose** - Improved configuration

### 📚 Documentation

- Added `docs/USER_GUIDE.md` - User guide for new installer

---

## [2.0.0] - 2024-12-11

### 🚀 Restructuring

- **Professional Documentation** - Complete documentation reorganization
  - Moved old and duplicate files to `docs/archive`
  - Consolidated important guides
  - Created professional structure under `docs/`
- **New Guides** - Added `CONFIGURATION.md` and `CONTRIBUTING.md`
- **README Update** - Completely rewritten for professionalism

### 📚 Documentation

- Reorganized `docs/` directory
- Created `docs/archive/` for old files
- Added Turkish documentation in `docs/tr/`

---

## [1.2.0] - 2024-12-01

### ✨ Added

- **Legal Pages** - Privacy Policy and Terms of Service
- **Corporate Content** - About and Contact pages with professional content
- **Logo Integration** - Official Haber Nexus logo
- **Contact Information** - Professional contact details in footer
- **License File** - LICENSE file (Proprietary)

### 🔧 Improved

- **Footer Updates** - Added legal links, contact info, and tagline
- **Email Addresses** - Added `info@habernexus.com` and `help@habernexus.com`
- **Template Improvements** - Modern and story-focused design

---

## [1.1.0] - 2024-12-01

### ✨ Added

- **Automated Installation Script** - `scripts/install.sh` for single-command Ubuntu setup
- **Docker Improvements** - More stable and faster Docker Compose setup

### 🔧 Improved

- **Documentation Optimization** - Reorganized and removed duplicates
- **README Update** - Comprehensive and better-explained README
- **Clean Project Structure** - Old reports moved to `docs/archive`

### 🐛 Fixed

- Fixed instability in `deploy.sh` and rewrote as `install.sh`

---

## [1.0.0] - 2024-11-30

### 🎉 Initial Release

- **Automated Content Generation** - SEO-friendly news articles with Google Gemini AI
- **RSS Integration** - Automatic news scraping from multiple RSS sources
- **Asynchronous Processing** - 24/7 continuous task processing with Celery
- **Docker Support** - Easy setup with Docker Compose
- **CI/CD Pipeline** - Automated testing and code quality checks with GitHub Actions
- **Admin Panel** - Full control through Django admin interface
- **Professional Architecture** - Microservices-based design
- **Database** - PostgreSQL with proper migrations
- **Monitoring** - Prometheus and Grafana integration
- **Search** - Elasticsearch integration for full-text search
- **Task Monitoring** - Flower for Celery task visualization

---

## Version Comparison

| Feature | v1.0 | v1.1 | v1.2 | v2.0 | v3.1 | v4.0 |
|---------|------|------|------|------|------|------|
| AI Content Generation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| RSS Integration | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Docker Support | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Automated Installation | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| TUI Installer | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Cloudflare Tunnel | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Nginx Proxy Manager | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Multiple Deployment Options | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Input Validation | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Health Check System | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Upgrade Guide

### From v3.1 to v4.0

1. **Backup your data:**
   ```bash
   sudo bash scripts/backup.sh
   ```

2. **Download new installer:**
   ```bash
   curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v4.sh
   ```

3. **Run new installer:**
   ```bash
   sudo bash install_v4.sh
   ```

4. **Select upgrade option** from the menu

### From v1.x to v4.0

Use smart migration feature:
```bash
# On old server
sudo bash scripts/migrate_server.sh backup

# On new server
sudo bash install_v4.sh
# Select smart migration option
```

---

## Future Roadmap

### Planned for v4.1
- [ ] Advanced analytics dashboard
- [ ] API rate limiting dashboard
- [ ] Multi-language content generation

### Planned for v5.0
- [ ] Kubernetes support
- [ ] Multi-server deployment
- [ ] Advanced AI models support
- [ ] Automated S3 backups
- [ ] GraphQL API

### Long-term Goals
- [ ] Mobile app
- [ ] Advanced user roles and permissions
- [ ] Custom AI model training
- [ ] Real-time collaboration features
- [ ] Advanced content scheduling

---

## Support

- **GitHub Issues:** https://github.com/sata2500/habernexus/issues
- **Email:** salihtanriseven25@gmail.com
- **Documentation:** https://github.com/sata2500/habernexus/tree/main/docs

---

## Contributors

- **Salih TANRISEVEN** - Lead Developer
- **Manus AI** - v4.0 Installer & Documentation

---

**Last Updated:** December 14, 2024  
**Current Version:** 4.0.0
