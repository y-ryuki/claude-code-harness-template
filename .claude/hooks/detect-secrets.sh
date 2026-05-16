#!/bin/bash
# PreToolUse hook: 書き込み内容に秘密情報パターンが含まれていないかチェック
# matcher: Edit|Write
# 動機: API キー・トークンのハードコードを未然に防ぐ

set -euo pipefail

INPUT=$(cat)
NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')

[ -z "$NEW_CONTENT" ] && exit 0

block() {
    local pattern="$1"
    jq -n --arg pattern "$pattern" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: ("🔑 Secret-looking pattern detected: " + $pattern + ". Use environment variables (process.env.X / os.environ[\"X\"]) instead of hardcoding secrets.")
        }
    }'
    exit 0
}

# 各種 API キー パターン
echo "$NEW_CONTENT" | grep -qE 'AKIA[0-9A-Z]{16}' && block "AWS Access Key"
echo "$NEW_CONTENT" | grep -qE 'aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}' && block "AWS Secret Access Key"
echo "$NEW_CONTENT" | grep -qE 'ghp_[a-zA-Z0-9]{36}' && block "GitHub Personal Access Token (classic)"
echo "$NEW_CONTENT" | grep -qE 'gho_[a-zA-Z0-9]{36}' && block "GitHub OAuth Token"
echo "$NEW_CONTENT" | grep -qE 'ghs_[a-zA-Z0-9]{36}' && block "GitHub App Token"
echo "$NEW_CONTENT" | grep -qE 'github_pat_[0-9a-zA-Z_]{82}' && block "GitHub Fine-Grained PAT"
echo "$NEW_CONTENT" | grep -qE 'sk-ant-[a-zA-Z0-9_-]{20,}' && block "Anthropic API Key"
echo "$NEW_CONTENT" | grep -qE 'sk_live_[a-zA-Z0-9]{24,}' && block "Stripe Live Key"
echo "$NEW_CONTENT" | grep -qE 'sk_test_[a-zA-Z0-9]{24,}' && block "Stripe Test Key"
echo "$NEW_CONTENT" | grep -qE 'xox[baprs]-[0-9A-Za-z-]+' && block "Slack Token"
echo "$NEW_CONTENT" | grep -qE 'AIza[0-9A-Za-z_-]{35}' && block "Google API Key"
echo "$NEW_CONTENT" | grep -qE 'glpat-[A-Za-z0-9_-]{20}' && block "GitLab PAT"
echo "$NEW_CONTENT" | grep -qE 'mongodb(\+srv)?://[^:\s]+:[^@\s]+@' && block "MongoDB Connection String with credentials"
echo "$NEW_CONTENT" | grep -qE 'postgres(ql)?://[^:\s]+:[^@\s]+@' && block "PostgreSQL Connection String with credentials"
echo "$NEW_CONTENT" | grep -qE 'mysql://[^:\s]+:[^@\s]+@' && block "MySQL Connection String with credentials"
echo "$NEW_CONTENT" | grep -qE '-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY' && block "Private Key block"

# OK
exit 0
