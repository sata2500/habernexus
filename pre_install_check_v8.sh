#!/bin/bash

################################################################################
# HaberNexus v8.0 - Advanced Pre-Installation System Check
# 
# Purpose: Comprehensive system compatibility verification before installation
# Features:
#   - Detailed hardware analysis
#   - Network connectivity tests
#   - Port availability check
#   - Docker compatibility verification
#   - Cloudflare API validation
#   - DNS resolution check
#   - Security configuration audit
#   - Recommendations for optimization
#
# Usage: sudo bash pre_install_check_v8.sh [OPTIONS]
#
# Author: Salih TANRISEVEN
# Date: December 15, 2025
# Version: 8.0
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_VERSION="8.0"
readonly MIN_CPU_CORES=2
readonly MIN_RAM_GB=2
readonly MIN_DISK_GB=15
readonly REQUIRED_PORTS=(80 443 5432 6379 8000)

# ============================================================================
# COLORS & SYMBOLS
# ============================================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

readonly CHECK="✓"
readonly CROSS="✗"
readonly WARNING="⚠"
readonly INFO="ℹ"
readonly ARROW="→"
readonly BULLET="•"

# ============================================================================
# COUNTERS
# ============================================================================

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0
RECOMMENDATIONS=()

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_banner() {
    echo ""
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                                                                       ║
    ║   ██╗  ██╗ █████╗ ██████╗ ███████╗██████╗ ███╗   ██╗███████╗██╗  ██╗  ║
    ║   ██║  ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗████╗  ██║██╔════╝╚██╗██╔╝  ║
    ║   ███████║███████║██████╔╝█████╗  ██████╔╝██╔██╗ ██║█████╗   ╚███╔╝   ║
    ║   ██╔══██║██╔══██║██╔══██╗██╔══╝  ██╔══██╗██║╚██╗██║██╔══╝   ██╔██╗   ║
    ║   ██║  ██║██║  ██║██████╔╝███████╗██║  ██║██║ ╚████║███████╗██╔╝ ██╗  ║
    ║   ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ║
    ║                                                                       ║
    ║              Pre-Installation System Check v8.0                       ║
    ║                                                                       ║
    ╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_section() {
    echo ""
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}${BOLD}  $*${NC}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_pass() {
    echo -e "  ${GREEN}[${CHECK}]${NC} $*"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo -e "  ${RED}[${CROSS}]${NC} $*"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo -e "  ${YELLOW}[${WARNING}]${NC} $*"
    ((CHECKS_WARNING++))
}

check_info() {
    echo -e "  ${BLUE}[${INFO}]${NC} $*"
}

add_recommendation() {
    RECOMMENDATIONS+=("$1")
}

# ============================================================================
# SYSTEM CHECKS
# ============================================================================

check_root_privileges() {
    print_section "Root Yetkileri"
    
    if [[ $EUID -eq 0 ]]; then
        check_pass "Root yetkisi ile çalışıyor"
    else
        check_warn "Root yetkisi yok (kurulum için gerekli)"
        add_recommendation "Kurulum için: sudo bash install_v8.sh"
    fi
}

check_operating_system() {
    print_section "İşletim Sistemi"
    
    if [[ ! -f /etc/os-release ]]; then
        check_fail "İşletim sistemi belirlenemedi"
        return
    fi
    
    source /etc/os-release
    
    check_info "İşletim Sistemi: ${PRETTY_NAME:-$ID}"
    check_info "Kernel: $(uname -r)"
    check_info "Mimari: $(uname -m)"
    
    if [[ "$ID" == "ubuntu" ]]; then
        check_pass "Ubuntu tespit edildi"
        
        case "$VERSION_ID" in
            20.04|22.04|24.04)
                check_pass "Ubuntu $VERSION_ID LTS - Tam destek"
                ;;
            *)
                check_warn "Ubuntu $VERSION_ID - Test edilmedi"
                add_recommendation "Ubuntu 22.04 veya 24.04 LTS önerilir"
                ;;
        esac
    elif [[ "$ID" == "debian" ]]; then
        check_warn "Debian tespit edildi - Sınırlı destek"
        add_recommendation "Ubuntu 22.04+ önerilir"
    else
        check_fail "Desteklenmeyen işletim sistemi: $ID"
        add_recommendation "Ubuntu 22.04 veya 24.04 LTS kullanın"
    fi
}

