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

# Check if Minikube is already installed
if command -v minikube &> /dev/null; then
    minikube_version=$(minikube version --short 2>/dev/null)
    log_info "Minikube is already installed (version: $minikube_version)"
    exit 0
fi

log_info "Starting Minikube installation"

# Check for Docker
if ! command -v docker &> /dev/null; then
    if [[ -f "${SCRIPT_DIR}/installdocker.sh" ]]; then
        log_info "Docker not found, installing Docker first"
        bash "${SCRIPT_DIR}/installdocker.sh"
    else
        log_error "Docker is required but not installed and installdocker.sh not found"
        exit 1
    fi
fi

# Download and install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Verify Minikube installation
if ! command -v minikube &> /dev/null; then
    log_error "Minikube installation failed"
    exit 1
fi

# Start Minikube as the original user
ORIGINAL_USER="${SUDO_USER:-$USER}"
su - "${ORIGINAL_USER}" -c "minikube start"

if minikube status; then
    log_info "Minikube installation and startup completed successfully"
    exit 0
else
    log_error "Minikube startup failed"
    exit 1
fi