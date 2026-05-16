---
name: changelog-update
description: 前回タグから現在までのコミットを基に CHANGELOG.md の Unreleased セクションを更新する。リリース準備時に使う。
argument-hint: "[--release <version>]"
allowed-tools: Read, Edit, Bash(git log *), Bash(git tag *), Bash(git describe *)
---

# Changelog Update

## Context (auto-injected)

- 最新タグ: !`git describe --tags --abbrev=0 2>/dev/null || echo "(no tags yet)"`
- 最新タグからの commits: !`git log $(git describe --tags --abbrev=0 2>/dev/null)..HEAD --oneline 2>/dev/null || git log --oneline -20`
- 現在の CHANGELOG.md: @CHANGELOG.md

## Task

1. commits を Conventional Commits の type で分類
2. CHANGELOG.md の `## [Unreleased]` セクションを更新

### 形式（Keep a Changelog v1.1.0）

```markdown
## [Unreleased]

### Added
- 新機能（feat: から）

### Changed
- 既存機能の変更（refactor:, perf: から）

### Deprecated
- 将来削除予定

### Removed
- 削除した機能

### Fixed
- バグ修正（fix: から）

### Security
- セキュリティ修正
```

### ルール

- BREAKING CHANGE フッターは **`### Breaking Changes`** セクションに分離
- `chore:`, `ci:`, `docs:`, `test:`, `refactor:` のうちユーザー影響なしのものは除外
- 引数 `--release <version>` があれば Unreleased を `## [<version>] - YYYY-MM-DD` に変換し、新しい Unreleased を追加
- 重複エントリは統合

## 出力

更新後の CHANGELOG.md の `[Unreleased]` セクションの diff を表示し、ユーザーの承認を待つ。
