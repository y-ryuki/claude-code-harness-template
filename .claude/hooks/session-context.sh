#!/bin/bash
# SessionStart hook: セッション開始時にコンテキストを注入
# matcher: startup | resume

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Git 情報を収集
BRANCH=$(git branch --show-current 2>/dev/null || echo "(not a git repo)")
STATUS_SUMMARY=$(git status --short 2>/dev/null | head -10 || echo "")
STATUS_COUNT=$(git status --short 2>/dev/null | wc -l | tr -d ' ' || echo "0")
RECENT_COMMITS=$(git log --oneline -5 2>/dev/null || echo "")

# 環境情報
NODE_VERSION=$(node --version 2>/dev/null || echo "not installed")
PYTHON_VERSION=$(python3 --version 2>/dev/null || echo "not installed")

CONTEXT=$(cat <<EOF
## Session Context

**Branch**: $BRANCH
**Uncommitted changes**: $STATUS_COUNT files

**Status (top 10)**:
$STATUS_SUMMARY

**Recent commits**:
$RECENT_COMMITS

**Environment**:
- Node: $NODE_VERSION
- Python: $PYTHON_VERSION
- Working directory: $(pwd)

⚠️ Reminder: This template enforces strict guardrails. Dangerous commands (rm -rf /, curl|sh, git push --force, etc.) are blocked. Secret files (.env, .aws/, .ssh/) cannot be read.
EOF
)

# additionalContext として注入
jq -n --arg ctx "$CONTEXT" '{
    hookSpecificOutput: {
        hookEventName: "SessionStart",
        additionalContext: $ctx
    }
}'

exit 0
