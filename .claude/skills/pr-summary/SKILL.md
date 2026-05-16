---
name: pr-summary
description: 現在の PR の diff・コメント・チェック結果を要約する。PR 作成前のセルフレビューや、長い PR の概要把握に使う。
argument-hint: "[PR番号]"
allowed-tools: Bash(gh pr *), Bash(git diff *), Bash(git log *)
context: fork
agent: general-purpose
---

# PR Summary

## Context (auto-injected)

- 現在のブランチ: !`git branch --show-current`
- PR 一覧: !`gh pr list --author "@me" --json number,title,state,reviewDecision`
- 引数で指定された PR (デフォルト: 現在のブランチの PR):
  - PR diff: !`gh pr diff ${ARGUMENTS:-} 2>/dev/null | head -500`
  - PR view: !`gh pr view ${ARGUMENTS:-} 2>/dev/null`
  - チェック状況: !`gh pr checks ${ARGUMENTS:-} 2>/dev/null`

## Task

上記のコンテキストをもとに、以下の構成で PR を要約してください:

```markdown
## 📝 PR Summary

### What
- 何を変更したか（3点以内）

### Why
- なぜ必要か（Issue リンクあれば記載）

### Changes by Area
| 領域 | 変更内容 |
|------|---------|
| ... | ... |

### Test Plan
- [ ] ...

### Risks
- ⚠️ ...

### Review Focus
- 👀 レビュアーに特に見てほしい箇所
```

長い diff の場合は要点に絞る。コード規約違反やセキュリティ懸念があれば「⚠️」付きでフラグする。
