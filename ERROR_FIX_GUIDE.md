# HaberNexus - Hata Düzeltme Rehberi

**Tarih:** 14 Aralık 2025  
**Amaç:** Tespit edilen tüm hataların düzeltilmesi ve kod kalitesinin iyileştirilmesi

---

## 📋 Hata Düzeltme Özeti

| Hata Türü | Sayı | Öncelik | Durum |
|-----------|------|---------|-------|
| Bare Except (E722) | 3 | 🔴 Yüksek | ⏳ Beklemede |
| Tanımsız Değişken (F821) | 2 | 🔴 Yüksek | ⏳ Beklemede |
| Kullanılmayan İmport (F401) | 38 | 🟡 Orta | ⏳ Beklemede |
| Atanmış ama Kullanılmayan Var (F841) | 4 | 🟡 Orta | ⏳ Beklemede |
| Trailing Whitespace (W291) | 4 | 🟢 Düşük | ⏳ Beklemede |
| Black Formatting | 4 | 🟢 Düşük | ⏳ Beklemede |
| **Toplam** | **55** | | |

---

## 🔴 Yüksek Öncelikli Hatalar

### 1. Bare Except Clauses (E722)

#### Dosya: `news/monitoring.py`

**Hata 1 - Satır 243:**
```python
# ❌ Hatalı
try:
    # kod
except:
    pass
```

**Çözüm:**
```python
# ✅ Doğru
try:
    # kod
except Exception as e:
    logger.error(f"Monitoring error: {e}")
```

#### Dosya: `news/quality_monitoring.py`

**Hata 2 - Satır 55:**
```python
# ❌ Hatalı
try:
    # kod
except:
    pass
```

**Hata 3 - Satır 65:**
```python
# ❌ Hatalı
try:
    # kod
except:
    pass
```

**Çözüm:**
```python
# ✅ Doğru
try:
    # kod
except (ValueError, TypeError) as e:
    logger.warning(f"Quality check error: {e}")
```

#### Dosya: `news/quality_utils.py`

**Hata 4 - Satır 47:**
```python
# ❌ Hatalı
try:
    # kod
except:
    pass
```

**Çözüm:**
```python
# ✅ Doğru
try:
    # kod
except Exception as e:
    logger.error(f"Quality utils error: {e}")
```

---

### 2. Tanımsız Değişkenler (F821)

#### Dosya: `news/monitoring.py`

**Hata 1 - Satır 106:**
```python
# ❌ Hatalı
from django.db.models import Count  # Sum import edilmemiş
# ...
Sum(...)  # F821 - Tanımsız
```

**Hata 2 - Satır 188-189:**
```python
# ❌ Hatalı
Sum(...)  # F821 - Tanımsız
```

**Çözüm:**
```python
# ✅ Doğru
from django.db.models import Count, Sum

# ...
Sum(...)  # Artık tanımlı
```

---

## 🟡 Orta Öncelikli Hatalar

### 1. Kullanılmayan İmportlar (F401)

#### Dosya: `news/content_utils.py`

**Hata - Satır 16:**
```python
# ❌ Hatalı
import spacy  # Kullanılmıyor
```

**Çözüm:**
```python
# ✅ Doğru
# İmport silinmeli
```

#### Dosya: `news/media_processor.py`

**Hatalar:**
```python
# ❌ Hatalı
import json  # Kullanılmıyor
from pathlib import Path  # Kullanılmıyor
from typing import Optional  # Kullanılmıyor
```

**Çözüm:**
```python
# ✅ Doğru
# Kullanılmayan importları sil
```

#### Dosya: `news/models_advanced.py`

**Hatalar:**
```python
# ❌ Hatalı
from django.utils.timezone import ...  # Kullanılmıyor
from django.utils.text.slugify import ...  # Kullanılmıyor
```

#### Dosya: `news/monitoring.py`

**Hatalar:**
```python
# ❌ Hatalı
from django.db.models import F  # Kullanılmıyor
from .models_extended import ContentQualityMetrics  # Kullanılmıyor
```

#### Dosya: `news/quality_monitoring.py`

**Hatalar:**
```python
# ❌ Hatalı
from typing import Optional  # Kullanılmıyor
from django.db.models import F  # Kullanılmıyor
from news.models_advanced import ArticleSEO  # Kullanılmıyor
```

