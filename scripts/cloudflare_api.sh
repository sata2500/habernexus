#!/bin/bash

################################################################################
# Cloudflare API Helper Functions
# 
# Provides functions for:
#   - DNS record management
#   - Tunnel configuration
#   - Zone management
#
# Usage: source scripts/cloudflare_api.sh
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $@"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $@"
}

log_error() {
    echo -e "${RED}[✗]${NC} $@"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $@"
}

################################################################################
# Cloudflare API Functions
################################################################################

# Get Zone ID for a domain
get_zone_id() {
    local domain=$1
    local api_token=$2
    
    if [[ -z "$domain" || -z "$api_token" ]]; then
        log_error "get_zone_id: Missing parameters"
        return 1
    fi
    
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain}" \
        -H "Authorization: Bearer ${api_token}" \
        -H "Content-Type: application/json")
    
    # Check if request was successful
    if ! echo "$response" | grep -q '"success":true'; then
        log_error "Failed to get Zone ID: $response"
        return 1
    fi
    
    # Extract Zone ID
    local zone_id=$(echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [[ -z "$zone_id" ]]; then
        log_error "Could not extract Zone ID from response"
        return 1
    fi
    
    echo "$zone_id"
}

# Create DNS CNAME record
create_dns_record() {
    local zone_id=$1
    local domain=$2
    local target=$3
    local api_token=$4
    
    if [[ -z "$zone_id" || -z "$domain" || -z "$target" || -z "$api_token" ]]; then
        log_error "create_dns_record: Missing parameters"
        return 1
    fi
    
    log_info "Creating DNS record: $domain → $target"
    
    local response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records" \
        -H "Authorization: Bearer ${api_token}" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"CNAME\",
            \"name\": \"${domain}\",
            \"content\": \"${target}\",
            \"ttl\": 1,
            \"proxied\": false
        }")
    
    # Check if request was successful
    if echo "$response" | grep -q '"success":true'; then
        log_success "DNS record created: $domain"
        return 0
    else
        log_error "Failed to create DNS record: $response"
        return 1
    fi
}

# Delete DNS record
delete_dns_record() {
    local zone_id=$1
    local record_id=$2
    local api_token=$3
    
    if [[ -z "$zone_id" || -z "$record_id" || -z "$api_token" ]]; then
        log_error "delete_dns_record: Missing parameters"
        return 1
    fi
    
    log_info "Deleting DNS record: $record_id"
    
    local response=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}" \
        -H "Authorization: Bearer ${api_token}" \
        -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"success":true'; then
        log_success "DNS record deleted"
        return 0
    else
        log_error "Failed to delete DNS record: $response"
        return 1
    fi
}

# List DNS records
list_dns_records() {
    local zone_id=$1
    local api_token=$2
    
    if [[ -z "$zone_id" || -z "$api_token" ]]; then
        log_error "list_dns_records: Missing parameters"
        return 1
    fi
    
    log_info "Listing DNS records for zone: $zone_id"
    
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records" \
        -H "Authorization: Bearer ${api_token}" \
        -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"success":true'; then
        echo "$response" | jq '.result[] | {name, type, content, id}'
        return 0
    else
        log_error "Failed to list DNS records: $response"
        return 1
    fi
}

# Get DNS record by name
get_dns_record() {
    local zone_id=$1
    local record_name=$2
    local api_token=$3
    
    if [[ -z "$zone_id" || -z "$record_name" || -z "$api_token" ]]; then
        log_error "get_dns_record: Missing parameters"
        return 1
    fi
    
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=${record_name}" \
        -H "Authorization: Bearer ${api_token}" \
        -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"success":true'; then
        echo "$response" | jq '.result[0]'
        return 0
    else
        log_error "Failed to get DNS record: $response"
        return 1
    fi
}

# Update DNS record
update_dns_record() {
    local zone_id=$1
    local record_id=$2
    local content=$3
    local api_token=$4
    
    if [[ -z "$zone_id" || -z "$record_id" || -z "$content" || -z "$api_token" ]]; then
        log_error "update_dns_record: Missing parameters"
        return 1
    fi
    
    log_info "Updating DNS record: $record_id"
    
    local response=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}" \
        -H "Authorization: Bearer ${api_token}" \
        -H "Content-Type: application/json" \
        -d "{
            \"content\": \"${content}\"
        }")
    
    if echo "$response" | grep -q '"success":true'; then
        log_success "DNS record updated"
        return 0
    else
        log_error "Failed to update DNS record: $response"
        return 1
    fi
}

