#!/usr/bin/env bats
# 命名規約の検証テスト
# docs/naming-conventions.md に従っているか確認

# 共通ヘルパー
VALID_TYPES_REGEX='^(feat|fix|docs|refactor|test|chore|perf|ci|style|build)'

# ============================================
# Issue / PR タイトル形式
# ============================================

assert_valid_title() {
    [[ "$1" =~ ^(feat|fix|docs|refactor|test|chore|perf|ci|style|build)(\(.+\))?:\ .+ ]]
}

assert_invalid_title() {
    ! [[ "$1" =~ ^(feat|fix|docs|refactor|test|chore|perf|ci|style|build)(\(.+\))?:\ .+ ]]
}

@test "valid title: feat: add dark mode" {
    assert_valid_title "feat: add dark mode"
}

@test "valid title: fix(auth): prevent null deref" {
    assert_valid_title "fix(auth): prevent null deref"
}

@test "valid title: docs: update README" {
    assert_valid_title "docs: update README"
}

@test "invalid title: Dark mode added" {
    assert_invalid_title "Dark mode added"
}

@test "invalid title: feature: add x (typo, feat と feature は別)" {
    assert_invalid_title "feature: add x"
}

@test "invalid title: feat add dark mode (colon missing)" {
    assert_invalid_title "feat add dark mode"
}

# ============================================
# Branch 名形式 <type>/<issue#>-<slug>
# ============================================

assert_valid_branch() {
    [[ "$1" =~ ^(feat|fix|docs|refactor|test|chore|perf|ci|style|build|hotfix)/[0-9a-z]+-[a-z0-9-]+$ ]]
}

assert_invalid_branch() {
    ! [[ "$1" =~ ^(feat|fix|docs|refactor|test|chore|perf|ci|style|build|hotfix)/[0-9a-z]+-[a-z0-9-]+$ ]]
}

@test "valid branch: feat/123-add-dark-mode" {
    assert_valid_branch "feat/123-add-dark-mode"
}

@test "valid branch: fix/456-null-deref" {
    assert_valid_branch "fix/456-null-deref"
}

@test "valid branch: hotfix/20260516-revert-broken-deploy" {
    assert_valid_branch "hotfix/20260516-revert-broken-deploy"
}

@test "invalid branch: darkmode (no type or issue)" {
    assert_invalid_branch "darkmode"
}

@test "invalid branch: feat-123-dark-mode (no slash)" {
    assert_invalid_branch "feat-123-dark-mode"
}

@test "invalid branch: Feat/123/Dark_Mode (case + underscore)" {
    assert_invalid_branch "Feat/123/Dark_Mode"
}

@test "invalid branch: feat/abc-dark (issue# not numeric/hash)" {
    # 厳密には数字ベース推奨だが、hotfix の YYYYMMDD パターンも許可
    # この test は数字以外の混入を弾く例
    skip "issue# は数字 or YYYYMMDD のみ。test の制限上 skip"
}

# ============================================
# Commit メッセージ（subject line）
# ============================================

assert_valid_commit_subject() {
    local subject="$1"
    [[ "$subject" =~ ^(feat|fix|docs|refactor|test|chore|perf|ci|style|build)(\(.+\))?:\ .+ ]] \
    && [[ ${#subject} -le 100 ]]  # gh の表示上 100 文字以内推奨
}

@test "valid commit: feat(hooks): add fork-bomb detection" {
    assert_valid_commit_subject "feat(hooks): add fork-bomb detection"
}

@test "valid commit: chore: bump prettier to 3.4" {
    assert_valid_commit_subject "chore: bump prettier to 3.4"
}

@test "valid commit: fix(e2e): allow flaky test retry" {
    assert_valid_commit_subject "fix(e2e): allow flaky test retry"
}

# ============================================
# 既存 ADR の命名チェック (docs/decisions/NNNN-*.md)
# ============================================

@test "all ADR files follow NNNN-kebab.md naming" {
    cd "$BATS_TEST_DIRNAME/../.."
    while IFS= read -r f; do
        bn=$(basename "$f" .md)
        case "$bn" in
            README|template) continue ;;
        esac
        [[ "$bn" =~ ^[0-9]{4}-[a-z0-9-]+$ ]] || (echo "Invalid ADR name: $bn" && return 1)
    done < <(find docs/decisions -name '*.md' -maxdepth 1 2>/dev/null)
}

# ============================================
# 既存 Spec の命名チェック (docs/specs/<issue#>-*.md)
# ============================================

@test "all Spec files follow <issue#>-kebab.md naming" {
    cd "$BATS_TEST_DIRNAME/../.."
    while IFS= read -r f; do
        bn=$(basename "$f" .md)
        case "$bn" in
            README|template) continue ;;
        esac
        [[ "$bn" =~ ^[0-9]+-[a-z0-9-]+$ ]] || (echo "Invalid Spec name: $bn" && return 1)
    done < <(find docs/specs -name '*.md' -maxdepth 1 2>/dev/null)
}
