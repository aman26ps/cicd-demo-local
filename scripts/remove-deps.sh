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
        log_error "Homebrew not found. Cannot remove tools."
        exit 1
    fi
    log_success "Homebrew found"
}

# Remove installed tools
remove_tools() {
    log_info "Removing GitOps tools..."
    
    local tools=("minikube" "kubectl" "helm" "terraform")
    local removed=()
    local not_found=()
    
    for tool in "${tools[@]}"; do
        if brew list "$tool" >/dev/null 2>&1; then
            log_info "Removing $tool..."
            brew uninstall "$tool"
            removed+=("$tool")
        else
            log_warn "$tool not installed via Homebrew (or not found)"
            not_found+=("$tool")
        fi
    done
    
    if [ ${#removed[@]} -gt 0 ]; then
        log_success "Removed: ${removed[*]}"
    fi
    
    if [ ${#not_found[@]} -gt 0 ]; then
        log_warn "Not found/removed: ${not_found[*]}"
    fi
}

# Clean up Homebrew
cleanup_homebrew() {
    log_info "Cleaning up Homebrew..."
    brew cleanup
    brew autoremove
    log_success "Homebrew cleanup complete"
}

# Warning about Docker Desktop
docker_warning() {
    log_warn "Docker Desktop NOT removed automatically"
    echo "  To remove Docker Desktop manually:"
    echo "  1. Quit Docker Desktop app"
    echo "  2. Delete /Applications/Docker.app"
    echo "  3. Remove ~/Library/Group Containers/group.com.docker"
    echo "  4. Remove ~/Library/Containers/com.docker.docker"
    echo ""
}

# Warning about Minikube data
minikube_warning() {
    log_warn "Minikube data may still exist"
    echo "  To completely remove Minikube data:"
    echo "  rm -rf ~/.minikube"
    echo "  This will delete all Minikube clusters and data"
    echo ""
}

# Main function
main() {
    echo "🗑️  Removing GitOps dependencies..."
    echo ""
    
    # Confirmation prompt
    echo "This will remove the following tools installed via Homebrew:"
    echo "  - minikube"
    echo "  - kubectl"
    echo "  - helm" 
    echo "  - terraform"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled"
        exit 0
    fi
    
    check_homebrew
    remove_tools
    cleanup_homebrew
    
    echo ""
    docker_warning
    minikube_warning
    
    log_success "Dependency removal complete!"
    echo ""
    echo "Note: This only removes tools installed via Homebrew."
    echo "Any tools installed via other methods remain unchanged."
}

main "$@"
