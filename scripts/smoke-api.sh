#!/usr/bin/env bash
# Local API smoke entry point; requires Python 3 and curl.
set -euo pipefail
if ! command -v python3 >/dev/null 2>&1; then
    mkdir -p .smoke-results
    printf '%s\n' '# API Smoke Results' 'Configuration error: Python 3 is required; no requests sent.' > .smoke-results/api.md
    cat .smoke-results/api.md >&2
    exit 2
fi
exec python3 "$(dirname "$0")/smoke-api.py" "$@"
