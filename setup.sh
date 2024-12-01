#!/bin/bash

# Exit on any error
set -e

# Variables
REPO_URL="https://github.com/SlayerK15/Scripts.git"
SCRIPTS_DIR="devops_tools"
LOG_FILE="installation_log.txt"
ERROR_LOG="error_log.txt"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize logs
> "${ERROR_LOG}"
echo "Installation started at: $(date)" > "${LOG_FILE}"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Function to log errors
log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "${ERROR_LOG}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install git if not present
ensure_git() {
    if ! command_exists git; then
        log_message "Installing git..."
        sudo apt-get update && sudo apt-get install -y git
    fi
}

# Function to clone repository
clone_repository() {
    log_message "Cloning scripts repository..."
    if [ -d "${SCRIPTS_DIR}" ]; then
        log_message "Directory exists, removing old files..."
        rm -rf "${SCRIPTS_DIR}"
    fi
    git clone "${REPO_URL}" "${SCRIPTS_DIR}"
}

# Function to check and fix scripts
check_and_fix_scripts() {
    cd "${SCRIPTS_DIR}"
    
    # Fix line endings
    find . -type f -name "*.sh" -exec dos2unix {} \;
    
    # Fix shebang lines
    find . -type f -name "*.sh" -exec sed -i '1s|^#!.*|#!/bin/bash|' {} \;
    
    # Make scripts executable
    chmod +x *.sh
    
    # Fix specific scripts
    
    # Fix Jenkins script
    sed -i 's|cat /var/lib/jenkins/secrets/initialAdminPassword|sleep 10 \&\& sudo cat /var/lib/jenkins/secrets/initialAdminPassword|' installjenkins.sh

    # Fix Docker script to handle existing installations
    sed -i '/apt-get remove/i if dpkg -l | grep -q "^ii.*docker"; then' installdocker.sh
    sed -i '/apt-get remove/a fi' installdocker.sh
    
    # Add error handling to Minikube script
    sed -i '/minikube start/i if ! command -v docker >/dev/null 2>\&1; then\n    echo "Docker is required but not installed. Installing Docker first..."\n    sudo ./installdocker.sh\nfi' installminikube.sh
    
    # Add verification to Terraform script
    sed -i '/terraform install/a if ! command -v terraform >/dev/null 2>\&1; then\n    echo "Terraform installation failed"\n    exit 1\nfi' installterraform.sh
    
    # Enhance main installation script
    cat > installtools.sh << 'EOF'
#!/bin/bash

# Exit on error
set -e

# Variables
LOG_FILE="installation_log.txt"
ERROR_LOG="error_log.txt"
FAILED_INSTALLATIONS=()

# Initialize logs
> "${ERROR_LOG}"
echo "Installation started at: $(date)" > "${LOG_FILE}"

# Function to handle installation
install_tool() {
    local tool=$1
    local script=$2
    
    echo "================================================================"
    echo "Installing ${tool}..."
    echo "================================================================"
    
    if sudo "./${script}" >> "${LOG_FILE}" 2>&1; then
        echo "✅ ${tool} installation completed successfully"
    else
        echo "❌ ${tool} installation failed"
        FAILED_INSTALLATIONS+=("${tool}")
        echo "${tool} installation failed. Check ${LOG_FILE} for details" >> "${ERROR_LOG}"
    fi
}

# Install tools
install_tool "Docker" "installdocker.sh"
install_tool "Jenkins" "installjenkins.sh"
install_tool "Kubernetes" "installk8s.sh"
install_tool "Minikube" "installminikube.sh"
install_tool "Terraform" "installterraform.sh"

# Report results
echo "================================================================"
echo "Installation Complete!"
echo "================================================================"

if [ ${#FAILED_INSTALLATIONS[@]} -eq 0 ]; then
    echo "✅ All installations completed successfully!"
else
    echo "❌ The following installations failed:"
    printf '%s\n' "${FAILED_INSTALLATIONS[@]}"
    echo "Please check ${ERROR_LOG} for details"
    exit 1
fi
EOF
}

# Main execution
echo "Starting installation setup..."

# Ensure git is installed
ensure_git

# Clone repository
clone_repository

# Check and fix scripts
check_and_fix_scripts

echo "
Scripts have been prepared successfully!

To start the installation:
cd ${SCRIPTS_DIR}
sudo ./installtools.sh

The installation will create two log files:
- ${LOG_FILE}: Detailed installation logs
- ${ERROR_LOG}: Error messages and failures

After installation, check these logs for any issues that occurred during the process.
"
