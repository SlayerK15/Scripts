# DevOps Tools Installation Suite

A comprehensive collection of installation scripts for common DevOps tools on Ubuntu/Debian systems.

## Tools Available

- Docker - Container runtime and management
- Jenkins - Continuous Integration/Continuous Deployment server
- Kubernetes (kubectl) - Kubernetes command-line tool
- Minikube - Local Kubernetes cluster
- Terraform - Infrastructure as Code tool

## Prerequisites

- Ubuntu/Debian-based Linux distribution
- Root/sudo privileges
- Internet connection
- Git (optional, for cloning the repository)

## Installation

1. Get the scripts:

   ```bash
   #Clone the repository
   git clone https://github.com/SlayerK15/Scripts.git
   cd devops-tools
   
   ```

2. Make scripts executable:

   ```bash
   chmod +x *.sh
   ```

## Usage

### Basic Usage

```bash
# Check available options
sudo ./setup.sh --help

# Check status of all tools
sudo ./setup.sh --status

# Install specific tools
sudo ./setup.sh docker jenkins

# Install all tools
sudo ./setup.sh --all
```

### Advanced Options

```bash
# Force reinstallation of tools (even if already installed)
sudo ./setup.sh --force docker

# Clean existing installations before installing
sudo ./setup.sh --clean --all

# List available tools
sudo ./setup.sh --list
```

### Individual Tool Installation

You can also install tools individually:

```bash
sudo ./installdocker.sh
sudo ./installjenkins.sh
sudo ./installk8s.sh
sudo ./installminikube.sh
sudo ./installterraform.sh
```

## Script Features

- Automatic dependency resolution
- Installation status checking
- Detailed logging
- Error handling
- Clean installation options
- Force installation options

## Logging

Logs are stored in `/var/log/devops-install/`:
- `installation.log` - General installation information
- `error.log` - Error messages and failures

## Post-Installation

### Docker
- The current user is automatically added to the docker group
- You may need to log out and back in for group changes to take effect
- Verify installation: `docker run hello-world`

### Jenkins
- Access Jenkins at: `http://localhost:8080`
- Initial admin password is displayed during installation
- Also found at: `/var/lib/jenkins/secrets/initialAdminPassword`

### Kubernetes
- Verify installation: `kubectl version --client`
- Configure kubectl: Set up your `~/.kube/config`

### Minikube
- Verify installation: `minikube status`
- Start Minikube: `minikube start`
- Stop Minikube: `minikube stop`

### Terraform
- Verify installation: `terraform --version`
- Initialize a project: `terraform init`

## Troubleshooting

1. **Permission Denied**
   ```bash
   # Make sure to run with sudo
   sudo ./setup.sh [options]
   ```

2. **Tool Already Installed**
   ```bash
   # Use force option to reinstall
   sudo ./setup.sh --force [tool]
   ```

3. **Clean Installation**
   ```bash
   # Remove existing installation and reinstall
   sudo ./setup.sh --clean [tool]
   ```

4. **Check Logs**
   ```bash
   # View installation logs
   sudo cat /var/log/devops-install/installation.log
   sudo cat /var/log/devops-install/error.log
   ```

## Security Notes

- All scripts require root privileges
- GPG keys are verified during installation
- Repository sources are validated
- Secure default configurations are applied

## Compatibility

Tested on:
- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Debian 11
- Debian 12
