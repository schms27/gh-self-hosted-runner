#!/bin/bash
set -e

# Match the host Docker socket's GID so the docker user can access it.
# The GID baked into the image almost never matches the host's docker group GID.
if [ -S /var/run/docker.sock ]; then
    SOCKET_GID=$(stat -c '%g' /var/run/docker.sock)
    groupmod -g "$SOCKET_GID" docker 2>/dev/null || groupadd -g "$SOCKET_GID" docker
    usermod -aG docker docker
fi

# Drop privileges and run the runner as the docker user.
# gosu preserves environment variables (unlike su).
exec gosu docker /start.sh
