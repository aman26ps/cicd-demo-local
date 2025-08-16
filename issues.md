# Issues Encountered During GitOps Setup

## 1. Complex Makefile with Too Many Targets
**Issue**: Original Makefile had numerous targets making it difficult to understand the core workflow.
**Why**: Over-engineering and trying to cover every possible scenario upfront.
**Resolution**: Refactored to minimal essential targets: `help`, `up`, `down`, `status`, `port-forward`, `promote`, `rollback`, `promote-status`, `urls`, `clean`.

## 2. Tag-Based Promotion Strategy Complexity
**Issue**: Initial approach used Git tags and complex version management for promotions.
**Why**: Attempted to implement a sophisticated versioning system without clear requirements.
**Resolution**: Switched to simple copy-based promotion - copy `values-staging.yaml` to `values-prod.yaml` with environment-specific adjustments.

## 3. ArgoCD Application Sync Issues
**Issue**: Applications not syncing properly or showing as out of sync.
**Why**: Conflicting Helm value files and incorrect branch tracking configurations.
**Resolution**: Ensured staging tracks `develop` branch and production tracks `main` branch with correct value file references.

## 4. Rollback Strategy Implementation
**Issue**: No clear rollback mechanism for production deployments.
**Why**: Focus was on promotion workflow without considering rollback scenarios.
**Resolution**: Implemented automatic backup creation in `promote.sh` script - saves previous production values before promotion.

## 5. Port Forwarding and Service Access
**Issue**: Difficulty accessing deployed applications locally for testing.
**Why**: Complex networking setup and unclear service exposure methods.
**Resolution**: Added `make port-forward` target with background processes and clear URL access via `make urls`.

## 6. Obsolete Files and Scripts
**Issue**: Accumulation of unused files, backup files, and test scripts.
**Why**: Iterative development without cleanup between approaches.
**Resolution**: Systematic cleanup - removed `terraform.tfstate.backup`, unused scripts, and consolidated functionality.

## 7. Documentation Out of Sync
**Issue**: README didn't reflect the actual implemented workflow.
**Why**: Multiple iterations of the implementation without updating documentation.
**Resolution**: Rewrote README to accurately document the copy-based promotion workflow with clear step-by-step instructions.

## 8. Gitea Repository Integration
**Issue**: Ensuring ArgoCD properly connects to local Gitea instance.
**Why**: Internal Kubernetes networking and service discovery configuration.
**Resolution**: Used internal service URL `http://gitea-http.dev-tools.svc.cluster.local:3000` for ArgoCD to access Gitea reliably.

## 9. Environment-Specific Value Management
**Issue**: Managing different configurations for staging vs production environments.
**Why**: Need to maintain separate but related configurations without duplication.
**Resolution**: Base `values.yaml` with environment-specific overrides in `values-staging.yaml` and `values-prod.yaml`.

## 10. Kubernetes Namespace Management
**Issue**: Applications deploying to incorrect or non-existent namespaces.
**Why**: Namespace creation timing and ArgoCD sync policy configuration.
**Resolution**: Added `CreateNamespace=true` sync option to automatically create target namespaces during deployment.
