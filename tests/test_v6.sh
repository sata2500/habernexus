#!/bin/bash

################################################################################
# HaberNexus v6.0 - Quick Test Suite
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0

# Functions
test_pass() {
    echo -e "${GREEN}[✓]${NC} $@"
    ((PASS++))
}

test_fail() {
    echo -e "${RED}[✗]${NC} $@"
    ((FAIL++))
}

test_info() {
    echo -e "${BLUE}[i]${NC} $@"
}

print_header() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  $@"
    echo "═══════════════════════════════════════════════════════════════"
}

# Main tests
cd "$(dirname "${BASH_SOURCE[0]}")/.."

print_header "HaberNexus v6.0 - Installation Tests"

# Test 1: Script Syntax
print_header "1. Script Syntax Checks"
if bash -n install_v6.sh > /dev/null 2>&1; then
    test_pass "install_v6.sh syntax is valid"
else
    test_fail "install_v6.sh has syntax errors"
fi

if bash -n scripts/cloudflare_api.sh > /dev/null 2>&1; then
    test_pass "cloudflare_api.sh syntax is valid"
else
    test_fail "cloudflare_api.sh has syntax errors"
fi

# Test 2: File Structure
print_header "2. File Structure"
files=(
    "install_v6.sh"
    "docker-compose.yml"
    ".env.example"
    "caddy/Dockerfile"
    "caddy/Caddyfile.template"
    "cloudflared/config.yml.template"
    "scripts/cloudflare_api.sh"
    "Dockerfile"
    "README.md"
)

for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        test_pass "$file exists"
    else
        test_fail "$file not found"
    fi
done

# Test 3: Environment Variables
print_header "3. Environment Variables"
if [[ -f ".env.example" ]]; then
    test_pass ".env.example exists"
    
    vars=("DOMAIN" "ADMIN_EMAIL" "CLOUDFLARE_API_TOKEN" "CLOUDFLARE_TUNNEL_TOKEN")
    for var in "${vars[@]}"; do
        if grep -q "$var" .env.example; then
            test_pass "$var found in .env.example"
        else
            test_fail "$var not found in .env.example"
        fi
    done
else
    test_fail ".env.example not found"
fi

# Test 4: Docker Configuration
print_header "4. Docker Configuration"
if [[ -f "docker-compose.yml" ]]; then
    test_pass "docker-compose.yml exists"
    
    # Check for required services
    services=("caddy" "cloudflared" "postgres" "redis" "app")
    for service in "${services[@]}"; do
        if grep -q "^  $service:" docker-compose.yml; then
            test_pass "Service '$service' defined in docker-compose.yml"
        else
            test_fail "Service '$service' not found in docker-compose.yml"
        fi
    done
else
    test_fail "docker-compose.yml not found"
fi

# Test 5: Dockerfile
print_header "5. Dockerfile Checks"
if [[ -f "Dockerfile" ]]; then
    test_pass "Dockerfile exists"
    
    if grep -q "FROM python" Dockerfile; then
        test_pass "Dockerfile has Python base image"
    else
        test_fail "Dockerfile missing Python base image"
    fi
else
    test_fail "Dockerfile not found"
fi

if [[ -f "caddy/Dockerfile" ]]; then
    test_pass "caddy/Dockerfile exists"
    
    if grep -q "FROM caddy" caddy/Dockerfile; then
        test_pass "Caddy Dockerfile has Caddy base image"
    else
        test_fail "Caddy Dockerfile missing Caddy base image"
    fi
else
    test_fail "caddy/Dockerfile not found"
fi

# Test 6: Configuration Templates
print_header "6. Configuration Templates"
if [[ -f "caddy/Caddyfile.template" ]]; then
    test_pass "Caddyfile.template exists"
    
    if grep -q "{DOMAIN}" caddy/Caddyfile.template; then
        test_pass "Caddyfile.template has domain placeholder"
    else
        test_fail "Caddyfile.template missing domain placeholder"
    fi
else
    test_fail "Caddyfile.template not found"
fi

if [[ -f "cloudflared/config.yml.template" ]]; then
    test_pass "config.yml.template exists"
    
    if grep -q "{TUNNEL_NAME}" cloudflared/config.yml.template; then
        test_pass "config.yml.template has tunnel name placeholder"
    else
        test_fail "config.yml.template missing tunnel name placeholder"
    fi
else
    test_fail "config.yml.template not found"
fi

# Test 7: Permissions
print_header "7. Script Permissions"
if [[ -x "install_v6.sh" ]]; then
    test_pass "install_v6.sh is executable"
else
    test_fail "install_v6.sh is not executable"
    chmod +x install_v6.sh
fi

if [[ -x "scripts/cloudflare_api.sh" ]]; then
    test_pass "cloudflare_api.sh is executable"
else
    test_fail "cloudflare_api.sh is not executable"
    chmod +x scripts/cloudflare_api.sh
fi

# Test 8: Documentation
print_header "8. Documentation"
if [[ -f "README.md" ]]; then
    test_pass "README.md exists"
    
    sections=("Installation" "Features" "Architecture")
    for section in "${sections[@]}"; do
        if grep -q "$section" README.md; then
            test_pass "README.md contains '$section' section"
        else
            test_fail "README.md missing '$section' section"
        fi
    done
else
    test_fail "README.md not found"
fi

# Test 9: Security
print_header "9. Security Checks"
if ! grep -E "password.*=.*['\"]" install_v6.sh | grep -v "CLOUDFLARE\|validate_password" > /dev/null 2>&1; then
    test_pass "No hardcoded passwords found"
else
    test_fail "Potential hardcoded passwords found"
fi

if grep -q "set -euo pipefail" install_v6.sh; then
    test_pass "Error handling enabled in install_v6.sh"
else
    test_fail "Error handling might be missing"
fi

# Test 10: Git Status
print_header "10. Git Status"
if git rev-parse --git-dir > /dev/null 2>&1; then
    test_pass "Git repository is valid"
    
    if git diff-index --quiet HEAD -- > /dev/null 2>&1; then
        test_pass "No uncommitted changes"
    else
        test_info "There are uncommitted changes (this is OK during development)"
    fi
else
    test_fail "Not a git repository"
fi

# Summary
print_header "Test Summary"
echo -e "${GREEN}Passed: ${PASS}${NC}"
echo -e "${RED}Failed: ${FAIL}${NC}"
echo "═══════════════════════════════════════════════════════════════"

if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
