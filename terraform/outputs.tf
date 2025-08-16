output "next_steps" {
  description = "Instructions for next steps"
  value = <<-EOT
    ArgoCD has been installed successfully!
    
    Next steps:
    1. Wait for ArgoCD to be ready: kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
    2. Deploy applications: kubectl apply -n argocd -f ../argocd/apps/
    3. Get service URLs: make urls
    4. Get ArgoCD login: make argocd-login
    
    Namespaces created:
    - argocd (ArgoCD control plane)
    - internal-staging, internal-prod (internal services)
    - external-staging, external-prod (external services)
  EOT
}

output "namespaces" {
  description = "Created namespaces"
  value = [
    kubernetes_namespace.argocd.metadata[0].name,
    kubernetes_namespace.internal_staging.metadata[0].name,
    kubernetes_namespace.internal_prod.metadata[0].name,
    kubernetes_namespace.external_staging.metadata[0].name,
    kubernetes_namespace.external_prod.metadata[0].name
  ]
}
