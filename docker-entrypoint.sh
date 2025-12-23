#!/bin/bash
set -e

echo "=========================================="
echo "HaberNexus Docker Entrypoint v10.9"
echo "=========================================="

# Dizinlerin varlığını kontrol et (non-root user için mkdir yerine sadece kontrol)
echo "→ Dizinler kontrol ediliyor..."
for dir in /app/staticfiles /app/media /app/logs; do
    if [ ! -d "$dir" ]; then
        echo "⚠ Dizin bulunamadı: $dir (Dockerfile'da oluşturulmalı)"
    fi
done

# Veritabanı bağlantısını bekle
echo "→ Veritabanı bağlantısı bekleniyor..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if python -c "
import os
import sys
try:
    import psycopg2
    conn = psycopg2.connect(
        host=os.environ.get('DB_HOST', 'postgres'),
        port=os.environ.get('DB_PORT', '5432'),
        dbname=os.environ.get('DB_NAME', 'habernexus'),
        user=os.environ.get('DB_USER', 'habernexus_user'),
        password=os.environ.get('DB_PASSWORD', 'changeme'),
        connect_timeout=5
    )
    conn.close()
    sys.exit(0)
except Exception as e:
    sys.exit(1)
" 2>/dev/null; then
        echo "✓ Veritabanı bağlantısı başarılı"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "  Veritabanı bekleniyor... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "✗ Veritabanına bağlanılamadı!"
    exit 1
fi

# Migration'ları çalıştır
echo "→ Migration'lar uygulanıyor..."
python manage.py migrate --noinput || {
    echo "✗ Migration hatası!"
    exit 1
}
echo "✓ Migration'lar tamamlandı"

# Static dosyaları topla
echo "→ Static dosyalar toplanıyor..."
python manage.py collectstatic --noinput --clear 2>/dev/null || python manage.py collectstatic --noinput || {
    echo "⚠ Static dosya toplama uyarısı (devam ediliyor)"
}
echo "✓ Static dosyalar toplandı"

# Superuser oluştur (eğer yoksa)
if [ -n "$DJANGO_SUPERUSER_USERNAME" ] && [ -n "$DJANGO_SUPERUSER_PASSWORD" ]; then
    echo "→ Superuser kontrol ediliyor..."
    python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
username = '$DJANGO_SUPERUSER_USERNAME'
email = '$DJANGO_SUPERUSER_EMAIL'
password = '$DJANGO_SUPERUSER_PASSWORD'
if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username=username, email=email, password=password)
    print('✓ Superuser oluşturuldu')
else:
    print('✓ Superuser zaten mevcut')
" 2>/dev/null || echo "⚠ Superuser kontrolü atlandı"
fi

# Django deployment check (optional, for debugging)
if [ "${DEBUG:-False}" = "False" ]; then
    echo "→ Django deployment kontrolü yapılıyor..."
    python manage.py check --deploy 2>/dev/null || echo "⚠ Deployment check uyarıları var (devam ediliyor)"
fi

echo "=========================================="
echo "✓ Başlatma tamamlandı, uygulama çalıştırılıyor..."
echo "=========================================="

# Ana komutu çalıştır
exec "$@"
