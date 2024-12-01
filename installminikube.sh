#!/bin/bash

# Exit on any error
set -e

echo "Starting Minikube installation..."

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run this script with sudo"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verify Docker installation
if ! command_exists docker; then
    if [ -f "./installdocker.sh" ]; then
        echo "Docker not found. Installing Docker using installdocker.sh..."
        bash ./installdocker.sh
    else
        echo "Error: Docker is not installed and installdocker.sh not found"
        exit 1
    fi
fi

# Verify Docker service is running
if ! systemctl is-active --quiet docker; then
    echo "Starting Docker service..."
    systemctl start docker
fi

# Download Minikube
echo "Downloading latest Minikube..."
if ! curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64; then
    echo "Error: Failed to download Minikube"
    exit 1
fi

# Install Minikube
echo "Installing Minikube..."
if ! install minikube-linux-amd64 /usr/local/bin/minikube; then
    echo "Error: Failed to install Minikube"
    rm minikube-linux-amd64
    exit 1
fi

# Clean up downloaded file
rm minikube-linux-amd64

# Verify Minikube installation
if ! command_exists minikube; then
    echo "Error: Minikube installation failed"
    exit 1
fi

echo "Starting Minikube..."
# Start Minikube as the original user, not as root
ORIGINAL_USER=$(logname)
su - $ORIGINAL_USER -c "minikube start"

echo "Minikube installation and startup complete!"
echo "You can now use 'minikube status' to verify the cluster status"
