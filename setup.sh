#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging setup
LOG_DIR="/var/log/devops-install"
INSTALL_LOG="${LOG_DIR}/installation.log"
ERROR_LOG="${LOG_DIR}/error.log"

# Logging functions
log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[INFO] ${timestamp} - $1"
    if [[ -w "${INSTALL_LOG}" ]]; then
        echo "[INFO] ${timestamp} - $1" >> "${INSTALL_LOG}"
    fi
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[ERROR] ${timestamp} - $1"
    if [[ -w "${ERROR_LOG}" ]]; then
        echo "[ERROR] ${timestamp} - $1" >> "${ERROR_LOG}"
    fi
}

# Available tools configuration
declare -A TOOLS=(
    ["docker"]="installdocker.sh"
    ["jenkins"]="installjenkins.sh"
    ["kubernetes"]="installk8s.sh"
    ["minikube"]="installminikube.sh"
    ["terraform"]="installterraform.sh"
)

# Function to validate root privileges
validate_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi
}

# Function to display usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [TOOLS...]

Options:
    -h, --help          Show this help message
    -l, --list          List available tools
    -a, --all           Install all tools
    -f, --force         Force installation even if tool is already installed
    -s, --status        Check installation status of all tools
    -c, --clean         Clean up existing installations before installing

Available tools:
    docker              Install Docker
    jenkins             Install Jenkins
    kubernetes          Install Kubernetes CLI
    minikube           Install Minikube
    terraform          Install Terraform

Examples:
    $0 --status                    # Check status of all tools
    $0 --list                      # List available tools
    $0 docker jenkins              # Install specific tools
    $0 --all                       # Install all tools
    $0 --force docker             # Force Docker installation
    $0 --clean --all              # Clean and reinstall all tools
EOF
}

# Function to list available tools
list_tools() {
    log_info "Available tools for installation:"
    for tool in "${!TOOLS[@]}"; do
        echo "    - $tool"
    done
}

# Function to check installation status of a tool
check_tool_status() {
    local tool=$1
    case $tool in
        docker)
            if command -v docker &> /dev/null && docker info &> /dev/null; then
                echo "Docker: Installed ($(docker --version))"
                return 0
            fi
            ;;
        jenkins)
            if systemctl is-active --quiet jenkins; then
                echo "Jenkins: Installed and running"
                return 0
            fi
            ;;
        kubernetes)
            if command -v kubectl &> /dev/null; then
                echo "Kubernetes CLI: Installed ($(kubectl version --client --short))"
                return 0
            fi
            ;;
        minikube)
            if command -v minikube &> /dev/null; then
                echo "Minikube: Installed ($(minikube version --short))"
                return 0
            fi
            ;;
        terraform)
            if command -v terraform &> /dev/null; then
                echo "Terraform: Installed ($(terraform version -json | grep -o '"version": *"[^"]*"' | cut -d'"' -f4))"
                return 0
            fi
            ;;
    esac
    echo "$tool: Not installed"
    return 1
}

# Function to install a specific tool
install_tool() {
    local tool=$1
    local script="${TOOLS[$tool]}"
    local force=$2

    if [[ ! -f "${SCRIPT_DIR}/${script}" ]]; then
        log_error "Installation script for $tool not found"
        return 1
    fi

    # Check if tool is already installed and force flag is not set
    if ! $force && check_tool_status "$tool" > /dev/null; then
        log_info "Skipping $tool installation (already installed)"
        return 0
    fi

    log_info "Installing $tool..."
    if bash "${SCRIPT_DIR}/${script}"; then
        log_info "$tool installation completed successfully"
        return 0
    else
        log_error "$tool installation failed"
        return 1
    fi
}

# Function to clean existing installations
clean_installation() {
    local tool=$1
    log_info "Cleaning existing installation of $tool..."
    
    case $tool in
        docker)
            systemctl stop docker || true
            apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            rm -rf /var/lib/docker
            ;;
        jenkins)
            systemctl stop jenkins || true
            apt-get remove -y jenkins
            rm -rf /var/lib/jenkins
            ;;
        kubernetes)
            apt-get remove -y kubectl
            ;;
        minikube)
            minikube delete || true
            rm -f /usr/local/bin/minikube
            ;;
        terraform)
            apt-get remove -y terraform
            ;;
    esac
}

# Main execution
validate_root

# Initialize logs
mkdir -p "${LOG_DIR}"
touch "${INSTALL_LOG}" "${ERROR_LOG}"
chmod 644 "${INSTALL_LOG}" "${ERROR_LOG}"

# Process command line arguments
TOOLS_TO_INSTALL=()
INSTALL_ALL=false
FORCE_INSTALL=false
CHECK_STATUS=false
CLEAN_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -l|--list)
            list_tools
            exit 0
            ;;
        -a|--all)
            INSTALL_ALL=true
            shift
            ;;
        -f|--force)
            FORCE_INSTALL=true
            shift
            ;;
        -s|--status)
            CHECK_STATUS=true
            shift
            ;;
        -c|--clean)
            CLEAN_INSTALL=true
            shift
            ;;
        *)
            if [[ -n "${TOOLS[$1]}" ]]; then
                TOOLS_TO_INSTALL+=("$1")
            else
                log_error "Unknown tool: $1"
                echo "Use --list to see available tools"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check status if requested
if [[ "$CHECK_STATUS" == true ]]; then
    echo "Checking installation status of all tools..."
    for tool in "${!TOOLS[@]}"; do
        check_tool_status "$tool"
    done
    exit 0
fi

# Prepare list of tools to install
if [[ "$INSTALL_ALL" == true ]]; then
    TOOLS_TO_INSTALL=("${!TOOLS[@]}")
fi

# Validate that tools were specified
if [[ ${#TOOLS_TO_INSTALL[@]} -eq 0 ]]; then
    log_error "No tools specified for installation"
    echo "Use --help to see usage information"
    exit 1
fi

# Track failed installations
FAILED_INSTALLATIONS=()

# Process installations
for tool in "${TOOLS_TO_INSTALL[@]}"; do
    # Clean if requested
    if [[ "$CLEAN_INSTALL" == true ]]; then
        clean_installation "$tool"
    fi
    
    # Install tool
    if ! install_tool "$tool" "$FORCE_INSTALL"; then
        FAILED_INSTALLATIONS+=("$tool")
    fi
done

# Report results
if [[ ${#FAILED_INSTALLATIONS[@]} -eq 0 ]]; then
    log_info "All requested installations completed successfully"
    exit 0
else
    log_error "The following installations failed:"
    printf '%s\n' "${FAILED_INSTALLATIONS[@]}"
    exit 1
fi