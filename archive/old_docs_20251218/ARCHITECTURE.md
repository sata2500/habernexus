# System Architecture

This document explains the technical architecture and components of HaberNexus.

---

## System Overview

HaberNexus is built on a microservices architecture with the following layers:

- **Edge Layer:** Cloudflare (optional) + Nginx Proxy Manager
- **Web Layer:** Nginx + Django (Gunicorn)
- **Data Layer:** PostgreSQL + Elasticsearch
- **Async Layer:** Redis + Celery + Celery Beat
- **Monitoring Layer:** Prometheus + Grafana
- **Task Monitoring:** Flower

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    CLOUDFLARE (Optional)                    │
│  - Tunnel (No port forwarding)                              │
│  - DNS Management                                           │
│  - SSL Termination                                          │
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
│  │  Nginx Web Server (Port 80/443)                        │ │
│  │  - Reverse Proxy to Django                            │ │
│  │  - Static file serving                                │ │
│  │  - SSL/TLS termination                                │ │
│  │  - Gzip compression                                   │ │
│  │  - Rate limiting                                      │ │
│  └────────────────────────────────────────────────────────┘ │
│                       ↓                                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Django Application (Port 8000)                        │ │
│  │  - Web interface                                      │ │
│  │  - Admin panel                                        │ │
│  │  - REST API                                           │ │
│  │  - Business logic                                     │ │
│  └────────────────────────────────────────────────────────┘ │
│         ↓                    ↓                    ↓          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ PostgreSQL   │  │ Redis        │  │ Elasticsearch│     │
│  │ (Port 5432)  │  │ (Port 6379)  │  │ (Port 9200)  │     │
│  │ - Data Store │  │ - Cache      │  │ - Search     │     │
│  │ - Logs       │  │ - Broker     │  │ - Analytics  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Celery Workers (Async Task Processing)               │ │
│  │  - Content generation                                 │ │
│  │  - RSS feed processing                                │ │
│  │  - Image generation                                   │ │
│  │  - Email sending                                      │ │
│  │  - Cleanup tasks                                      │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Celery Beat (Task Scheduler)                         │ │
│  │  - Schedule periodic tasks                            │ │
│  │  - Content generation schedule                        │ │
│  │  - Cleanup schedule                                   │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Monitoring Stack                                      │ │
│  │  - Prometheus (Port 9090) - Metrics                   │ │
│  │  - Grafana (Port 3000) - Dashboards                   │ │
│  │  - Flower (Port 5555) - Task monitoring               │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Cloudflared (Tunnel Connector - if using Tunnel)     │ │
│  │  - Cloudflare Tunnel connection                       │ │
│  │  - Traffic routing                                    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Cloudflare (Optional Edge Layer)

**Purpose:** Secure tunnel and DDoS protection

**Features:**
- Tunnel: No port forwarding required
- DNS Management: CNAME records
- SSL Termination: Cloudflare SSL
- DDoS Protection: Automatic

**When to Use:**
- No static IP
- Can't open ports
- Need DDoS protection

---

### 2. Nginx Proxy Manager

**Purpose:** GUI-based reverse proxy and SSL management

