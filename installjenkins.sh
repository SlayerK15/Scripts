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

# Check if Jenkins is already installed and running
if systemctl is-active --quiet jenkins; then
    jenkins_version=$(java -jar /usr/share/jenkins/jenkins.war --version 2>/dev/null)
    log_info "Jenkins is already installed and running (version: $jenkins_version)"
    
    # Ensure Jenkins is in docker group if Docker is installed
    if command -v docker &> /dev/null && ! groups jenkins | grep -q docker; then
        usermod -aG docker jenkins
        systemctl restart jenkins
        log_info "Added Jenkins to docker group and restarted service"
    fi
    exit 0
fi

log_info "Starting Jenkins installation"

# Install Java
log_info "Installing OpenJDK 17"
apt-get update
apt-get install -y fontconfig openjdk-17-jre

# Verify Java installation
if ! java -version 2>&1 >/dev/null; then
    log_error "Java installation failed"
    exit 1
fi

# Install Jenkins
wget -q -O /usr/share/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/" | tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update
apt-get install -y jenkins

# Add Jenkins to docker group if Docker is installed
if command -v docker &> /dev/null; then
    log_info "Adding Jenkins user to docker group"
    usermod -aG docker jenkins
fi

# Start Jenkins
systemctl enable jenkins
systemctl start jenkins

# Wait for Jenkins to start and get initial password
log_info "Waiting for Jenkins to start (30 seconds)..."
sleep 30

if [[ -f /var/lib/jenkins/secrets/initialAdminPassword ]]; then
    log_info "Jenkins initial admin password: $(cat /var/lib/jenkins/secrets/initialAdminPassword)"
    log_info "Jenkins installation completed successfully"
    exit 0
else
    log_error "Could not retrieve Jenkins initial admin password"
    exit 1
fi