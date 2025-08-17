#!/usr/bin/env sh
set -e
# Local CI script: build Docker image, push to minikube registry, update staging values

# Registry configuration for minikube
REGISTRY_HOST="registry.kube-system.svc.cluster.local:80"
IMAGE_NAME="hostaway/hello-nginx"
FULL_IMAGE_NAME="${REGISTRY_HOST}/${IMAGE_NAME}"

SHORT_SHA=$(git rev-parse --short=12 HEAD)
TAG=${SHORT_SHA}

echo "🔨 Building image: ${FULL_IMAGE_NAME}:${TAG}"

# Configure Docker to use minikube's daemon
echo "🐳 Configuring Docker for minikube..."
eval $(minikube docker-env)

# Build image directly in minikube's Docker daemon
docker build -t ${FULL_IMAGE_NAME}:${TAG} .
echo "📦 Image built in minikube registry: ${FULL_IMAGE_NAME}:${TAG}"

# Update staging values file with new image tag (use k8s registry URL)
VALUES_FILE="charts/hello-nginx/values-staging.yaml"
if command -v yq >/dev/null 2>&1; then
  yq eval -i ".image.repository = \"${REGISTRY_HOST}/${IMAGE_NAME}\"" ${VALUES_FILE}
  yq eval -i ".image.tag = \"${TAG}\"" ${VALUES_FILE}
else
  # Fallback: use sed to update both repository and tag
  sed -i.bak "s|repository: .*|repository: ${REGISTRY_HOST}/${IMAGE_NAME}|" ${VALUES_FILE}
  sed -i.bak "s/tag: .*/tag: \"${TAG}\"/" ${VALUES_FILE}
fi

echo "📝 Updated ${VALUES_FILE} with tag: ${TAG}"

# Commit and push to develop branch
git add ${VALUES_FILE}
if git diff --staged --quiet; then
  echo "ℹ️  No changes to commit"
else
  git commit -m "ci: deploy staging image ${TAG}

- Built image: ${FULL_IMAGE_NAME}:${TAG}
- Updated staging values with new tag
- Image available in minikube registry"
  echo "� Pushing changes to Gitea..."
  git push

  # Force ArgoCD to sync the changes immediately
  echo "🔄 Forcing ArgoCD to sync staging application..."
  if kubectl get app hello-staging -n argocd >/dev/null 2>&1; then
    kubectl patch app hello-staging -n argocd --type merge -p '{"operation":{"initiatedBy":{"automated":true}}}' >/dev/null 2>&1 || true
    sleep 3
    # Use kubectl rollout restart to force deployment update
    kubectl rollout restart deployment/hello-staging-hello-nginx -n internal-staging >/dev/null 2>&1 || true
    echo "✅ ArgoCD sync triggered"
  else
    echo "⚠️  ArgoCD application not found, skipping sync"
  fi
fi

echo ""
echo "🎉 CI pipeline completed successfully!"
echo "📍 Next steps:"
echo "  - Run: make smoke-test (to verify staging deployment)"
echo "  - Run: make promote-image TAG=${TAG} (to promote to production)"
