# HaberNexus - Düzeltme ve Geliştirme Planı

**Tarih:** 22 Aralık 2025  
**Hazırlayan:** Manus AI  
**Versiyon:** 10.8.0 → 10.9.0

---

## 📋 Özet

Bu belge, HaberNexus projesinde tespit edilen sorunların düzeltilmesi ve güncel best practices'e uygun hale getirilmesi için yapılacak değişiklikleri içerir.

---

## 🔴 Kritik Düzeltmeler

### 1. Docker Compose Güncellemeleri

**Sorun:** `version:` field artık deprecated ve gereksiz.

**Dosyalar:**
- `docker-compose.yml`
- `docker-compose.prod.yml`
- `docker-compose.monitoring.yml`

**Değişiklikler:**
- [x] `version: '3.9'` satırını kaldır
- [x] Healthcheck'leri güncelle
- [x] Non-root user ekle (güvenlik)

### 2. Caddyfile Oluşturma

**Sorun:** `caddy/Caddyfile` dosyası eksik, sadece template'ler var.

**Değişiklikler:**
- [x] `caddy/Caddyfile.ip.template`'i varsayılan olarak kopyala
- [x] setup.sh'de otomatik Caddyfile oluşturma mantığını düzelt

### 3. Dockerfile Güncellemeleri

**Sorun:** Container root olarak çalışıyor (güvenlik riski).

**Değişiklikler:**
- [x] Non-root user oluştur ve kullan
- [x] Multi-stage build optimize et
- [x] .dockerignore dosyasını güncelle

### 4. Django Settings Güncellemeleri

**Sorun:** Production güvenlik ayarları eksik veya yanlış.

**Değişiklikler:**
- [x] `CSRF_COOKIE_SECURE` ve `SESSION_COOKIE_SECURE` ayarlarını düzelt
- [x] `SECURE_HSTS_*` ayarlarını ekle
- [x] `CONN_MAX_AGE` ekle (connection pooling)

### 5. Celery Yapılandırması Güncellemeleri

**Sorun:** Production için önerilen ayarlar eksik.

**Değişiklikler:**
- [x] `CELERY_TASK_ACKS_LATE = True` ekle
- [x] `CELERY_WORKER_PREFETCH_MULTIPLIER = 1` ekle
- [x] `CELERY_WORKER_MAX_TASKS_PER_CHILD` ekle

---

## 🟡 İyileştirmeler

### 6. PostgreSQL Healthcheck Güncellemesi

**Değişiklikler:**
- [x] Daha güvenilir healthcheck komutu

### 7. Redis Yapılandırması

**Değişiklikler:**
- [x] Healthcheck iyileştirmesi
- [x] Memory policy ayarları

### 8. Cloudflared Config Template

**Değişiklikler:**
- [x] Varsayılan config.yml oluştur

---

## 📁 Değiştirilecek Dosyalar

| Dosya | Değişiklik Türü | Öncelik |
|-------|-----------------|---------|
| `docker-compose.yml` | Güncelleme | Kritik |
| `docker-compose.prod.yml` | Güncelleme | Kritik |
| `Dockerfile` | Güncelleme | Kritik |
| `caddy/Caddyfile` | Yeni Dosya | Kritik |
| `.dockerignore` | Güncelleme | Orta |
| `habernexus_config/settings.py` | Güncelleme | Kritik |
| `docker-entrypoint.sh` | Güncelleme | Orta |
| `cloudflared/config.yml` | Yeni Dosya | Düşük |

---

## ✅ Uygulama Sırası

1. Docker Compose dosyalarını güncelle
2. Dockerfile'ı güncelle
3. Caddyfile oluştur
4. Django settings'i güncelle
5. docker-entrypoint.sh'i güncelle
6. .dockerignore'u güncelle
7. Testleri çalıştır
8. GitHub'a push et

---

## 🧪 Test Planı

1. `ruff check .` - Kod kalitesi kontrolü
2. `ruff format .` - Kod formatı
3. `pytest` - Unit testler
4. `docker compose -f docker-compose.prod.yml build` - Docker build testi
5. `docker compose -f docker-compose.prod.yml up -d` - Container başlatma testi
6. Health endpoint kontrolü

---
