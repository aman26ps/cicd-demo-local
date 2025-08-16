#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}🔵 $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Check if Homebrew is installed
check_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        log_error "Homebrew not found. Install from: https://brew.sh"
        exit 1
    fi
    log_success "Homebrew found"
}

# Install required tools
install_tools() {
    log_info "Installing required tools..."
    brew install minikube kubectl helm terraform
    log_success "Tools installed"
}

# Check Docker installation
check_docker() {
    log_info "Checking Docker Desktop installation..."
    if ! command -v docker >/dev/null 2>&1; then
        log_warn "Docker Desktop not found"
        echo "Please install Docker Desktop from: https://docs.docker.com/desktop/install/mac-install/"
        echo "Then restart this command."
        exit 1
    fi
    log_success "Docker Desktop found"
}

# Main function
main() {
    echo "📋 Installing dependencies for macOS..."
    echo ""
    
    check_homebrew
    install_tools
    check_docker
    
    log_success "All dependencies installed!"
    echo ""
    echo "📍 Next: Run 'make up' to start the GitOps stack"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
