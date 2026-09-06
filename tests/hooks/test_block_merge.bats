#!/usr/bin/env bats
# block-merge.sh のテスト
# Merge 系コマンドが正しく block されるかを検証

HOOK="$BATS_TEST_DIRNAME/../../.claude/hooks/block-merge.sh"

run_hook() {
    local command="$1"
    jq -n --arg cmd "$command" '{tool_name:"Bash", tool_input:{command:$cmd}}' \
      | bash "$HOOK"
}

assert_blocked() {
    [[ "$output" == *"permissionDecision"* ]] && [[ "$output" == *"deny"* ]]
}

assert_passed() {
    [ -z "$output" ]
}

# ============================================
# gh pr merge は block
# ============================================

@test "blocks: gh pr merge 123" {
    run run_hook "gh pr merge 123"
    assert_blocked
}

@test "blocks: gh pr merge with --auto" {
    run run_hook "gh pr merge 123 --auto --squash"
    assert_blocked
}

@test "blocks: gh pr merge with --merge" {
    run run_hook "gh pr merge 123 --merge"
    assert_blocked
}

@test "blocks: gh pr review --approve" {
    run run_hook "gh pr review 123 --approve"
    assert_blocked
}

# ============================================
# git merge は block
# ============================================

@test "blocks: git merge feature-branch" {
    run run_hook "git merge feature-branch"
    assert_blocked
}

@test "blocks: git merge --no-ff origin/main" {
    run run_hook "git merge --no-ff origin/main"
    assert_blocked
}

# ============================================
# main / master / develop への直 push は block
# ============================================

@test "blocks: git push origin main" {
    run run_hook "git push origin main"
    assert_blocked
}

@test "blocks: git push origin master" {
    run run_hook "git push origin master"
    assert_blocked
}

@test "blocks: git push origin develop" {
    run run_hook "git push origin develop"
    assert_blocked
}

@test "blocks: git push -u origin main" {
    run run_hook "git push -u origin main"
    assert_blocked
}

@test "blocks: git push origin release" {
    run run_hook "git push origin release"
    assert_blocked
}

@test "blocks: feature refspec targeting main" {
    run run_hook "git push origin feat/123-fix:main"
    assert_blocked
}

@test "blocks: Git abbreviated protected destination" {
    run run_hook "git push origin feat/123-fix:heads/main"
    assert_blocked
}

@test "blocks: symbolic HEAD added after a feature refspec" {
    run run_hook "git push origin feat/123-fix HEAD"
    assert_blocked
}

@test "blocks: protected push inside control flow" {
    run run_hook "if true; then git push origin main; fi"
    assert_blocked
}

@test "blocks: protected push inside a shell command string" {
    run run_hook 'bash -c "git push origin feat/123-fix:main"'
    assert_blocked
}

@test "blocks: protected push following a comment" {
    run run_hook $'echo start # comment\ngit push origin main'
    assert_blocked
}

@test "blocks: ambiguous shorthand after another git context" {
    run run_hook "git -C /tmp status; git push origin feat/123-fix"
    assert_blocked
}

@test "blocks: ambiguous shorthand after a subshell" {
    run run_hook "(cd /tmp); git push origin feat/123-fix"
    assert_blocked
}

@test "allows: explicit feature push following status" {
    run run_hook "git status && git push origin feat/123-fix:refs/heads/feat/123-fix"
    assert_passed
}

@test "blocks: fully qualified protected destination with trailing flags" {
    run run_hook "git push -u origin fix/123-fix:refs/heads/main --porcelain"
    assert_blocked
}

@test "blocks: protected destination in second refspec" {
    run run_hook "git push origin feat/123-fix:feat/123-fix fix/456-fix:master"
    assert_blocked
}

@test "blocks: release subbranch destination" {
    run run_hook "git push origin feat/123-fix:release/2026-09"
    assert_blocked
}

@test "blocks: global git options cannot hide a protected push" {
    run run_hook "git -C /tmp push origin feat/123-fix:develop"
    assert_blocked
}

@test "blocks: bulk push even after an allowed feature argument" {
    run run_hook "git push origin feat/123-fix --all"
    assert_blocked
}

@test "blocks: destination omitted from push" {
    run run_hook "git push origin"
    assert_blocked
}

@test "blocks: variable destination needs explicit review" {
    run run_hook 'git push origin feat/123-fix:$TARGET'
    assert_blocked
}

@test "blocks: configured push remapping for shorthand ref" {
    git init -q "$BATS_TEST_TMPDIR/repo"
    git -C "$BATS_TEST_TMPDIR/repo" config remote.origin.push 'refs/heads/feat/*:refs/heads/main'
    export CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/repo"
    run run_hook "git push origin feat/123-fix"
    assert_blocked
}

@test "allows: explicit feature destination" {
    run run_hook "git push -u origin feat/123-fix:refs/heads/feat/123-fix"
    assert_passed
}

@test "allows: protected source copied to feature destination" {
    run run_hook "git push origin main:feat/123-snapshot"
    assert_passed
}

# ============================================
# Safe pushes (should pass)
# ============================================

@test "allows: git push origin feat/123-dark-mode" {
    run run_hook "git push origin feat/123-dark-mode"
    assert_passed
}

@test "allows: git push -u origin fix/456-null-deref" {
    run run_hook "git push -u origin fix/456-null-deref"
    assert_passed
}

@test "allows: gh pr create" {
    run run_hook "gh pr create --title 'feat: x' --body y"
    assert_passed
}

@test "allows: gh pr comment" {
    run run_hook "gh pr comment 123 --body 'looks good'"
    assert_passed
}

@test "allows: gh pr review --comment" {
    run run_hook "gh pr review 123 --comment --body 'lgtm'"
    assert_passed
}

@test "allows: gh pr view" {
    run run_hook "gh pr view 123"
    assert_passed
}

@test "allows: git fetch origin" {
    run run_hook "git fetch origin"
    assert_passed
}

@test "allows: git status" {
    run run_hook "git status"
    assert_passed
}

@test "allows: empty command" {
    run run_hook ""
    assert_passed
}
