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

# Check if kubectl is already installed
if command -v kubectl &> /dev/null; then
    kubectl_version=$(kubectl version --client --short 2>/dev/null)
    log_info "kubectl is already installed (version: $kubectl_version)"
    exit 0
fi

log_info "Starting Kubernetes CLI installation"

# Install prerequisites
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg

# Add Kubernetes repository
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
    https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | \
    tee /etc/apt/sources.list.d/kubernetes.list

# Install kubectl
apt-get update
apt-get install -y kubectl kubeadm kubelet

# Verify installation
if kubectl version --client; then
    log_info "Kubernetes CLI installation completed successfully"
    exit 0
else
    log_error "kubectl installation failed"
    exit 1
fi
