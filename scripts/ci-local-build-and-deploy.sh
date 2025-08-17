#!/usr/bin/env sh
set -e
# Usage: ./ci-local-build-and-deploy.sh [IMAGE_NAME]
IMAGE_NAME=${1:-localhost:5000/hostaway/hello-nginx}
SHORT_SHA=$(git rev-parse --short=12 HEAD)
TAG=${SHORT_SHA}

echo "Building ${IMAGE_NAME}:${TAG}"
docker build -t ${IMAGE_NAME}:${TAG} .

echo "Pushing ${IMAGE_NAME}:${TAG}"
docker push ${IMAGE_NAME}:${TAG}

# Update staging values file
VALUES_FILE="charts/hello-nginx/values-staging.yaml"
if command -v yq >/dev/null 2>&1; then
  yq eval -i ".image.tag = \"${TAG}\"" ${VALUES_FILE}
else
  sed -i.bak -E "s/(tag:).*/\1 \"${TAG}\"/" ${VALUES_FILE} || true
fi

# Commit and push to develop (assumes remote origin points to Gitea)
git add ${VALUES_FILE}
if git diff --staged --quiet; then
  echo "No change to values file; skipping commit"
else
  git commit -m "ci: staging image ${TAG}"
  git push origin develop
fi

echo "Staging deploy requested (ArgoCD will pick up change)."
echo "${TAG}"
