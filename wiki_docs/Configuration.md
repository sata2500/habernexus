## HaberNexus Configuration Guide

This guide explains the basic configuration settings of the HaberNexus application and how to manage them. Configuration is primarily managed through environment variables and stored in the `.env` file.

---

### `.env` File

The `.env` file in the project's root directory contains all sensitive information and environment-specific settings. This file **must absolutely not be included in Git repositories** (it is listed in the `.gitignore` file).

You need to create your own `.env` file by copying the `.env.example` file during installation with the `install.sh` script or manually.

```bash
cp .env.example .env
```

#### Basic Configuration Variables

| Variable | Description | Example Value |
|---|---|---|
| `SECRET_KEY` | The security key of the Django application. **Very confidential.** | `django-insecure-!@#...` |
| `DEBUG` | Enables or disables debug mode. **Must be `False` in production.** | `False` |
| `ALLOWED_HOSTS` | The domain addresses that the application will serve. | `habernexus.com,www.habernexus.com` |
| `DOMAIN_NAME` | The main domain name of the project. | `habernexus.com` |
| `ADMIN_EMAIL` | Administrator email address. | `salihtanriseven25@gmail.com` |

#### Database Configuration (PostgreSQL)

| Variable | Description | Example Value |
|---|---|---|
| `DB_ENGINE` | Django database engine. | `django.db.backends.postgresql` |
| `DB_NAME` | Database name. | `habernexus` |
| `DB_USER` | Database user. | `habernexus_user` |
| `DB_PASSWORD` | Database password. | `StrongPassword123` |
| `DB_HOST` | The address of the database server. | `postgres` (in Docker) or `localhost` |
| `DB_PORT` | Database port. | `5432` |

#### Redis Configuration

| Variable | Description | Example Value |
|---|---|---|
| `REDIS_HOST` | The address of the Redis server. | `redis` (in Docker) or `localhost` |
| `REDIS_PORT` | Redis port. | `6379` |

#### Cloudflare Configuration

| Variable | Description | Example Value |
|---|---|---|
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token (for DNS management). | `...` |
| `CLOUDFLARE_TUNNEL_TOKEN` | Cloudflare Tunnel token (for secure connection). | `...` |
| `CLOUDFLARE_ACCOUNT_ID` | Your Cloudflare account ID. | `...` |
| `CLOUDFLARE_ZONE_ID` | The Cloudflare Zone ID where your domain is located. | `...` |

#### AI and API Keys

These settings can be managed dynamically from the **Core > API Settings** section of the Django admin panel, but can also be added to the `.env` file.

| Variable | Description | Example Value |
|---|---|---|
| `GOOGLE_GEMINI_API_KEY` | API key for Google Gemini AI content generation. | `AIza...` |
| `GOOGLE_IMAGEN_API_KEY` | API key for Google Imagen image generation. | `AIza...` |

---

### Configuration from the Django Admin Panel

Some operational settings can be changed directly from the admin panel without changing the code. This provides flexibility and does not require re-deployment.

**Admin Panel Address:** `/admin/`

#### API Settings

-   **Location:** `Core > API Settings` (`/admin/core/settings/`)
-   **Manageable Settings:**
    -   **Google Gemini API Key:** Used for AI text generation.
    -   **Google Imagen API Key:** Used for AI image generation.
    -   **RSS Scan Frequency:** Determines how often RSS sources are scanned (in minutes).
    -   **Content Generation Frequency:** Determines how often artificial intelligence will generate new content (in minutes).

Changes made through this panel are saved to the database and instantly update the timing of periodic tasks run by Celery Beat.

#### RSS Source Management

-   **Location:** `News > RSS Sources`
-   **Manageable Settings:**
    -   You can add new RSS sources, edit existing ones, or delete them.
    -   You can manage properties such as `category`, `scan frequency`, and `is active` for each source.
