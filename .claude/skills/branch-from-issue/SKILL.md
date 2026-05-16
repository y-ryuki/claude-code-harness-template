---
name: branch-from-issue
description: GitHub Issue 番号から命名規約に従ったブランチを作成し、worktree も切る。/autopilot の最初のステップで使われる他、手動でも呼べる。
argument-hint: "<issue-number>"
allowed-tools: Bash(gh issue view *), Bash(git fetch *), Bash(git worktree *), Bash(git switch *), Bash(git branch *)
---

# Branch from Issue

issue: $ARGUMENTS

## Context (auto-injected)

- Current branch: !`git branch --show-current`
- Origin URL: !`git remote get-url origin 2>/dev/null || echo "(no remote)"`
- Issue 情報: !`gh issue view $ARGUMENTS --json number,title,labels 2>/dev/null || echo "Issue #$ARGUMENTS not found"`

## Task

上記の Issue タイトルから、`docs/naming-conventions.md` に従ったブランチを作成してください。

### 命名ルール

1. **Issue title** から `<type>: <subject>` の `<type>` を抽出
2. `<subject>` を kebab-case 化 → `<slug>`
3. ブランチ名: `<type>/<issue#>-<slug>`

例:
- Issue: `feat: add dark mode toggle to login`
- Branch: `feat/123-add-dark-mode-toggle`

### 実行手順

```bash
# 1. 現状確認（既に対応ブランチがあれば switch するだけ）
git fetch origin

# 2. 既存ブランチチェック
git branch -a | grep -E "<type>/$ARGUMENTS-" && echo "既存ブランチあり"

# 3. なければ作成（オプション: worktree）
# (a) 同じディレクトリで作業
git switch -c "<type>/<issue#>-<slug>" origin/main

# (b) worktree で並列作業（推奨）
git worktree add "../<repo-name>-wt/<type>/<issue#>-<slug>" -b "<type>/<issue#>-<slug>" origin/main
```

### 確認事項

- [ ] Issue タイトルが Conventional Commits 形式か（そうでなければ警告）
- [ ] type が許可リスト（feat/fix/docs/refactor/test/chore/perf/ci/style/build）か
- [ ] 既存の同名ブランチ・worktree がないか

### 出力

```markdown
✅ Branch created: <branch-name>
📁 Worktree (option b): <path>

次のステップ:
- ブランチで作業 → /plan で実装計画
- または /autopilot $ARGUMENTS で一気通貫実行
```

### Issue タイトルが規約違反の場合

```markdown
⚠️ Issue タイトル "<title>" は Conventional Commits 形式ではありません。

推奨形式: <type>: <subject>
例: feat: add dark mode toggle

タイトルを修正するか、type を手動指定:
- 推測 type: feat | fix | docs | ... ?
```
