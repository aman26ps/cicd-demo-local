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

# Check if dependencies are installed
check_dependencies() {
    log_info "Checking dependencies..."
    local missing=false
    
    for cmd in minikube kubectl helm terraform; do
        if ! command -v $cmd >/dev/null 2>&1; then
            log_error "$cmd not found. Run: make deps"
            missing=true
        fi
    done
    
    if [ "$missing" = true ]; then
        exit 1
    fi
    
    log_success "Dependencies OK"
}

# Start Minikube
start_minikube() {
    log_info "Checking Minikube status..."
    if minikube status >/dev/null 2>&1; then
        log_success "Minikube already running"
    else
        log_info "Starting Minikube..."
        minikube start --driver=docker || true
        log_success "Minikube started"
    fi
}

# Deploy infrastructure
deploy_infrastructure() {
    log_info "Initializing Terraform..."
    cd terraform
    terraform init -upgrade >/dev/null 2>&1
    
    log_info "Deploying infrastructure with Terraform..."
    if terraform apply -auto-approve; then
        log_success "Infrastructure deployed"
    else
        log_error "Infrastructure deployment failed"
        exit 1
    fi
    cd ..
}

# Wait for services to be ready
wait_for_services() {
    log_info "Waiting for ArgoCD..."
    if kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s; then
        log_success "ArgoCD is ready"
    else
        log_error "ArgoCD failed to start"
        exit 1
    fi
    
    log_info "Waiting for Gitea..."
    if kubectl wait --for=condition=available deployment/gitea -n dev-tools --timeout=300s; then
        log_success "Gitea is ready"
    else
        log_error "Gitea failed to start"
        exit 1
    fi
}

# Setup ArgoCD repository
setup_argocd_repo() {
    log_info "Adding repository credentials to ArgoCD..."
    if kubectl create secret generic gitea-repo -n argocd \
        --from-literal=type=git \
        --from-literal=url=http://gitea-http.dev-tools.svc.cluster.local:3000/admin/hostaway-devops-task.git \
        --from-literal=username=admin \
        --from-literal=password=admin12345 \
        --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1; then
        log_success "Repository secret created"
    else
        log_warn "Repository secret already exists"
    fi
    
    kubectl label secret gitea-repo -n argocd argocd.argoproj.io/secret-type=repository --overwrite >/dev/null 2>&1 || true
    log_success "Repository credentials configured"
}

# Deploy ArgoCD applications
deploy_argocd_apps() {
    log_info "Deploying ArgoCD applications..."
    if kubectl apply -f argocd/apps/ >/dev/null 2>&1; then
        log_success "ArgoCD applications deployed"
    else
        log_warn "ArgoCD applications might already exist"
    fi
    
    log_info "Refreshing applications..."
    kubectl annotate app hello-staging -n argocd argocd.argoproj.io/refresh=normal --overwrite >/dev/null 2>&1 || true
    kubectl annotate app hello-prod -n argocd argocd.argoproj.io/refresh=normal --overwrite >/dev/null 2>&1 || true
    sleep 5
    
    log_success "ArgoCD applications refreshed"
}

# Main setup function
main() {
    echo "🚀 Starting GitOps stack..."
    echo ""
    
    check_dependencies
    start_minikube
    deploy_infrastructure
    wait_for_services
    
    # Setup Git repository (call git-setup.sh)
    ./scripts/git-setup.sh
    
    setup_argocd_repo
    deploy_argocd_apps
    
    log_success "GitOps stack ready!"
    echo ""
    echo "📍 Next steps:"
    echo "  - Run: make port-forward (to access services)"
    echo "  - Run: make status (to check deployments)"
    echo "  - Access ArgoCD: http://localhost:8080 (no login required)"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
