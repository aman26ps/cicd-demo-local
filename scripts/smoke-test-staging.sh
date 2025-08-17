#!/usr/bin/env sh
set -e
# Smoke test script for staging environment

NAMESPACE="internal-staging"
DEPLOY="hello-staging-hello-nginx"

echo "🧪 Running smoke tests for staging..."

# Wait for rollout to complete
echo "⏳ Waiting for deployment rollout..."
kubectl -n ${NAMESPACE} rollout status deployment/${DEPLOY} --timeout=120s

# Check if service exists and is accessible
echo "🔍 Checking service health..."
if kubectl get svc -n ${NAMESPACE} hello-nginx >/dev/null 2>&1; then
  # Try to access the service via port-forward temporarily
  echo "🌐 Testing service connectivity..."
  kubectl port-forward -n ${NAMESPACE} svc/hello-nginx 8888:80 &
  PF_PID=$!
  sleep 3
  
  # Test the service
  if curl -fsS http://localhost:8888/health >/dev/null 2>&1; then
    echo "✅ Staging smoke test passed!"
    STATUS=0
  else
    echo "❌ Staging smoke test failed - service not responding"
    STATUS=1
  fi
  
  # Clean up port-forward
  kill $PF_PID 2>/dev/null || true
  sleep 1
  
  exit $STATUS
else
  echo "❌ Service not found in namespace ${NAMESPACE}"
  exit 1
fi
