# Simple linkerd-await image using pre-built binary
FROM alpine:3.18

# Install dependencies
RUN apk --no-cache add ca-certificates curl

# Set version
ARG LINKERD_AWAIT_VERSION=v0.3.1

# Download the linkerd-await binary from GitHub releases
RUN curl -sSLo /usr/local/bin/linkerd-await \
    "https://github.com/linkerd/linkerd-await/releases/download/release/${LINKERD_AWAIT_VERSION}/linkerd-await-${LINKERD_AWAIT_VERSION}-amd64" \
    && chmod +x /usr/local/bin/linkerd-await

# Create non-root user
RUN adduser -D -s /bin/sh linkerd-await

# Use non-root user
USER linkerd-await

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/linkerd-await"]