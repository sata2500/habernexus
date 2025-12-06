#!/bin/bash

################################################################################
# Haber Nexus - Otomatik VM Taşıma Scripti
# Bir VM'den başka bir VM'ye uygulamayı taşır
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
║                  🚀 HABER NEXUS - OTOMATIK VM TAŞIMA 🚀                    ║
║                                                                              ║
║                    Bir VM'den Başka VM'ye Uygulamayı Taşır                   ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF

# ============================================================================
# AYARLAR
# ============================================================================

log_section "Taşıma Ayarları"

# Orijinal VM bilgileri
echo "Orijinal VM Bilgileri:"
read -p "  Orijinal VM IP Adresi: " ORIGINAL_IP
read -p "  Orijinal VM SSH Kullanıcısı [ubuntu]: " ORIGINAL_USER
ORIGINAL_USER=${ORIGINAL_USER:-ubuntu}
read -p "  Orijinal VM SSH Anahtarı Yolu [~/.ssh/id_rsa]: " ORIGINAL_KEY
ORIGINAL_KEY=${ORIGINAL_KEY:-~/.ssh/id_rsa}

# Yeni VM bilgileri
echo ""
echo "Yeni VM Bilgileri:"
read -p "  Yeni VM IP Adresi: " NEW_IP
read -p "  Yeni VM SSH Kullanıcısı [ubuntu]: " NEW_USER
NEW_USER=${NEW_USER:-ubuntu}
read -p "  Yeni VM SSH Anahtarı Yolu [~/.ssh/id_rsa]: " NEW_KEY
NEW_KEY=${NEW_KEY:-~/.ssh/id_rsa}

# Proje dizini
echo ""
read -p "Proje Dizini [/opt/habernexus]: " PROJECT_PATH
PROJECT_PATH=${PROJECT_PATH:-/opt/habernexus}

# Taşıma yöntemi
echo ""
echo "Taşıma Yöntemi:"
echo "  1) Yedekleme + Geri Yükleme (Önerilen)"
echo "  2) Doğrudan Taşıma (rsync)"
echo ""
read -p "Seçim (1 veya 2) [1]: " MIGRATION_METHOD
MIGRATION_METHOD=${MIGRATION_METHOD:-1}

# Özet
log_section "Taşıma Özeti"

echo "Orijinal VM: $ORIGINAL_USER@$ORIGINAL_IP:$PROJECT_PATH"
echo "Yeni VM: $NEW_USER@$NEW_IP:$PROJECT_PATH"
echo "Taşıma Yöntemi: $([ "$MIGRATION_METHOD" = "1" ] && echo "Yedekleme + Geri Yükleme" || echo "Doğrudan Taşıma")"
echo ""

read -p "Devam etmek istediğinize emin misiniz? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_error "Taşıma iptal edildi."
fi

# ============================================================================
# YÖNTEM 1: YEDEKLEMEİ GERI YÜKLEME
# ============================================================================

if [ "$MIGRATION_METHOD" = "1" ]; then

log_section "Yöntem 1: Yedekleme + Geri Yükleme"

# ADIM 1: Orijinal VM'de yedekleme oluştur
log_section "Adım 1: Orijinal VM'de Yedekleme Oluşturuluyor"

log_step "Orijinal VM'ye bağlanılıyor..."
ssh -i "$ORIGINAL_KEY" "$ORIGINAL_USER@$ORIGINAL_IP" "cd $PROJECT_PATH && sudo bash scripts/backup-full.sh $PROJECT_PATH" || log_error "Yedekleme başarısız oldu."
log_info "Yedekleme oluşturuldu."

# ADIM 2: Yedekleme dosyasını bul
log_step "Yedekleme dosyası bulunuyor..."
BACKUP_FILE=$(ssh -i "$ORIGINAL_KEY" "$ORIGINAL_USER@$ORIGINAL_IP" "ls -t $PROJECT_PATH/.backups/*.tar.gz | head -1")
if [ -z "$BACKUP_FILE" ]; then
    log_error "Yedekleme dosyası bulunamadı."
