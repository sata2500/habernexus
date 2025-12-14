# Monitoring & Observability Guide

Haber Nexus includes a comprehensive monitoring stack to ensure system reliability and performance.

## Components

1. **Prometheus**: Collects metrics from Django, Celery, PostgreSQL, and Redis.
2. **Grafana**: Visualizes metrics through interactive dashboards.
3. **Flower**: Real-time monitoring for Celery tasks.

## Accessing Dashboards

| Service | URL | Default Credentials |
|---|---|---|
| **Grafana** | `http://your-domain:3000` | `admin` / `admin` |
| **Prometheus** | `http://your-domain:9090` | None |
| **Flower** | `http://your-domain:5555` | None (Protected by Nginx in prod) |

## Key Metrics to Watch

### Django App
- `django_http_requests_total_by_view_transport_method_total`: Request volume
- `django_http_requests_latency_seconds_by_view_method`: Response time

### Celery
- `celery_task_runtime_seconds`: Task execution duration
- `celery_queue_length`: Number of pending tasks

### System
- `process_cpu_seconds_total`: CPU usage
- `process_resident_memory_bytes`: Memory usage

## Setup

The monitoring stack is defined in `docker-compose.monitoring.yml`. To enable it:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```