#### Dosya: `news/tasks_advanced.py`

**Hatalar:**
```python
# ❌ Hatalı
from datetime import timedelta  # Kullanılmıyor
from django.core.cache import cache  # Kullanılmıyor
from django.db import transaction  # Kullanılmıyor
from django.utils import timezone  # Kullanılmıyor
from celery import chord, group  # Kullanılmıyor
from news.models import RssSource  # Kullanılmıyor
```

#### Dosya: `news/tasks_v2.py`

**Hatalar:**
```python
# ❌ Hatalı
import requests  # Kullanılmıyor
from celery import chord  # Kullanılmıyor
from PIL import Image  # Kullanılmıyor
from authors.models import Author  # Kullanılmıyor
```

#### Dosya: `news/tests/test_content_generation_v2.py`

**Hatalar:**
```python
# ❌ Hatalı
from unittest.mock import MagicMock, patch  # Kullanılmıyor
from django.utils import timezone  # Kullanılmıyor
import pytest  # Kullanılmıyor
from news.tasks_v2 import score_single_headline  # Kullanılmıyor
```

**Çözüm:**
```bash
# Tüm kullanılmayan importları otomatik olarak kaldır
python3 -m autoflake --in-place --remove-all-unused-imports -r .
```

---

### 2. Atanmış ama Kullanılmayan Değişkenler (F841)

#### Dosya: `news/tasks_advanced.py`

**Hata 1 - Satır 137:**
```python
# ❌ Hatalı
summary = generate_summary()  # Atanıyor ama kullanılmıyor
```

**Hata 2 - Satır 349:**
```python
# ❌ Hatalı
image_prompt = create_prompt()  # Atanıyor ama kullanılmıyor
```

**Hata 3 - Satır 352:**
```python
# ❌ Hatalı
client = get_client()  # Atanıyor ama kullanılmıyor
```

**Hata 4 - Satır 395:**
```python
# ❌ Hatalı
content = generate_content()  # Atanıyor ama kullanılmıyor
```

**Çözüm:**
```python
# ✅ Doğru - Değişkeni kaldır veya kullan
# Eğer kullanılmıyorsa:
_ = generate_summary()  # Kasıtlı olarak kullanılmadığını göster

# Eğer kullanılmalıysa:
summary = generate_summary()
return summary  # Veya başka şekilde kullan
```

#### Dosya: `news/tasks_v2.py`

**Hata 1 - Satır 95:**
```python
# ❌ Hatalı
headline_score = calculate_score()  # Kullanılmıyor
```

**Hata 2 - Satır 356:**
```python
# ❌ Hatalı
result = process_data()  # Kullanılmıyor
```

---

## 🟢 Düşük Öncelikli Hatalar

### 1. Trailing Whitespace (W291)

#### Dosya: `news/content_utils.py`

**Hatalar - Satırlar 477-480:**
```python
# ❌ Hatalı (sondaki boşluk)
line = "something"   
another_line = "text"  

# ✅ Doğru
line = "something"
another_line = "text"
```

**Çözüm:**
```bash
# Otomatik olarak düzelt
python3 -m black . --exclude migrations
```

#### Dosya: `news/tests/test_content_generation_v2.py`

**Hata - Satır 104:**
```python
# ❌ Hatalı
test_data = {...}  

# ✅ Doğru
test_data = {...}
```

---

### 2. Black Formatting

#### Dosyalar:
- `authors/migrations/0001_initial.py`
- `core/migrations/0001_initial.py`
- `news/migrations/0001_initial.py`
- `news/migrations/0002_articleclassification_contentqualitymetrics_and_more.py`

**Çözüm:**
```bash
# Tüm dosyaları otomatik olarak formatla
python3 -m black . --exclude migrations

# Veya migration dosyalarını da formatla
python3 -m black .
```

---

## 🛠️ Otomatik Düzeltme Komutları

### 1. Tüm Hataları Otomatik Düzelt

```bash
cd /home/ubuntu/habernexus

# 1. Black formatting
python3 -m black . --exclude migrations

# 2. isort (import sıralama)
python3 -m isort . --skip migrations

# 3. Kullanılmayan importları kaldır (autoflake yüklü değilse)
# pip install autoflake
# autoflake --in-place --remove-all-unused-imports -r .
```

### 2. Adım Adım Düzeltme

