# Hostaway DevOps Task - Clean GitOps Workflow
.PHONY: help up down status port-forward promote rollback promote-status urls clean deps troubleshoot
.DEFAULT_GOAL := help

help:
	@echo "🚀 Hostaway DevOps Task - GitOps Workflow"
	@echo "=========================================="
	@echo ""
	@echo "📋 Setup (one-time):"
	@echo "  deps         - Install required dependencies via Homebrew"
	@echo ""
	@echo "📦 Infrastructure:"
	@echo "  up           - Start Minikube and deploy GitOps stack"
	@echo "  down         - Destroy everything"
	@echo "  status       - Show cluster status"
	@echo ""
	@echo "🚀 GitOps Workflow:"
	@echo "  promote      - Copy staging values to production"
	@echo "  rollback     - Rollback production to backup"
	@echo "  promote-status - Show version status"
	@echo ""
	@echo "🔗 Access:"
	@echo "  port-forward - Access services via port-forward"
	@echo "  urls         - Show service URLs"
	@echo "  troubleshoot - Diagnose common issues"
	@echo ""
	@echo "💡 Workflow:"
	@echo "  1. Edit charts/hello-nginx/values-staging.yaml"
	@echo "  2. make promote-status  # Check versions"
	@echo "  3. make promote         # Copy staging → production"
	@echo "  4. make port-forward    # Access services"

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
	@./scripts/promote.sh rollback

promote-status:
	@./scripts/promote.sh status

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
