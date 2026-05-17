---
description: Dependency management — version verification, security-critical packages, prohibited patterns.
globs:
  - "**/package.json"
  - "**/package-lock.json"
  - "**/pnpm-lock.yaml"
  - "**/yarn.lock"
  - "**/requirements*.txt"
  - "**/pyproject.toml"
  - "**/poetry.lock"
  - "**/Gemfile"
  - "**/go.mod"
  - "**/Cargo.toml"
---

# Dependency Management

## Version Verification

依存を追加・更新する前に、**訓練データに頼らず** 必ずコマンドで確認：

| エコシステム | 最新版確認 | 現状確認 |
|---|---|---|
| npm/pnpm | `npm view <pkg> version` | `npm outdated` |
| pip | `pip index versions <pkg>` | `pip list --outdated` |
| go | `go list -m -u <pkg>` | `go list -m -u all` |
| cargo | `cargo search <pkg>` | `cargo outdated` |

判断はコマンド出力に基づく。記憶ベースのバージョン指定は禁止。

## Version Specifier

- npm: caret (`^`) を既定。exact pin する場合は理由をコメント
- pip: `~=` または exact pin。理由をコメント
- breaking 変更を含む major up は **ADR 起票** してから

## Security-Critical Packages

認証 / 暗号 / HTTP / セッション / TLS 系：

- 常に **最新の stable** を使う
- `npm audit` / `pip-audit` / `cargo audit` で脆弱性確認
- HIGH 以上の脆弱性が出たら **24h 以内** に対応

## Supply Chain Protection (Takumi Guard)

本テンプレートは **Takumi Guard** (shisho.dev) の registry proxy 経由で install する前提。`npm audit` が出る**前**の悪性パッケージを 403 でブロックする proactive 防御層。

- 詳細: [ADR-0002](../../docs/decisions/0002-introduce-takumi-guard-for-supply-chain-protection.md)
- セットアップ: `cp .npmrc.example .npmrc` → `tg_anon_*` トークンを埋める
- 対応: npm / pnpm / yarn / pip / uv / poetry
- トークン (`tg_*`) は **secret 扱い**。`.npmrc` は `.gitignore` 済み

## Prohibited Patterns

- NEVER add a dependency without checking the latest version first
- NEVER downgrade a package without explicit user approval
- NEVER use deprecated packages（`npm view <pkg> deprecated` で要確認）
- NEVER use packages with 0 maintainers or > 2 years no activity（リスク評価必須）
- NEVER pin via git URL / fork without ADR（保守責任が発生する）
- NEVER mix package managers（`npm` + `yarn` + `pnpm` 同居禁止）
- NEVER commit `node_modules`, `.venv`, vendored dependencies
- NEVER ignore lockfile changes — `package-lock.json` / `pnpm-lock.yaml` も commit
- NEVER commit `.npmrc` — Takumi Guard token (`tg_*`) を含むため secret 扱い (`.npmrc.example` のみ commit)
- NEVER hardcode `tg_*` トークンをコードや docs に書く — 必ず `.npmrc` 経由
