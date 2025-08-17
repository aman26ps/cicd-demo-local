#!/usr/bin/env sh
# Start a local Docker registry on localhost:5000
set -e

if docker ps -a --format '{{.Names}}' | grep -q '^registry$'; then
  echo "Docker registry container already exists. Starting it if stopped..."
  docker start registry || true
else
  echo "Creating and starting local Docker registry on localhost:5000"
  docker run -d --restart=always -p 5000:5000 --name registry registry:2
fi

echo "local registry available at localhost:5000"
