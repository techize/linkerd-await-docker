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
# Disable exit on error for shutdown logic
set +e

# Function to handle shutdown
shutdown_linkerd() {
    echo "Attempting linkerd proxy shutdown..."

    # Try HTTP shutdown endpoint
    if curl -s -X POST http://localhost:4191/shutdown > /dev/null 2>&1; then
        echo "Linkerd proxy shutdown via HTTP endpoint successful"
        sleep 3
    else
        echo "HTTP shutdown failed, trying alternative methods..."
        # Send SIGTERM to linkerd-proxy processes
        pkill -TERM linkerd-proxy 2>/dev/null && echo "Sent SIGTERM to linkerd-proxy" || echo "No linkerd-proxy processes found"
        sleep 5
    fi
    echo "Shutdown attempts completed"
}

# Trap to ensure shutdown runs even if script is killed
trap 'shutdown_linkerd; exit 130' INT TERM

# Check if we should do linkerd shutdown
SHUTDOWN_MODE=""
if [[ "$1" == "--shutdown" ]]; then
    SHUTDOWN_MODE="true"
    shift
fi

# If we have arguments after "--", we're being used as a wrapper
if [[ "$1" == "--" ]]; then
    shift

    # Execute the main command
    echo "Executing main command: $*"
    "$@" &
    MAIN_PID=$!

    # Wait for main process to complete
    wait $MAIN_PID
    EXIT_CODE=$?
    echo "Main process completed with exit code: $EXIT_CODE"

    # Always attempt shutdown if linkerd proxy is detected
    if [[ -n "$SHUTDOWN_MODE" ]] || curl -s http://localhost:4191/ready > /dev/null 2>&1; then
        shutdown_linkerd
    else
        echo "No linkerd proxy detected or shutdown not requested"
    fi

    exit $EXIT_CODE
else
    # If not being used as wrapper, just pass through (shouldn't happen in our case)
    echo "Direct call - this shouldn't happen in our setup"
    exit 1
fi
EOF

# Make wrapper script replace the original linkerd-await, and ensure it's executable
RUN cp /linkerd-await /linkerd-await-original && \
    mv /linkerd-await-wrapper.sh /linkerd-await && \
    chmod +x /linkerd-await && \
    chmod +x /linkerd-await-original

# Create non-root user
RUN adduser -D -s /bin/sh linkerd-await

# Use non-root user
USER linkerd-await

ENTRYPOINT ["/linkerd-await"]