#!/bin/bash

################################################################################
# HaberNexus v8.0 - One-Click Installer
# 
# Purpose: Ultra-simple one-command installation
# Just run: curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/one_click_install.sh | sudo bash
#
# Author: Salih TANRISEVEN
# Date: December 15, 2025
# Version: 8.0
################################################################################

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

# Configuration
readonly REPO_URL="https://github.com/sata2500/habernexus.git"
readonly PROJECT_PATH="/opt/habernexus"
readonly BRANCH="main"

# Animated banner
show_banner() {
    clear
    echo ""
    echo -e "${CYAN}"
    cat << 'EOF'
    ██╗  ██╗ █████╗ ██████╗ ███████╗██████╗ ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
    ██║  ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
    ███████║███████║██████╔╝█████╗  ██████╔╝██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
    ██╔══██║██╔══██║██╔══██╗██╔══╝  ██╔══██╗██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
    ██║  ██║██║  ██║██████╔╝███████╗██║  ██║██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
    ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${BOLD}                    🚀 One-Click Installer v8.0 🚀${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[✗]${NC} Bu script root yetkisi ile çalıştırılmalıdır"
        echo ""
        echo -e "    Kullanım: ${YELLOW}curl -fsSL <url> | sudo bash${NC}"
        echo ""
        exit 1
    fi
    echo -e "${GREEN}[✓]${NC} Root yetkisi doğrulandı"
}

# Install dependencies
install_deps() {
    echo -e "${CYAN}[→]${NC} Bağımlılıklar yükleniyor..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y -qq git curl wget > /dev/null 2>&1
    
    echo -e "${GREEN}[✓]${NC} Bağımlılıklar hazır"
}

# Clone repository
clone_repo() {
    echo -e "${CYAN}[→]${NC} Proje dosyaları indiriliyor..."
    
    if [[ -d "$PROJECT_PATH" ]]; then
        rm -rf "$PROJECT_PATH"
    fi
    
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$PROJECT_PATH" > /dev/null 2>&1
    
    echo -e "${GREEN}[✓]${NC} Proje dosyaları indirildi"
}

# Run installer
run_installer() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Ana kurulum başlatılıyor...${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    cd "$PROJECT_PATH"
    chmod +x install_v8.sh
    
    # Run the main installer
    bash install_v8.sh --auto
}

# Main
main() {
    show_banner
    check_root
    install_deps
    clone_repo
    run_installer
}

main "$@"
