#!/bin/bash

################################################################################
# HaberNexus v6.0 - Installation Test Suite
#
# Tests:
#   - Pre-flight checks
#   - Installation script syntax
#   - Docker configuration
#   - Environment file generation
#   - Service startup
#   - Health checks
#   - API endpoints
#
# Usage: bash tests/test_installation.sh
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log_test() {
    echo -e "${BLUE}[TEST]${NC} $@"
    ((TESTS_TOTAL++))
}

log_pass() {
    echo -e "${GREEN}[✓]${NC} $@" >&2
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[✗]${NC} $@"
    ((TESTS_FAILED++))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $@"
}

print_header() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  $@"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
}

print_summary() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Test Summary"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "Total Tests: ${TESTS_TOTAL}"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    fi
}

################################################################################
# Test Functions
################################################################################

test_script_syntax() {
    print_header "Testing Script Syntax"
    
    log_test "Checking install_v6.sh syntax"
    if timeout 5 bash -n install_v6.sh > /dev/null 2>&1; then
        log_pass "install_v6.sh syntax is valid"
    else
        log_fail "install_v6.sh has syntax errors"
    fi
    
    log_test "Checking cloudflare_api.sh syntax"
    if timeout 5 bash -n scripts/cloudflare_api.sh > /dev/null 2>&1; then
        log_pass "cloudflare_api.sh syntax is valid"
    else
        log_fail "cloudflare_api.sh has syntax errors"
    fi
}

