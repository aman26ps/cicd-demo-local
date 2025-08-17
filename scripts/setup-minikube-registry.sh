#!/usr/bin/env sh
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}🔵 $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

log_info "Setting up minikube registry for local GitOps workflow..."

# Check if minikube is running
if ! minikube status >/dev/null 2>&1; then
    log_error "Minikube is not running. Please start it first with 'make up'"
    exit 1
fi

# Enable registry addon if not already enabled
log_info "Enabling minikube registry addon..."
if minikube addons enable registry >/dev/null 2>&1; then
    log_success "Registry addon enabled"
else
    log_info "Registry addon already enabled"
fi

# Wait for registry to be ready
log_info "Waiting for registry to be ready..."
sleep 5

# Verify registry is accessible
if kubectl get svc registry -n kube-system >/dev/null 2>&1; then
    log_success "Registry service is running"
else
    log_error "Registry service not found"
    exit 1
fi

# Configure Docker to use minikube's daemon for subsequent builds
log_info "Configuring Docker environment for minikube..."
eval $(minikube docker-env)

log_success "Minikube registry setup complete!"
echo ""
echo "📍 Next steps:"
echo "  - Use 'make ci-local' to build and deploy images"
echo "  - Images will be built directly in minikube's Docker daemon"
echo "  - No external registry push/pull required"
