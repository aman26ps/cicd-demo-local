#!/usr/bin/env sh
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}🔵 $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

log_info "Using minikube's built-in registry instead of external Docker registry"
log_warn "External registry is not needed for this setup"

# Check if minikube registry is enabled
if minikube addons list | grep -q "registry.*enabled" >/dev/null 2>&1; then
    log_success "Minikube registry is already enabled and ready"
else
    log_info "Enabling minikube registry..."
    minikube addons enable registry >/dev/null 2>&1
    log_success "Minikube registry enabled"
fi

echo ""
echo "📍 Registry Information:"
echo "  - Registry runs inside minikube cluster"
echo "  - Internal address: registry.kube-system.svc.cluster.local:80"
echo "  - No external port binding needed"
echo "  - Images built directly in minikube's Docker daemon"
