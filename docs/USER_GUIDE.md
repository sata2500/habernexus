# Haber Nexus User Guide

## 🚀 One-Click Installation (CLI)

We have introduced a new, interactive Command Line Interface (CLI) installer to simplify the deployment process.

### How to Install
1. **Download the installer:**
   ```bash
   curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install.sh
   ```
2. **Run it:**
   ```bash
   sudo bash install.sh
   ```
3. **Follow the on-screen instructions:**
   - Select **"Fresh Installation"** for a new setup.
   - Enter your domain, email, and database password when prompted.

---

## 🔄 Smart Migration (Server-to-Server)

Move your entire Haber Nexus instance (Database + Media) to a new server seamlessly.

### Step 1: On the OLD Server
1. Log in to your server via SSH.
2. Generate a migration token:
   ```bash
   cd /opt/habernexus
   docker compose -f docker-compose.prod.yml exec web python manage.py create_migration_token
   ```
   *Copy the generated token. It is valid for 1 hour.*

### Step 2: On the NEW Server
1. Run the installer:
   ```bash
   sudo bash install.sh
   ```
2. Select **"Smart Migration"** from the menu.
3. Enter the **URL of the OLD server** (e.g., `https://old-habernexus.com`).
4. Enter the **Migration Token** you copied.
5. Sit back and relax! The installer will:
   - Download the backup stream directly from the old server.
   - Restore the database.
   - Restore media files.
   - Start the new system.

---

## 🛠️ System Updates

To update your Haber Nexus instance to the latest version:
1. Run the installer: `sudo bash install.sh`
2. Select **"Update System"**.
