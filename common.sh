#!/bin/bash
# common.sh - Shared utility functions for installation scripts

# Configuration
LOG_DIR="/var/log/devops-install"
INSTALL_LOG="${LOG_DIR}/installation.log"
ERROR_LOG="${LOG_DIR}/error.log"

# Initialize log directory
mkdir -p "${LOG_DIR}"
touch "${INSTALL_LOG}" "${ERROR_LOG}"
chmod 644 "${INSTALL_LOG}" "${ERROR_LOG}"

# Logging functions
function log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[INFO] ${timestamp} - $1"
    if [[ -w "${INSTALL_LOG}" ]]; then
        echo "[INFO] ${timestamp} - $1" >> "${INSTALL_LOG}"
    fi
}

function log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[ERROR] ${timestamp} - $1"
    if [[ -w "${ERROR_LOG}" ]]; then
        echo "[ERROR] ${timestamp} - $1" >> "${ERROR_LOG}"
    fi
}

# Validation function
function validate_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi
}

# Function to check if a command exists
function check_command() {
    command -v "$1" &> /dev/null
}