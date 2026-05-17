---
description: Core invariants — always loaded. Non-negotiables, security NEVERs, process NEVERs.
alwaysApply: true
---

# Core Invariants

このファイルは Claude セッションに常時ロードされる **絶対ルール**。違反は即座に停止して再確認する。

## Non-Negotiables

1. **Worktree-based development** — リポジトリルートは常に `main` に固定。`git checkout <branch>` をルートで実行禁止。作業は `.claude/worktrees/` 配下で行い、PR 経由でマージする。
2. **DocDD** — 実装前に要件 / 仕様 / ADR を確認し、計画を策定する。`chore` タイプは省略可。
3. **Research before editing** — コード変更前に該当箇所を読む。読んでいないコードを変更してはならない。
4. **Small steps** — 大きな変更は段階に分け、各段階でテスト。
5. **Root cause** — 表面的な fix ではなく根本原因を特定する。

## Security NEVERs

- NEVER read `.env*`, `*.key`, `*.pem`, `*.p12`, `.aws/`, `.ssh/`, credentials files
- NEVER run `rm -rf /`, `rm -rf *`, `rm -rf ~`
- NEVER run `curl ... | sh`, `wget ... | sh`, `eval $(...)` against untrusted input
- NEVER commit secrets, tokens, or API keys（ハードコード禁止）
- NEVER run `DROP DATABASE`, `TRUNCATE`, destructive SQL without explicit approval
- NEVER use `--dangerously-skip-permissions`

## Process NEVERs

- NEVER merge a PR yourself — Merge は **GitHub UI で人間が実行**（`gh pr merge`, `git merge`, main への直 push は AI 禁止）
- NEVER bypass hooks (`--no-verify`, `--no-gpg-sign`) — ブロックされたら根本原因を修正
- NEVER run `git push --force` to `main`/`master`
- NEVER edit `CLAUDE.md` / `.claude/CLAUDE.md` / `.claude/rules/*` without an Issue
- NEVER add features, refactors, or abstractions beyond what the task requires
- NEVER leave half-finished implementations or TODO/FIXME without an Issue link
- NEVER take destructive actions (delete branch, reset --hard, drop table) without user confirmation

## When in doubt

不確実な箇所は「**未確認**」「**推測**」と明示し、user に確認を取る。**沈黙して進めない**。
