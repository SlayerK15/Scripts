#!/bin/bash

# Get script directory and source common functions if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/common.sh" ]]; then
    source "${SCRIPT_DIR}/common.sh"
else
    log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
    log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
    validate_root() { [[ $EUID -ne 0 ]] && echo "This script must be run as root" && exit 1; }
fi

# Validate root access
validate_root

# Check if Docker is already installed and running
if command -v docker &> /dev/null && docker info &> /dev/null; then
    docker_version=$(docker --version | cut -d' ' -f3 | tr -d ',')
    log_info "Docker is already installed and running (version: $docker_version)"
    
    # Ensure user is in docker group even if Docker is installed
    if ! groups "${SUDO_USER:-$USER}" | grep -q docker; then
        usermod -aG docker "${SUDO_USER:-$USER}"
        log_info "Added ${SUDO_USER:-$USER} to docker group"
        newgrp docker < <(echo "")
    fi
else
    log_info "Starting Docker installation"
    
    # Remove existing installations
    log_info "Removing existing Docker installations"
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        apt-get remove -y $pkg || true
    done

    # Install prerequisites
    log_info "Installing prerequisites"
    apt-get update
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        apt-transport-https \
        software-properties-common \
        git

    # Add Docker repository
    log_info "Adding Docker repository"
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    log_info "Installing Docker"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Configure Docker groups
    log_info "Configuring user groups for Docker"
    usermod -aG docker "${SUDO_USER:-$USER}"
    log_info "Added ${SUDO_USER:-$USER} to docker group"
    newgrp docker < <(echo "")

    # Enable and start Docker service
    log_info "Enabling and starting Docker services"
    systemctl enable docker.service
    systemctl enable containerd.service
    systemctl start docker
fi

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    log_info "Installing Docker Compose"
    LATEST_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    curl -L "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log_info "Docker Compose installed successfully"
else
    compose_version=$(docker-compose --version | cut -d' ' -f3 | tr -d ',')
    log_info "Docker Compose is already installed (version: $compose_version)"
fi

# Create version file
log_info "Creating version information file"
docker_version_file="/home/${SUDO_USER:-$USER}/docker_version.txt"
{
    echo "Docker Version:"
    docker --version
    echo -e "\nDocker Compose Version:"
    docker-compose --version
} > "$docker_version_file"
log_info "Version information saved to $docker_version_file"

# Verify installation
if docker run hello-world; then
    log_info "Docker installation and configuration completed successfully"
    exit 0
else
    log_error "Docker installation verification failed"
    exit 1
fi
