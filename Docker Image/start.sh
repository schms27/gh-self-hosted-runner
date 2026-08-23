#!/bin/bash
set -euo pipefail

: "${REPO:?Set REPO as owner/repo}"
: "${NAME:?Set NAME to the runner name}"

RUNNER_URL="https://github.com/${REPO}"

get_runner_token() {
  local token_type="$1"

  if [ -n "${REG_TOKEN:-}" ]; then
    printf '%s' "${REG_TOKEN}"
    return
  fi

  : "${ACCESS_TOKEN:?Set ACCESS_TOKEN or REG_TOKEN}"

  curl -fsSL \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}/actions/runners/${token_type}-token" \
    | jq -r '.token'
}

cd /home/docker/actions-runner || exit

CONFIG_TOKEN="$(get_runner_token registration)"
./config.sh \
  --url "${RUNNER_URL}" \
  --token "${CONFIG_TOKEN}" \
  --name "${NAME}" \
  --unattended \
  --replace

cleanup() {
  echo "Removing runner..."
  REMOVE_TOKEN="$(get_runner_token remove)"
  ./config.sh remove --unattended --token "${REMOVE_TOKEN}"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