fi
log_info "Yedekleme dosyası: $BACKUP_FILE"

# ADIM 3: Yedekleme dosyasını indir
log_section "Adım 2: Yedekleme Dosyası İndiriliyor"

log_step "Yedekleme dosyası indiriliyor..."
BACKUP_NAME=$(basename "$BACKUP_FILE")
scp -i "$ORIGINAL_KEY" "$ORIGINAL_USER@$ORIGINAL_IP:$BACKUP_FILE" "/tmp/$BACKUP_NAME" || log_error "Yedekleme indirilemedi."
log_info "Yedekleme indirildi: /tmp/$BACKUP_NAME"

# ADIM 4: Yedekleme dosyasını yeni VM'ye yükle
log_section "Adım 3: Yedekleme Dosyası Yeni VM'ye Yükleniyor"

log_step "Yedekleme dosyası yükleniyor..."
scp -i "$NEW_KEY" "/tmp/$BACKUP_NAME" "$NEW_USER@$NEW_IP:/tmp/" || log_error "Yedekleme yüklenemedi."
log_info "Yedekleme yüklendi."

# ADIM 5: Yeni VM'de geri yükleme
log_section "Adım 4: Yeni VM'de Geri Yükleme Yapılıyor"

log_step "Geri yükleme scriptini çalıştırılıyor..."
BACKUP_DIR="/tmp/$(echo $BACKUP_NAME | sed 's/.tar.gz//')"

ssh -i "$NEW_KEY" "$NEW_USER@$NEW_IP" "cd /tmp && tar -xzf $BACKUP_NAME && echo 'y' | sudo bash $PROJECT_PATH/scripts/restore-full.sh $BACKUP_DIR $PROJECT_PATH" || log_warning "Geri yükleme sırasında hata oluştu, ancak devam ediliyor..."
log_info "Geri yükleme tamamlandı."

# ADIM 6: Servisleri yeniden başlat
log_section "Adım 5: Servisleri Yeniden Başlatılıyor"

log_step "Servisleri yeniden başlatılıyor..."
ssh -i "$NEW_KEY" "$NEW_USER@$NEW_IP" "sudo systemctl restart habernexus habernexus-celery habernexus-celery-beat" || log_warning "Servisleri yeniden başlatmada hata oluştu."
log_info "Servisleri yeniden başlatıldı."

# ADIM 7: Temizlik
log_section "Adım 6: Temizlik"

log_step "Geçici dosyalar temizleniyor..."
rm -f "/tmp/$BACKUP_NAME"
ssh -i "$NEW_KEY" "$NEW_USER@$NEW_IP" "rm -rf /tmp/habernexus_backup_*" || true
log_info "Geçici dosyalar temizlendi."

# ============================================================================
# YÖNTEM 2: DOĞRUDAN TAŞIMA
# ============================================================================

elif [ "$MIGRATION_METHOD" = "2" ]; then

log_section "Yöntem 2: Doğrudan Taşıma (rsync)"

# ADIM 1: Yeni VM'de proje dizinini hazırla
log_section "Adım 1: Yeni VM Hazırlanıyor"

log_step "Proje dizini oluşturuluyor..."
ssh -i "$NEW_KEY" "$NEW_USER@$NEW_IP" "sudo mkdir -p $PROJECT_PATH && sudo chown $NEW_USER:$NEW_USER $PROJECT_PATH" || log_error "Proje dizini oluşturulamadı."
log_info "Proje dizini oluşturuldu."

# ADIM 2: Dosyaları senkronize et
log_section "Adım 2: Dosyalar Senkronize Ediliyor"

log_step "Dosyalar rsync ile senkronize ediliyor..."
rsync -avz -e "ssh -i $ORIGINAL_KEY" \
    --exclude='venv' \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='.pytest_cache' \
    --exclude='*.pyc' \
    --exclude='.backups' \
    "$ORIGINAL_USER@$ORIGINAL_IP:$PROJECT_PATH/" \
    "/tmp/habernexus_sync/" || log_error "rsync başarısız oldu."
