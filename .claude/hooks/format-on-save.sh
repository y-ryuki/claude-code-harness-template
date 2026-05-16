#!/bin/bash
# PostToolUse hook: ファイル編集後に自動フォーマット
# matcher: Edit|Write

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# 拡張子別フォーマッタ
case "$FILE_PATH" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.css|*.scss|*.html|*.md|*.yml|*.yaml)
        if command -v prettier &>/dev/null; then
            prettier --write "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    *.py)
        if command -v ruff &>/dev/null; then
            ruff format "$FILE_PATH" 2>/dev/null || true
            ruff check --fix "$FILE_PATH" 2>/dev/null || true
        elif command -v black &>/dev/null; then
            black --quiet "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    *.go)
        command -v gofmt &>/dev/null && gofmt -w "$FILE_PATH" 2>/dev/null || true
        ;;
    *.rs)
        command -v rustfmt &>/dev/null && rustfmt "$FILE_PATH" 2>/dev/null || true
        ;;
    *.sh|*.bash)
        command -v shfmt &>/dev/null && shfmt -w -i 4 "$FILE_PATH" 2>/dev/null || true
        ;;
esac

exit 0
