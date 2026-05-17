---
description: Commit rules — Conventional Commits, message body, prohibited patterns.
alwaysApply: true
---

# Commits

## Format

Conventional Commits:

```
<type>(<scope>): <subject>

<body>

<footer>
```

詳細: [`docs/naming-conventions.md`](../../docs/naming-conventions.md)

## Types

`feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`, `style`, `build`

## Rules

- **Subject**: 英語・現在形（命令形）・50 文字以内・末尾ピリオドなし
- **Body**: **なぜ** その変更が必要かを書く（**何を** は diff が語る）
- **1 コミット 1 論理変更** — 複数の意図を混ぜない
- Breaking change は `feat!:` または footer に `BREAKING CHANGE:`
- 関連 Issue は footer に `Refs: #123` / `Closes: #123`

## Examples

良い例：

```
feat(auth): add refresh token rotation

Mitigates replay attacks by invalidating the previous refresh token
on each rotation. Aligns with OAuth 2.0 BCP-22.

Closes: #142
```

悪い例：

```
update stuff
fix bug
wip
misc changes
```

## Prohibited Patterns

- NEVER commit with `--no-verify` — pre-commit hook をスキップしない（hook が失敗したら根本原因を修正）
- NEVER commit `.env`, credentials, large binaries, generated files
- NEVER use `git commit --amend` for already-pushed commits（履歴改変は事故の元）
- NEVER write WIP commits to `main` — worktree branch で完結させる
- NEVER use vague messages: `fix bug`, `update`, `wip`, `misc`, `changes`
- NEVER mix functional change + formatting in one commit — 分離する
- NEVER commit without reading `git diff --staged` first
