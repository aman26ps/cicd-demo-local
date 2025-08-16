#!/bin/bash
set -euo pipefail

# Simple copy-based promotion with backup and rollback
# Strategy: Copy staging values to production with environment adjustments

promote() {
    echo "🚀 Promoting staging to production (copy strategy)..."
    
    # Remember current branch
    current_branch=$(git branch --show-current)
    echo "📝 Current branch: $current_branch"
    
    # Check if we have staging values
    if [ ! -f "charts/hello-nginx/values-staging.yaml" ]; then
        echo "❌ Staging values file not found!"
        exit 1
    fi
    
    # Copy staging values to temp location (from current branch)
    cp charts/hello-nginx/values-staging.yaml /tmp/staging-values.yaml
    echo "📝 Captured staging values from $current_branch branch"
    
    # Switch to main branch for production changes
    echo "🔄 Switching to main branch for production deployment..."
    git checkout main
    
    # Backup current production values
    cp charts/hello-nginx/values-prod.yaml charts/hello-nginx/values-prod.yaml.backup
    echo "✅ Backed up current production values"
    
    # Copy staging to production (from temp file)
    cp /tmp/staging-values.yaml charts/hello-nginx/values-prod.yaml
    echo "✅ Copied staging values to production"
    
    # Adjust for production environment
    sed -i.tmp 's/staging environment/production environment/g' charts/hello-nginx/values-prod.yaml
    sed -i.tmp 's/replicaCount: 1/replicaCount: 2/' charts/hello-nginx/values-prod.yaml
    rm -f charts/hello-nginx/values-prod.yaml.tmp
    echo "✅ Adjusted values for production (2 replicas, production message)"
    
    # Show the changes
    echo ""
    echo "📋 Production values after promotion:"
    echo "---"
    cat charts/hello-nginx/values-prod.yaml
    echo "---"
    
    # Check if there are any changes to commit
    git add charts/hello-nginx/values-prod.yaml
    
    if git diff --cached --quiet; then
        echo "ℹ️ No changes to promote - staging and production are already in sync"
        echo "📊 Current state:"
        grep -E "(message|appVersion|replicaCount)" charts/hello-nginx/values-prod.yaml | sed 's/^/  /'
        # Clean up temp file
        rm -f /tmp/staging-values.yaml
        # Switch back to original branch
        git checkout "$current_branch"
        return 0
    fi
    
    # Commit and push to main branch (triggers production deployment)
    version=$(grep 'appVersion:' charts/hello-nginx/values-prod.yaml | cut -d'"' -f2)
    git commit -m "promote: deploy ${version} to production

- Promoted from staging via copy strategy
- Updated replicas to 2 for production
- Backup saved as values-prod.yaml.backup"
    
    echo "✅ Committed promotion changes to main branch"
    echo "🚀 Pushing to deploy..."
    git push origin main
    
    # Clean up temp file
    rm -f /tmp/staging-values.yaml
    
    # Switch back to original branch
    echo "🔄 Switching back to $current_branch branch..."
    git checkout "$current_branch"
    echo "✅ Promotion complete!"
}

rollback() {
    echo "⏮️ Rolling back production..."
    
    # Remember current branch
    current_branch=$(git branch --show-current)
    echo "📝 Current branch: $current_branch"
    
    # Switch to main branch for production changes
    echo "🔄 Switching to main branch for production rollback..."
    git checkout main
    
    if [ ! -f "charts/hello-nginx/values-prod.yaml.backup" ]; then
        echo "❌ No backup found! Cannot rollback."
        echo "Available backups:"
        ls -la charts/hello-nginx/values-prod.yaml.backup* 2>/dev/null || echo "  None found"
        git checkout "$current_branch"
        exit 1
    fi
    
    # Show what we're rolling back from/to
    echo "📋 Rolling back from:"
    echo "---"
    head -3 charts/hello-nginx/values-prod.yaml
    echo "---"
    echo "📋 Rolling back to:"
    echo "---"
    head -3 charts/hello-nginx/values-prod.yaml.backup
    echo "---"
    
    # Restore from backup
    cp charts/hello-nginx/values-prod.yaml.backup charts/hello-nginx/values-prod.yaml
    echo "✅ Restored production values from backup"
    
    # Check if there are any changes to commit
    git add charts/hello-nginx/values-prod.yaml
    
    if git diff --cached --quiet; then
        echo "ℹ️ No changes to rollback - already at the backup state"
        echo "📊 Current state:"
        grep -E "(message|appVersion|replicaCount)" charts/hello-nginx/values-prod.yaml | sed 's/^/  /'
        # Switch back to original branch
        git checkout "$current_branch"
        return 0
    fi
    
    # Commit and push
    git commit -m "rollback: restore previous production version

- Restored from values-prod.yaml.backup
- Reverted to previous stable state"
    
    echo "✅ Committed rollback changes to main branch"
    echo "🚀 Pushing to deploy rollback..."
    git push origin main
    
    # Switch back to original branch
    echo "🔄 Switching back to $current_branch branch..."
    git checkout "$current_branch"
    echo "✅ Rollback complete!"
}

status() {
    echo "📊 Promotion Status"
    echo "==================="
    echo ""
    echo "🔧 Staging (values-staging.yaml):"
    if [ -f "charts/hello-nginx/values-staging.yaml" ]; then
        grep -E "(message|appVersion|replicaCount)" charts/hello-nginx/values-staging.yaml | sed 's/^/  /'
    else
        echo "  ❌ Not found"
    fi
    
    echo ""
    echo "🚀 Production (values-prod.yaml):"
    if [ -f "charts/hello-nginx/values-prod.yaml" ]; then
        grep -E "(message|appVersion|replicaCount)" charts/hello-nginx/values-prod.yaml | sed 's/^/  /'
    else
        echo "  ❌ Not found"
    fi
    
    echo ""
    echo "💾 Backup:"
    if [ -f "charts/hello-nginx/values-prod.yaml.backup" ]; then
        echo "  ✅ Available (values-prod.yaml.backup)"
        grep -E "(message|appVersion|replicaCount)" charts/hello-nginx/values-prod.yaml.backup | sed 's/^/    /'
    else
        echo "  ❌ No backup available"
    fi
}

case "${1:-}" in
    promote)
        promote
        ;;
    rollback)
        rollback
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {promote|rollback|status}"
        echo ""
        echo "Copy-based GitOps Promotion Strategy:"
        echo "  promote  - Copy staging values to production with adjustments"
        echo "  rollback - Restore production from backup"
        echo "  status   - Show current staging/production versions"
        echo ""
        echo "Workflow:"
        echo "  1. Test in staging"
        echo "  2. make promote     # Copy staging → production & deploy"  
        echo "  3. make rollback    # If issues occur"
        exit 1
        ;;
esac
