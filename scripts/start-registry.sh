#!/usr/bin/env sh
# Start a local Docker registry on localhost:5001 (port 5000 is occupied)
set -e

echo "🐳 Starting local Docker registry..."

if docker ps -a --format '{{.Names}}' | grep -q '^registry$'; then
  echo "📦 Docker registry container already exists. Starting it if stopped..."
  docker start registry || true
else
  echo "🚀 Creating and starting local Docker registry on localhost:5001"
  docker run -d --restart=always -p 5001:5000 --name registry registry:2
fi

# Test registry
sleep 2
if curl -s http://localhost:5001/v2/ > /dev/null; then
  echo "✅ Local registry is available at http://localhost:5001"
else
  echo "❌ Registry health check failed"
  exit 1
fi
