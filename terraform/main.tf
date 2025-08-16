# Create namespaces
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/component" = "argocd"
    }
  }
}

resource "kubernetes_namespace" "dev_tools" {
  metadata {
    name = "dev-tools"
    labels = {
      "app.kubernetes.io/component" = "dev-tools"
    }
  }
}

resource "kubernetes_namespace" "internal_staging" {
  metadata {
    name = "internal-staging"
    labels = {
      environment = "staging"
      tier        = "internal"
    }
  }
}

resource "kubernetes_namespace" "internal_prod" {
  metadata {
    name = "internal-prod"
    labels = {
      environment = "production"
      tier        = "internal"
    }
  }
}

resource "kubernetes_namespace" "external_staging" {
  metadata {
    name = "external-staging"
    labels = {
      environment = "staging"
      tier        = "external"
    }
  }
}

resource "kubernetes_namespace" "external_prod" {
  metadata {
    name = "external-prod"
    labels = {
      environment = "production"
      tier        = "external"
    }
  }
}

# Install ArgoCD via Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.46.7"

  values = [
    file("${path.module}/values/argocd-values.yaml")
  ]

  depends_on = [kubernetes_namespace.argocd]
}

# Install Gitea via Helm
resource "helm_release" "gitea" {
  name       = "gitea"
  repository = "https://dl.gitea.io/charts/"
  chart      = "gitea"
  namespace  = kubernetes_namespace.dev_tools.metadata[0].name

  values = [
    file("${path.module}/values/gitea-values.yaml")
  ]

  depends_on = [kubernetes_namespace.dev_tools]
}
