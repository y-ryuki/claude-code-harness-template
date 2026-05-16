#!/usr/bin/env bats
# detect-secrets.sh のテスト

HOOK="$BATS_TEST_DIRNAME/../../.claude/hooks/detect-secrets.sh"

run_hook() {
    local content="$1"
    jq -n --arg c "$content" '{tool_name:"Edit", tool_input:{new_string:$c}}' \
      | bash "$HOOK"
}

assert_blocked() {
    [[ "$output" == *"permissionDecision"* ]] && [[ "$output" == *"deny"* ]]
}

assert_passed() {
    [ -z "$output" ]
}

# ============================================
# API Keys (should block)
# ============================================

@test "blocks: AWS Access Key" {
    run run_hook 'const KEY = "AKIAIOSFODNN7EXAMPLE";'
    assert_blocked
}

@test "blocks: GitHub PAT (classic)" {
    run run_hook 'token: ghp_1234567890abcdefghij1234567890abcdef12'
    assert_blocked
}

@test "blocks: GitHub Fine-Grained PAT" {
    run run_hook 'export TOKEN=github_pat_11AAAAAAAA000000000000_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    assert_blocked
}

@test "blocks: Anthropic API Key" {
    run run_hook 'ANTHROPIC_API_KEY=sk-ant-api03-1234567890abcdefghijk'
    assert_blocked
}

@test "blocks: Stripe Live Key" {
    run run_hook 'stripe.setKey("sk_live_4eC39HqLyjWDarjtT1zdp7dc");'
    assert_blocked
}

@test "blocks: Slack Bot Token" {
    run run_hook 'SLACK_BOT_TOKEN=xoxb-1234567890-1234567890123-AbCdEfGhIjKlMnOpQrStUvWx'
    assert_blocked
}

@test "blocks: Google API Key" {
    run run_hook 'apiKey: "AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"'
    assert_blocked
}

@test "blocks: MongoDB connection string" {
    run run_hook 'MONGO_URI=mongodb://user:password@cluster.example.com/db'
    assert_blocked
}

@test "blocks: PostgreSQL connection string" {
    run run_hook 'DATABASE_URL=postgresql://admin:secret@db.example.com:5432/mydb'
    assert_blocked
}

@test "blocks: Private Key PEM" {
    run run_hook '-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...'
    assert_blocked
}

# ============================================
# Safe content (should pass)
# ============================================

@test "allows: env var reference (no hardcoded key)" {
    run run_hook 'const key = process.env.AWS_ACCESS_KEY;'
    assert_passed
}

@test "allows: documentation placeholder" {
    run run_hook 'export ANTHROPIC_API_KEY="sk-ant-..."'
    assert_passed
}

@test "allows: regular code" {
    run run_hook 'function hello() { return "world"; }'
    assert_passed
}

@test "allows: empty content" {
    run run_hook ''
    assert_passed
}
