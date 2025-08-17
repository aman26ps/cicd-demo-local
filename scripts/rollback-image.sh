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

# Image-based rollback for minikube registry GitOps workflow
rollback_production() {
    local target_tag="${1:-}"
    log_info "Rolling back production deployment..."
    
    VALUES_FILE="charts/hello-nginx/values-prod.yaml"
    
    # Check if production values file exists
    if [ ! -f "${VALUES_FILE}" ]; then
        log_error "Production values file not found: ${VALUES_FILE}"
        exit 1
    fi
    
    # Get current production image tag
    current_tag=$(grep "tag:" ${VALUES_FILE} | head -1 | sed 's/.*tag: *"\([^"]*\)".*/\1/')
    log_info "Current production image tag: ${current_tag}"
    
    # If no target tag specified, find the previous tag from git history
    if [ -z "${target_tag}" ]; then
        log_info "Finding previous production image tag from git history..."
        target_tag=$(git log -n 10 --oneline ${VALUES_FILE} | grep -E "(promote:|ci:)" | head -2 | tail -1 | grep -o '[a-f0-9]\{12\}' | head -1)
        
        if [ -z "${target_tag}" ]; then
            log_error "Could not find previous image tag in git history"
            log_info "Recent commits affecting ${VALUES_FILE}:"
            git log --oneline -5 ${VALUES_FILE} | sed 's/^/  /'
            exit 1
        fi
    else
        log_info "Using specified target tag: ${target_tag}"
    fi
    
    if [ "${current_tag}" = "${target_tag}" ]; then
        log_warn "Production is already at the target tag: ${target_tag}"
        log_info "No rollback needed"
        exit 0
    fi
    
    log_info "Rolling back from ${current_tag} to ${target_tag}"
    
    # Registry configuration for minikube
    REGISTRY_HOST="registry.kube-system.svc.cluster.local:80"
    IMAGE_NAME="hostaway/hello-nginx"
    
    # Check if the target image exists in the registry
    log_info "Checking if target image exists in minikube registry..."
    eval $(minikube docker-env)
    
    if docker image inspect ${REGISTRY_HOST}/${IMAGE_NAME}:${target_tag} >/dev/null 2>&1; then
        log_success "Target image found in registry: ${REGISTRY_HOST}/${IMAGE_NAME}:${target_tag}"
    else
        log_error "Target image not found in minikube registry: ${REGISTRY_HOST}/${IMAGE_NAME}:${target_tag}"
        log_info "Available images:"
        docker images ${REGISTRY_HOST}/${IMAGE_NAME} | head -10 | sed 's/^/  /'
        exit 1
    fi
    
    # Update production values file with target tag
    if command -v yq >/dev/null 2>&1; then
        yq eval -i ".image.tag = \"${target_tag}\"" ${VALUES_FILE}
    else
        sed -i.bak "s/tag: .*/tag: \"${target_tag}\"/" ${VALUES_FILE}
    fi
    
    log_success "Updated ${VALUES_FILE} with target tag: ${target_tag}"
    
    # Commit and push the rollback
    git add ${VALUES_FILE}
    if git diff --staged --quiet; then
        log_warn "No changes to commit"
    else
        git commit -m "rollback: revert production to image ${target_tag}

- Rolled back from: ${current_tag}
- Rolled back to: ${target_tag}
- Image available in minikube registry"
        
        log_info "Pushing rollback to trigger deployment..."
        git push
        
        # Force ArgoCD to sync the rollback immediately
        log_info "Forcing ArgoCD to sync production application..."
        if kubectl get app hello-prod -n argocd >/dev/null 2>&1; then
            kubectl patch app hello-prod -n argocd --type merge -p '{"operation":{"initiatedBy":{"automated":true}}}' >/dev/null 2>&1 || true
            sleep 3
            # Force deployment restart to pick up the rolled back image
            kubectl rollout restart deployment/hello-prod-hello-nginx -n internal-prod >/dev/null 2>&1 || true
            log_success "ArgoCD sync triggered for rollback"
        else
            log_warn "ArgoCD production application not found, skipping sync"
        fi
    fi
    
    echo ""
    log_success "Rollback completed!"
    echo ""
    echo "📍 Rollback Summary:"
    echo "  - From: ${current_tag}"
    echo "  - To:   ${target_tag}"
    echo "  - Image: ${REGISTRY_HOST}/${IMAGE_NAME}:${target_tag}"
    echo ""
    echo "🔍 Next steps:"
    echo "  - Monitor: kubectl get pods -n internal-prod"
    echo "  - Test: make smoke-test (update script for prod namespace)"
}

# Show rollback status and history
show_status() {
    log_info "Production Rollback Status"
    echo ""
    
    VALUES_FILE="charts/hello-nginx/values-prod.yaml"
    
    if [ ! -f "${VALUES_FILE}" ]; then
        log_error "Production values file not found"
        exit 1
    fi
    
    # Current tag
    current_tag=$(grep "tag:" ${VALUES_FILE} | head -1 | sed 's/.*tag: *"\([^"]*\)".*/\1/')
    echo "🏷️  Current production tag: ${current_tag}"
    
    # Recent promotion history
    echo ""
    echo "📜 Recent promotion history:"
    git log --oneline -5 ${VALUES_FILE} | sed 's/^/  /'
    
    # Available rollback targets with improved formatting
    echo ""
    echo "🎯 Available rollback targets:"
    git log -n 20 --oneline ${VALUES_FILE} | grep -E "(promote:|ci:)" | head -10 | while read line; do
        tag=$(echo $line | grep -o '[a-f0-9]\{12\}' | head -1)
        if [ -n "$tag" ] && [ "$tag" != "$current_tag" ]; then
            commit_msg=$(echo $line | cut -d' ' -f2-)
            echo "  - ${tag} ($(echo $commit_msg))"
        fi
    done
    
    echo ""
    echo "🔄 Usage:"
    echo "  make rollback              # Rollback to previous version"
    echo "  make rollback TAG=<tag>    # Rollback to specific version"
    echo "  make promote-status        # Show this status"
}

case "${1:-}" in
    rollback)
        rollback_production "${2:-}"
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {rollback|status} [TAG]"
        echo ""
        echo "Image-based Rollback for GitOps:"
        echo "  rollback         - Roll back production to previous image tag"
        echo "  rollback TAG     - Roll back production to specific image tag"
        echo "  status           - Show current production tag and rollback options"
        echo ""
        echo "Examples:"
        echo "  make rollback                    # Rollback to previous version"
        echo "  make rollback TAG=abc123def456   # Rollback to specific version"
        echo "  make promote-status              # Show rollback options"
        exit 1
        ;;
esac