**Features:**
- Web-based admin panel (Port 81)
- Automatic SSL certificates (Let's Encrypt)
- DNS Challenge support (Cloudflare)
- Proxy host management
- Access lists and basic auth
- Wildcard certificate support

**Database Options:**
- SQLite (default, recommended)
- PostgreSQL (advanced)
- MySQL/MariaDB (enterprise)

**Configuration:** `config/docker-compose.npm.yml`

---

### 3. Nginx Web Server

**Purpose:** Reverse proxy and static file serving

**Responsibilities:**
- HTTP/HTTPS request handling
- Proxy to Django application
- Static file serving (CSS, JS, images)
- SSL/TLS encryption
- Gzip compression
- Rate limiting
- Security headers

**Configuration:** `nginx/nginx.conf`, `nginx/conf.d/`

**Ports:** 80 (HTTP), 443 (HTTPS)

---

### 4. Django Application

**Purpose:** Web application and business logic

**Components:**
- `habernexus_config/`: Project configuration
- `core/`: System settings and logging
- `news/`: News management and generation
- `authors/`: Author management
- `templates/`: HTML templates
- `static/`: CSS, JS, images

**Server:** Gunicorn (Port 8000, behind Nginx)

**Features:**
- Admin panel
- REST API
- User authentication
- Content management
- RSS feed management

---

### 5. PostgreSQL Database

**Purpose:** Primary data storage

**Responsibilities:**
- Application data
- User accounts
- News articles
- RSS sources
- Celery Beat schedules
- System logs

**Port:** 5432

**Key Tables:**
- `core_setting`: System settings
- `core_systemlog`: Logs
- `news_article`: Articles
- `news_rsssource`: RSS sources
- `authors_author`: Authors
- `django_celery_beat_*`: Schedules

---

### 6. Redis

**Purpose:** Cache and message broker

**Responsibilities:**
- Celery task queue (Broker)
- Task result storage (Result Backend)
- Session cache
- Application cache

**Port:** 6379

---

### 7. Celery Workers

**Purpose:** Asynchronous task processing

**Responsibilities:**
- Content generation
- RSS feed processing
- Image generation
- Email sending
- Cleanup tasks

**Task Queues:**
- `default`: General tasks
- `video_processing`: Video tasks (isolated)

**Key Tasks:**
- `fetch_rss_feeds`: Fetch RSS sources
- `generate_ai_content`: Generate articles
- `process_video_content`: Process videos
- `cleanup_old_logs`: Clean logs

---

### 8. Celery Beat

**Purpose:** Task scheduling

**Responsibilities:**
- Schedule periodic tasks
- Content generation schedule
- Cleanup schedule
- RSS feed refresh schedule

**Configuration:** `habernexus_config/celery.py`

---

### 9. Elasticsearch

**Purpose:** Full-text search

**Responsibilities:**
- Article indexing
- Search functionality
- Analytics

**Port:** 9200

---

### 10. Prometheus

**Purpose:** Metrics collection

**Responsibilities:**
- System metrics
- Application metrics
- Database metrics
- Container metrics

**Port:** 9090

**Configuration:** `config/prometheus.yml`

---

### 11. Grafana

**Purpose:** Metrics visualization

**Responsibilities:**
- Dashboard creation
- Alerting
- Data visualization

**Port:** 3000

**Default Login:**
- Username: `admin`
- Password: `admin`

---

### 12. Flower

**Purpose:** Celery task monitoring

**Responsibilities:**
- Task monitoring
- Worker status
- Task history
- Performance metrics

**Port:** 5555

---

## Data Flow

### Content Generation Pipeline

```
1. RSS Feed Fetch
   └─ Celery Task: fetch_rss_feeds
   └─ Source: RSS sources in database
   └─ Output: Raw feed items

2. Content Processing
   └─ Celery Task: generate_ai_content
   └─ Input: Raw feed items
   └─ Process: Google Gemini AI
   └─ Output: Generated articles

3. Database Storage
   └─ Store in PostgreSQL
   └─ Index in Elasticsearch
   └─ Cache in Redis

4. Web Display
   └─ Django fetches from database
   └─ Renders HTML templates
   └─ Serves via Nginx
```

### Request Flow

```
1. User Request
   └─ Cloudflare (if enabled)
   └─ Nginx Proxy Manager (if enabled)
   └─ Nginx Web Server
   └─ Django Application
   └─ PostgreSQL/Redis/Elasticsearch

2. Response
   └─ Django renders response
   └─ Nginx compresses (gzip)
   └─ Returns to user
```

---

## Deployment Options

### Option 1: Cloudflare Tunnel + Nginx Proxy Manager (Recommended)

**Architecture:**
```
Cloudflare Tunnel
    ↓
Nginx Proxy Manager (Port 81)
    ↓
Nginx Web Server (Port 80/443)
    ↓
Django Application (Port 8000)
```

**Advantages:**
- No port forwarding
- GUI management
- Automatic SSL
- DDoS protection

---

### Option 2: Cloudflare Tunnel + Direct Nginx

**Architecture:**
```
Cloudflare Tunnel
    ↓
Nginx Web Server (Port 80/443)
    ↓
Django Application (Port 8000)
```

**Advantages:**
- No port forwarding
- Minimal resources
- Simple setup

---

### Option 3: Direct Port Forwarding

**Architecture:**
```
Nginx Web Server (Port 80/443)
    ↓
Django Application (Port 8000)
```

**Advantages:**
- Direct control
- No Cloudflare dependency
- Simple architecture

**Requirements:**
- Static IP
- Open ports 80 and 443

---

## Network Architecture

### Docker Network

All containers communicate via `habernexus_network` bridge:

```
habernexus_network (Bridge)
├── app (Django)
├── postgres (Database)
├── redis (Cache)
├── celery (Workers)
├── celery_beat (Scheduler)
├── flower (Monitoring)
├── nginx (Web Server)
├── nginx_proxy_manager (Reverse Proxy)
├── cloudflared (Tunnel)
├── prometheus (Metrics)
├── grafana (Dashboards)
└── elasticsearch (Search)
```

### Port Mapping

| Service | Internal Port | External Port | Access |
|---------|---------------|---------------|--------|
| Nginx | 80, 443 | 80, 443 | Public |
| Django | 8000 | - | Internal |
| PostgreSQL | 5432 | - | Internal |
| Redis | 6379 | - | Internal |
| Elasticsearch | 9200 | - | Internal |
| Prometheus | 9090 | 9090 | Internal |
| Grafana | 3000 | 3000 | Internal |
| Flower | 5555 | 5555 | Internal |
| NPM Admin | 81 | 81 | Internal |

---

## Volume Management

### Persistent Volumes

```
Volumes:
├── postgres_data
│   └─ PostgreSQL database files
├── redis_data
│   └─ Redis persistence (optional)
├── static_volume
│   └─ Django static files
├── media_volume
│   └─ User uploaded files
├── npm_data
│   └─ Nginx Proxy Manager config
└── npm_letsencrypt
    └─ SSL certificates
```

---

## Security Architecture

### SSL/TLS

**Options:**
1. Cloudflare SSL (if using Tunnel)
2. Let's Encrypt (via Nginx Proxy Manager)
3. Self-signed (development)

**Renewal:** Automatic via Let's Encrypt

### Network Security

- Rate limiting (Nginx)
- Security headers (HSTS, CSP, X-Frame-Options)
- CORS configuration
- Input validation (Django)

### Database Security

- Strong password requirements
- Database encryption
- Backup encryption
- Access control

---

## Scalability Considerations

### Horizontal Scaling

To scale the application:

1. **Add Celery Workers**
   ```bash
   docker compose up -d --scale celery=3
   ```

2. **Add Nginx Instances**
   - Use load balancer
   - Multiple Nginx containers

3. **Database Replication**
   - PostgreSQL replication
   - Read replicas for scaling

### Vertical Scaling

- Increase container resource limits
- Increase host machine resources
- Optimize database queries

---

## Monitoring and Observability

### Metrics Collection

- Prometheus scrapes metrics from:
  - Node Exporter (system metrics)
  - cAdvisor (container metrics)
  - Django application
  - PostgreSQL

### Dashboards

- Grafana dashboards for visualization
- Flower for task monitoring
- Django admin for application monitoring

### Alerting

- Prometheus alerting rules
- Grafana alert notifications
- Email alerts (configurable)

---

## Backup and Recovery

### Backup Strategy

- Daily database backups
- File system backups
- Compressed archives
- Encrypted storage

### Recovery Process

1. Stop containers
2. Extract backup
3. Restore database
4. Restore files
5. Start containers
6. Verify restoration

---

## Performance Optimization

### Caching Strategy

- Redis for session cache
- Elasticsearch for search cache
- Browser cache (static files)
- CDN cache (Cloudflare)

### Database Optimization

- Indexed queries
- Query optimization
- Connection pooling
- Slow query logging

### Application Optimization

- Gzip compression
- Static file minification
- Lazy loading
- Asynchronous processing

---

## Technology Stack Summary

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Django | 5.0 |
| Language | Python | 3.11 |
| Database | PostgreSQL | 16 |
| Cache | Redis | 7 |
| Task Queue | Celery | 5.4 |
| Scheduler | Celery Beat | 2.6 |
| Web Server | Nginx | Alpine |
| App Server | Gunicorn | 22.0 |
| Reverse Proxy | Nginx Proxy Manager | Latest |
| Tunnel | Cloudflare Tunnel | Latest |
| Search | Elasticsearch | 8.0 |
| Monitoring | Prometheus | Latest |
| Visualization | Grafana | Latest |
| Task Monitor | Flower | 2.0 |
| Containerization | Docker | Latest |
| Orchestration | Docker Compose | v2 |

---

## Support

- **GitHub Issues:** https://github.com/sata2500/habernexus/issues
- **Email:** salihtanriseven25@gmail.com
- **Documentation:** https://github.com/sata2500/habernexus/tree/main/docs

---

**Last Updated:** December 14, 2024  
**Version:** 4.0
