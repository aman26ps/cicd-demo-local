#!/usr/bin/env sh
set -e
# Usage: ./promote-to-prod.sh <tag>
TAG=$1
if [ -z "${TAG}" ]; then
  echo "usage: $0 <tag>" >&2
  exit 1
fi
VALUES_FILE="charts/hello-nginx/values-prod.yaml"

if command -v yq >/dev/null 2>&1; then
  yq eval -i ".image.tag = \"${TAG}\"" ${VALUES_FILE}
else
  sed -i.bak -E "s/(tag:).*/\1 \"${TAG}\"/" ${VALUES_FILE} || true
fi

git add ${VALUES_FILE}
if git diff --staged --quiet; then
  echo "No change to prod values file; skipping commit"
else
  git commit -m "promote: image ${TAG} -> production"
  git push origin main
fi

echo "Promotion requested (ArgoCD prod app will pick up)."
