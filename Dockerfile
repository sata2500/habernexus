# =============================================================================
# HaberNexus v10.9 - Production Dockerfile
# Multi-stage build with non-root user for security
# Updated: December 2025
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Builder - Install dependencies
# -----------------------------------------------------------------------------
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# -----------------------------------------------------------------------------
# Stage 2: Production - Final image
# -----------------------------------------------------------------------------
FROM python:3.11-slim AS production

# Labels
LABEL maintainer="Salih TANRISEVEN <salihtanriseven25@gmail.com>"
LABEL version="10.9.0"
LABEL description="HaberNexus - AI-powered news aggregation platform"

# Create non-root user for security
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} appgroup && \
    useradd -m -u ${UID} -g appgroup -s /bin/bash appuser

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    postgresql-client \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application code
COPY --chown=appuser:appgroup . .

# Create necessary directories with proper permissions
RUN mkdir -p /app/staticfiles /app/media /app/logs && \
    chown -R appuser:appgroup /app/staticfiles /app/media /app/logs && \
    chmod -R 755 /app/staticfiles /app/media /app/logs

# Copy and set entrypoint script
COPY --chown=appuser:appgroup docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    DJANGO_SETTINGS_MODULE=habernexus_config.settings \
    # Gunicorn settings
    GUNICORN_WORKERS=4 \
    GUNICORN_THREADS=2 \
    GUNICORN_TIMEOUT=120

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health/', timeout=5)" || exit 1

# Switch to non-root user
USER appuser

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["gunicorn", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "4", \
     "--threads", "2", \
     "--worker-class", "gthread", \
     "--worker-tmp-dir", "/dev/shm", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--capture-output", \
     "--enable-stdio-inheritance", \
     "habernexus_config.wsgi:application"]
