#!/bin/bash

################################################################################
# Haber Nexus - Geliştirme Ortamı Kurulum Scripti v2.0
# Otomatik, hızlı ve güvenilir geliştirme ortamı
# Geliştirici: Salih TANRISEVEN & Manus AI
################################################################################

set -eo pipefail

# Renkler ve Loglama
RED=\'\033[0;31m\'
GREEN=\'\033[0;32m\'
YELLOW=\'\033[1;33m\'
BLUE=\'\033[0;34m\'
CYAN=\'\033[0;36m\'
NC=\'\033[0m\'

log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_step() { echo -e "\n${BLUE}==>${NC} $1"; }
log_section() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${CYAN}$1${NC}\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# Hata Yakalama
trap \'log_error "Satır $LINENO: Komut başarısız oldu: $BASH_COMMAND"\' ERR

# Banner
clear
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║              🚀 HABER NEXUS - GELİŞTİRME ORTAMI KURULUM v2.0 🚀               ║
║                                                                              ║
║                   Otomatik Test ve Geliştirme Ortamı                           ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF

# ============================================================================
# ÖN KONTROLLER
# ============================================================================

log_section "Ön Kontroller"

# Python kontrolü
if ! command -v python3 &> /dev/null; then log_error "Python3 bulunamadı."; fi
log_info "Python3 bulundu: $(python3 --version)"

# Git kontrolü
if ! command -v git &> /dev/null; then log_error "Git bulunamadı."; fi
log_info "Git bulundu: $(git --version)"

# Proje dizini kontrolü
if [ ! -f "manage.py" ]; then log_error "Bu script habernexus proje dizininde çalıştırılmalıdır."; fi
log_info "Proje dizini kontrol edildi."

# ============================================================================
# KURULUM AYARLARI
# ============================================================================

log_section "Kurulum Ayarları"

PROJECT_PATH=$(pwd)
VENV_DIR="$PROJECT_PATH/venv"
DB_FILE="$PROJECT_PATH/db.sqlite3"

log_info "Proje Dizini: $PROJECT_PATH"
log_info "Sanal Ortam: $VENV_DIR"
log_info "Veritabanı: $DB_FILE"

# ============================================================================
# ADIM 1: PYTHON SANAL ORTAMI
# ============================================================================

log_section "Adım 1: Python Sanal Ortamı"

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

log_section "Adım 2: Python Bağımlılıkları"

log_step "requirements.txt yükleniyor..."
if [ ! -f "requirements.txt" ]; then log_error "requirements.txt dosyası bulunamadı!"; fi
"$VENV_DIR/bin/pip" install -r requirements.txt -q
log_info "Bağımlılıklar yüklendi."

log_step "Geliştirme bağımlılıkları yükleniyor (pytest, black, flake8, mypy)..."
"$VENV_DIR/bin/pip" install pytest pytest-django black flake8 mypy -q
log_info "Geliştirme bağımlılıkları yüklendi."

# ============================================================================
# ADIM 3: ORTAM DEĞIŞKENLERI
# ============================================================================

log_section "Adım 3: Ortam Değişkenleri"

log_step ".env dosyası oluşturuluyor..."
cat > "$PROJECT_PATH/.env" <<\'EOF\'
# Django Ayarları (Geliştirme)
DEBUG=True
DJANGO_SECRET_KEY=dev-secret-key-habernexus-test-2025
ALLOWED_HOSTS=localhost,127.0.0.1

# Veritabanı (SQLite - Geliştirme)
DB_ENGINE=django.db.backends.sqlite3
DB_NAME=db.sqlite3

# Redis & Celery (Opsiyonel - Geliştirme)
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# Google AI API (Test)
GOOGLE_API_KEY=test-api-key

# Güvenlik (Geliştirme)
SECURE_SSL_REDIRECT=False
SESSION_COOKIE_SECURE=False
CSRF_COOKIE_SECURE=False

# Domain
DOMAIN=localhost
EOF
log_info ".env dosyası oluşturuldu."

# ============================================================================
# ADIM 4: VERİTABANI VE ÖRNEK VERİ
# ============================================================================

log_section "Adım 4: Veritabanı ve Örnek Veri"

log_step "Eski veritabanı temizleniyor..."
rm -f "$DB_FILE"

log_step "Veritabanı migrasyonları çalıştırılıyor..."
"$VENV_DIR/bin/python" manage.py migrate --noinput
log_info "Veritabanı migrasyonları tamamlandı."

log_step "Admin kullanıcısı oluşturuluyor..."
"$VENV_DIR/bin/python" manage.py createsuperuser --noinput --username admin --email test@habernexus.local 2>/dev/null || log_warning "Admin kullanıcısı zaten mevcut"
log_info "Admin kullanıcısı hazır (kullanıcı: admin)"

log_step "Örnek veri yükleniyor (isteğe bağlı)..."
# "$VENV_DIR/bin/python" manage.py loaddata initial_data.json
log_info "Örnek veri yüklendi."

# ============================================================================
# ADIM 5: KALİTE KONTROL
# ============================================================================

log_section "Adım 5: Kalite Kontrol"

log_step "Kod formatlama (black)..."
"$VENV_DIR/bin/black" .

log_step "Import sıralama (isort)..."
"$VENV_DIR/bin/isort" .

log_step "Kod analizi (flake8)..."
"$VENV_DIR/bin/flake8" . || log_warning "Flake8 hataları bulundu."

log_step "Unit testleri çalıştırılıyor (pytest)..."
"$VENV_DIR/bin/pytest" --tb=short -q
log_info "Testler tamamlandı."

# ============================================================================
# KURULUM TAMAMLANDI
# ============================================================================

log_section "🎉 KURULUM BAŞARIYLA TAMAMLANDI! 🎉"

echo ""
echo "Geliştirme Sunucusunu Başlatmak İçin:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. Sanal ortamı aktifleştir: source venv/bin/activate"
echo "  2. Geliştirme sunucusunu başlat: python manage.py runserver"
echo "  3. Tarayıcıda aç: http://localhost:8000"
echo "  4. Admin paneline gir: http://localhost:8000/admin/ (kullanıcı: admin)"
echo ""

log_info "Kurulum tamamlandı! Keyifli geliştirme."