check_cpu() {
    print_section "CPU Bilgileri"
    
    local cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo "Bilinmiyor")
    local cpu_cores=$(nproc 2>/dev/null || echo 1)
    local cpu_threads=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo 1)
    
    check_info "Model: $cpu_model"
    check_info "Çekirdek: $cpu_cores"
    check_info "Thread: $cpu_threads"
    
    if [[ $cpu_cores -ge 4 ]]; then
        check_pass "$cpu_cores çekirdek - Mükemmel"
    elif [[ $cpu_cores -ge $MIN_CPU_CORES ]]; then
        check_warn "$cpu_cores çekirdek - Minimum (4+ önerilir)"
        add_recommendation "Daha iyi performans için 4+ CPU çekirdeği önerilir"
    else
        check_fail "$cpu_cores çekirdek - Yetersiz (minimum $MIN_CPU_CORES)"
    fi
}

check_memory() {
    print_section "Bellek (RAM)"
    
    local mem_total_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
    local mem_total_gb=$((mem_total_kb / 1024 / 1024))
    local mem_available_kb=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
    local mem_available_gb=$((mem_available_kb / 1024 / 1024))
    local swap_total_kb=$(grep SwapTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
    local swap_total_gb=$((swap_total_kb / 1024 / 1024))
    
    check_info "Toplam RAM: ${mem_total_gb}GB"
    check_info "Kullanılabilir: ${mem_available_gb}GB"
    check_info "Swap: ${swap_total_gb}GB"
    
    if [[ $mem_total_gb -ge 8 ]]; then
        check_pass "${mem_total_gb}GB RAM - Mükemmel"
    elif [[ $mem_total_gb -ge 4 ]]; then
        check_warn "${mem_total_gb}GB RAM - Yeterli (8GB+ önerilir)"
        add_recommendation "Daha iyi performans için 8GB+ RAM önerilir"
    elif [[ $mem_total_gb -ge $MIN_RAM_GB ]]; then
        check_warn "${mem_total_gb}GB RAM - Minimum"
        add_recommendation "En az 4GB RAM önerilir"
    else
        check_fail "${mem_total_gb}GB RAM - Yetersiz (minimum ${MIN_RAM_GB}GB)"
    fi
    
    if [[ $swap_total_gb -lt 2 ]]; then
        check_warn "Swap alanı düşük (${swap_total_gb}GB)"
        add_recommendation "En az 2GB swap alanı oluşturun"
    fi
}

check_disk_space() {
    print_section "Disk Alanı"
    
    local partitions=("/" "/opt" "/var" "/home")
    
    for partition in "${partitions[@]}"; do
        if [[ -d "$partition" ]]; then
            local available=$(df "$partition" 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)
            local available_gb=$((available / 1024 / 1024))
            local total=$(df "$partition" 2>/dev/null | awk 'NR==2 {print $2}' || echo 0)
            local total_gb=$((total / 1024 / 1024))
            local used_percent=$(df "$partition" 2>/dev/null | awk 'NR==2 {print $5}' || echo "0%")
            
            check_info "$partition: ${available_gb}GB boş / ${total_gb}GB toplam (${used_percent} kullanımda)"
        fi
    done
    
    local opt_available=$(df /opt 2>/dev/null | awk 'NR==2 {print $4}' || df / 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)
    local opt_available_gb=$((opt_available / 1024 / 1024))
    
    if [[ $opt_available_gb -ge 50 ]]; then
        check_pass "${opt_available_gb}GB boş alan - Mükemmel"
    elif [[ $opt_available_gb -ge 20 ]]; then
        check_pass "${opt_available_gb}GB boş alan - Yeterli"
    elif [[ $opt_available_gb -ge $MIN_DISK_GB ]]; then
        check_warn "${opt_available_gb}GB boş alan - Minimum (20GB+ önerilir)"
        add_recommendation "En az 20GB boş disk alanı önerilir"
    else
        check_fail "${opt_available_gb}GB boş alan - Yetersiz (minimum ${MIN_DISK_GB}GB)"
    fi
}

check_network() {
    print_section "Ağ Bağlantısı"
    
    # IP adresi
    local ip_address=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "Bilinmiyor")
    check_info "IP Adresi: $ip_address"
    
    # DNS çözümleme
    local dns_servers=$(grep "nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' | head -3 | tr '\n' ' ')
    check_info "DNS Sunucuları: ${dns_servers:-Bilinmiyor}"
    
    # İnternet bağlantısı testi
    local test_urls=("https://github.com" "https://api.cloudflare.com" "https://registry.hub.docker.com" "https://www.google.com")
    local connected=false
    
    for url in "${test_urls[@]}"; do
        if timeout 5 curl -s -I "$url" > /dev/null 2>&1; then
            check_pass "Bağlantı: $url"
            connected=true
        else
            check_warn "Bağlantı yok: $url"
        fi
    done
    
    if [[ "$connected" == false ]]; then
        check_fail "İnternet bağlantısı yok"
        add_recommendation "İnternet bağlantısını kontrol edin"
    fi
    
    # DNS çözümleme testi
    if host github.com > /dev/null 2>&1 || nslookup github.com > /dev/null 2>&1; then
        check_pass "DNS çözümleme çalışıyor"
    else
        check_warn "DNS çözümleme sorunu olabilir"
        add_recommendation "DNS ayarlarını kontrol edin"
    fi
}

check_ports() {
    print_section "Port Durumu"
    
    local blocked_ports=()
    
    for port in "${REQUIRED_PORTS[@]}"; do
        local service=""
        case $port in
            80) service="HTTP" ;;
            443) service="HTTPS" ;;
            5432) service="PostgreSQL" ;;
            6379) service="Redis" ;;
            8000) service="Django" ;;
            *) service="Unknown" ;;
        esac
        
        if ss -tuln 2>/dev/null | grep -q ":$port " || netstat -tuln 2>/dev/null | grep -q ":$port "; then
            local process=$(ss -tulnp 2>/dev/null | grep ":$port " | awk '{print $NF}' | head -1 || echo "bilinmiyor")
            check_warn "Port $port ($service) kullanımda: $process"
            blocked_ports+=($port)
        else
            check_pass "Port $port ($service) müsait"
        fi
    done
    
    if [[ ${#blocked_ports[@]} -gt 0 ]]; then
        add_recommendation "Kullanımdaki portları serbest bırakın veya Docker bunları yönetecek"
    fi
}

check_docker() {
    print_section "Docker Durumu"
    
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version 2>/dev/null | awk '{print $3}' | sed 's/,//')
        check_pass "Docker kurulu: $docker_version"
        
        if docker ps &> /dev/null; then
            check_pass "Docker daemon çalışıyor"
            
            local running_containers=$(docker ps -q 2>/dev/null | wc -l)
            check_info "Çalışan container: $running_containers"
        else
            check_warn "Docker daemon çalışmıyor"
            add_recommendation "Docker'ı başlatın: sudo systemctl start docker"
        fi
    else
        check_info "Docker kurulu değil (kurulum sırasında yüklenecek)"
    fi
    
    if command -v docker-compose &> /dev/null; then
        local compose_version=$(docker-compose --version 2>/dev/null | awk '{print $4}' | sed 's/,//' || echo "bilinmiyor")
        check_pass "Docker Compose kurulu: $compose_version"
    elif docker compose version &> /dev/null; then
        local compose_version=$(docker compose version 2>/dev/null | awk '{print $4}' || echo "bilinmiyor")
        check_pass "Docker Compose (plugin) kurulu: $compose_version"
    else
        check_info "Docker Compose kurulu değil (kurulum sırasında yüklenecek)"
    fi
}

check_required_commands() {
    print_section "Gerekli Komutlar"
    
    local commands=(
        "curl:HTTP istekleri"
        "wget:Dosya indirme"
        "git:Versiyon kontrolü"
        "python3:Python runtime"
        "pip3:Python paket yöneticisi"
        "openssl:SSL/TLS"
        "jq:JSON işleme"
    )
    
    for cmd_info in "${commands[@]}"; do
        IFS=':' read -r cmd desc <<< "$cmd_info"
        
        if command -v "$cmd" &> /dev/null; then
            local version=$("$cmd" --version 2>&1 | head -1 | cut -d' ' -f2 | head -c 20 || echo "")
            check_pass "$cmd ($desc) ${version:+- $version}"
        else
            check_warn "$cmd ($desc) kurulu değil"
            add_recommendation "$cmd kurun: sudo apt install $cmd"
        fi
    done
}

check_firewall() {
    print_section "Güvenlik Duvarı"
    
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status 2>/dev/null | head -1 || echo "bilinmiyor")
        check_info "UFW durumu: $ufw_status"
        
        if echo "$ufw_status" | grep -q "active"; then
            check_warn "UFW aktif - portları açmayı unutmayın"
            add_recommendation "Portları açın: sudo ufw allow 80,443/tcp"
        else
            check_pass "UFW devre dışı"
        fi
    else
        check_info "UFW kurulu değil"
    fi
    
    if command -v iptables &> /dev/null; then
        local iptables_rules=$(iptables -L -n 2>/dev/null | grep -c "REJECT\|DROP" || echo 0)
        if [[ $iptables_rules -gt 0 ]]; then
            check_warn "iptables kuralları mevcut ($iptables_rules engelleme kuralı)"
        else
            check_pass "iptables engelleme kuralı yok"
        fi
    fi
}