# Get Tunnel information
get_tunnel_info() {
    local account_id=$1
    local tunnel_id=$2
    local api_token=$3
    
    if [[ -z "$account_id" || -z "$tunnel_id" || -z "$api_token" ]]; then
        log_error "get_tunnel_info: Missing parameters"
        return 1
    fi
    
    log_info "Getting tunnel info: $tunnel_id"
    
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/${account_id}/cfd_tunnel/${tunnel_id}" \
        -H "Authorization: Bearer ${api_token}" \
        -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"success":true'; then
        echo "$response" | jq '.result'
        return 0
    else
        log_error "Failed to get tunnel info: $response"
        return 1
    fi
}

# Create Tunnel public hostname
create_public_hostname() {
    local account_id=$1
    local tunnel_id=$2
    local hostname=$3
    local service_url=$4
    local api_token=$5
    
    if [[ -z "$account_id" || -z "$tunnel_id" || -z "$hostname" || -z "$service_url" || -z "$api_token" ]]; then
        log_error "create_public_hostname: Missing parameters"
        return 1
    fi
    
    log_info "Creating public hostname: $hostname → $service_url"
    
    local response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${account_id}/cfd_tunnel/${tunnel_id}/public_hostnames" \
        -H "Authorization: Bearer ${api_token}" \
        -H "Content-Type: application/json" \
        -d "{
            \"hostname\": \"${hostname}\",
            \"service\": \"${service_url}\"
        }")
    
    if echo "$response" | grep -q '"success":true'; then
        log_success "Public hostname created: $hostname"
        return 0
    else
        log_error "Failed to create public hostname: $response"
        return 1
    fi
}

# Verify API token
verify_api_token() {
    local api_token=$1
    
    if [[ -z "$api_token" ]]; then
        log_error "verify_api_token: Missing API token"
        return 1
    fi
    
    log_info "Verifying API token..."
    
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
        -H "Authorization: Bearer ${api_token}" \
        -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"success":true'; then
        log_success "API token verified"
        return 0
    else
        log_error "Invalid API token"
        return 1
    fi
}

# Get account ID from API token
get_account_id() {
    local api_token=$1
    
    if [[ -z "$api_token" ]]; then
        log_error "get_account_id: Missing API token"
        return 1
    fi
    
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
        -H "Authorization: Bearer ${api_token}" \
        -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"success":true'; then
        local account_id=$(echo "$response" | jq -r '.result[0].id')
        echo "$account_id"
        return 0
    else
        log_error "Failed to get account ID: $response"
        return 1
    fi
}

################################################################################
# Utility Functions
################################################################################

# Validate domain
validate_domain() {
    local domain=$1
    
    if [[ ! $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    
    return 0
}

# Validate email
validate_email() {
    local email=$1
    
    if [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    
    return 0
}

# Extract tunnel UUID from token
extract_tunnel_uuid() {
    local token=$1
    
    if [[ -z "$token" ]]; then
        log_error "extract_tunnel_uuid: Missing token"
        return 1
    fi
    
    # Try to decode base64
    local decoded=$(echo "$token" | base64 -d 2>/dev/null || echo "")
    
    if [[ -z "$decoded" ]]; then
        log_warning "Could not decode tunnel token"
        return 1
    fi
    
    # Extract tunnel ID from JSON
    local tunnel_uuid=$(echo "$decoded" | grep -o '"t":"[^"]*"' | cut -d'"' -f4 || echo "")
    
    if [[ -z "$tunnel_uuid" ]]; then
        log_warning "Could not extract tunnel UUID"
        return 1
    fi
    
    echo "$tunnel_uuid"
}

################################################################################
# Export functions (if sourced)
################################################################################

export -f get_zone_id
export -f create_dns_record
export -f delete_dns_record
export -f list_dns_records
export -f get_dns_record
export -f update_dns_record
export -f get_tunnel_info
export -f create_public_hostname
export -f verify_api_token
export -f get_account_id
export -f validate_domain
export -f validate_email
export -f extract_tunnel_uuid
export -f log_info
export -f log_success
export -f log_error
export -f log_warning
