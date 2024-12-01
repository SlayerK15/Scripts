#!/bin/bash

# Exit on any error
set -e

# Script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check script existence
check_script() {
    local script=$1
    if [ ! -f "$SCRIPT_DIR/$script" ]; then
        echo "Error: $script not found in $SCRIPT_DIR"
        return 1
    fi
    # Make script executable
    chmod +x "$SCRIPT_DIR/$script"
}

# Function to run installation script
run_installation() {
    local tool=$1
    local script=$2
    
    echo "================================================================"
    echo "Starting $tool installation..."
    echo "================================================================"
    
    if check_script "$script"; then
        if sudo "$SCRIPT_DIR/$script"; then
            echo "$tool installation completed successfully"
        else
            echo "$tool installation failed"
            return 1
        fi
    else
        echo "$tool installation skipped - script not found"
        return 1
    fi
    
    echo
}

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run this script with sudo"
    exit 1
fi

# Installation order
declare -A installations=(
    ["Docker"]="installdocker.sh"
    ["Jenkins"]="installjenkins.sh"
    ["Kubernetes"]="installk8s.sh"
    ["Minikube"]="installminikube.sh"
    ["Terraform"]="installterraform.sh"
)

# Print installation plan
echo "Installation Plan:"
for tool in "${!installations[@]}"; do
    echo "- $tool"
done
echo

# Confirmation prompt
read -p "Do you want to proceed with the installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled"
    exit 1
fi

# Track overall success
SUCCESS=true

# Run installations
for tool in "${!installations[@]}"; do
    if ! run_installation "$tool" "${installations[$tool]}"; then
        SUCCESS=false
    fi
done

# Final status
echo "================================================================"
if [ "$SUCCESS" = true ]; then
    echo "All tools were installed successfully!"
else
    echo "Some installations failed. Please check the logs above."
    exit 1
fi

echo "
Installation Summary:
- Docker
- Jenkins
- Kubernetes
- Minikube
- Terraform

You may need to log out and back in for some changes to take effect.
Run 'source ~/.bashrc' to update your current session.
================================================================"
