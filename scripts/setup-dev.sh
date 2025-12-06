#!/bin/bash

################################################################################
# Haber Nexus - Geliştirme Ortamı Kurulum Scripti (Test)
# Yerel geliştirme için SQLite ve otomatik kurulum
# Geliştirici: Salih TANRISEVEN
# Tarih: 2025-12-06
################################################################################

set -e

# ============================================================================
# RENKLER VE FONKSIYONLAR
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_step() { echo -e "\n${BLUE}==>${NC} $1"; }
log_section() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${CYAN}$1${NC}\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# ============================================================================
# BANNER
# ============================================================================

clear
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║              🚀 HABER NEXUS - GELİŞTİRME ORTAMI KURULUM 🚀                 ║
║                                                                              ║
║                   Otomatik Test Kurulumu (SQLite)                            ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF

# ============================================================================
# ÖN KONTROLLER
# ============================================================================

log_section "Ön Kontroller"

# Python kontrolü
if ! command -v python3 &> /dev/null; then
    log_error "Python3 bulunamadı. Lütfen Python3 kurun."
fi
log_info "Python3 bulundu: $(python3 --version)"

# Git kontrolü
if ! command -v git &> /dev/null; then
    log_error "Git bulunamadı. Lütfen Git kurun."
fi
log_info "Git bulundu: $(git --version)"

# Proje dizini kontrolü
if [ ! -f "manage.py" ]; then
    log_error "Bu script habernexus proje dizininde çalıştırılmalıdır."
fi
log_info "Proje dizini kontrol edildi."

# ============================================================================
# KURULUM AYARLARI (OTOMATİK)
# ============================================================================

log_section "Kurulum Ayarları (Otomatik Test)"

PROJECT_PATH=$(pwd)
VENV_DIR="$PROJECT_PATH/venv"
DB_FILE="$PROJECT_PATH/db.sqlite3"

log_info "Proje Dizini: $PROJECT_PATH"
log_info "Sanal Ortam: $VENV_DIR"
log_info "Veritabanı: $DB_FILE"

# ============================================================================
# ADIM 1: PYTHON SANAL ORTAMI
# ============================================================================

log_section "Adım 1: Python Sanal Ortamı Oluşturuluyor"

if [ -d "$VENV_DIR" ]; then
    log_warning "Sanal ortam zaten mevcut, silinip yeniden oluşturuluyor..."
    rm -rf "$VENV_DIR"
fi

log_step "Sanal ortam oluşturuluyor..."
python3 -m venv "$VENV_DIR"
log_info "Sanal ortam oluşturuldu."

log_step "pip güncelleştiriliyor..."
"$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel -q
log_info "pip güncelleştirildi."

# ============================================================================
# ADIM 2: BAĞIMLILIKLARI YÜKLEME
# ============================================================================

log_section "Adım 2: Python Bağımlılıkları Yükleniyor"

log_step "requirements.txt yükleniyor..."
if [ ! -f "requirements.txt" ]; then
    log_error "requirements.txt dosyası bulunamadı!"
fi

"$VENV_DIR/bin/pip" install -r requirements.txt -q
log_info "Bağımlılıklar yüklendi."

# ============================================================================
# ADIM 3: ORTAM DEĞIŞKENLERI
# ============================================================================

log_section "Adım 3: Ortam Değişkenleri Ayarlanıyor"

log_step ".env dosyası oluşturuluyor..."

cat > "$PROJECT_PATH/.env" <<'EOF'
# Django Ayarları (Geliştirme)
DEBUG=True
DJANGO_SECRET_KEY=dev-secret-key-habernexus-test-2025-change-in-production
ALLOWED_HOSTS=localhost,127.0.0.1

# Veritabanı (SQLite - Geliştirme)
DB_ENGINE=django.db.backends.sqlite3
DB_NAME=db.sqlite3

# Redis & Celery (Opsiyonel)
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# Google AI API
GOOGLE_API_KEY=test-api-key-not-configured

