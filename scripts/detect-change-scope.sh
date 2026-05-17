#!/usr/bin/env bash
# detect-change-scope.sh — git diff から変更スコープを判定
#
# Output (stdout): "ui" / "backend" / "both" / "other"
#
# Usage:
#   bash scripts/detect-change-scope.sh [base-ref]   (default: origin/main)

set -euo pipefail

BASE="${1:-origin/main}"

# git diff のファイル一覧 (HEAD vs base、フォールバックあり)
files=$(git diff --name-only "$BASE"...HEAD 2>/dev/null \
  || git diff --name-only "$BASE" 2>/dev/null \
  || git diff --name-only HEAD 2>/dev/null \
  || echo "")

if [ -z "$files" ]; then
  echo "other"
  exit 0
fi

# 判定パターン (拡張子 OR ディレクトリ名)
ui_pattern='\.(tsx|jsx|vue|svelte|css|scss|sass|less|html|astro)$|(^|/)(components|pages|app|ui|views|layouts|frontend)(/|$)'
api_pattern='\.(py|go|rs|java|kt|rb|php|cs)$|(^|/)(api|server|routes|controllers|handlers|endpoints|backend|services)(/|$)'

has_ui=false
has_api=false

while IFS= read -r f; do
  [ -z "$f" ] && continue
  if echo "$f" | grep -qE "$ui_pattern"; then has_ui=true; fi
  if echo "$f" | grep -qE "$api_pattern"; then has_api=true; fi
done <<< "$files"

if $has_ui && $has_api; then
  echo "both"
elif $has_ui; then
  echo "ui"
elif $has_api; then
  echo "backend"
else
  echo "other"
fi
