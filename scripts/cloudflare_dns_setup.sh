#!/bin/bash

################################################################################
# HaberNexus - Cloudflare DNS Setup Script
# Automatically creates DNS records and configures tunnel
# Requirements: curl, jq
################################################################################

set -eo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Logging Functions ---
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log_step() {
    echo -e "\n${BLUE}==>${NC} $1"
}

# --- Validation Functions ---
validate_token() {
    local token=$1
    if [[ -z "$token" ]]; then
        return 1
    fi
    return 0
}

validate_domain() {
    local domain=$1
    if [[ $domain =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# --- Cloudflare API Functions ---
get_zone_id() {
    local domain=$1
    local api_token=$2
    
    log_info "Getting Zone ID for $domain..."
    
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json")
    
    local zone_id=$(echo "$response" | jq -r '.result[0].id' 2>/dev/null)
    
    if [[ -z "$zone_id" ]] || [[ "$zone_id" == "null" ]]; then
        log_error "Could not find zone for domain: $domain"
    fi
    
    echo "$zone_id"
}

create_dns_record() {
    local zone_id=$1
    local record_type=$2
    local record_name=$3
    local record_content=$4
    local api_token=$5
    local proxied=${6:-true}
    
    log_info "Creating DNS record: $record_name ($record_type)"
    
    local response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"$record_type\",
            \"name\": \"$record_name\",
            \"content\": \"$record_content\",
            \"ttl\": 1,
            \"proxied\": $proxied
        }")
    
    local success=$(echo "$response" | jq -r '.success' 2>/dev/null)
    
    if [[ "$success" != "true" ]]; then
        local error=$(echo "$response" | jq -r '.errors[0].message' 2>/dev/null)
        log_warn "Failed to create DNS record: $error"
        return 1
    fi
    
    log_info "DNS record created successfully"
    return 0
}

update_tunnel_config() {
    local zone_id=$1
    local tunnel_id=$2
    local domain=$3
    local api_token=$4
    
    log_step "Configuring Tunnel Public Hostnames"
    
    log_info "Setting up public hostname for $domain..."
    
    # This would require additional API calls to configure the tunnel
    # For now, we'll provide instructions
    log_warn "Please configure Public Hostnames in Cloudflare Dashboard:"
    echo ""
    echo "1. Go to: https://one.dash.cloudflare.com/networks/tunnels"
    echo "2. Select your tunnel: $tunnel_id"
    echo "3. Click 'Public Hostname'"
    echo "4. Add the following hostnames:"
    echo "   - Subdomain: (empty), Domain: $domain, Service: HTTP, URL: http://nginx_proxy_manager:81"
    echo "   - Subdomain: *, Domain: $domain, Service: HTTP, URL: http://nginx_proxy_manager:81"
    echo ""
}

# --- Main Functions ---
setup_dns_records() {
    log_step "Setting up Cloudflare DNS Records"
    
    # Get inputs
    read -p "Enter your domain (e.g., habernexus.com): " DOMAIN
    if ! validate_domain "$DOMAIN"; then
        log_error "Invalid domain format"
    fi
    
    read -p "Enter your Cloudflare API Token: " API_TOKEN
    if ! validate_token "$API_TOKEN"; then
        log_error "Invalid API token"
    fi
    
    read -p "Enter your Cloudflare Tunnel ID: " TUNNEL_ID
    if [[ -z "$TUNNEL_ID" ]]; then
        log_error "Tunnel ID is required"
    fi
    
    # Get Zone ID
    ZONE_ID=$(get_zone_id "$DOMAIN" "$API_TOKEN")
    log_info "Zone ID: $ZONE_ID"
    
    # Create DNS records
    TUNNEL_CNAME="${TUNNEL_ID}.cfargotunnel.com"
    
    # Main domain
    create_dns_record "$ZONE_ID" "CNAME" "$DOMAIN" "$TUNNEL_CNAME" "$API_TOKEN" "true"
    
    # Wildcard subdomain
    create_dns_record "$ZONE_ID" "CNAME" "*.$DOMAIN" "$TUNNEL_CNAME" "$API_TOKEN" "true"
    
    # Update tunnel configuration
    update_tunnel_config "$ZONE_ID" "$TUNNEL_ID" "$DOMAIN" "$API_TOKEN"
    
    log_step "DNS Setup Complete"
    log_info "DNS records have been created successfully"
    log_info "Please complete the Public Hostname configuration in Cloudflare Dashboard"
}

# --- Main Execution ---
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  HaberNexus - Cloudflare DNS Setup${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"

# Check dependencies
if ! command -v curl &> /dev/null; then
    log_error "curl is required but not installed"
fi

if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed"
fi

setup_dns_records
