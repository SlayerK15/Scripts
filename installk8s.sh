#!/bin/bash

echo "Checking and creating required directories..."
if [ ! -d "/etc/apt/keyrings" ]; then
   sudo mkdir -p -m 755 /etc/apt/keyrings
   echo "Created /etc/apt/keyrings directory"
fi

echo "Updating package information..."
sudo apt-get update

echo "Installing prerequisites..."
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
if [ $? -ne 0 ]; then
   echo "Failed to install prerequisites. Exiting..."
   exit 1
fi

echo "Adding Kubernetes GPG key..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "Adding Kubernetes repository..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

echo "Installing kubectl..."
sudo apt-get update
sudo apt-get install -y kubectl

echo "Verifying kubectl installation..."
kubectl version --client

echo "Installation completed!"
echo "To verify installation, try running: kubectl version --client"

# Check if kubectl is in PATH
if ! command -v kubectl &> /dev/null; then
   echo "Warning: kubectl command not found in PATH"
   echo "Please check your installation"
else
   echo "kubectl is properly installed and accessible"
fi
