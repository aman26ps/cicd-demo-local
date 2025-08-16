# DevOps Task - Modular GitOps Workflow

A robust, modular GitOps workflow for local development using Minikube, ArgoCD, Helm, Terraform, and Gitea. Features copy-based promotion, one-command rollback, and background port-forwarding.

## 🎯 Quick Start

```bash
# 1. Install dependencies
make deps

# 2. Start everything
make up

# 3. Access services 
make port-forward

# 4. View URLs
make urls
```

## 📋 Prerequisites

The system will install these tools automatically on macOS:
- **Minikube** - Local Kubernetes cluster
- **kubectl** - Kubernetes CLI
- **Helm** - Package manager for Kubernetes
- **Terraform** - Infrastructure as Code
- **Docker Desktop** - Container runtime (manual install required)

## 🏗️ Architecture Overview

This is a **local-first GitOps setup** designed for development and testing:

- **Minikube**: Local Kubernetes cluster
- **Gitea**: Self-hosted Git server (replaces GitHub/GitLab for local development)
- **ArgoCD**: GitOps controller with web UI
- **Helm**: Package manager for Kubernetes applications
- **Terraform**: Manages infrastructure and Helm charts

### Components

- **ArgoCD**: `http://localhost:8080` (no login required)
- **Gitea**: `http://localhost:3001` (admin/admin12345)
- **Staging App**: `http://localhost:8081`
- **Production App**: `http://localhost:8082`

## 🚀 Commands

### Infrastructure Management

```bash
make up           # Start complete GitOps stack
make down         # Destroy everything
make status       # Show cluster status
make deps         # Install dependencies (macOS only)
```

### GitOps Workflow

```bash
make promote-status   # Check current versions
make promote          # Copy staging → production
make rollback         # Rollback production to backup
```

### Access & Debugging

```bash
make port-forward     # Start background port-forwarding
make urls             # Show service URLs
make clean            # Stop port-forwards and cleanup
make troubleshoot     # Comprehensive diagnostics
```

## 🔄 GitOps Workflow

### 1. Edit Staging Configuration
```bash
# Edit staging values
vim charts/hello-nginx/values-staging.yaml

# Check current status
make promote-status
```

### 2. Test in Staging
```bash
# Staging is automatically deployed via ArgoCD
# Access at http://localhost:8081
```

### 3. Promote to Production
```bash
# Copy staging values to production
make promote

# Check deployment status
make status
```

### 4. Rollback if Needed
```bash
# Rollback to previous production version
make rollback
```

## 🎛️ Modular Architecture

The system uses a **modular script-based architecture** where the Makefile acts as a thin wrapper:

### Scripts Directory Structure
```
scripts/
├── setup.sh         # Infrastructure setup logic
├── teardown.sh      # Cleanup logic  
├── git-setup.sh     # Git repository configuration
├── deps.sh          # Dependency installation
├── status.sh        # Status reporting
├── troubleshoot.sh  # Comprehensive diagnostics
├── promote.sh       # Promotion/rollback logic (copy-based)
└── pf.sh            # Background port-forwarding
```

### Benefits of Modular Design

1. **Clean Makefile**: Simple, readable targets that call scripts
2. **Maintainable**: Complex logic isolated in individual scripts
3. **Debuggable**: Each script can be run independently
4. **Extensible**: Easy to add new functionality
5. **Testable**: Scripts can be tested in isolation
6. **Robust**: Each script handles errors and edge cases

## 🔧 Troubleshooting

### Quick Diagnostics
```bash
make troubleshoot
```

This comprehensive diagnostic script checks:
- Minikube status
- Kubernetes namespaces and pods
- ArgoCD applications
- Port-forward status
- Git repository state
- Service accessibility
- Common solutions

### Common Issues & Solutions

#### Services Not Accessible
```bash
make port-forward    # Start port-forwarding
make clean           # Reset port-forwards
```

#### ArgoCD Apps Not Syncing
```bash
kubectl get apps -n argocd
kubectl describe app hello-staging -n argocd
```

#### Git/Gitea Issues
```bash
git status           # Check repository state
git remote -v        # Check remote configuration
```

#### Complete Reset
```bash
make down            # Destroy everything
make up              # Start fresh
```

## 🎮 Development Workflow

### Daily Development
```bash
# Start development session
make up && make port-forward

# Edit staging configuration
vim charts/hello-nginx/values-staging.yaml

# Check promotion status
make promote-status

# Promote when ready
make promote

# Stop everything when done
make down
```

### Background Operation

The system supports **background port-forwarding** with automatic PID management:

```bash
# Start all port-forwards in background
make port-forward

# View logs
tail -f ~/portforward-argocd-server.log
tail -f ~/portforward-gitea-http.log

# Stop specific service
kill $(cat ~/portforward-argocd-server.pid)

# Stop all
make clean
```

## 📁 Repository Structure

```
.
├── Makefile                 # Clean interface to scripts
├── README.md               # This documentation
├── issues.md              # Setup issues and resolutions
├── scripts/               # Modular script architecture
│   ├── setup.sh          # Infrastructure setup
│   ├── teardown.sh       # Cleanup
│   ├── git-setup.sh      # Git/Gitea integration
│   ├── promote.sh        # Promotion workflow
│   ├── pf.sh             # Port-forwarding
│   └── ...
├── terraform/            # Infrastructure as Code
│   ├── main.tf          # Main infrastructure
│   ├── providers.tf     # Provider configuration
│   └── values/          # Helm chart values
│       ├── argocd-values.yaml
│       └── gitea-values.yaml
├── argocd/              # ArgoCD application manifests
│   └── apps/
│       ├── hello-staging.yaml
│       └── hello-prod.yaml
└── charts/              # Helm charts
    └── hello-nginx/
        ├── values-staging.yaml
        ├── values-prod.yaml
        └── templates/
```

## 🔒 Security Notes

This is a **development environment** with simplified security:

- ArgoCD has authentication disabled (`server.disable.auth: true`)
- Gitea uses default credentials (`admin/admin12345`)
- All traffic is local (`localhost` only)
- No TLS certificates required

**Do not use this configuration in production environments.**

## 🎯 Key Features

✅ **One-command setup**: `make up`  
✅ **One-command teardown**: `make down`  
✅ **Copy-based promotion**: Safe, reversible promotions  
✅ **One-command rollback**: `make rollback`  
✅ **Background port-forwarding**: Non-blocking access  
✅ **Comprehensive diagnostics**: `make troubleshoot`  
✅ **Modular architecture**: Clean, maintainable code  
✅ **Local-first**: No external dependencies  
✅ **Self-contained**: Includes Git server (Gitea)  
✅ **Production-ready patterns**: GitOps best practices  

## 🚨 Troubleshooting & Support

If you encounter issues:

1. Run comprehensive diagnostics:
   ```bash
   make troubleshoot
   ```

2. Check the issues log:
   ```bash
   cat issues.md
   ```

3. Reset everything:
   ```bash
   make down && make up
   ```

4. Verify dependencies:
   ```bash
   make deps
   ```

The modular script architecture makes it easy to debug and extend the system. Each script can be run independently for testing and troubleshooting.
