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

# Setup Git repository
setup_git_repo() {
    log_info "Setting up Git repository..."
    git init || true
    git config user.name "GitOps Admin" || true
    git config user.email "admin@example.com" || true
    git add . || true
    git commit -m "GitOps setup - automated commit" || true
    git checkout -b main || git checkout main || true
    git merge develop || true
    log_success "Git repository initialized"
}

# Check if Gitea port-forward is already running
check_gitea_port_forward() {
    if ps aux | grep "kubectl port-forward.*gitea-http.*3001:3000" | grep -v grep >/dev/null; then
        log_info "Gitea port-forward already running, using existing connection"
        return 0
    else
        return 1
    fi
}

# Create Gitea repository via API
create_gitea_repo() {
    local use_existing_pf=false
    local pf_pid=""
    
    if check_gitea_port_forward; then
        use_existing_pf=true
    else
        log_info "Setting up temporary port-forward to Gitea..."
        kubectl port-forward -n dev-tools svc/gitea-http 3001:3000 >/dev/null 2>&1 &
        pf_pid=$!
        sleep 5
    fi
    
    log_info "Creating Gitea repository..."
    if curl -s -X POST -u admin:admin12345 \
        -H "Content-Type: application/json" \
        -d '{"name": "cicd-demo-local", "description": "DevOps task with GitOps workflow"}' \
        http://localhost:3001/api/v1/user/repos >/dev/null 2>&1; then
        log_success "Gitea repository created"
    else
        log_warn "Repository might already exist"
    fi
    
    if [ "$use_existing_pf" = false ] && [ -n "$pf_pid" ]; then
        log_info "Stopping temporary port-forward..."
        kill $pf_pid 2>/dev/null || true
        sleep 2
    fi
}

# Push code to Gitea
push_to_gitea() {
    log_info "Pushing code to Gitea..."
    
    # Remove any old remotes and add correct one
    git remote remove origin 2>/dev/null || true
    git remote remove gitea 2>/dev/null || true
    git remote add origin http://admin:admin12345@localhost:3001/admin/cicd-demo-local.git
    
    local use_existing_pf=false
    local pf_pid=""
    
    if check_gitea_port_forward; then
        use_existing_pf=true
    else
        log_info "Setting up port-forward for Git push..."
        kubectl port-forward -n dev-tools svc/gitea-http 3001:3000 >/dev/null 2>&1 &
        pf_pid=$!
        sleep 3
    fi
    
    # Push branches with error handling
    log_info "Pushing main branch..."
    if git push -u origin main 2>/dev/null; then
        log_success "Main branch pushed"
    else
        log_warn "Main branch push failed (might already exist)"
    fi
    
    log_info "Switching to develop branch..."
    git checkout develop 2>/dev/null || git checkout -b develop
    
    log_info "Pushing develop branch..."
    if git push -u origin develop 2>/dev/null; then
        log_success "Develop branch pushed"
    else
        log_warn "Develop branch push failed (might already exist)"
    fi
    
    # Cleanup only if we created the port-forward
    if [ "$use_existing_pf" = false ] && [ -n "$pf_pid" ]; then
        log_info "Stopping temporary port-forward..."
        kill $pf_pid 2>/dev/null || true
        # Clean up any lingering port-forwards we might have created
        pkill -f "kubectl port-forward.*gitea-http" 2>/dev/null || true
        sleep 2
    fi
    
    log_success "Code pushed to Gitea"
}

# Main function
main() {
    log_info "Setting up Git repository and Gitea integration..."
    echo ""
    
    setup_git_repo
    create_gitea_repo
    push_to_gitea
    
    log_success "Git setup completed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
