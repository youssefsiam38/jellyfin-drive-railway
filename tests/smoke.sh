#!/usr/bin/env bash
set -Eeuo pipefail

base_url="${1:-http://127.0.0.1:3000}"

retry() {
  local url="$1"
  for _ in {1..90}; do
    if curl --noproxy '*' -fsS "$url" >/dev/null; then
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for ${url}" >&2
  return 1
}

retry "${base_url}/healthz"
retry "${base_url}/"
retry "${base_url}/openlist/"
retry "${base_url}/assets/index-legacy-Exg5IBbL.js"
retry "${base_url}/jellyfin/health"

echo "All public routes are healthy."
