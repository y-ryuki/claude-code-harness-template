#!/bin/bash
# PreToolUse hook: 秘密ファイルの読み取り/編集/書き込みをブロック
# matcher: Read|Edit|Write
# 動機: deny ルールだけでは過去にバグで漏れた事例があるため、hook で二重防御

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

[ -z "$FILE_PATH" ] && exit 0

# 正規化（パス区切りを統一）
# shellcheck disable=SC1003
NORMALIZED_PATH=$(echo "$FILE_PATH" | tr '\\' '/')

PROTECTED_PATTERNS=(
    '\.env$'
    '\.env\.[^/]*$'
    '\.envrc$'
    '/\.aws/'
    '/\.ssh/'
    '/\.gnupg/'
    '/id_rsa$'
    '/id_ed25519$'
    '\.pem$'
    '\.key$'
    '\.pfx$'
    '\.p12$'
    '/credentials\.json$'
    '/credentials$'
    '/service-account.*\.json$'
    '/token\.json$'
    '/secrets/'
    '\.kube/config$'
    '/auth\.json$'
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if echo "$NORMALIZED_PATH" | grep -qE "$pattern"; then
        jq -n --arg path "$FILE_PATH" --arg tool "$TOOL_NAME" '{
            hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: ("🔒 Access to sensitive file blocked: " + $path + " (tool: " + $tool + "). If you need this access, edit .claude/settings.local.json individually.")
            }
        }'
        exit 0
    fi
done

exit 0
