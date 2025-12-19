#!/bin/bash
set -e

echo "=========================================="
echo "HaberNexus Docker Entrypoint"
echo "=========================================="

# Dizinlerin varlığını kontrol et ve oluştur
echo "→ Dizinler kontrol ediliyor..."
mkdir -p /app/staticfiles /app/media /app/logs
chmod -R 755 /app/staticfiles /app/media /app/logs 2>/dev/null || true

# Veritabanı bağlantısını bekle
echo "→ Veritabanı bağlantısı bekleniyor..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if python -c "
import os
import psycopg2
try:
    conn = psycopg2.connect(
        host=os.environ.get('DB_HOST', 'postgres'),
        port=os.environ.get('DB_PORT', '5432'),
        dbname=os.environ.get('DB_NAME', 'habernexus'),
        user=os.environ.get('DB_USER', 'habernexus_user'),
        password=os.environ.get('DB_PASSWORD', 'changeme')
    )
    conn.close()
    exit(0)
except:
    exit(1)
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
if not User.objects.filter(username='$DJANGO_SUPERUSER_USERNAME').exists():
    User.objects.create_superuser(
        username='$DJANGO_SUPERUSER_USERNAME',
        email='$DJANGO_SUPERUSER_EMAIL',
        password='$DJANGO_SUPERUSER_PASSWORD'
    )
    print('✓ Superuser oluşturuldu')
else:
    print('✓ Superuser zaten mevcut')
" 2>/dev/null || echo "⚠ Superuser kontrolü atlandı"
fi

echo "=========================================="
echo "✓ Başlatma tamamlandı, uygulama çalıştırılıyor..."
echo "=========================================="

# Ana komutu çalıştır
exec "$@"
