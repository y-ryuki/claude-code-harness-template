#!/bin/bash
# 設定スコアリング: 15項目の監査
# Critical 項目に欠落があれば上限 6.0/10（dotforge 流）

set -uo pipefail

cd "$(dirname "$0")/.."

PASS=0
FAIL=0
CRITICAL_FAIL=0
TOTAL=15

check() {
    local desc="$1"
    local severity="$2"
    local condition="$3"

    if eval "$condition" &>/dev/null; then
        echo "  ✅ [${severity}] $desc"
        PASS=$((PASS + 1))
    else
        echo "  ❌ [${severity}] $desc"
        FAIL=$((FAIL + 1))
        if [ "$severity" = "Critical" ]; then
            CRITICAL_FAIL=$((CRITICAL_FAIL + 1))
        fi
    fi
}

echo "═══════════════════════════════════════════════"
echo "  Claude Code Harness Audit"
echo "═══════════════════════════════════════════════"
echo ""

echo "▶ Layer 1: Permissions"
check "settings.json が存在" \
    "Critical" \
    "test -f .claude/settings.json"
check "disableBypassPermissionsMode が disable" \
    "Critical" \
    "jq -e '.permissions.disableBypassPermissionsMode == \"disable\"' .claude/settings.json"
check "deny に rm -rf / が含まれる" \
    "Critical" \
    "jq -e '.permissions.deny[] | select(test(\"rm -rf /\"))' .claude/settings.json"
check "deny に curl|sh パターン" \
    "Critical" \
    "jq -e '.permissions.deny[] | select(test(\"curl.*\\\\|\"))' .claude/settings.json"
check "deny に git push --force" \
    "High" \
    "jq -e '.permissions.deny[] | select(test(\"push --force\"))' .claude/settings.json"
check "deny に .env Read" \
    "Critical" \
    "jq -e '.permissions.deny[] | select(test(\"\\\\.env\"))' .claude/settings.json"

echo ""
echo "▶ Layer 2: Hooks"
check "block-dangerous.sh が存在" \
    "Critical" \
    "test -x .claude/hooks/block-dangerous.sh"
check "block-secrets.sh が存在" \
    "Critical" \
    "test -x .claude/hooks/block-secrets.sh"
check "detect-secrets.sh が存在" \
    "High" \
    "test -x .claude/hooks/detect-secrets.sh"
check "injection-scanner.py が存在" \
    "High" \
    "test -x .claude/hooks/injection-scanner.py"
check "PreToolUse:Bash hook が登録" \
    "Critical" \
    "jq -e '.hooks.PreToolUse[] | select(.matcher == \"Bash\")' .claude/settings.json"

echo ""
echo "▶ Layer 3: Isolation"
check "DevContainer 設定" \
    "Recommended" \
    "test -f .devcontainer/devcontainer.json"
check "init-firewall.sh" \
    "Recommended" \
    "test -f .devcontainer/init-firewall.sh"

echo ""
echo "▶ Files"
check ".gitignore に .env" \
    "Critical" \
    "grep -qE '^\\.env\$|^\\.env\\.\\*' .gitignore"
check "SECURITY.md が存在" \
    "Recommended" \
    "test -f SECURITY.md"

echo ""
echo "═══════════════════════════════════════════════"
SCORE=$(awk "BEGIN { printf \"%.1f\", ($PASS / $TOTAL) * 10 }")

# Critical 欠落があれば上限 6.0
if [ $CRITICAL_FAIL -gt 0 ]; then
    CAPPED_SCORE=$(awk "BEGIN { s = $SCORE; if (s > 6.0) s = 6.0; printf \"%.1f\", s }")
    echo "  📊 スコア: $CAPPED_SCORE / 10  (生スコア: $SCORE, Critical欠落で上限6.0)"
    echo "  ⚠️  Critical 項目に $CRITICAL_FAIL 件の欠落"
    EXIT_CODE=1
else
    echo "  📊 スコア: $SCORE / 10"
    EXIT_CODE=0
fi

echo "  ✅ $PASS / $TOTAL passed, ❌ $FAIL / $TOTAL failed"
echo "═══════════════════════════════════════════════"

if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "❌ Critical 項目を修正してください。"
    echo "   詳細: docs/security.md"
fi

exit $EXIT_CODE
