#!/usr/bin/env sh
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}🔵 $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

echo "🧪 Testing automated GitOps workflow..."
echo ""

# Test 1: Check minikube registry
log_info "Testing minikube registry setup..."
if kubectl get svc registry -n kube-system >/dev/null 2>&1; then
    log_success "Minikube registry is running"
else
    log_error "Minikube registry not found"
    exit 1
fi

# Test 2: Check ArgoCD applications
log_info "Testing ArgoCD applications..."
if kubectl get app hello-staging -n argocd >/dev/null 2>&1; then
    log_success "Staging application exists"
else
    log_error "Staging application not found"
    exit 1
fi

if kubectl get app hello-prod -n argocd >/dev/null 2>&1; then
    log_success "Production application exists"
else
    log_error "Production application not found" 
    exit 1
fi

# Test 3: Check namespaces
log_info "Testing target namespaces..."
if kubectl get ns internal-staging >/dev/null 2>&1; then
    log_success "Staging namespace exists"
else
    log_error "Staging namespace not found"
    exit 1
fi

if kubectl get ns internal-prod >/dev/null 2>&1; then
    log_success "Production namespace exists"
else
    log_error "Production namespace not found"
    exit 1
fi

# Test 4: Check Git remote
log_info "Testing Git configuration..."
if git remote get-url origin | grep -q "localhost:3001" >/dev/null 2>&1; then
    log_success "Git remote points to local Gitea"
else
    log_error "Git remote not configured for local Gitea"
    exit 1
fi

# Test 5: Test Docker environment for minikube
log_info "Testing Docker environment..."
eval $(minikube docker-env)
if docker info >/dev/null 2>&1; then
    log_success "Docker configured for minikube"
else
    log_error "Cannot access minikube Docker daemon"
    exit 1
fi

echo ""
log_success "All automated workflow tests passed! 🎉"
echo ""
echo "🚀 Ready to run the complete workflow:"
echo "  1. make ci-local        # Build & deploy to staging"
echo "  2. make smoke-test      # Test staging"  
echo "  3. make promote-image TAG=<sha>  # Promote to production"
