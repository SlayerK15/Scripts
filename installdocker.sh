#!/bin/bash

echo "Cleaning up old Docker installations..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg
done

echo "Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl

echo "Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installing Docker..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group to run docker without sudo
echo "Adding current user to docker group..."
sudo usermod -aG docker $USER

echo "Verifying Docker installation..."
sudo docker run hello-world

echo "Docker installation completed!"
echo "Docker version:"
docker --version
echo "🔍 Docker Compose version:"
docker compose version

echo -e "\n  NOTE: You may need to log out and back in for the docker group changes to take effect."
echo "To verify installation, try running: docker run hello-world"
