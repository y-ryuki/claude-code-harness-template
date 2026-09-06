#!/usr/bin/env bash
# Deterministic, offline guard tests. No live push, API calls or firewall changes.
set -euo pipefail
cd "$(dirname "$0")/.."
for dependency in bats jq python3; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        echo "Security tests require $dependency." >&2
        exit 1
    fi
done
export LC_ALL=C
exec bats --tap tests/hooks/ tests/smoke/ tests/firewall/
