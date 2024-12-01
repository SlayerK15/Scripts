#!/bin/bash

# Exit on any error
set -e

echo "Starting Terraform installation..."

# Check if wget is installed
if ! command -v wget &> /dev/null; then
    echo "wget not found. Installing wget..."
    sudo apt-get update && sudo apt-get install -y wget
fi

# Download and add HashiCorp GPG key
echo "Adding HashiCorp GPG key..."
if ! wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg; then
    echo "Failed to add GPG key"
    exit 1
fi

# Add HashiCorp repository
echo "Adding HashiCorp repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update package list and install Terraform
echo "Updating package list and installing Terraform..."
if ! sudo apt-get update; then
    echo "Failed to update package list"
    exit 1
fi

if ! sudo apt-get install -y terraform; then
    echo "Failed to install Terraform"
    exit 1
fi

# Verify installation
if ! command -v terraform &> /dev/null; then
    echo "Terraform installation verification failed"
    exit 1
fi

# Display success message and version
echo "Terraform installation successful!"
terraform --version
echo "You can now use Terraform. Try 'terraform --help' to get started."
