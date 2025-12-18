## HaberNexus Installation Guide

This guide provides the necessary steps to install the HaberNexus platform in different environments.

---

### ⚡ One-Command Installation (Recommended Method)

The fastest and easiest installation method is to use the `get-habernexus.sh` script. This script installs all necessary dependencies (Docker, Caddy, Cloudflare Tunnel), configures the system, and starts the application.

**Requirements:**
- Ubuntu 22.04 or 24.04
- A user with `sudo` privileges
- Your Cloudflare account and a domain

**Installation Step:**

```bash
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/get-habernexus.sh | sudo bash
```

When the script runs, it will ask you to enter information such as your domain, email address, and Cloudflare API token.

#### Advanced Installation Options

```bash
# Installation by providing domain and email address as parameters
sudo bash get-habernexus.sh -- --domain habernexus.com --email salihtanriseven25@gmail.com

# Quick installation (without interactive input, with default values)
sudo bash get-habernexus.sh -- --quick

# Reinstall by completely resetting the existing installation
sudo bash get-habernexus.sh -- --reset
```

### 🐳 Installation with Docker

You can run the project in a production or development environment using Docker Compose.

**Requirements:**
- Docker and Docker Compose

**Steps:**

1.  **Clone the Project:**
    ```bash
    git clone https://github.com/sata2500/habernexus.git
    cd habernexus
    ```

2.  **Create the Configuration File:**
    Create a new file named `.env` by copying the `.env.example` file and edit the values in it according to your configuration.
    ```bash
    cp .env.example .env
    ```

3.  **Start the Application:**

    -   **For Production Environment:**
        This command starts the application in an optimized way with Caddy, Cloudflare Tunnel, and Gunicorn.
        ```bash
        docker compose -f docker-compose.prod.yml up -d
        ```

    -   **For Development Environment:**
        This command starts the application with Django's internal development server and reflects code changes instantly.
        ```bash
        docker compose up -d
        ```

4.  **Monitor Logs:**
    ```bash
    docker compose logs -f
    ```

### 💻 Local Development Environment Setup

You can follow the steps below to develop the project directly on your machine without Docker.

**Requirements:**
- Python 3.11+
- PostgreSQL (or SQLite)
- Redis

**Steps:**

1.  **Clone the Project:**
    ```bash
    git clone https://github.com/sata2500/habernexus.git
    cd habernexus
    ```

2.  **Create a Virtual Environment:**
    ```bash
    python -m venv venv
    source venv/bin/activate  # Linux/macOS
    # venv\Scripts\activate  # Windows
    ```

3.  **Install Dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Database Setup and Migration:**
    After setting your database connection information in your `.env` file, create the database.
    ```bash
    python manage.py migrate
    ```

5.  **Start the Development Server:**
    ```bash
    python manage.py runserver
    ```
    The application will now be running at `http://127.0.0.1:8000`.

6.  **Start the Celery Worker (in a separate terminal):**
    You need to start the Celery worker for background tasks (RSS fetching, content generation, etc.) to run.
    ```bash
    celery -A habernexus_config worker -l info
    ```

7.  **Start Celery Beat (in a separate terminal):**
    Start Celery Beat to schedule periodic tasks.
    ```bash
    celery -A habernexus_config beat -l info
    ```
