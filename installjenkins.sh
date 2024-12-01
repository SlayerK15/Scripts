#!/bin/bash

# Function to check if Java is installed
function check_java() {
    if java -version 2>&1 >/dev/null; then
        echo "Java is already installed:"
        java -version
        return 0
    else
        echo "Java is not installed"
        return 1
    fi
}

# Main installation script
echo "Checking Java installation..."
if ! check_java; then
    echo "Installing OpenJDK 17..."
    sudo apt update
    sudo apt install -y fontconfig openjdk-17-jre
    
    # Verify Java installation
    if ! check_java; then
        echo "Java installation failed. Exiting..."
        exit 1
    fi
fi

# Proceed with Jenkins installation
echo "Installing Jenkins..."
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update
sudo apt-get install -y jenkins

# Verify Jenkins service status
echo "Checking Jenkins service status..."
sudo systemctl status jenkins | grep Active

echo "Jenkins installation completed"
echo "Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
