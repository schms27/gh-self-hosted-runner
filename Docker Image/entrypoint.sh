#!/bin/bash
set -e

# Match the host Docker socket's GID so the docker user can access it.
# The GID baked into the image almost never matches the host's docker group GID.
if [ -S /var/run/docker.sock ]; then
    SOCKET_GID=$(stat -c '%g' /var/run/docker.sock)

    # Check if the docker group already has the correct GID
    CURRENT_GID=$(getent group docker | cut -d: -f3 || true)
    if [ "$CURRENT_GID" != "$SOCKET_GID" ]; then
        # If another group already owns the socket's GID, add the docker user to it.
        # Otherwise, change the existing docker group's GID to match.
        if getent group "$SOCKET_GID" >/dev/null 2>&1; then
            SOCKET_GROUP=$(getent group "$SOCKET_GID" | cut -d: -f1)
            usermod -aG "$SOCKET_GROUP" docker
        else
            groupmod -g "$SOCKET_GID" docker
        fi
    fi
fi

# Ensure the docker user owns its home cache dir.
# Docker creates the parent of any volume mount point as root, so
# /home/docker/.cache ends up root-owned when go-build-cache is mounted
# at /home/docker/.cache/go-build — which blocks golangci-lint from
# creating /home/docker/.cache/golangci-lint.
mkdir -p /home/docker/.cache/go-build /home/docker/go/pkg/mod
chown docker:docker /home/docker/.cache /home/docker/.cache/go-build \
                    /home/docker/go /home/docker/go/pkg /home/docker/go/pkg/mod

# Drop privileges and run the runner as the docker user.
# gosu preserves environment variables (unlike su).
exec gosu docker /start.sh