check_selinux() {
    print_section "SELinux / AppArmor"
    
    if command -v getenforce &> /dev/null; then
        local selinux_status=$(getenforce 2>/dev/null || echo "bilinmiyor")
        check_info "SELinux: $selinux_status"
        
        if [[ "$selinux_status" == "Enforcing" ]]; then
            check_warn "SELinux enforcing modunda - sorunlara neden olabilir"
            add_recommendation "SELinux'u permissive yapın: sudo setenforce 0"
        fi
    fi
    
    if command -v aa-status &> /dev/null; then
        local apparmor_profiles=$(aa-status 2>/dev/null | grep "profiles are loaded" | awk '{print $1}' || echo 0)
        check_info "AppArmor profilleri: $apparmor_profiles"
    fi
}

check_time_sync() {
    print_section "Zaman Senkronizasyonu"
    
    local current_time=$(date '+%Y-%m-%d %H:%M:%S %Z')
    check_info "Sistem zamanı: $current_time"
    
    if command -v timedatectl &> /dev/null; then
        local ntp_status=$(timedatectl show --property=NTPSynchronized --value 2>/dev/null || echo "bilinmiyor")
        
        if [[ "$ntp_status" == "yes" ]]; then
            check_pass "NTP senkronizasyonu aktif"
        else
            check_warn "NTP senkronizasyonu devre dışı"
            add_recommendation "NTP'yi etkinleştirin: sudo timedatectl set-ntp true"
        fi
    fi
    
    local timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo "bilinmiyor")
    check_info "Saat dilimi: $timezone"
}

