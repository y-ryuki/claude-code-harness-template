---
name: autopilot
description: Issue 番号を引数に取り、worktree 作成 → Spec 起票 → 実装 → テスト → 多角レビュー → PR 作成 を自動実行。Merge は人間専用なので最後に PR URL を返して停止する。
argument-hint: "<issue-number>"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(git *), Bash(gh issue *), Bash(gh pr create *), Bash(gh pr view *), Bash(gh pr diff *), Bash(gh pr checks *), Bash(npm *), Bash(pnpm *), Bash(npx *), Bash(pytest *), Bash(bats *), Bash(jq *)
---

# /autopilot: Issue → PR の一気通貫実行

issue: $ARGUMENTS

## ⚠️ 重要ルール

このコマンドは **PR 作成までで停止** します。**Merge は絶対に行いません**。Merge は人間専用のアクションです（settings.json と hook で技術的にもブロック済み）。

## 実行フロー

### Step 1: Issue 確認

```bash
gh issue view $ARGUMENTS --json number,title,body,labels,milestone,assignees
```

- Issue タイトルから `<type>` を判定
- `<slug>` を生成（subject を kebab-case 化）
- ブランチ名: `<type>/<issue#>-<slug>`

確認事項:
- [ ] Issue が "open" 状態か
- [ ] 自分にアサインされてるか（任意）
- [ ] 既存 PR がないか（`gh pr list --search "linked:$ARGUMENTS"`）

### Step 2: ブランチ + Worktree

```bash
BRANCH="<type>/<issue#>-<slug>"
WORKTREE="../<repo-name>-wt/$BRANCH"
git fetch origin
git worktree add "$WORKTREE" -b "$BRANCH" origin/main
cd "$WORKTREE"
```

以降の作業は **worktree 内** で実行。

### Step 3: 要件確認

Issue 本文を分析:

- **大規模機能** か **小さな変更** かを判定
  - 大規模（30行超 / 複数ファイル / 新概念）→ Step 3a へ
  - 小さい変更 → Step 3b へ

#### Step 3a: Requirements / ADR / Spec 作成（大規模時）

1. `/requirements <topic>` を内部実行 → `docs/requirements/<slug>.md` 雛形作成
2. 技術選定が必要なら `/adr "<title>"` で ADR 起票
3. `/spec $ARGUMENTS` で `docs/specs/$ARGUMENTS-<slug>.md` 作成
4. ユーザーに「**Spec を確認してください**」と提示し、承認待ち

#### Step 3b: Spec のみ（小規模時）

`/spec $ARGUMENTS` で Spec 雛形作成 → 自動で要点埋め

### Step 4: 実装計画

`/plan` 相当のロジック:

- Spec の Acceptance Criteria を読む
- 影響ファイルを `knowledge-explorer` で特定
- 3-7 のステップに分解
- 各ステップの見積もり

### Step 5: 実装

ステップごとに:
1. ファイル編集（`PostToolUse` hook で自動フォーマット）
2. 各ステップで小コミット（任意）
3. テストファイルも併せて作成・更新

### Step 6: テスト

```bash
npm run test     # または該当するテスト
npm run lint     # lint
```

`test-runner` agent を使うと失敗だけ抽出される。

すべて green になるまで修正。

### Step 7: 多角レビュー

```
/review-multi main
```

7エージェント並列レビューを実行。

- **Blockers (REQUEST CHANGES)** があれば → 修正 → Step 7 を再実行
- すべて APPROVE → Step 8 へ

### Step 8: コミット

`commit-helper` Skill で Conventional Commits 形式に整形:

```
<type>(<scope>): <subject>

<body explaining WHY>

Refs: #<issue#>
Co-Authored-By: Claude <noreply@anthropic.com>
```

複数の論理的変更があれば **複数コミットに分割**。

### Step 9: Push

```bash
git push -u origin "$BRANCH"
```

### Step 10: PR 作成

```bash
gh pr create \
  --title "<type>: <subject> (#$ARGUMENTS)" \
  --body "$(cat <<EOF
## 概要
<1-3行>

## 動機
Closes #$ARGUMENTS

## 変更内容
$(spec/specs/issue#-*.md の Acceptance Criteria を転記)

## 検証
- [x] ユニットテスト追加
- [x] /review-multi で全観点 APPROVE
- [ ] 動作確認（レビュアーお願いします）

## レビューサマリー
<7エージェントの統合結果のExecutive Summary>

🤖 Generated with /autopilot
EOF
)"
```

### Step 11: 完了報告

```markdown
## ✅ Autopilot 完了

**Issue**: #$ARGUMENTS
**Branch**: <branch-name>
**PR**: <PR URL>
**Worktree**: <path>

### 実装サマリー
- ファイル変更: X files (+YYY/-ZZZ)
- テスト: Y/Y passed
- 多角レビュー: 7/7 APPROVE
- コミット: N

### ⚠️ Merge は人間専用
レビュアーの最終承認後、人間が Merge してください。
このスクリプトは Merge を **行いません**（settings + hook で技術的に禁止）。

### Worktree 後処理
PR がマージされた後:
\`\`\`bash
git worktree remove <path>
git branch -d <branch-name>
\`\`\`
```

## エラーハンドリング

- **Issue が見つからない** → 停止、ユーザー確認
- **既存 PR あり** → 既存 PR に commit を追加するか確認
- **テスト失敗** → 修正を試みる、3回失敗で停止してユーザー報告
- **レビュー REQUEST CHANGES** → 自動修正可能なものは適用、不可能なら停止
- **Merge コマンドが呼ばれそうになる** → Hook で技術的にブロック、ログのみ

## ルール

1. **絶対に Merge しない**（PR 作成までで停止）
2. **絶対に main に直 push しない**（hook で技術的にブロック）
3. **すべての commit は Conventional Commits 形式**
4. **大きな変更は Spec / ADR を先に書く**
5. **テスト green + 多角レビュー APPROVE が PR 作成の前提**
6. **ユーザーが介入できる pause point を残す**（特に Spec 承認、最終 PR 内容確認）
