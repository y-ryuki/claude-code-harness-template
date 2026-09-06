#!/bin/bash
# PreToolUse: inspect Git destinations without executing the requested command.
set -euo pipefail
if ! command -v python3 >/dev/null 2>&1; then
    echo "Git guard requires python3; refusing to run the tool." >&2
    exit 2
fi
if ! python3 "$(dirname "$0")/block-merge.py"; then
    echo "Git guard failed; refusing to run the tool." >&2
    exit 2
fi