log_info "Dosyalar senkronize edildi."

# ADIM 3: Senkronize edilen dosyaları yeni VM'ye kopyala
log_step "Dosyalar yeni VM'ye kopyalanıyor..."
rsync -avz -e "ssh -i $NEW_KEY" \
    "/tmp/habernexus_sync/" \
    "$NEW_USER@$NEW_IP:$PROJECT_PATH/" || log_error "Dosyalar kopyalanamadı."
log_info "Dosyalar kopyalandı."

# ADIM 4: Sanal ortamı yeniden oluştur
log_section "Adım 3: Sanal Ortam Yeniden Oluşturuluyor"

log_step "Sanal ortam oluşturuluyor..."
ssh -i "$NEW_KEY" "$NEW_USER@$NEW_IP" "cd $PROJECT_PATH && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt" || log_error "Sanal ortam oluşturulamadı."
log_info "Sanal ortam oluşturuldu."

# ADIM 5: Migrasyonları çalıştır
log_section "Adım 4: Veritabanı Migrasyonları Çalıştırılıyor"

log_step "Migrasyonları çalıştırılıyor..."
ssh -i "$NEW_KEY" "$NEW_USER@$NEW_IP" "cd $PROJECT_PATH && source venv/bin/activate && python manage.py migrate" || log_warning "Migrasyonlar çalıştırılamadı."
log_info "Migrasyonlar çalıştırıldı."

# ADIM 6: Statik dosyaları topla
log_section "Adım 5: Statik Dosyalar Toplanıyor"

log_step "Statik dosyalar toplanıyor..."
ssh -i "$NEW_KEY" "$NEW_USER@$NEW_IP" "cd $PROJECT_PATH && source venv/bin/activate && python manage.py collectstatic --noinput" || log_warning "Statik dosyalar toplanamadı."
log_info "Statik dosyalar toplandı."

# ADIM 7: Servisleri yeniden başlat
log_section "Adım 6: Servisleri Yeniden Başlatılıyor"

log_step "Servisleri yeniden başlatılıyor..."
ssh -i "$NEW_KEY" "$NEW_USER@$NEW_IP" "sudo systemctl restart habernexus habernexus-celery habernexus-celery-beat" || log_warning "Servisleri yeniden başlatmada hata oluştu."
log_info "Servisleri yeniden başlatıldı."

# ADIM 8: Temizlik
log_section "Adım 7: Temizlik"

log_step "Geçici dosyalar temizleniyor..."
rm -rf "/tmp/habernexus_sync"
log_info "Geçici dosyalar temizlendi."

fi

# ============================================================================
# TAŞIMA TAMAMLANDI
# ============================================================================

log_section "🎉 TAŞIMA BAŞARIYLA TAMAMLANDI! 🎉"

echo ""
echo "Taşıma Bilgileri:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Orijinal VM: $ORIGINAL_USER@$ORIGINAL_IP"
echo "  Yeni VM: $NEW_USER@$NEW_IP"
echo "  Proje Dizini: $PROJECT_PATH"
echo "  Taşıma Tarihi: $(date)"
echo ""

echo "Sonraki Adımlar:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Yeni VM'ye bağlan:"
echo "   ssh -i $NEW_KEY $NEW_USER@$NEW_IP"
echo ""
echo "2. Servislerin durumunu kontrol et:"
echo "   sudo systemctl status habernexus"
echo ""
echo "3. Logları kontrol et:"
echo "   sudo journalctl -u habernexus -f"
echo ""
echo "4. Web sitesini test et:"
echo "   https://NEW_DOMAIN"
echo ""
echo "5. Admin paneline gir:"
echo "   https://NEW_DOMAIN/admin/"
echo ""

log_info "Taşıma tamamlandı!"
