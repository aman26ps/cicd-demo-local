#!/usr/bin/env sh
set -e
# Promote a tested image from staging to production

TAG=$1
if [ -z "${TAG}" ]; then
  echo "❌ Usage: $0 <image-tag>"
  echo "   Example: $0 abc123def456"
  exit 1
fi

VALUES_FILE="charts/hello-nginx/values-prod.yaml"

echo "🚀 Promoting image ${TAG} to production..."

# Update production values file with the tested image tag
if command -v yq >/dev/null 2>&1; then
  yq eval -i ".image.tag = \"${TAG}\"" ${VALUES_FILE}
else
  sed -i.bak "s/tag: .*/tag: \"${TAG}\"/" ${VALUES_FILE}
fi

echo "📝 Updated ${VALUES_FILE} with tag: ${TAG}"

# Commit and push to main branch
git add ${VALUES_FILE}
if git diff --staged --quiet; then
  echo "ℹ️  No changes to commit"
else
  git commit -m "promote: deploy production image ${TAG}"
  echo "🚀 Pushing to main branch..."
  git push origin main || echo "⚠️  Git push failed - you may need to set up the remote"
fi

echo "✅ Production promotion requested. ArgoCD will pick up the changes."
echo "🏷️  Production will use image tag: ${TAG}"
