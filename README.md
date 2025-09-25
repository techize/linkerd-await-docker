# linkerd-await Docker Image

A Docker image for the [linkerd-await](https://github.com/linkerd/linkerd-await) utility, built from the latest GitHub releases.

## Overview

This repository provides a containerized version of linkerd-await, which is a command wrapper that polls Linkerd for readiness and can call shutdown hooks after a command ends.

## Features

- Built from official linkerd-await GitHub releases
- Minimal Alpine Linux base image
- Non-root user for security
- Multi-arch support (AMD64)

## Usage

### Pre-built Images

Images are automatically built and published to GitHub Container Registry:

```bash
# Pull the latest image
docker pull ghcr.io/techize/linkerd-await-docker:latest

# Pull a specific version
docker pull ghcr.io/techize/linkerd-await-docker:v0.3.1
```

### Building Locally

```bash
# Build the image
docker build --build-arg LINKERD_AWAIT_VERSION=v0.3.1 -t linkerd-await:v0.3.1 .

# Or use the build script for ECR
./build.sh
```

### Using the Image

```bash
# Basic usage
docker run --rm ghcr.io/techize/linkerd-await-docker:latest --help

# In Kubernetes as an init container
containers:
  - name: linkerd-await
    image: ghcr.io/techize/linkerd-await-docker:v0.3.1
    command: ["cp"]
    args: ["/usr/local/bin/linkerd-await", "/shared/linkerd-await"]
    volumeMounts:
    - name: linkerd-await
      mountPath: /shared
```

## Configuration

The image supports the following build arguments:

- `LINKERD_AWAIT_VERSION`: Version of linkerd-await to download (default: v0.3.1)

## Supported Versions

- v0.3.1 (latest)
- Any version available from the [linkerd-await releases](https://github.com/linkerd/linkerd-await/releases)

## License

This project follows the same license as the upstream linkerd-await project.
