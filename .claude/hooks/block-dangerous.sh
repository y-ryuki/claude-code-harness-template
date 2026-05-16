#!/bin/bash
# PreToolUse hook: 危険な Bash コマンドをブロック
# stdin: { tool_name: "Bash", tool_input: { command: "..." } }
# stdout: hookSpecificOutput JSON で deny 判定

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

# クォート正規化（回避策対策）
NORMALIZED=$(echo "$COMMAND" | tr -d '"'"'" | tr -s ' ')

block() {
    local reason="$1"
    jq -n --arg reason "$reason" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $reason
        }
    }'
    exit 0
}

# ============================================
# Critical: 即停止すべき破壊コマンド
# ============================================

# rm -rf / ~ $HOME *
if echo "$NORMALIZED" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f\s+(/[\s$]|/$|~[\s$]|~/$|\$HOME[\s$]|\$HOME/)'; then
    block "🚨 CRITICAL: Destructive rm -rf on root/home detected. Use specific paths instead."
fi

# rm -rf * / **
if echo "$NORMALIZED" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f\s+(\*|\.|\*/|\.\.)\s*$'; then
    block "🚨 CRITICAL: Wildcard rm -rf blocked. Specify exact paths."
fi

# Pipe to shell
if echo "$NORMALIZED" | grep -qE '(curl|wget|fetch)\s+[^|]*\|\s*(sh|bash|zsh|fish|python|python3|ruby|perl|node)\b'; then
    block "🚨 CRITICAL: Pipe-to-shell execution blocked (supply chain risk). Download to file, review, then execute."
fi

# Fork bomb
if echo "$NORMALIZED" | grep -qE ':\(\)\s*\{.*:\|:'; then
    block "🚨 CRITICAL: Fork bomb pattern detected."
fi

# Disk destruction
if echo "$NORMALIZED" | grep -qE '^dd\s+if=/dev/(zero|random|urandom)'; then
    block "🚨 CRITICAL: Direct device write (dd if=/dev/...) blocked."
fi
if echo "$NORMALIZED" | grep -qE '^(mkfs|fdisk|parted)\b'; then
    block "🚨 CRITICAL: Filesystem/partition tool blocked."
fi

# ============================================
# High: 確認なしでの実行を防ぐべきコマンド
# ============================================

# git push --force / -f
if echo "$NORMALIZED" | grep -qE 'git\s+push\s+.*(--force(\s|$)|-f(\s|$))'; then
    block "⚠️ HIGH: git push --force blocked. Use PR review process or git push --force-with-lease if absolutely needed."
fi

# git push --no-verify
if echo "$NORMALIZED" | grep -qE 'git\s+push\s+.*--no-verify'; then
    block "⚠️ HIGH: --no-verify blocked. Hooks must run before push."
fi

# git commit --no-verify
if echo "$NORMALIZED" | grep -qE 'git\s+commit\s+.*--no-verify'; then
    block "⚠️ HIGH: --no-verify blocked. Fix the hook failure instead."
fi

# git reset --hard
if echo "$NORMALIZED" | grep -qE 'git\s+reset\s+--hard'; then
    block "⚠️ HIGH: git reset --hard can destroy uncommitted work. Use git stash or specific paths."
fi

# chmod 777 / a+rwx
if echo "$NORMALIZED" | grep -qE 'chmod\s+(-R\s+)?(777|a\+rwx|o\+w)'; then
    block "⚠️ HIGH: chmod 777 blocked. Use least-privilege permissions."
fi

# sudo / su
if echo "$NORMALIZED" | grep -qE '^sudo\s|;\s*sudo\s|&&\s*sudo\s'; then
    block "⚠️ HIGH: sudo blocked in Claude Code context. Run privileged commands manually."
fi
if echo "$NORMALIZED" | grep -qE '^su\s+(-\s+)?[a-zA-Z]'; then
    block "⚠️ HIGH: su (switch user) blocked."
fi

# Claude Code own bypass
if echo "$NORMALIZED" | grep -q '\-\-dangerously-skip-permissions'; then
    block "⚠️ HIGH: --dangerously-skip-permissions flag blocked by policy."
fi

# /etc 配下の書き換え
if echo "$NORMALIZED" | grep -qE '(tee|>|>>)\s*/etc/'; then
    block "⚠️ HIGH: Writing to /etc/ blocked."
fi

# OK
exit 0
