#!/bin/bash

#############################################################################
# Haber Nexus VM Migration Script
# Migrates entire application to a new VM with one command
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    log_error "Usage: $0 <source_backup_path> <target_vm_user@target_vm_host>"
    log_info "Example: $0 .backup/habernexus_backup_20231206_120000 ubuntu@34.185.172.35"
    exit 1
fi

BACKUP_PATH="$1"
TARGET_VM="$2"
TARGET_USER=$(echo $TARGET_VM | cut -d@ -f1)
TARGET_HOST=$(echo $TARGET_VM | cut -d@ -f2)

# Verify backup exists
if [ ! -d "$BACKUP_PATH" ]; then
    log_error "Backup directory not found: $BACKUP_PATH"
    exit 1
fi

# Create compressed backup if not already done
log_section "Preparing Backup"
if [ ! -f "${BACKUP_PATH}.tar.gz" ]; then
    log_info "Creating compressed backup archive..."
    BACKUP_DIR=$(dirname "$BACKUP_PATH")
    BACKUP_NAME=$(basename "$BACKUP_PATH")
    tar -czf "${BACKUP_PATH}.tar.gz" -C "${BACKUP_DIR}" "${BACKUP_NAME}"
fi

BACKUP_SIZE=$(du -sh "${BACKUP_PATH}.tar.gz" | cut -f1)
log_info "Backup size: ${BACKUP_SIZE}"

# Test SSH connection
log_section "Testing SSH Connection"
log_info "Testing connection to ${TARGET_VM}..."
if ssh -o ConnectTimeout=5 "${TARGET_VM}" "echo 'SSH connection successful'" > /dev/null 2>&1; then
    log_info "✅ SSH connection successful"
else
    log_error "Cannot connect to ${TARGET_VM}"
    log_info "Please ensure:"
    log_info "  1. Target VM is running"
    log_info "  2. SSH key is configured"
    log_info "  3. User has sudo privileges"
    exit 1
fi

# Prepare target VM
log_section "Preparing Target VM"
log_info "Installing Docker and Docker Compose on target VM..."
ssh "${TARGET_VM}" << 'EOF'
    set -e
    
    # Update system
    sudo apt-get update
    sudo apt-get upgrade -y
    
    # Install Docker
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
    fi
    
    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    
    echo "✅ Docker and Docker Compose installed"
EOF

# Transfer backup to target VM
log_section "Transferring Backup"
log_info "Uploading backup to ${TARGET_VM}..."
log_info "This may take a few minutes depending on backup size..."

scp -C "${BACKUP_PATH}.tar.gz" "${TARGET_VM}:~/"

if [ $? -eq 0 ]; then
    log_info "✅ Backup transferred successfully"
else
    log_error "Backup transfer failed"
    exit 1
fi

# Clone repository on target VM
log_section "Setting Up Application"
log_info "Cloning repository on target VM..."
ssh "${TARGET_VM}" << 'EOF'
    set -e
    
    # Clone repository
    if [ ! -d "habernexus" ]; then
        git clone https://github.com/sata2500/habernexus.git
    fi
    
    cd habernexus
    git fetch origin
    git reset --hard origin/main
    
    echo "✅ Repository cloned/updated"
EOF

# Extract and restore backup
log_section "Restoring Data"
log_info "Extracting and restoring backup on target VM..."
ssh "${TARGET_VM}" << 'EOF'
    set -e
    
    cd habernexus
    
    # Extract backup
    BACKUP_FILE=$(ls ~/*.tar.gz | head -1)
    BACKUP_NAME=$(basename $BACKUP_FILE .tar.gz)
    
    mkdir -p .backup
    tar -xzf ~/$BACKUP_FILE -C .backup
    
    # Run restore script
    chmod +x scripts/restore.sh
    ./scripts/restore.sh ".backup/${BACKUP_NAME}"
    
    # Cleanup
    rm ~/$BACKUP_FILE
    
    echo "✅ Data restored successfully"
EOF

# Verify deployment
log_section "Verifying Deployment"
log_info "Checking application health..."
ssh "${TARGET_VM}" << 'EOF'
    set -e
    
    cd habernexus
    
    # Wait for application
    for i in {1..30}; do
        if curl -f http://localhost:8000/health/ > /dev/null 2>&1; then
            echo "✅ Application is healthy!"
            break
        fi
        echo "Waiting for application... ($i/30)"
        sleep 2
    done
    
    # Show container status
    echo ""
    echo "Container status:"
    docker-compose -f docker-compose.prod.yml ps
EOF

# Final instructions
log_section "Migration Complete!"
log_info "✅ Application successfully migrated to ${TARGET_VM}"
log_info ""
log_info "Next steps:"
log_info "1. Update DNS records to point to the new VM"
log_info "2. Configure SSL certificates on the new VM"
log_info "3. Test the application at https://habernexus.com"
log_info "4. Update GitHub Actions secrets with new VM details (if needed)"
log_info ""
log_info "To access the new VM:"
log_info "  ssh ${TARGET_VM}"
log_info ""
log_info "To view logs:"
log_info "  ssh ${TARGET_VM} 'cd habernexus && docker-compose -f docker-compose.prod.yml logs -f'"
log_info ""