# Güvenlik (Geliştirme)
SECURE_SSL_REDIRECT=False
SESSION_COOKIE_SECURE=False
CSRF_COOKIE_SECURE=False
SECURE_HSTS_SECONDS=0
SECURE_HSTS_INCLUDE_SUBDOMAINS=False
SECURE_HSTS_PRELOAD=False

# Domain
DOMAIN=localhost
EOF

log_info ".env dosyası oluşturuldu."

# ============================================================================
# ADIM 4: VERİTABANI KURULUMU
# ============================================================================

log_section "Adım 4: Veritabanı Kurulumu"

log_step "Eski veritabanı temizleniyor..."
if [ -f "$DB_FILE" ]; then
    rm -f "$DB_FILE"
    log_info "Eski veritabanı silindi."
fi

log_step "Veritabanı migrasyonları çalıştırılıyor..."
"$VENV_DIR/bin/python" manage.py migrate --noinput
log_info "Veritabanı migrasyonları tamamlandı."

# ============================================================================
# ADIM 5: STATİK DOSYALARI TOPLAMA
# ============================================================================

log_section "Adım 5: Statik Dosyalar Toplanıyor"

log_step "Statik dosyalar toplanıyor..."
"$VENV_DIR/bin/python" manage.py collectstatic --noinput
log_info "Statik dosyalar toplandı."

# ============================================================================
# ADIM 6: ADMIN KULLANICISI OLUŞTURMA
# ============================================================================

log_section "Adım 6: Admin Kullanıcısı Oluşturuluyor"

log_step "Admin kullanıcısı oluşturuluyor..."
"$VENV_DIR/bin/python" manage.py createsuperuser --noinput \
    --username admin \
    --email test@habernexus.local 2>/dev/null || log_warning "Admin kullanıcısı zaten mevcut"

log_info "Admin kullanıcısı hazır (kullanıcı: admin)"

# ============================================================================
# ADIM 7: TESTLER
# ============================================================================

log_section "Adım 7: Testler Çalıştırılıyor"

log_step "Django sistem kontrolleri çalıştırılıyor..."
"$VENV_DIR/bin/python" manage.py check
log_info "Sistem kontrolleri başarılı."

log_step "Unit testleri çalıştırılıyor..."
"$VENV_DIR/bin/python" -m pytest --tb=short -q 2>&1 | tail -20
log_info "Testler tamamlandı."

# ============================================================================
# KURULUM TAMAMLANDI
# ============================================================================

log_section "🎉 KURULUM BAŞARIYLA TAMAMLANDI! 🎉"

echo ""
echo "Kurulum Bilgileri:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Proje Dizini: $PROJECT_PATH"
echo "  Sanal Ortam: $VENV_DIR"
echo "  Veritabanı: $DB_FILE"
echo "  Django Sürümü: $("$VENV_DIR/bin/python" -c 'import django; print(django.VERSION)')"
echo ""

echo "Geliştirme Sunucusunu Başlatmak İçin:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. Sanal ortamı aktifleştir:"
echo "     source venv/bin/activate"
echo ""
echo "  2. Geliştirme sunucusunu başlat:"
echo "     python manage.py runserver"
echo ""
echo "  3. Tarayıcıda aç:"
echo "     http://localhost:8000"
echo ""
echo "  4. Admin paneline gir:"
echo "     http://localhost:8000/admin/"
echo "     Kullanıcı: admin"
echo ""

echo "Faydalı Komutlar:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  # Django shell"
echo "  python manage.py shell"
echo ""
echo "  # Testleri çalıştır"
echo "  python -m pytest"
echo ""
echo "  # Migrasyonları oluştur"
echo "  python manage.py makemigrations"
echo ""
echo "  # Migrasyonları uygula"
echo "  python manage.py migrate"
echo ""

log_info "Kurulum tamamlandı! Keyifli geliştirme."
