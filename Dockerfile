# Multi-stage build
FROM python:3.11-slim as builder

WORKDIR /app

# Sistem bağımlılıklarını yükle
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Python bağımlılıklarını yükle
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.11-slim

WORKDIR /app

# Node.js ve npm'i yükle (Tailwind CSS için)
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs \
    npm \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Builder stage'den Python paketlerini kopyala
COPY --from=builder /root/.local /root/.local

# PATH'i güncelle
ENV PATH=/root/.local/bin:$PATH

# Proje dosyalarını kopyala
COPY . .

# Statik dosyaları topla
RUN python manage.py collectstatic --noinput 2>/dev/null || true

# Gunicorn'u başlat
CMD ["gunicorn", "habernexus_config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "4"]