check_existing_installation() {
    print_section "Mevcut Kurulum"
    
    if [[ -d "/opt/habernexus" ]]; then
        check_info "Mevcut kurulum bulundu: /opt/habernexus"
        
        if [[ -f "/opt/habernexus/.env" ]]; then
            check_info ".env dosyası mevcut"
        fi
        
        if [[ -f "/opt/habernexus/docker-compose.yml" ]]; then
            check_info "docker-compose.yml mevcut"
        fi
        
        if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "habernexus"; then
            local running=$(docker ps --format '{{.Names}}' 2>/dev/null | grep "habernexus" | wc -l)
            check_warn "$running HaberNexus container'ı çalışıyor"
            add_recommendation "Yeni kurulum için: sudo bash install_v8.sh --force"
        fi
    else
        check_pass "Temiz kurulum ortamı"
    fi
}

# ============================================================================
# SUMMARY
# ============================================================================

print_summary() {
    print_section "Kontrol Özeti"
    
    echo ""
    echo -e "  ${GREEN}Başarılı:${NC}  $CHECKS_PASSED"
    echo -e "  ${YELLOW}Uyarı:${NC}     $CHECKS_WARNING"
    echo -e "  ${RED}Başarısız:${NC} $CHECKS_FAILED"
    echo ""
    
    if [[ ${#RECOMMENDATIONS[@]} -gt 0 ]]; then
        echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}${BOLD}  Öneriler${NC}"
        echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        for rec in "${RECOMMENDATIONS[@]}"; do
            echo -e "  ${ARROW} $rec"
        done
        echo ""
    fi
    
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ $CHECKS_FAILED -eq 0 ]]; then
        echo ""
        echo -e "  ${GREEN}${CHECK} Sistem kuruluma hazır!${NC}"
        echo ""
        echo -e "  Kurulumu başlatmak için:"
        echo -e "  ${WHITE}sudo bash install_v8.sh --auto${NC}"
        echo ""
        return 0
    else
        echo ""
        echo -e "  ${RED}${CROSS} Kurulum öncesi düzeltilmesi gereken sorunlar var${NC}"
        echo ""
        echo -e "  Sorunları düzelttikten sonra tekrar kontrol edin:"
        echo -e "  ${WHITE}sudo bash pre_install_check_v8.sh${NC}"
        echo ""
        return 1
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    print_banner
    
    check_root_privileges
    check_operating_system
    check_cpu
    check_memory
    check_disk_space
    check_network
    check_ports
    check_docker
    check_required_commands
    check_firewall
    check_selinux
    check_time_sync
    check_existing_installation
    
    print_summary
}

main "$@"
