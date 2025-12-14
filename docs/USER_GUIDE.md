# HaberNexus User Guide v3.1

## 🚀 One-Click Installation

HaberNexus features a powerful TUI (Text User Interface) installer that handles everything from dependency installation to Cloudflare Tunnel configuration.

### Quick Start
Run the following command on your fresh Ubuntu server (20.04+):

```bash
curl -O https://raw.githubusercontent.com/sata2500/habernexus/main/install.sh && sudo bash install.sh
```

### Features

1.  **Fresh Installation:**
    *   **Environment Cleanup:** Automatically detects and cleans up old installations.
    *   **Cloudflare Tunnel:** Securely expose your site without opening ports.
    *   **Auto-Admin:** Creates a superuser account automatically.
    *   **Post-Install Summary:** Displays all critical information at the end.

2.  **Smart Migration:**
    *   Transfer your entire site (Database + Media) from another server using a secure token.

3.  **Update System:**
    *   Pulls the latest code from GitHub and rebuilds containers with one click.

## ☁️ Cloudflare Tunnel Setup (Recommended)

Cloudflare Tunnel allows you to expose your HaberNexus instance to the internet securely without opening ports 80/443 on your firewall.

### How to Get Your Tunnel Token
1.  Log in to the [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com).
2.  Navigate to **Networks > Tunnels**.
3.  Click **Create a Tunnel** and select **Cloudflared**.
4.  Name your tunnel (e.g., `habernexus-prod`) and click **Save Tunnel**.
5.  Under "Install and run a connector", look for the command block. Copy the long token string after `--token`.
    *   Example: `eyJhIjoi...`
6.  Paste this token into the HaberNexus installer when prompted.

### Configuring Public Hostname
After the installer finishes:
1.  Go back to the Cloudflare Tunnel configuration page.
2.  Click **Next** to go to the "Public Hostnames" tab.
3.  Add a public hostname:
    *   **Subdomain:** (Leave empty for root domain, or use `www`)
    *   **Domain:** Select your domain (e.g., `habernexus.com`)
    *   **Path:** (Leave empty)
    *   **Service:** `http://nginx:80` (This is crucial! It points to the internal Nginx container)
4.  Click **Save Hostname**.

Your site should now be live!

## 🔧 Post-Installation Steps

1.  **Admin Panel:**
    *   Log in at `https://yourdomain.com/admin` using the credentials you set during installation.
    *   Configure your API keys (Google Gemini, etc.) in the Settings model.

## 🆘 Troubleshooting

*   **Logs:** Check `/var/log/habernexus_installer.log` for detailed installation logs.
*   **Services:** Run `docker compose ps` in `/opt/habernexus` to check service status.
