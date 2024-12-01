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

# Check if Terraform is already installed
if command -v terraform &> /dev/null; then
    terraform_version=$(terraform version -json | grep -o '"version": *"[^"]*"' | cut -d'"' -f4)
    log_info "Terraform is already installed (version: $terraform_version)"
    exit 0
fi

log_info "Starting Terraform installation"

# Install wget
apt-get update
apt-get install -y wget

# Add HashiCorp GPG key
wget -O - https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform
apt-get update
apt-get install -y terraform

# Verify installation
if terraform version; then
    log_info "Terraform installation completed successfully"
    exit 0
else
    log_error "Terraform installation failed"
    exit 1
fi