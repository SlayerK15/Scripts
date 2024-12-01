#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/common.sh" ]]; then
    source "${SCRIPT_DIR}/common.sh"
else
    log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
    log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
    validate_root() { [[ $EUID -ne 0 ]] && echo "This script must be run as root" && exit 1; }
fi

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
    exit 0
fi

log_info "Starting Docker installation"

# Remove existing installations
log_info "Removing existing Docker installations"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    apt-get remove -y $pkg || true
done

# Install prerequisites
log_info "Installing prerequisites"
apt-get update
apt-get install -y ca-certificates curl gnupg

# Add Docker repository
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure Docker groups
log_info "Configuring user groups for Docker"

# Add current user to docker group
usermod -aG docker "${SUDO_USER:-$USER}"
log_info "Added ${SUDO_USER:-$USER} to docker group"

# Apply group changes in current session
newgrp docker < <(echo "")
log_info "Applied docker group changes"

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Verify installation
if docker run hello-world; then
    log_info "Docker installation and group configuration completed successfully"
    exit 0
else
    log_error "Docker installation verification failed"
    exit 1
fi