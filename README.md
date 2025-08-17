# Local GitOps — Minimal

A minimal, local-first GitOps workflow using Minikube, ArgoCD, Helm, and a local Git server. Designed to get you running quickly.

## Quick start

One-command install & run (after cloning):

  make deps && make up

Then build and deploy to staging:

  make ci-local

Test staging:

  make smoke-test

Promote a tested image to production:

  make promote-image TAG=<image-tag>

Rollback (to previous or specific tag):

  make rollback            # previous
  make rollback TAG=<tag>  # specific

## Essential commands

- make up / make down — start/stop the stack
- make ci-local — build in minikube, push, update values, deploy to staging
- make promote-image TAG=<tag> — promote image to production
- make rollback [TAG=<tag>] — rollback production
- make smoke-test — basic staging tests
- make port-forward — access services locally
- make troubleshoot — diagnostics

## Service URLs (default)

- ArgoCD: http://localhost:8080
- Staging app: http://localhost:8081
- Production app: http://localhost:8082
- Gitea: http://localhost:3001 (admin/admin12345)

## Technologies

Minikube, ArgoCD, Helm, Gitea, Docker (minikube's internal registry).

## GitOps Diagram

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Local as Local Repo
    participant CI as CI (make ci-local)
    participant Reg as Registry
    participant Git as Git (Gitea/GitHub)
    participant Argo as ArgoCD
    participant K8s as Kubernetes

    Dev->>Local: code change
    Dev->>CI: make ci-local (build in minikube)
    CI->>Reg: push image (tag)
    CI->>Git: update values-*.yaml (image tag) & push
    Git->>Argo: ArgoCD detects commit
    Argo->>K8s: deploy to staging
    Dev->>Git: make promote-image TAG=<tag>
    Git->>Argo: update production values
    Argo->>K8s: deploy to production
    Dev->>Git: make rollback TAG=<tag>
    Git->>Argo: update production values
    Argo->>K8s: rollback to requested image
```

## Monitoring & Alerts

A compact set of suggested monitors and thresholds (use Prometheus + Alertmanager locally).

| Metric | What to monitor | Warning | Critical | Why |
|---|---|---:|---:|---|
| Request latency (P95) | 95th percentile latency (ms) | P95 > 200 ms for 5m | P95 > 500 ms for 2m | Impacts UX; signals performance regressions or resource contention |
| Error rate (5xx) | % of requests returning 5xx | > 1% for 5m | > 5% for 2m | Indicates app failures or misconfigurations needing immediate action |
| Request throughput (RPS) | Requests/sec | sustained drop >50% vs baseline for 5m | sustained drop >80% vs baseline for 2m | Sudden drops indicate routing/network/upstream failures |
| Pod restarts | Restart count per pod (5m) | >=1 restart in 5m | >=3 restarts in 5m or across multiple pods | Signals crashes, OOMs, or failing probes |
| CPU usage (per-pod) | CPU % of requests/limits | >80% for 5m | >95% for 2m | High CPU degrades performance; may require scaling |
| Memory usage (per-pod) | Memory % of limits | >80% for 5m | >95% or OOM events | Memory pressure can cause OOM kills and instability |

How to alert (recommended)

- Scrape app and kube metrics with Prometheus, use Alertmanager for routing.
- Send critical alerts to on-call (e.g., Slack/email), warning alerts to a team channel.
- For local testing, run Prometheus + Alertmanager + Grafana in Minikube.

## Troubleshooting (quick)

- If services are unreachable: make port-forward
- ArgoCD apps OutOfSync: check ArgoCD UI and run make troubleshoot
- Build failures: ensure Docker is running and rerun make ci-local

This README intentionally minimal — see scripts/ and charts/ for details.
