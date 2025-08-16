#!/bin/bash

# Note: Remove set -e for teardown script to allow graceful cleanup even if some commands fail

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

# Clean up port-forwards first to avoid conflicts
cleanup_port_forwards() {
    log_info "Stopping all port-forwards..."
    
    # Stop port-forwards using PID files
    for pidfile in ~/portforward-*.pid; do
        if [ -f "$pidfile" ]; then
            service_name=$(basename "$pidfile" .pid | sed 's/portforward-//')
            pid=$(cat "$pidfile" 2>/dev/null || echo "")
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                log_info "  🛑 Stopping $service_name (PID: $pid)"
                kill "$pid" 2>/dev/null || true
            fi
            rm -f "$pidfile"
        fi
    done
    
    # Kill any remaining kubectl port-forward processes
    pkill -f "kubectl port-forward" 2>/dev/null || true
    
    # Clean up log files
    rm -f ~/portforward-*.log 2>/dev/null || true
    
    log_success "Port-forwards stopped"
}

# Clean up ArgoCD applications
cleanup_argocd() {
    log_info "Deleting ArgoCD applications..."
    if kubectl delete -f argocd/apps/ --ignore-not-found=true 2>/dev/null; then
        log_success "ArgoCD applications deleted"
    else
        log_warn "ArgoCD applications deletion failed or not found"
    fi
    
    log_info "Cleaning up repository secrets..."
    if kubectl delete secret gitea-repo -n argocd --ignore-not-found=true 2>/dev/null; then
        log_success "Repository secrets cleaned up"
    else
        log_warn "Repository secrets not found"
    fi
}

# Destroy Terraform infrastructure
destroy_infrastructure() {
    log_info "Destroying Terraform infrastructure..."
    cd terraform
    if terraform destroy -auto-approve 2>/dev/null; then
        log_success "Infrastructure destroyed"
    else
        log_warn "Infrastructure destruction failed (might not exist)"
    fi
    cd ..
}

# Stop Minikube
stop_minikube() {
    log_info "Checking Minikube status..."
    if minikube status >/dev/null 2>&1; then
        log_info "Stopping Minikube..."
        if minikube stop 2>/dev/null; then
            log_success "Minikube stopped"
        else
            log_warn "Minikube stop failed"
        fi
    else
        log_info "Minikube not running"
    fi
}

# Clean up temporary files
cleanup_files() {
    log_info "Cleaning up temporary files..."
    rm -f charts/hello-nginx/*.backup* 2>/dev/null || true
    log_success "Temporary files cleaned up"
}

# Main teardown function
main() {
    echo "🛑 Stopping GitOps stack..."
    echo ""
    
    cleanup_port_forwards
    cleanup_argocd
    destroy_infrastructure
    stop_minikube
    cleanup_files
    
    log_success "Everything stopped and cleaned up"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
