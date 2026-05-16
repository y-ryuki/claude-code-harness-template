#!/bin/bash
# PreToolUse hook: 書き込み内容に秘密情報パターンが含まれていないかチェック
# matcher: Edit|Write
# 動機: API キー・トークンのハードコードを未然に防ぐ

set -uo pipefail   # -e を外す: grep 不一致が大量発生するため if 文制御

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

# 各種 API キー パターン（誤検知を避けるため文字列長や前後文脈もチェック）
match() {
    local pattern="$1"
    echo "$NEW_CONTENT" | grep -qE "$pattern"
}

if match 'AKIA[0-9A-Z]{16}'; then block "AWS Access Key"; fi
if match 'aws_secret_access_key[[:space:]]*=[[:space:]]*[A-Za-z0-9/+=]{40}'; then block "AWS Secret Access Key"; fi
if match 'ghp_[a-zA-Z0-9]{36}'; then block "GitHub Personal Access Token (classic)"; fi
if match 'gho_[a-zA-Z0-9]{36}'; then block "GitHub OAuth Token"; fi
if match 'ghs_[a-zA-Z0-9]{36}'; then block "GitHub App Token"; fi
if match 'github_pat_[0-9a-zA-Z_]{20,}'; then block "GitHub Fine-Grained PAT"; fi
# Anthropic API key: sk-ant- + 20文字以上の英数記号
if match 'sk-ant-[a-zA-Z0-9_-]{20,}'; then
    # documentation placeholder "sk-ant-..." は除外
    if ! echo "$NEW_CONTENT" | grep -qE 'sk-ant-(\.\.\.|XXX|YOUR_)'; then
        block "Anthropic API Key"
    fi
fi
if match 'sk_live_[a-zA-Z0-9]{24,}'; then block "Stripe Live Key"; fi
if match 'sk_test_[a-zA-Z0-9]{24,}'; then block "Stripe Test Key"; fi
if match 'xox[baprs]-[0-9A-Za-z-]{10,}'; then block "Slack Token"; fi
if match 'AIza[0-9A-Za-z_-]{35}'; then block "Google API Key"; fi
if match 'glpat-[A-Za-z0-9_-]{20}'; then block "GitLab PAT"; fi
if match 'mongodb(\+srv)?://[^:[:space:]]+:[^@[:space:]]+@'; then block "MongoDB Connection String with credentials"; fi
if match 'postgres(ql)?://[^:[:space:]]+:[^@[:space:]]+@'; then block "PostgreSQL Connection String with credentials"; fi
if match 'mysql://[^:[:space:]]+:[^@[:space:]]+@'; then block "MySQL Connection String with credentials"; fi
if match '^-----BEGIN[[:space:]].*PRIVATE KEY'; then block "Private Key block"; fi

# OK
exit 0
