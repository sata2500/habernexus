#!/bin/bash

# Function to clean up the environment
cleanup_environment() {
    echo "Cleaning up existing environment..."
    
    # Stop all running containers related to the project
    if [ -d "/opt/habernexus" ]; then
        cd /opt/habernexus
        if command -v docker &> /dev/null && docker compose version &> /dev/null; then
            docker compose down -v --remove-orphans >/dev/null 2>&1
        fi
    fi

    # Remove project directory
    rm -rf /opt/habernexus

    # Prune Docker system to remove unused containers, networks, and images (optional, use with caution)
    # docker system prune -af --volumes >/dev/null 2>&1

    echo "Environment cleanup complete."
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)."
    exit 1
fi

cleanup_environment
