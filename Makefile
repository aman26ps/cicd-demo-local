# Hostaway DevOps Task - Clean GitOps Workflow
.PHONY: help up down status port-forward promote rollback promote-status urls clean deps troubleshoot
.DEFAULT_GOAL := help

# 🐳 Local Image-based GitOps Workflow
start-registry:
	@echo "🐳 Starting local Docker registry..."
	@./scripts/start-registry.sh

ci-local:
	@echo "🔨 Building and deploying to staging..."
	@./scripts/ci-local-build-and-deploy.sh

smoke-test:
	@echo "🧪 Running smoke tests against staging..."
	@./scripts/smoke-test-staging.sh

promote-image:
	@if [ -z "$(TAG)" ]; then \
		echo "❌ TAG required: make promote-image TAG=abc123def456"; \
		exit 1; \
	fi
	@echo "🚀 Promoting image $(TAG) to production..."
	@./scripts/promote-to-prod.sh $(TAG)

test-automation:
	@echo "🧪 Testing automated GitOps workflow..."
	@./scripts/test-automation.sh

help:
	@echo "🚀 Hostaway DevOps Task - Image-based GitOps"
	@echo "=============================================="
	@echo ""
	@echo "📋 Setup (one-time):"
	@echo "  deps           - Install required dependencies"
	@echo "  up             - Start Minikube and deploy GitOps stack (includes registry)"
	@echo "  start-registry - Enable minikube registry (auto-included in 'up')"
	@echo ""
	@echo "📦 Infrastructure:"
	@echo "  status         - Show cluster status"
	@echo "  down           - Destroy everything"
	@echo ""
	@echo "🚀 Image-based GitOps Workflow:"
	@echo "  ci-local       - Build image, push to registry, deploy to staging"
	@echo "  smoke-test     - Test staging deployment"
	@echo "  promote-image  - Promote tested image to production (requires TAG=...)"
	@echo "  rollback       - Roll back production to previous image"
	@echo "  promote-status - Show promotion status and rollback options"
	@echo "  test-automation - Test the automated workflow setup"
	@echo ""
	@echo "🔗 Access:"
	@echo "  port-forward   - Access services via port-forward"
	@echo "  urls           - Show service URLs"
	@echo "  clean          - Stop port-forwards and cleanup"
	@echo ""
	@echo "💡 Complete Workflow:"
	@echo "  1. make up          # Start cluster and GitOps stack"
	@echo "  2. make ci-local    # Build & deploy to staging"
	@echo "  3. make smoke-test  # Test staging"
	@echo "  4. make promote-image TAG=<sha>  # Promote to production"
	@echo "  5. make rollback    # If issues occur (optional)"
	@echo ""
	@echo "🛠️  Registry Information:"
	@echo "  - Uses minikube's built-in registry"
	@echo "  - Images built directly in cluster"
	@echo "  - No external registry setup needed"

up:
	@./scripts/setup.sh

down:
	@./scripts/teardown.sh

status:
	@./scripts/status.sh

promote:
	@echo "🚀 Promoting staging to production..."
	@./scripts/promote.sh promote

rollback:
	@echo "⏮️ Rolling back production..."
	@./scripts/rollback-image.sh rollback

promote-status:
	@echo "📊 Checking promotion status..."
	@./scripts/rollback-image.sh status

urls:
	@echo "🔗 Service URLs (requires port-forward)"
	@echo "======================================"
	@echo "  ArgoCD:     http://localhost:8080 (no login required)"
	@echo "  Gitea:      http://localhost:3001 (admin/admin12345)"
	@echo "  Staging:    http://localhost:8081"
	@echo "  Production: http://localhost:8082"
	@echo ""
	@echo "📋 Management:"
	@echo "  Start:      make port-forward"
	@echo "  Stop all:   make clean"
	@echo "  Logs:       tail -f ~/portforward-<service-name>.log"

port-forward: clean
	@echo "🔗 Starting background port forwards..."
	@echo ""
	@./scripts/pf.sh argocd-server 8080 443 argocd
	@./scripts/pf.sh gitea-http 3001 3000 dev-tools
	@if kubectl get svc -n internal-staging hello-nginx >/dev/null 2>&1; then ./scripts/pf.sh hello-nginx 8081 80 internal-staging; fi
	@if kubectl get svc -n internal-prod hello-nginx >/dev/null 2>&1; then ./scripts/pf.sh hello-nginx 8082 80 internal-prod; fi
	@echo ""
	@echo "🌐 Services now available at:"
	@echo "  ArgoCD:     http://localhost:8080 (no login required)"
	@echo "  Gitea:      http://localhost:3001"
	@echo "  Staging:    http://localhost:8081"
	@echo "  Production: http://localhost:8082"
	@echo ""
	@echo "📋 Management:"
	@echo "  View logs:    tail -f ~/portforward-<service-name>-<namespace>.log"
	@echo "  Stop all:     make clean"
	@echo "  Stop single:  kill \$$(cat ~/portforward-<service-name>-<namespace>.pid)"

clean:
	@echo "🧹 Cleaning up..."
	@rm -f charts/hello-nginx/*.backup*
	@echo "🛑 Stopping background port-forwards..."
	@for pidfile in ~/portforward-*.pid; do \
		if [ -f "$$pidfile" ]; then \
			service_name=$$(basename "$$pidfile" .pid | sed 's/portforward-//'); \
			pid=$$(cat "$$pidfile" 2>/dev/null || echo ""); \
			if [ -n "$$pid" ] && kill -0 "$$pid" 2>/dev/null; then \
				echo "  🛑 Stopping $$service_name (PID: $$pid)"; \
				kill "$$pid" 2>/dev/null || true; \
			fi; \
			rm -f "$$pidfile"; \
		fi; \
	done
	@rm -f ~/portforward-*.log 2>/dev/null || true
	@pkill -f "kubectl port-forward" 2>/dev/null || true
	@echo "✅ Cleaned up"

deps:
	@./scripts/deps.sh

troubleshoot:
	@./scripts/troubleshoot.sh
