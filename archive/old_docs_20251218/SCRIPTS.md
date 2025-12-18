# Scripts Guide

This guide explains the usage and functions of scripts in the project.

---

## Table of Contents

1. [Installation Scripts](#installation-scripts)
2. [Management Scripts](#management-scripts)
3. [Backup and Restore](#backup-and-restore)
4. [Utility Scripts](#utility-scripts)
5. [Development Scripts](#development-scripts)

---

## Installation Scripts

### install_v7.sh (Recommended) ⭐ NEW

**Purpose:** Advanced automatic installer with multiple installation modes and enhanced error handling.

**Usage:**
```bash
# Quick setup (recommended)
sudo bash install_v7.sh --quick

# Custom configuration (interactive)
sudo bash install_v7.sh --custom

# Development mode
sudo bash install_v7.sh --dev

# Force reinstall with backup
sudo bash install_v7.sh --quick --force

# Show help
bash install_v7.sh --help
```

**Features:**
- Three installation modes: Quick, Custom, Development
- Automatic system dependency installation
- Docker and Docker Compose auto-installation
- Advanced error handling and recovery
- Beautiful colored UI with progress indicators
- Comprehensive logging
- Pre-flight system checks
- Automatic configuration file generation
- Health verification after installation
- Estimated installation time: 5-10 minutes

**Installation Modes:**

| Mode | Description | Time | Use Case |
|------|-------------|------|----------|
| `--quick` | Default values, fully automated | 5-10 min | Production |
| `--custom` | Interactive configuration | 10-15 min | Custom setup |
| `--dev` | Development mode with debug | 10-15 min | Development |

**What It Does:**
1. Checks system requirements
2. Installs missing dependencies
3. Installs Docker (if needed)
4. Clones/updates repository
5. Creates environment configuration
6. Builds Docker images
7. Starts services
8. Runs database migrations
9. Creates admin user
10. Verifies installation

**Log Files:**
- Installation log: `/var/log/habernexus/install_v7_*.log`
- Configuration: `/var/log/habernexus/installation_config_*.conf`

### install_v6.sh (Previous)

**Purpose:** Automatic installer with Cloudflare Tunnel and Caddy support.

**Usage:**
```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v6.sh
sudo bash install_v6.sh
```

**Features:**
- Cloudflare Tunnel integration
- Caddy reverse proxy
- Automatic HTTPS
- Interactive configuration

**Note:** Use `install_v7.sh` for new installations.

### install_v4.sh (Legacy)

**Purpose:** Universal installer with multiple deployment options.

**Usage:**
```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v4.sh
sudo bash install_v4.sh
```

**Features:**
- Multiple deployment options
- Nginx Proxy Manager support
- Interactive menu

**Note:** Use `install_v7.sh` for new installations.

### install.sh (Legacy)

**Purpose:** TUI-based installer for backward compatibility.

**Note:** Use `install_v7.sh` for new installations.

---

## Management Scripts

### manage_habernexus.sh (NEW)

**Purpose:** Manage and maintain HaberNexus after installation.

**Usage:**
```bash
bash manage_habernexus.sh [COMMAND] [OPTIONS]
```

**Status & Monitoring:**
```bash
bash manage_habernexus.sh status          # Show service status
bash manage_habernexus.sh logs [SERVICE] # View logs
bash manage_habernexus.sh health         # Check system health
bash manage_habernexus.sh troubleshoot   # Run diagnostics
```

**Service Management:**
```bash
bash manage_habernexus.sh start           # Start all services
bash manage_habernexus.sh stop            # Stop all services
bash manage_habernexus.sh restart         # Restart all services
bash manage_habernexus.sh restart [SVC]   # Restart specific service
```

**Database:**
```bash
bash manage_habernexus.sh backup-db       # Backup database
bash manage_habernexus.sh restore-db FILE # Restore from backup
bash manage_habernexus.sh migrate         # Run migrations
```

**User Management:**
```bash
bash manage_habernexus.sh create-user U E P    # Create admin user
bash manage_habernexus.sh change-password U P  # Change password
bash manage_habernexus.sh list-users           # List all users
```

**Maintenance:**
```bash
bash manage_habernexus.sh cleanup-logs    # Remove old logs
bash manage_habernexus.sh cleanup-docker  # Clean Docker resources
bash manage_habernexus.sh update          # Update project
```

**Backup:**
```bash
bash manage_habernexus.sh full-backup     # Create full backup
bash manage_habernexus.sh list-backups    # List backups
```

---

## Backup and Restore

### backup.sh

**Purpose:** Create backup of entire system including database and files.

**Usage:**
```bash
sudo bash scripts/backup.sh
```

**Features:**
- Database backup
- File system backup
- Compression
- Timestamped archive
- Logging

**Output:**
```
/opt/habernexus/backups/habernexus_backup_YYYYMMDD_HHMMSS.tar.gz
```

**Automated Backup:**
```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /opt/habernexus/scripts/backup.sh
```

### restore.sh

**Purpose:** Restore system from backup archive.

**Usage:**
```bash
sudo bash scripts/restore.sh /path/to/backup.tar.gz
```

**Features:**
- Database restoration
- File system restoration
- Verification
- Logging

**Process:**
1. Stops containers
2. Extracts backup
3. Restores database
4. Restores files
5. Starts containers
6. Verifies restoration

---

## Utility Scripts

### health-check.sh

**Purpose:** Verify system health and connectivity.

**Usage:**
```bash
bash scripts/health-check.sh
```

**Checks:**
- Docker daemon
- Container status
- Database connectivity
- Application health
- SSL certificate validity
- Disk space
- Memory usage

**Output Example:**
```
✓ Docker daemon: Running
✓ Containers: 8/8 running
✓ Database: Connected
✓ Application: Healthy
✓ SSL Certificate: Valid (expires in 89 days)
✓ Disk Space: 15 GB free
✓ Memory: 6.2 GB available
```

### pre_install_check.sh (NEW)

**Purpose:** Verify system compatibility before installation.

**Usage:**
```bash
sudo bash pre_install_check.sh
```

**Checks:**
- Root privileges
- Operating system (Ubuntu 20.04+)
- CPU cores (min 2, recommended 4+)
- RAM memory (min 4GB, recommended 8+)
- Disk space (min 20GB)
- Internet connectivity
- Required commands
- Docker installation
- Docker Compose installation
- Port availability
- File permissions
- Firewall status
- SELinux status
- Git repository status

**Output:**
- Green (✓): Passed checks
- Yellow (⚠): Warnings
- Red (✗): Failed checks
- Summary report

### migrate_server.sh

**Purpose:** Migrate entire system to new server.

**Usage:**

**Create backup on old server:**
```bash
sudo bash scripts/migrate_server.sh backup
```

**Restore on new server:**
```bash
sudo bash scripts/migrate_server.sh restore <path_to_archive>
```

**Process:**
1. Creates full system backup
2. Compresses and encrypts
3. Provides download link
4. On new server: restores from backup
5. Verifies installation

### create_admin.py

**Purpose:** Create additional admin user.

**Usage:**
```bash
docker compose exec app python scripts/create_admin.py
```

**Interactive Prompts:**
- Email
- Username
- Password
- First Name (optional)
- Last Name (optional)

---

## Development Scripts

### setup-dev.sh

**Purpose:** Setup development environment.

**Usage:**
```bash
bash scripts/setup-dev.sh
```

**Steps:**
1. Creates Python virtual environment
2. Installs dependencies
3. Creates .env file
4. Runs migrations
5. Creates superuser

**Access Development Server:**
```bash
# Start server
python manage.py runserver

# Access at http://localhost:8000
```

---

## Script Management

### Running Scripts with Docker

```bash
# Execute script in container
docker compose exec app bash scripts/script_name.sh

# Execute Python script
docker compose exec app python scripts/script_name.py
```

### Script Logging

All scripts generate logs:
```bash
# View installation logs
tail -f /var/log/habernexus_install_*.log

# View backup logs
tail -f /var/log/habernexus_backup_*.log
```

### Script Permissions

Ensure scripts are executable:
```bash
# Make script executable
chmod +x scripts/script_name.sh

# Verify permissions
ls -l scripts/
```

---

## Troubleshooting Scripts

### Script Not Found
```bash
# Verify script exists
ls -la scripts/

# Clone repository if missing
git clone https://github.com/sata2500/habernexus.git
```

### Permission Denied
```bash
# Make script executable
sudo chmod +x scripts/script_name.sh

# Run with sudo
sudo bash scripts/script_name.sh
```

### Script Fails
```bash
# Check logs
cat /var/log/habernexus_*.log

# Run with debug mode
bash -x scripts/script_name.sh
```

---

## Best Practices

### 1. Always Backup Before Major Changes
```bash
sudo bash scripts/backup.sh
```

### 2. Run Health Checks Regularly
```bash
bash scripts/health-check.sh
```

### 3. Schedule Automatic Backups
```bash
# Daily backup at 2 AM
0 2 * * * /opt/habernexus/scripts/backup.sh
```

### 4. Keep Logs for Debugging
```bash
# View recent logs
tail -50 /var/log/habernexus_*.log
```

### 5. Test Restore Procedure
```bash
# Periodically test restore
sudo bash scripts/restore.sh /path/to/test_backup.tar.gz
```

---

## Quick Reference

| Script | Purpose | Command |
|--------|---------|---------|
| `install_v7.sh` | Main installer | `sudo bash install_v7.sh --quick` |
| `manage_habernexus.sh` | Management | `bash manage_habernexus.sh status` |
| `pre_install_check.sh` | Pre-flight checks | `sudo bash pre_install_check.sh` |
| `backup.sh` | Backup system | `sudo bash scripts/backup.sh` |
| `restore.sh` | Restore system | `sudo bash scripts/restore.sh` |
| `health-check.sh` | Health check | `bash scripts/health-check.sh` |
| `setup-dev.sh` | Dev setup | `bash scripts/setup-dev.sh` |

---

## Support

- **GitHub Issues:** https://github.com/sata2500/habernexus/issues
- **Email:** salihtanriseven25@gmail.com
- **Documentation:** https://github.com/sata2500/habernexus/tree/main/docs

---

**Last Updated:** December 15, 2025  
**Version:** 7.0
