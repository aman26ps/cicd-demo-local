#!/bin/bash

# Kubernetes Port Forward Background Script
# Usage: pf <service-name> <local-port> <remote-port> [namespace]
# Example: pf argocd-server 8080 443 argocd

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    echo "❌ Usage: pf <service-name> <local-port> <remote-port> [namespace]"
    echo ""
    echo "Examples:"
    echo "  pf argocd-server 8080 443 argocd"
    echo "  pf gitea-http 3001 3000 dev-tools"
    echo "  pf hello-nginx 8081 80 internal-staging"
    echo ""
    echo "📋 To stop: kill \$(cat ~/portforward-<service-name>-<namespace>.pid)"
    echo "📋 View logs: tail -f ~/portforward-<service-name>-<namespace>.log"
    exit 1
fi

SERVICE_NAME=$1
LOCAL_PORT=$2
REMOTE_PORT=$3
NAMESPACE=${4:-default}

# Create unique filenames by including namespace
LOG_FILE="$HOME/portforward-$SERVICE_NAME-$NAMESPACE.log"
PID_FILE="$HOME/portforward-$SERVICE_NAME-$NAMESPACE.pid"

# Check if service exists
if ! kubectl get svc -n "$NAMESPACE" "$SERVICE_NAME" >/dev/null 2>&1; then
    echo "❌ Service '$SERVICE_NAME' not found in namespace '$NAMESPACE'"
    echo "Available services in $NAMESPACE:"
    kubectl get svc -n "$NAMESPACE" 2>/dev/null || echo "No services found or namespace doesn't exist"
    exit 1
fi

# Kill existing port-forward for this service if running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "🔄 Stopping existing port-forward (PID: $OLD_PID)..."
        kill "$OLD_PID"
        sleep 1
    fi
    rm -f "$PID_FILE"
fi

# Start new port-forward in background
echo "🚀 Starting port-forward: $SERVICE_NAME ($NAMESPACE) -> localhost:$LOCAL_PORT"
echo "📝 Logs: $LOG_FILE"
echo "🔑 PID file: $PID_FILE"

nohup kubectl port-forward -n "$NAMESPACE" "svc/$SERVICE_NAME" "$LOCAL_PORT:$REMOTE_PORT" > "$LOG_FILE" 2>&1 &
PORT_FORWARD_PID=$!

# Save PID for later cleanup
echo "$PORT_FORWARD_PID" > "$PID_FILE"

# Wait a moment and check if it started successfully
sleep 2
if kill -0 "$PORT_FORWARD_PID" 2>/dev/null; then
    echo "✅ Port-forward started successfully!"
    echo "🌐 Access at: http://localhost:$LOCAL_PORT"
    echo ""
    echo "📋 Management commands:"
    echo "  View logs: tail -f $LOG_FILE"
    echo "  Stop:      kill \$(cat $PID_FILE) && rm $PID_FILE"
    echo "  Status:    ps -p \$(cat $PID_FILE 2>/dev/null) 2>/dev/null || echo 'Not running'"
else
    echo "❌ Failed to start port-forward. Check logs: $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
fi
