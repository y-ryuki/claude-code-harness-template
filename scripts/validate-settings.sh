#!/bin/bash
# settings.json の構文 + 主要項目検証

set -uo pipefail

cd "$(dirname "$0")/.."

SETTINGS=".claude/settings.json"
ERRORS=0

if [ ! -f "$SETTINGS" ]; then
    echo "❌ $SETTINGS が存在しません"
    exit 1
fi

# JSON 構文検証
if ! jq empty "$SETTINGS" 2>/dev/null; then
    echo "❌ $SETTINGS に JSON 構文エラー"
    jq empty "$SETTINGS" || true
    exit 1
fi
echo "✅ JSON 構文 OK"

# 必須キーの存在確認
REQUIRED_KEYS=(
    ".permissions"
    ".permissions.allow"
    ".permissions.deny"
    ".permissions.disableBypassPermissionsMode"
    ".hooks"
    ".hooks.PreToolUse"
)
for key in "${REQUIRED_KEYS[@]}"; do
    if jq -e "$key" "$SETTINGS" &>/dev/null; then
        echo "  ✅ $key"
    else
        echo "  ❌ 必須キー欠落: $key"
        ERRORS=$((ERRORS + 1))
    fi
done

# disableBypassPermissionsMode == "disable"
MODE=$(jq -r '.permissions.disableBypassPermissionsMode // "(not set)"' "$SETTINGS")
if [ "$MODE" = "disable" ]; then
    echo "  ✅ disableBypassPermissionsMode = \"disable\""
else
    echo "  ⚠️  disableBypassPermissionsMode = \"$MODE\" (推奨: \"disable\")"
fi

# settings.local.json があれば検証
if [ -f .claude/settings.local.json ]; then
    if jq empty .claude/settings.local.json 2>/dev/null; then
        echo "✅ settings.local.json も valid JSON"
    else
        echo "❌ settings.local.json に JSON 構文エラー"
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "❌ $ERRORS 件のエラーがあります"
    exit 1
fi
echo ""
echo "✅ 設定は valid です"
