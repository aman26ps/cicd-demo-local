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

# Show cluster status
main() {
    echo "📊 Cluster Status"
    echo "================="
    echo ""
    
    echo "🏗️  Namespaces:"
    if kubectl get namespaces 2>/dev/null | grep -E "(argocd|dev-tools|internal-)" >/dev/null; then
        kubectl get namespaces | grep -E "(argocd|dev-tools|internal-)"
    else
        log_warn "No namespaces found - run 'make up'"
    fi
    echo ""
    
    echo "📋 ArgoCD Applications:"
    if kubectl get applications -n argocd 2>/dev/null; then
        log_success "ArgoCD applications are deployed"
    else
        log_warn "No applications found - run 'make up'"
    fi
    echo ""
    
    echo "🚢 Deployments:"
    echo "Staging deployments:"
    if kubectl get deployments -n internal-staging 2>/dev/null; then
        log_success "Staging deployments found"
    else
        log_warn "No staging deployments"
    fi
    
    echo ""
    echo "Production deployments:"
    if kubectl get deployments -n internal-prod 2>/dev/null; then
        log_success "Production deployments found"
    else
        log_warn "No production deployments"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
