#!/bin/bash

################################################################################
# HaberNexus Pre-Installation Check Script
#
# Purpose: Verify system compatibility before installation
# Usage: bash pre_install_check.sh
#
# Author: Salih TANRISEVEN
# Date: December 15, 2025
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $@${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_check() {
    echo -e "${BLUE}→ $@${NC}"
}

check_pass() {
    echo -e "${GREEN}  [✓]${NC} $@"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo -e "${RED}  [✗]${NC} $@"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo -e "${YELLOW}  [⚠]${NC} $@"
    ((CHECKS_WARNING++))
}

# ============================================================================
# CHECKS
# ============================================================================

check_root() {
    print_check "Root Privileges"
    
    if [[ $EUID -eq 0 ]]; then
        check_pass "Running as root"
    else
        check_warn "Not running as root (use: sudo bash pre_install_check.sh)"
    fi
}

check_os() {
    print_check "Operating System"
    
    if [[ ! -f /etc/os-release ]]; then
        check_fail "Cannot determine OS"
        return
    fi
    
    source /etc/os-release
    
    if [[ "$ID" == "ubuntu" ]]; then
        check_pass "Ubuntu detected: $VERSION_ID"
        
        if [[ "$VERSION_ID" =~ ^(20\.04|22\.04|24\.04) ]]; then
            check_pass "Supported Ubuntu version"
        else
            check_warn "Ubuntu version not officially tested: $VERSION_ID"
        fi
    else
        check_fail "Not Ubuntu (detected: $ID)"
    fi
}

check_cpu() {
    print_check "CPU Cores"
    
    local cpu_count=$(nproc)
    
    if [[ $cpu_count -ge 4 ]]; then
        check_pass "$cpu_count cores (recommended: 4+)"
    elif [[ $cpu_count -ge 2 ]]; then
        check_warn "$cpu_count cores (minimum: 2, recommended: 4+)"
    else
        check_fail "$cpu_count cores (minimum: 2 required)"
    fi
}

check_memory() {
    print_check "RAM Memory"
    
    local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_gb=$((mem_kb / 1024 / 1024))
    
    if [[ $mem_gb -ge 8 ]]; then
        check_pass "${mem_gb}GB RAM (recommended: 8+)"
    elif [[ $mem_gb -ge 4 ]]; then
        check_warn "${mem_gb}GB RAM (minimum: 4, recommended: 8+)"
    else
        check_fail "${mem_gb}GB RAM (minimum: 4 required)"
    fi
}

check_disk_space() {
    print_check "Disk Space"
    
    local available=$(df /opt 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
    local available_gb=$((available / 1024 / 1024))
    
    if [[ $available_gb -ge 20 ]]; then
        check_pass "${available_gb}GB available (required: 20+)"
    elif [[ $available_gb -ge 10 ]]; then
        check_warn "${available_gb}GB available (minimum: 20, have: $available_gb)"
    else
        check_fail "${available_gb}GB available (minimum: 20 required)"
    fi
}

check_internet() {
    print_check "Internet Connectivity"
    
    local urls=("https://github.com" "https://api.cloudflare.com" "https://www.google.com")
    local connected=false
    
    for url in "${urls[@]}"; do
        if timeout 5 curl -s -I "$url" > /dev/null 2>&1; then
            check_pass "Connected to $url"
            connected=true
            break
        fi
    done
    
    if [[ "$connected" == false ]]; then
        check_fail "No internet connection"
    fi
}

check_command() {
    local cmd=$1
    local description=${2:-$cmd}
    
    if command -v "$cmd" &> /dev/null; then
        local version=$("$cmd" --version 2>&1 | head -1 || echo "installed")
        check_pass "$description: $version"
        return 0
    else
        check_fail "$description: not installed"
        return 1
    fi
}

check_required_commands() {
    print_check "Required Commands"
    
    local commands=("curl" "wget" "git" "python3")
    
    for cmd in "${commands[@]}"; do
        check_command "$cmd"
    done
}

check_docker() {
    print_check "Docker Installation"
    
    if command -v docker &> /dev/null; then
        local version=$(docker --version | awk '{print $3}' | sed 's/,//')
        check_pass "Docker installed: $version"
        
        if docker ps &> /dev/null; then
            check_pass "Docker daemon is running"
        else
            check_fail "Docker daemon is not running"
            check_warn "Start Docker with: sudo systemctl start docker"
        fi
    else
        check_warn "Docker not installed (will be installed automatically)"
    fi
    
    if command -v docker-compose &> /dev/null; then
        local version=$(docker-compose --version | awk '{print $4}' | sed 's/,//')
        check_pass "Docker Compose installed: $version"
    else
        check_warn "Docker Compose not installed (will be installed automatically)"
    fi
}

check_ports() {
    print_check "Required Ports"
    
    local ports=(80 443 5432 6379 8000)
    local ports_available=true
    
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
            check_warn "Port $port is already in use"
            ports_available=false
        else
            check_pass "Port $port is available"
        fi
    done
}

check_permissions() {
    print_check "File Permissions"
    
    if [[ -w /opt ]]; then
        check_pass "/opt directory is writable"
    else
        check_fail "/opt directory is not writable"
    fi
    
    if [[ -w /var/log ]]; then
        check_pass "/var/log directory is writable"
    else
        check_fail "/var/log directory is not writable"
    fi
}

check_firewall() {
    print_check "Firewall Status"
    
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            check_warn "UFW firewall is active (ensure ports 80, 443 are allowed)"
        else
            check_pass "UFW firewall is inactive"
        fi
    else
        check_pass "UFW firewall not installed"
    fi
}

check_selinux() {
    print_check "SELinux Status"
    
    if command -v getenforce &> /dev/null; then
        local status=$(getenforce 2>/dev/null || echo "unknown")
        if [[ "$status" == "Enforcing" ]]; then
            check_warn "SELinux is enforcing (may cause issues)"
        else
            check_pass "SELinux is not enforcing"
        fi
    else
        check_pass "SELinux not installed"
    fi
}

check_git_repo() {
    print_check "Git Repository"
    
    if [[ -d .git ]]; then
        check_pass "Git repository detected"
        
        if git status &> /dev/null; then
            local branch=$(git rev-parse --abbrev-ref HEAD)
            check_pass "Current branch: $branch"
        fi
    else
        check_warn "Not in a git repository"
    fi
}

# ============================================================================
# SUMMARY
# ============================================================================

print_summary() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Check Summary${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${GREEN}Passed:${NC}   $CHECKS_PASSED"
    echo -e "${YELLOW}Warnings:${NC} $CHECKS_WARNING"
    echo -e "${RED}Failed:${NC}   $CHECKS_FAILED"
    echo ""
    
    if [[ $CHECKS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ System is ready for installation!${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Run: ${CYAN}sudo bash install_v7.sh --quick${NC}"
        echo "  2. Or:  ${CYAN}sudo bash install_v7.sh --custom${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Please fix the failed checks before installing${NC}"
        echo ""
        return 1
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    print_header "HaberNexus Pre-Installation Check"
    
    check_root
    check_os
    check_cpu
    check_memory
    check_disk_space
    check_internet
    check_required_commands
    check_docker
    check_ports
    check_permissions
    check_firewall
    check_selinux
    check_git_repo
    
    print_summary
}

main "$@"
