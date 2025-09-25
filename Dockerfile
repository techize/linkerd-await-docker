# Simple linkerd-await image using pre-built binary
FROM alpine:3.18

# Install dependencies
RUN apk --no-cache add ca-certificates curl bash

# Set version
ARG LINKERD_AWAIT_VERSION=v0.3.1

# Download the linkerd-await binary from GitHub releases
RUN curl -sSLo /linkerd-await \
    "https://github.com/linkerd/linkerd-await/releases/download/release/${LINKERD_AWAIT_VERSION}/linkerd-await-${LINKERD_AWAIT_VERSION}-amd64" \
    && chmod +x /linkerd-await \
    && ln -s /linkerd-await /usr/local/bin/linkerd-await

# Create wrapper script for proper shutdown handling
RUN cat > /linkerd-await-wrapper.sh << 'EOF' && chmod +x /linkerd-await-wrapper.sh
#!/bin/bash
set -e

# Check if we should do linkerd shutdown
SHUTDOWN_MODE=""
if [[ "$1" == "--shutdown" ]]; then
    SHUTDOWN_MODE="true"
    shift
fi

# If we have arguments after "--", we're being used as a wrapper
if [[ "$1" == "--" ]]; then
    shift
    # Wait for linkerd proxy to be ready first (if available)
    if [[ -n "$SHUTDOWN_MODE" ]] && curl -s http://localhost:4191/ready > /dev/null 2>&1; then
        echo "Linkerd proxy detected, waiting for readiness..."
        /linkerd-await-original --timeout=60s -- echo "Linkerd ready"
    fi

    # Execute the main command
    echo "Executing main command: $*"
    exec "$@" &
    MAIN_PID=$!
else
    # Call original linkerd-await if we're not being used as wrapper
    exec /linkerd-await-original "$@"
fi

# Wait for main process to complete
wait $MAIN_PID
EXIT_CODE=$?
echo "Main process completed with exit code: $EXIT_CODE"

# Always attempt linkerd proxy shutdown when running in a sidecar environment
if [[ -n "$SHUTDOWN_MODE" ]] || curl -s http://localhost:4191/ready > /dev/null 2>&1; then
    echo "Attempting linkerd proxy shutdown..."

    # Try multiple shutdown approaches
    if curl -s -X POST http://localhost:4191/shutdown > /dev/null 2>&1; then
        echo "Linkerd proxy shutdown via HTTP endpoint successful"
        sleep 2  # Give it time to shutdown
    else
        echo "HTTP shutdown failed, trying alternative methods..."
        # Send SIGTERM to any linkerd-proxy processes
        pkill -TERM linkerd-proxy 2>/dev/null || true
        sleep 5
        echo "Shutdown attempts completed"
    fi
else
    echo "No linkerd proxy detected or shutdown not requested"
fi

exit $EXIT_CODE
EOF

# Make wrapper script replace the original linkerd-await
RUN mv /linkerd-await /linkerd-await-original && \
    mv /linkerd-await-wrapper.sh /linkerd-await

# Create non-root user
RUN adduser -D -s /bin/sh linkerd-await

# Use non-root user
USER linkerd-await

ENTRYPOINT ["/linkerd-await"]