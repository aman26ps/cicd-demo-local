#!/usr/bin/env sh
set -e
# Local CI script: build Docker image, push to local registry, update staging values

# Registry URLs: localhost for push, host IP for k8s pull  
LOCAL_REGISTRY="localhost:5001/hostaway/hello-nginx"
K8S_REGISTRY="192.168.49.1:5001/hostaway/hello-nginx"
IMAGE_NAME=${1:-${LOCAL_REGISTRY}}
SHORT_SHA=$(git rev-parse --short=12 HEAD)
TAG=${SHORT_SHA}

echo "🔨 Building image: ${LOCAL_REGISTRY}:${TAG}"

# Build and push image using localhost (no HTML manipulation needed - it's static)
docker build -t ${LOCAL_REGISTRY}:${TAG} .
echo "📦 Pushing image: ${LOCAL_REGISTRY}:${TAG}"
docker push ${LOCAL_REGISTRY}:${TAG}

# Update staging values file with new image tag (use k8s registry URL)
VALUES_FILE="charts/hello-nginx/values-staging.yaml"
if command -v yq >/dev/null 2>&1; then
  yq eval -i ".image.repository = \"${K8S_REGISTRY%:*}\"" ${VALUES_FILE}
  yq eval -i ".image.tag = \"${TAG}\"" ${VALUES_FILE}
else
  # Fallback: use sed to update both repository and tag
  sed -i.bak "s|repository: .*|repository: ${K8S_REGISTRY%:*}|" ${VALUES_FILE}
  sed -i.bak "s/tag: .*/tag: \"${TAG}\"/" ${VALUES_FILE}
fi

echo "📝 Updated ${VALUES_FILE} with tag: ${TAG}"

# Commit and push to develop branch
git add ${VALUES_FILE}
if git diff --staged --quiet; then
  echo "ℹ️  No changes to commit"
else
  git commit -m "ci: deploy staging image ${TAG}"
  echo "🚀 Pushing to develop branch..."
  git push origin develop || echo "⚠️  Git push failed - you may need to set up the remote"
fi

echo "✅ Staging deployment requested. ArgoCD will pick up the changes."
echo "🏷️  Image tag: ${TAG}"