```bash
# 1. Adım: Bare except clauses'ı düzelt
# Dosyaları manuel olarak düzelt veya sed kullan
sed -i 's/except:/except Exception as e:/g' news/monitoring.py
sed -i 's/except:/except Exception as e:/g' news/quality_monitoring.py
sed -i 's/except:/except Exception as e:/g' news/quality_utils.py

# 2. Adım: Tanımsız değişkenleri düzelt
# Dosyaları manuel olarak düzelt

# 3. Adım: Kullanılmayan importları kaldır
# Dosyaları manuel olarak düzelt

# 4. Adım: Atanmış ama kullanılmayan değişkenleri düzelt
# Dosyaları manuel olarak düzelt

# 5. Adım: Trailing whitespace'i temizle
python3 -m black . --exclude migrations

# 6. Adım: Kontrol et
python3 -m flake8 . --exclude=migrations,__pycache__ --max-line-length=120
```

---

## ✅ Doğrulama Adımları

### 1. Flake8 Kontrol
```bash
cd /home/ubuntu/habernexus
python3 -m flake8 . --exclude=migrations,__pycache__ --max-line-length=120 --count
```

**Beklenen Sonuç:** 0 hata

### 2. Black Kontrol
```bash
python3 -m black --check . --exclude migrations
```

**Beklenen Sonuç:** All done! ✨

### 3. isort Kontrol
```bash
python3 -m isort --check-only . --skip migrations
```

**Beklenen Sonuç:** Skipped 4 files (migration dosyaları)

### 4. Pylint Kontrol
```bash
python3 -m pylint news/models.py --disable=all --enable=E,F
```

**Beklenen Sonuç:** 10/10 veya daha yüksek

### 5. Test Çalıştır
```bash
pytest --cov=. --cov-report=term-missing
```

**Beklenen Sonuç:** Tüm testler geçmeli

---

## 📋 Düzeltme Kontrol Listesi

### Yüksek Öncelikli

- [ ] `news/monitoring.py` - Bare except düzelt (satır 243)
- [ ] `news/monitoring.py` - Sum import ekle (satır 106, 188, 189)
- [ ] `news/quality_monitoring.py` - Bare except düzelt (satır 55, 65)
- [ ] `news/quality_utils.py` - Bare except düzelt (satır 47)

### Orta Öncelikli

- [ ] Tüm kullanılmayan importları kaldır (38 adet)
- [ ] Atanmış ama kullanılmayan değişkenleri düzelt (4 adet)

### Düşük Öncelikli

- [ ] Trailing whitespace'i temizle (4 adet)
- [ ] Black formatting uygula (4 migration dosyası)

### Doğrulama

- [ ] Flake8 kontrol - 0 hata
- [ ] Black kontrol - All done
- [ ] isort kontrol - Başarılı
- [ ] Pylint kontrol - 9+/10
- [ ] Testler - Tümü geçmeli
- [ ] Coverage - %71+ hedefinde

---

## 🔐 Güvenlik İyileştirmeleri

### Production Settings

```python
# habernexus_config/settings.py

# HTTPS Zorunluluğu
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# HSTS
SECURE_HSTS_SECONDS = 31536000  # 1 yıl
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Diğer Security Headers
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_SECURITY_POLICY = {
    'default-src': ("'self'",),
    'script-src': ("'self'", "'unsafe-inline'"),
    'style-src': ("'self'", "'unsafe-inline'"),
}
```

### Nginx Security Headers

```nginx
# config/nginx.conf

add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```

---

## 📊 İlerleme Takibi

| Görev | Durum | Tarih | Notlar |
|-------|-------|-------|--------|
| Bare except düzelt | ⏳ | | |
| Tanımsız değişkenleri düzelt | ⏳ | | |
| Kullanılmayan importları kaldır | ⏳ | | |
| Atanmış ama kullanılmayan var düzelt | ⏳ | | |
| Trailing whitespace temizle | ⏳ | | |
| Black formatting uygula | ⏳ | | |
| Flake8 kontrol | ⏳ | | |
| Testler çalıştır | ⏳ | | |
| Coverage kontrol | ⏳ | | |
| Production ayarları ekle | ⏳ | | |

---

**Rapor Tarihi:** 14 Aralık 2025  
**Hazırlayan:** Manus AI  
**Durum:** ✅ **Hazır - Uygulamaya Başlanabilir**
