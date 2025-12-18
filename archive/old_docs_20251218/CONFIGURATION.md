# Haber Nexus - Configuration Guide

**Version:** 1.0  
**Last Updated:** December 11, 2025

---

## Table of Contents

1. [Environment Variables](#environment-variables)
2. [Django Settings](#django-settings)
3. [Database Configuration](#database-configuration)
4. [Cache Configuration](#cache-configuration)
5. [Celery Configuration](#celery-configuration)
6. [API Keys and Secrets](#api-keys-and-secrets)
7. [Email Configuration](#email-configuration)
8. [Security Settings](#security-settings)
9. [Logging Configuration](#logging-configuration)
10. [Docker Configuration](#docker-configuration)

---

## Environment Variables

### Quick Reference

Create a `.env` file in the project root with the following variables:

```ini
# Django
DEBUG=False
DJANGO_SECRET_KEY=your_very_secure_secret_key_here
ALLOWED_HOSTS=habernexus.com,www.habernexus.com,localhost

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=habernexus
DB_USER=habernexus_user
DB_PASSWORD=your_secure_database_password
DB_HOST=postgres
DB_PORT=5432

# Redis
REDIS_URL=redis://redis:6379/0
REDIS_PASSWORD=your_secure_redis_password

# Google Gemini API
GOOGLE_GEMINI_API_KEY=your_gemini_api_key_here

# Email (optional)
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your_email@gmail.com
EMAIL_HOST_PASSWORD=your_app_password

# Application
SITE_NAME=Haber Nexus
SITE_DOMAIN=habernexus.com
SITE_URL=https://habernexus.com

# Security
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True

# Content Generation
CONTENT_MIN_QUALITY_SCORE=60
CONTENT_MAX_WORD_COUNT=2000
CONTENT_MIN_WORD_COUNT=800
CONTENT_TARGET_READABILITY=60

# Celery
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
CELERY_ACCEPT_CONTENT=json
CELERY_TASK_SERIALIZER=json
CELERY_RESULT_SERIALIZER=json
CELERY_TIMEZONE=UTC
```

---

## Django Settings

### Development Settings

```python
# habernexus_config/settings.py

DEBUG = True
ALLOWED_HOSTS = ['localhost', '127.0.0.1', 'habernexus.local']

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Cache
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
}

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'DEBUG',
    },
}
```

### Production Settings

```python
# habernexus_config/settings.py

DEBUG = False
ALLOWED_HOSTS = ['habernexus.com', 'www.habernexus.com']

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME'),
        'USER': os.getenv('DB_USER'),
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': os.getenv('DB_HOST'),
        'PORT': os.getenv('DB_PORT', '5432'),
        'CONN_MAX_AGE': 600,
        'OPTIONS': {
            'connect_timeout': 10,
        }
    }
}

# Cache
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': os.getenv('REDIS_URL'),
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'PASSWORD': os.getenv('REDIS_PASSWORD'),
            'CONNECTION_POOL_KWARGS': {
                'max_connections': 50,
                'retry_on_timeout': True
            }
        }
    }
}

# Security
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
```

---

## Database Configuration

### PostgreSQL Setup

#### Local Development

```bash
# Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE habernexus;
CREATE USER habernexus_user WITH PASSWORD 'your_password';
ALTER ROLE habernexus_user SET client_encoding TO 'utf8';
ALTER ROLE habernexus_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE habernexus_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE habernexus TO habernexus_user;
EOF
```

#### Docker

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: habernexus
      POSTGRES_USER: habernexus_user
      POSTGRES_PASSWORD: your_secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
```

### Database Optimization

```python
# settings.py

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'CONN_MAX_AGE': 600,
        'OPTIONS': {
            'connect_timeout': 10,
            'options': '-c statement_timeout=30000'
        },
        'ATOMIC_REQUESTS': True,
    }
}

# Connection pooling (optional)
# Use pgBouncer for connection pooling in production
```

### Database Backups

```bash
# Manual backup
docker-compose exec postgres pg_dump -U habernexus_user habernexus > backup.sql

# Restore from backup
docker-compose exec -T postgres psql -U habernexus_user habernexus < backup.sql

# Automated backup (cron)
0 2 * * * docker-compose exec -T postgres pg_dump -U habernexus_user habernexus > /backups/db_$(date +\%Y\%m\%d).sql
```

---

## Cache Configuration

### Redis Setup

#### Local Development

```bash
# Install Redis
brew install redis  # macOS
sudo apt-get install redis-server  # Ubuntu

# Start Redis
redis-server

# Test connection
redis-cli ping
```

#### Docker

```yaml
# docker-compose.yml
services:
  redis:
    image: redis:7-alpine
    command: redis-server --requirepass your_secure_password
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
```

### Django Cache Configuration

```python
# settings.py

CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/0',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {
                'max_connections': 50,
                'retry_on_timeout': True,
                'socket_connect_timeout': 5,
                'socket_timeout': 5,
            },
            'SOCKET_CONNECT_TIMEOUT': 5,
            'SOCKET_TIMEOUT': 5,
            'COMPRESSOR': 'django_redis.compressors.zlib.ZlibCompressor',
            'IGNORE_EXCEPTIONS': True,
        }
    }
}

# Cache timeout settings
CACHE_TIMEOUT = 300  # 5 minutes
CACHE_TIMEOUT_LONG = 3600  # 1 hour
CACHE_TIMEOUT_VERY_LONG = 86400  # 24 hours
```

### Cache Strategies

```python
# Cache article list
from django.views.decorators.cache import cache_page

@cache_page(60 * 5)  # 5 minutes
def article_list(request):
    articles = Article.objects.filter(status='published')
    return render(request, 'article_list.html', {'articles': articles})

# Cache individual articles
from django.core.cache import cache

def get_article(slug):
    cache_key = f'article_{slug}'
    article = cache.get(cache_key)
    
    if article is None:
        article = Article.objects.get(slug=slug)
        cache.set(cache_key, article, 3600)  # 1 hour
    
    return article
```

---

## Celery Configuration

### Basic Setup

```python
# habernexus_config/celery.py

import os
from celery import Celery
from celery.schedules import crontab

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'habernexus_config.settings')

app = Celery('habernexus')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

# Celery configuration
app.conf.update(
    CELERY_BROKER_URL=os.getenv('CELERY_BROKER_URL'),
    CELERY_RESULT_BACKEND=os.getenv('CELERY_RESULT_BACKEND'),
    CELERY_ACCEPT_CONTENT=['json'],
    CELERY_TASK_SERIALIZER='json',
    CELERY_RESULT_SERIALIZER='json',
    CELERY_TIMEZONE='UTC',
    CELERY_ENABLE_UTC=True,
    CELERY_TASK_TRACK_STARTED=True,
    CELERY_TASK_TIME_LIMIT=30 * 60,  # 30 minutes
    CELERY_TASK_SOFT_TIME_LIMIT=25 * 60,  # 25 minutes
)
```

### Scheduled Tasks

```python
# habernexus_config/celery.py

app.conf.beat_schedule = {
    'fetch-rss-feeds': {
        'task': 'news.tasks_v2.fetch_rss_feeds_v2',
        'schedule': crontab(minute='*/15'),  # Every 15 minutes
        'options': {'queue': 'default', 'priority': 10}
    },
    'score-headlines': {
        'task': 'news.tasks_v2.score_headlines',
        'schedule': crontab(minute=0),  # Every hour
        'options': {'queue': 'default', 'priority': 9}
    },
    'classify-headlines': {
        'task': 'news.tasks_v2.classify_headlines',
        'schedule': crontab(minute='*/30'),  # Every 30 minutes
        'options': {'queue': 'default', 'priority': 8}
    },
    'cleanup-old-logs': {
        'task': 'core.tasks.cleanup_old_logs',
        'schedule': crontab(day_of_week=1, hour=2, minute=0),  # Monday 2 AM
        'options': {'queue': 'default', 'priority': 1}
    },
}
```

### Queue Configuration

```python
# settings.py

CELERY_QUEUES = {
    'default': {
        'exchange': 'default',
        'routing_key': 'default',
        'priority': 10,
    },
    'high_priority': {
        'exchange': 'high_priority',
        'routing_key': 'high_priority',
        'priority': 20,
    },
    'low_priority': {
        'exchange': 'low_priority',
        'routing_key': 'low_priority',
        'priority': 1,
    },
    'video_processing': {
        'exchange': 'video_processing',
        'routing_key': 'video_processing',
        'priority': 5,
    },
}

CELERY_DEFAULT_QUEUE = 'default'
CELERY_DEFAULT_EXCHANGE = 'default'
CELERY_DEFAULT_ROUTING_KEY = 'default'
```

### Worker Configuration

```bash
# Start worker
celery -A habernexus_config worker -l info

# Start worker with specific queue
celery -A habernexus_config worker -Q default,high_priority -l info

# Start worker with concurrency limit
celery -A habernexus_config worker -c 4 -l info

# Start beat scheduler
celery -A habernexus_config beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
```

---

## API Keys and Secrets

### Google Gemini API

```bash
# Get API key from Google Cloud Console
# https://console.cloud.google.com/

# Set in .env
GOOGLE_GEMINI_API_KEY=your_api_key_here

# Usage in code
import google.generativeai as genai

genai.configure(api_key=os.getenv('GOOGLE_GEMINI_API_KEY'))
model = genai.GenerativeModel('gemini-2.5-flash')
```

### Secret Key Generation

```bash
# Generate a new Django secret key
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

# Or use this Python snippet
import secrets
print(secrets.token_urlsafe(50))
```

### Managing Secrets

```python
# settings.py

# Load secrets from environment
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')
if not SECRET_KEY:
    raise ValueError("DJANGO_SECRET_KEY environment variable is not set")

# Use python-decouple for better secret management
from decouple import config

SECRET_KEY = config('DJANGO_SECRET_KEY')
DEBUG = config('DEBUG', default=False, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost').split(',')
```

---

## Email Configuration

### SMTP Configuration

```python
# settings.py

EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = os.getenv('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', 587))
EMAIL_USE_TLS = os.getenv('EMAIL_USE_TLS', True)
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD')
DEFAULT_FROM_EMAIL = os.getenv('DEFAULT_FROM_EMAIL', 'noreply@habernexus.com')
```

### Gmail Configuration

```ini
# .env
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your_email@gmail.com
EMAIL_HOST_PASSWORD=your_app_password
```

**Note:** Use App Password, not your Gmail password. Generate at: https://myaccount.google.com/apppasswords

### Sending Emails

```python
# views.py or tasks.py

from django.core.mail import send_mail

send_mail(
    subject='Welcome to Haber Nexus',
    message='Thank you for signing up!',
    from_email='noreply@habernexus.com',
    recipient_list=['user@example.com'],
    fail_silently=False,
)
```

---

## Security Settings

### HTTPS/SSL Configuration

```python
# settings.py (Production)

SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_SECURITY_POLICY = {
    'default-src': ("'self'",),
    'script-src': ("'self'", "'unsafe-inline'"),
    'style-src': ("'self'", "'unsafe-inline'"),
}
```

### CORS Configuration

```python
# settings.py

INSTALLED_APPS = [
    ...
    'corsheaders',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    ...
]

CORS_ALLOWED_ORIGINS = [
    'https://habernexus.com',
    'https://www.habernexus.com',
]
```

### CSRF Protection

```python
# settings.py

CSRF_TRUSTED_ORIGINS = [
    'https://habernexus.com',
    'https://www.habernexus.com',
]

CSRF_COOKIE_HTTPONLY = True
CSRF_COOKIE_SECURE = True
```

---

## Logging Configuration

### Basic Logging

```python
# settings.py

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
    },
    'filters': {
        'require_debug_false': {
            '()': 'django.utils.log.RequireDebugFalse',
        },
        'require_debug_true': {
            '()': 'django.utils.log.RequireDebugTrue',
        },
    },
    'handlers': {
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'simple'
        },
        'file': {
            'level': 'ERROR',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': 'logs/django.log',
            'maxBytes': 1024 * 1024 * 15,  # 15MB
            'backupCount': 10,
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
        'news.tasks': {
            'handlers': ['console', 'file'],
            'level': 'DEBUG',
            'propagate': False,
        },
    },
}
```

### Celery Logging

```python
# habernexus_config/celery.py

app.conf.update(
    CELERY_WORKER_LOG_FORMAT='[%(asctime)s: %(levelname)s/%(processName)s] %(message)s',
    CELERY_WORKER_TASK_LOG_FORMAT='[%(asctime)s: %(levelname)s/%(processName)s][%(task_name)s(%(task_id)s)] %(message)s',
)
```

---

## Docker Configuration

### Docker Compose

```yaml
# docker-compose.yml

version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    build: .
    command: gunicorn habernexus_config.wsgi:application --bind 0.0.0.0:8000
    environment:
      - DEBUG=${DEBUG}
      - DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}
      - DB_ENGINE=${DB_ENGINE}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_HOST=postgres
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "8000:8000"

  celery:
    build: .
    command: celery -A habernexus_config worker -l info
    environment:
      - DEBUG=${DEBUG}
      - DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}
      - DB_ENGINE=${DB_ENGINE}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_HOST=postgres
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
    depends_on:
      - postgres
      - redis

  celery_beat:
    build: .
    command: celery -A habernexus_config beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
    environment:
      - DEBUG=${DEBUG}
      - DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}
      - DB_ENGINE=${DB_ENGINE}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_HOST=postgres
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
    depends_on:
      - postgres
      - redis

volumes:
  postgres_data:
  redis_data:
```

---

## Configuration Validation

### Pre-Deployment Checklist

```bash
# Check environment variables
python manage.py check --deploy

# Verify database connection
python manage.py dbshell

# Test Redis connection
python -c "import redis; r = redis.from_url(os.getenv('REDIS_URL')); print(r.ping())"

# Test Gemini API
python -c "import google.generativeai as genai; genai.configure(api_key=os.getenv('GOOGLE_GEMINI_API_KEY')); print('API OK')"

# Collect static files
python manage.py collectstatic --noinput

# Run migrations
python manage.py migrate
```

---

## Support

For configuration issues:

- **Email:** salihtanriseven25@gmail.com
- **GitHub Issues:** https://github.com/sata2500/habernexus/issues
- **Documentation:** See `docs/` folder