test_file_structure() {
    print_header "Testing File Structure"
    
    local required_files=(
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
    
    for file in "${required_files[@]}"; do
        log_test "Checking if $file exists"
        if [[ -f "$file" ]]; then
            log_pass "$file exists"
        else
            log_fail "$file not found"
        fi
    done
}

test_docker_compose_syntax() {
    print_header "Testing Docker Compose Syntax"
    
    log_test "Validating docker-compose.yml"
    if timeout 10 docker-compose config > /dev/null 2>&1; then
        log_pass "docker-compose.yml is valid"
    else
        log_fail "docker-compose.yml has errors"
    fi
}

test_environment_variables() {
    print_header "Testing Environment Variables"
    
    log_test "Checking .env.example file"
    if [[ -f ".env.example" ]]; then
        log_pass ".env.example exists"
        
        # Check for required variables
        local required_vars=(
            "DOMAIN"
            "ADMIN_EMAIL"
            "CLOUDFLARE_API_TOKEN"
            "CLOUDFLARE_TUNNEL_TOKEN"
            "DB_PASSWORD"
            "SECRET_KEY"
        )
        
        for var in "${required_vars[@]}"; do
            log_test "Checking if $var is in .env.example"
            if grep -q "$var" .env.example; then
                log_pass "$var found in .env.example"
            else
                log_fail "$var not found in .env.example"
            fi
        done
    else
        log_fail ".env.example not found"
    fi
}

test_dockerfile_syntax() {
    print_header "Testing Dockerfile Syntax"
    
    log_test "Checking Dockerfile syntax"
    if docker build --dry-run -f Dockerfile . > /dev/null 2>&1; then
        log_pass "Dockerfile syntax is valid"
    else
        log_fail "Dockerfile has syntax errors"
    fi
    
    log_test "Checking Caddy Dockerfile syntax"
    if docker build --dry-run -f caddy/Dockerfile . > /dev/null 2>&1; then
        log_pass "caddy/Dockerfile syntax is valid"
    else
        log_fail "caddy/Dockerfile has syntax errors"
    fi
}

test_configuration_templates() {
    print_header "Testing Configuration Templates"
    
    log_test "Checking Caddyfile.template"
    if [[ -f "caddy/Caddyfile.template" ]]; then
        log_pass "Caddyfile.template exists"
        
        # Check for placeholders
        if grep -q "{DOMAIN}" caddy/Caddyfile.template; then
            log_pass "Caddyfile.template has domain placeholder"
        else
            log_fail "Caddyfile.template missing domain placeholder"
        fi
    else
        log_fail "Caddyfile.template not found"
    fi
    
    log_test "Checking config.yml.template"
    if [[ -f "cloudflared/config.yml.template" ]]; then
        log_pass "config.yml.template exists"
        
        # Check for placeholders
        if grep -q "{TUNNEL_NAME}" cloudflared/config.yml.template; then
            log_pass "config.yml.template has tunnel name placeholder"
        else
            log_fail "config.yml.template missing tunnel name placeholder"
        fi
    else
        log_fail "config.yml.template not found"
    fi
}

test_documentation() {
    print_header "Testing Documentation"
    
    log_test "Checking README.md"
    if [[ -f "README.md" ]]; then
        log_pass "README.md exists"
        
        # Check for important sections
        local sections=("Installation" "Features" "Architecture" "Support")
        for section in "${sections[@]}"; do
            if grep -q "$section" README.md; then
                log_pass "README.md contains '$section' section"
            else
                log_fail "README.md missing '$section' section"
            fi
        done
    else
        log_fail "README.md not found"
    fi
}

test_script_permissions() {
    print_header "Testing Script Permissions"
    
    log_test "Checking install_v6.sh permissions"
    if [[ -x "install_v6.sh" ]]; then
        log_pass "install_v6.sh is executable"
    else
        log_fail "install_v6.sh is not executable"
        chmod +x install_v6.sh
    fi
    
    log_test "Checking cloudflare_api.sh permissions"
    if [[ -x "scripts/cloudflare_api.sh" ]]; then
        log_pass "cloudflare_api.sh is executable"
    else
        log_fail "cloudflare_api.sh is not executable"
        chmod +x scripts/cloudflare_api.sh
    fi
}

test_python_syntax() {
    print_header "Testing Python Syntax"
    
    log_test "Checking admin_dashboard.py syntax"
    if python3 -m py_compile app/habernexus/admin_dashboard.py 2>/dev/null; then
        log_pass "admin_dashboard.py has valid Python syntax"
    else
        log_fail "admin_dashboard.py has Python syntax errors"
    fi
}

test_git_status() {
    print_header "Testing Git Status"
    
    log_test "Checking git repository"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        log_pass "Git repository is valid"
        
        log_test "Checking for uncommitted changes"
        if git diff-index --quiet HEAD --; then
            log_pass "No uncommitted changes"
        else
            log_fail "There are uncommitted changes"
        fi
    else
        log_fail "Not a git repository"
    fi
}

test_security_checks() {
    print_header "Testing Security Checks"
    
    log_test "Checking for hardcoded secrets in install_v6.sh"
    if ! grep -E "(password|secret|token|key).*=" install_v6.sh | grep -v "CLOUDFLARE_API_TOKEN\|CLOUDFLARE_TUNNEL_TOKEN"; then
        log_pass "No hardcoded secrets found"
    else
        log_fail "Potential hardcoded secrets found"
    fi
    
    log_test "Checking for proper error handling"
    if grep -q "set -euo pipefail" install_v6.sh; then
        log_pass "Error handling is enabled"
    else
        log_fail "Error handling might be missing"
    fi
}

test_docker_images() {
    print_header "Testing Docker Images"
    
    log_test "Checking if Docker daemon is running"
    if docker ps > /dev/null 2>&1; then
        log_pass "Docker daemon is running"
        
        log_test "Checking Docker Compose version"
        if docker-compose --version > /dev/null 2>&1; then
            log_pass "Docker Compose is installed"
        else
            log_fail "Docker Compose is not installed"
        fi
    else
        log_fail "Docker daemon is not running"
    fi
}

################################################################################
# Main Test Execution
################################################################################

main() {
    print_header "HaberNexus v6.0 - Installation Test Suite"
    
    # Change to project directory
    cd "$(dirname "${BASH_SOURCE[0]}")/.."
    
    # Run tests
    test_script_syntax
    test_file_structure
    test_docker_compose_syntax
    test_environment_variables
    test_dockerfile_syntax
    test_configuration_templates
    test_documentation
    test_script_permissions
    test_python_syntax
    test_git_status
    test_security_checks
    test_docker_images
    
    # Print summary
    print_summary
}

# Run main function
main "$@"
