# Scripts Guide

This guide explains the usage and functions of scripts in the project.

---

## Table of Contents

1. [Installation Scripts](#installation-scripts)
2. [Backup and Restore](#backup-and-restore)
3. [Utility Scripts](#utility-scripts)
4. [Development Scripts](#development-scripts)

---

## Installation Scripts

### install_v4.sh (Recommended)

**Purpose:** Universal installer for production deployment with multiple options.

**Usage:**
```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install_v4.sh
sudo bash install_v4.sh
```

**Features:**
- Ubuntu 22.04/24.04 LTS support
- Three deployment options:
  - Cloudflare Tunnel + Nginx Proxy Manager (Recommended)
  - Cloudflare Tunnel + Direct Nginx
  - Direct Port Forwarding
- System pre-flight checks
- Interactive configuration
- Input validation
- Cloudflare integration
- Nginx Proxy Manager setup
- Database migrations
- Admin user creation
- Health checks
- Detailed logging

**Installation Time:** 15-20 minutes

**What It Does:**
1. Checks system requirements
2. Installs Docker and Docker Compose
3. Clones repository
4. Guides through configuration
5. Sets up Cloudflare (if applicable)
6. Configures Nginx Proxy Manager (if applicable)
7. Starts containers
8. Runs migrations
9. Creates admin user
10. Verifies installation

### install.sh (Legacy)

**Purpose:** TUI-based installer for backward compatibility.

**Usage:**
```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install.sh
sudo bash install.sh
```

**Features:**
- Interactive menu
- Cloudflare Tunnel support
- Smart migration
- Admin user creation

**Note:** Use `install_v4.sh` for new installations.

### setup-dev.sh

**Purpose:** Quick development environment setup.

**Usage:**
```bash
bash scripts/setup-dev.sh
```

**Features:**
- Python virtual environment creation
- Dependency installation
- Database setup (SQLite)
- Development server startup

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

## Script Development

### Creating New Scripts

Follow this template:

```bash
#!/bin/bash

# Script description
# Usage: bash scripts/my_script.sh

set -e  # Exit on error

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Main logic
main() {
    log_info "Starting script..."
    # Your code here
    log_info "Script completed successfully!"
}

# Run main function
main "$@"
```

### Testing Scripts

```bash
# Test in dry-run mode
bash -n scripts/script_name.sh

# Test with debug output
bash -x scripts/script_name.sh
```

---

## Support

- **GitHub Issues:** https://github.com/sata2500/habernexus/issues
- **Email:** salihtanriseven25@gmail.com
- **Documentation:** https://github.com/sata2500/habernexus/tree/main/docs

---

**Last Updated:** December 14, 2024  
**Version:** 4.0
