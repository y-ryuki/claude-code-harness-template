#!/usr/bin/env bats
# block-secrets.sh のテスト

HOOK="$BATS_TEST_DIRNAME/../../.claude/hooks/block-secrets.sh"

run_hook() {
    local tool="$1"
    local path="$2"
    jq -n --arg tool "$tool" --arg path "$path" '{tool_name:$tool, tool_input:{file_path:$path}}' \
      | bash "$HOOK"
}

assert_blocked() {
    [[ "$output" == *"permissionDecision"* ]] && [[ "$output" == *"deny"* ]]
}

assert_passed() {
    [ -z "$output" ]
}

# ============================================
# .env 系
# ============================================

@test "blocks: Read .env" {
    run run_hook "Read" "/Users/me/project/.env"
    assert_blocked
}

@test "blocks: Read .env.local" {
    run run_hook "Read" "/Users/me/project/.env.local"
    assert_blocked
}

@test "blocks: Read .env.production" {
    run run_hook "Read" "/path/to/.env.production"
    assert_blocked
}

@test "blocks: Edit .env" {
    run run_hook "Edit" "./.env"
    assert_blocked
}

@test "blocks: Write .env" {
    run run_hook "Write" "/abs/path/.env"
    assert_blocked
}

@test "blocks: Read .envrc" {
    run run_hook "Read" "/Users/me/project/.envrc"
    assert_blocked
}

# ============================================
# Cloud credentials
# ============================================

@test "blocks: Read AWS credentials" {
    run run_hook "Read" "/Users/me/.aws/credentials"
    assert_blocked
}

@test "blocks: Read AWS config" {
    run run_hook "Read" "/Users/me/.aws/config"
    assert_blocked
}

@test "blocks: Read .kube/config" {
    run run_hook "Read" "/Users/me/.kube/config"
    assert_blocked
}

@test "blocks: Read service-account.json" {
    run run_hook "Read" "/path/to/service-account.json"
    assert_blocked
}

# ============================================
# SSH / GPG
# ============================================

@test "blocks: Read SSH id_rsa" {
    run run_hook "Read" "/Users/me/.ssh/id_rsa"
    assert_blocked
}

@test "blocks: Read SSH id_ed25519" {
    run run_hook "Read" "/Users/me/.ssh/id_ed25519"
    assert_blocked
}

@test "blocks: Read GPG dir" {
    run run_hook "Read" "/Users/me/.gnupg/secring.gpg"
    assert_blocked
}

# ============================================
# Certificates / Keys
# ============================================

@test "blocks: Read .pem file" {
    run run_hook "Read" "/path/cert.pem"
    assert_blocked
}

@test "blocks: Read .key file" {
    run run_hook "Read" "/path/private.key"
    assert_blocked
}

@test "blocks: Read .pfx file" {
    run run_hook "Read" "/path/cert.pfx"
    assert_blocked
}

# ============================================
# Generic credentials
# ============================================

@test "blocks: Read credentials.json" {
    run run_hook "Read" "/path/credentials.json"
    assert_blocked
}

@test "blocks: Read secrets/ dir" {
    run run_hook "Read" "/path/secrets/api.txt"
    assert_blocked
}

@test "blocks: Read token.json" {
    run run_hook "Read" "/path/token.json"
    assert_blocked
}

# ============================================
# Safe paths (should pass)
# ============================================

@test "allows: Read README.md" {
    run run_hook "Read" "/Users/me/project/README.md"
    assert_passed
}

@test "allows: Read package.json" {
    run run_hook "Read" "/Users/me/project/package.json"
    assert_passed
}

@test "allows: Read .env.example (gitignored example)" {
    run run_hook "Read" "/Users/me/project/.env.example"
    assert_blocked  # 念のため .env.* 全部ブロック
}

@test "allows: Read src/index.ts" {
    run run_hook "Read" "/Users/me/project/src/index.ts"
    assert_passed
}

@test "allows: Read tests/auth.spec.ts" {
    run run_hook "Read" "/Users/me/project/tests/auth.spec.ts"
    assert_passed
}

@test "allows: empty path" {
    run run_hook "Read" ""
    assert_passed
}
