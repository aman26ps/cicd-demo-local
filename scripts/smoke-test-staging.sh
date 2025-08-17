#!/usr/bin/env sh
set -e
NAMESPACE="internal-staging"
DEPLOY="hello-nginx" # adjust to chart deployment name
# Wait for rollout
kubectl -n ${NAMESPACE} rollout status deployment/${DEPLOY} --timeout=120s

# Example test: curl an Ingress/service (adjust URL)
# If using port-forward, set up before running test
SERVICE_URL="http://localhost:8081/"
curl -fsS ${SERVICE_URL} >/dev/null && echo "smoke: ok" || (echo "smoke: failed" && exit 2)
