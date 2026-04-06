#!/bin/bash
set -e

# Match the host Docker socket's GID so the docker user can access it.
# The GID baked into the image almost never matches the host's docker group GID.
if [ -S /var/run/docker.sock ]; then
    SOCKET_GID=$(stat -c '%g' /var/run/docker.sock)
    groupmod -g "$SOCKET_GID" docker 2>/dev/null || groupadd -g "$SOCKET_GID" docker
    usermod -aG docker docker
fi

# Ensure the docker user owns its home cache dir.
# Docker creates the parent of any volume mount point as root, so
# /home/docker/.cache ends up root-owned when go-build-cache is mounted
# at /home/docker/.cache/go-build — which blocks golangci-lint from
# creating /home/docker/.cache/golangci-lint.
mkdir -p /home/docker/.cache /home/docker/go
chown docker:docker /home/docker/.cache /home/docker/go

# Drop privileges and run the runner as the docker user.
# gosu preserves environment variables (unlike su).
exec gosu docker /start.sh
