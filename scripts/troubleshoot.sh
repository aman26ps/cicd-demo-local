#!/bin/bash

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

# Check Minikube status
check_minikube() {
    echo "🏗️ Minikube Status:"
    if minikube status 2>/dev/null; then
        log_success "Minikube is running"
    else
        log_error "Minikube not running - run 'make up'"
    fi
    echo ""
}

# Check namespaces
check_namespaces() {
    echo "🏗️ Namespaces:"
    if kubectl get namespaces 2>/dev/null | grep -E "(argocd|dev-tools|internal-)" >/dev/null; then
        kubectl get namespaces | grep -E "(argocd|dev-tools|internal-)"
        log_success "Required namespaces found"
    else
        log_error "Namespaces not found - run 'make up'"
    fi
    echo ""
}

# Check ArgoCD applications
check_argocd_apps() {
    echo "📋 ArgoCD Applications:"
    if kubectl get applications -n argocd 2>/dev/null; then
        log_success "ArgoCD applications found"
    else
        log_error "Applications not found - run 'make up'"
    fi
    echo ""
}

# Check pod status
check_pods() {
    echo "🚢 Pod Status:"
    echo "ArgoCD Pods:"
    if kubectl get pods -n argocd 2>/dev/null; then
        log_success "ArgoCD pods found"
    else
        log_error "ArgoCD pods not found"
    fi
    
    echo ""
    echo "Gitea Pods:"
    if kubectl get pods -n dev-tools 2>/dev/null; then
        log_success "Gitea pods found"
    else
        log_error "Gitea pods not found"
    fi
    echo ""
}

# Check port-forwards
check_port_forwards() {
    echo "🔗 Port-forward Status:"
    if ps aux | grep "kubectl port-forward" | grep -v grep >/dev/null; then
        ps aux | grep "kubectl port-forward" | grep -v grep
        log_success "Port-forwards are running"
    else
        log_warn "No port-forwards running - run 'make port-forward'"
    fi
    echo ""
}

# Check Git repository status
check_git_repo() {
    echo "📂 Git Repository Status:"
    if git status 2>/dev/null; then
        log_success "Git repository is initialized"
    else
        log_warn "Not a git repository or git issues detected"
    fi
    echo ""
}

# Test service accessibility
check_service_access() {
    echo "🌐 Service Accessibility:"
    echo "Testing localhost ports..."
    
    if nc -z localhost 8080 >/dev/null 2>&1; then
        log_success "ArgoCD (8080) - accessible"
    else
        log_error "ArgoCD (8080) - not accessible"
    fi
    
    if nc -z localhost 3001 >/dev/null 2>&1; then
        log_success "Gitea (3001) - accessible"
    else
        log_error "Gitea (3001) - not accessible"
    fi
    
    if nc -z localhost 8081 >/dev/null 2>&1; then
        log_success "Staging (8081) - accessible"
    else
        log_warn "Staging (8081) - not accessible (might not be deployed yet)"
    fi
    
    if nc -z localhost 8082 >/dev/null 2>&1; then
        log_success "Production (8082) - accessible"
    else
        log_warn "Production (8082) - not accessible (might not be deployed yet)"
    fi
    echo ""
}

# Show common solutions
show_solutions() {
    echo "🔧 Common Solutions:"
    echo "==================="
    echo ""
    echo "🔴 If services are not running:"
    echo "  make up              # Start everything from scratch"
    echo ""
    echo "🔴 If port-forwards are not accessible:"
    echo "  make port-forward    # Start port-forwarding"
    echo "  make clean           # Clean up and restart port-forwards"
    echo ""
    echo "🔴 If ArgoCD apps are not syncing:"
    echo "  kubectl get apps -n argocd              # Check app status"
    echo "  kubectl describe app hello-staging -n argocd   # Debug staging app"
    echo ""
    echo "🔴 If Minikube issues:"
    echo "  minikube delete      # Delete and recreate cluster"
    echo "  make up              # Restart everything"
    echo ""
    echo "🔴 If Git/Gitea issues:"
    echo "  git status           # Check git status"
    echo "  git remote -v        # Check remote configuration"
    echo ""
}

# Main troubleshoot function
main() {
    echo "🔍 GitOps Stack Troubleshooting"
    echo "================================"
    echo ""
    
    check_minikube
    check_namespaces
    check_argocd_apps
    check_pods
    check_port_forwards
    check_git_repo
    check_service_access
    show_solutions
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
