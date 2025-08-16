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

### 🔄 GitOps Workflow Diagram

```mermaid
graph TB
    subgraph "Developer Machine"
        DEV[👨‍💻 Developer]
        LOCAL[📁 Local Repo]
    end
    
    subgraph "Git Repository (Gitea)"
        DEVELOP[🌱 develop branch<br/>Staging Config]
        MAIN[🏭 main branch<br/>Production Config]
    end
    
    subgraph "Kubernetes Cluster (Minikube)"
        subgraph "ArgoCD"
            ARGOCD[🔄 ArgoCD<br/>GitOps Controller]
        end
        
        subgraph "Staging Namespace"
            STAGING[🧪 Staging App<br/>hello-staging<br/>Port: 8081]
        end
        
        subgraph "Production Namespace"
            PROD[🚀 Production App<br/>hello-prod<br/>Port: 8082]
        end
    end
    
    DEV --> LOCAL
    LOCAL --> |git push| DEVELOP
    LOCAL --> |make promote| MAIN
    
    DEVELOP --> |watches develop| ARGOCD
    MAIN --> |watches main| ARGOCD
    
    ARGOCD --> |deploys| STAGING
    ARGOCD --> |deploys| PROD
    
    STAGING --> |test & verify| DEV
    PROD --> |monitor| DEV
    
    style DEVELOP fill:#90EE90
    style MAIN fill:#FFB6C1
    style STAGING fill:#90EE90
    style PROD fill:#FFB6C1
    style ARGOCD fill:#87CEEB
```

### 📊 GitOps Flow ASCII Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │   Git Repository│    │   Kubernetes    │
│                 │    │     (Gitea)     │    │   (Minikube)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │ 1. Edit staging       │                       │
         │ values-staging.yaml   │                       │
         ├──────────────────────▶│                       │
         │                       │                       │
         │ 2. git push develop   │                       │
         ├──────────────────────▶│ develop branch        │
         │                       ├──────────────────────▶│ ArgoCD watches
         │                       │                       │ 3. Auto-deploy
         │                       │                       │    to STAGING
         │                       │                       │
         │ 4. Test staging app   │                       │
         │ http://localhost:8081 │                       │
         ◄───────────────────────┼───────────────────────┤
         │                       │                       │
         │ 5. make promote       │                       │
         │ (copy staging→prod)   │                       │
         ├──────────────────────▶│ main branch           │
         │                       ├──────────────────────▶│ ArgoCD watches
         │                       │                       │ 6. Auto-deploy
         │                       │                       │    to PRODUCTION
         │                       │                       │
         │ 7. Verify production  │                       │
         │ http://localhost:8082 │                       │
         ◄───────────────────────┼───────────────────────┤
         │                       │                       │
         │ 8. make rollback      │                       │
         │ (if needed)           │                       │
         ├──────────────────────▶│ main branch           │
         │                       ├──────────────────────▶│ ArgoCD watches
         │                       │                       │ 9. Auto-rollback
```

### 🔧 Promotion Strategy Diagram

```
Staging Values (develop)     Production Values (main)
┌─────────────────────┐     ┌─────────────────────┐
│ appVersion: "v1.2"  │────▶│ appVersion: "v1.2"  │
│ message: "staging"  │     │ message: "prod"     │
│ replicaCount: 1     │     │ replicaCount: 2     │ 
│                     │     │                     │
│ values-staging.yaml │     │ values-prod.yaml    │
└─────────────────────┘     └─────────────────────┘
                                      │
                                      ▼
                            ┌─────────────────────┐
                            │ Backup Created      │
                            │ values-prod.yaml    │
                            │      .backup        │
                            └─────────────────────┘
                                      │
                                      ▼ (for rollback)
                            ┌─────────────────────┐
                            │ make rollback       │
                            │ Restores from       │
                            │ backup file         │
                            └─────────────────────┘
```

### Components

- **ArgoCD**: `http://localhost:8080` (no login required)
- **Gitea**: `http://localhost:3001` (admin/admin12345)
- **Staging App**: `http://localhost:8081`
- **Production App**: `http://localhost:8082`

### 🎯 GitOps Principles Implementation

This workflow implements the core GitOps principles:

#### 1. 📋 **Declarative Configuration**
- All infrastructure and application configurations are declared in Git
- Helm charts define the desired state
- Values files specify environment-specific settings

#### 2. 🔄 **Git as Single Source of Truth**
- `develop` branch → Staging environment
- `main` branch → Production environment
- All changes tracked in Git history

#### 3. 🚀 **Automated Deployment**
- ArgoCD continuously monitors Git repositories
- Automatic synchronization when changes detected
- No manual deployment commands needed

#### 4. 🔒 **GitOps Reconciliation Loop**
- ArgoCD ensures cluster state matches Git state
- Self-healing: automatically corrects drift
- Continuous monitoring and synchronization

#### 5. 🛡️ **Safe Rollback Strategy**
- Copy-based promotion with automatic backups
- One-command rollback: `make rollback`
- Git history preserves all previous states

### 🌿 Branch Strategy Diagram

```
Git Repository Structure:

develop branch (Staging)          main branch (Production)
┌────────────────────────┐       ┌────────────────────────┐
│                        │       │                        │
│  📝 Feature commits    │       │  🚀 Promotion commits  │
│  🧪 Staging config     │       │  🏭 Production config  │
│  values-staging.yaml   │       │  values-prod.yaml      │
│                        │       │                        │
│  Auto-deployed to:     │       │  Auto-deployed to:     │
│  🧪 Staging (8081)     │       │  🏭 Production (8082)  │
│                        │       │                        │
└────────────────────────┘       └────────────────────────┘
            │                                 ▲
            │                                 │
            └─────── make promote ────────────┘
                   (copies staging→prod)

Workflow:
1. Developer commits to develop branch
2. ArgoCD auto-deploys to staging environment
3. After testing: make promote
4. Staging config copied to production config
5. ArgoCD auto-deploys to production environment
6. If issues: make rollback (restores from backup)
```

### 🔄 ArgoCD Application Mapping

```
ArgoCD Applications:

┌─────────────────────────────────────────────────────────────┐
│                        ArgoCD                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📱 hello-staging                📱 hello-prod             │
│  ┌─────────────────────┐        ┌─────────────────────┐     │
│  │ Source:             │        │ Source:             │     │
│  │  repo: gitea        │        │  repo: gitea        │     │
│  │  branch: develop    │        │  branch: main       │     │
│  │  path: charts/      │        │  path: charts/      │     │
│  │  values:            │        │  values:            │     │
│  │   - values-staging  │        │   - values-prod     │     │
│  │                     │        │                     │     │
│  │ Target:             │        │ Target:             │     │
│  │  namespace: staging │        │  namespace: prod    │     │
│  │  port: 8081         │        │  port: 8082         │     │
│  └─────────────────────┘        └─────────────────────┘     │
│           │                               │                 │
│           ▼                               ▼                 │
│  🧪 Staging Environment          🏭 Production Environment  │
└─────────────────────────────────────────────────────────────┘
```

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
