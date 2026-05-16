#!/bin/bash
# PreToolUse hook: PR/branch の Merge 系コマンドをブロック
# matcher: Bash
# 動機: Merge は人間専用。AI エージェントは PR 作成までで停止する。

set -uo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

# クォート正規化
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
# gh pr merge / gh pr review --approve
# ============================================

# gh pr merge - PR をマージ
if echo "$NORMALIZED" | grep -qE 'gh[[:space:]]+pr[[:space:]]+merge'; then
    block "🚫 MERGE BLOCKED: 'gh pr merge' is reserved for humans only. AI agents must stop at PR creation. See docs/workflows/docdd.md."
fi

# gh pr review --approve (機械承認の禁止)
if echo "$NORMALIZED" | grep -qE 'gh[[:space:]]+pr[[:space:]]+review[[:space:]]+.*--approve'; then
    block "🚫 BLOCKED: AI agents must not approve PRs. Use 'gh pr comment' or 'gh pr review --comment' instead."
fi

# ============================================
# git merge (ローカル merge)
# ============================================

if echo "$NORMALIZED" | grep -qE '^git[[:space:]]+merge([[:space:]]|$)'; then
    block "🚫 MERGE BLOCKED: 'git merge' should be performed by humans on the GitHub UI. Use PR-based flow instead."
fi

# ============================================
# main / master / develop への直 push
# ============================================

if echo "$NORMALIZED" | grep -qE 'git[[:space:]]+push[[:space:]]+.*(origin|upstream)?[[:space:]]+(main|master|develop|release)(\s|$|:)'; then
    block "🚫 DIRECT PUSH BLOCKED: Pushing to main/master/develop directly is forbidden. Create a feature branch and open a PR."
fi

# git push without args (current branch could be main)
if echo "$NORMALIZED" | grep -qE '^git[[:space:]]+push([[:space:]]+--[a-z-]+)*[[:space:]]*$'; then
    # 現在のブランチが main/master か確認できる場合のみブロック
    CURRENT_BRANCH=$(git -C "${CLAUDE_PROJECT_DIR:-$(pwd)}" branch --show-current 2>/dev/null || echo "")
    case "$CURRENT_BRANCH" in
        main|master|develop|release|release/*)
            block "🚫 DIRECT PUSH BLOCKED: Current branch is '$CURRENT_BRANCH'. Create a feature branch first."
            ;;
    esac
fi

# ============================================
# auto-merge 設定
# ============================================

if echo "$NORMALIZED" | grep -qE 'gh[[:space:]]+pr[[:space:]]+merge[[:space:]]+.*--auto'; then
    block "🚫 BLOCKED: PR auto-merge must be enabled by humans only."
fi

# OK
exit 0
