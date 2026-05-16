<!-- AGENTS.md: auto-synced from CLAUDE.md by .claude/hooks/sync-agents-md.sh -->
<!-- このファイルは Codex CLI 互換性のため CLAUDE.md と同期されています。直接編集せず、CLAUDE.md を編集してください。-->

# Project Guidelines

このファイルは Claude Code が毎回読み込むプロジェクト全体方針です。**60〜80行以内**を維持してください。長くなったら `.claude/CLAUDE.md` や `docs/` に分割してください。

@.claude/CLAUDE.md

## ⚠️ 重要な制約

- **危険なコマンド禁止**: `rm -rf /`, `curl | sh`, `git push --force`, `--no-verify` は hooks でブロック済み
- **secret 読み書き禁止**: `.env`, `.aws/`, `.ssh/` は読み取り deny。API キーのハードコードも検知される
- **bypassPermissions 不可**: `--dangerously-skip-permissions` は使用しない
- **🚫 Merge 禁止 (AI専用ルール)**: `gh pr merge`, `git merge`, main/master への直 push は **AI 専用で禁止**。Merge は **人間が GitHub UI で実行** すること。

## 📋 開発フロー (DocDD)

1. Issue 起票 → 必要なら `/requirements` で要件定義
2. 技術選定が要れば `/adr "<title>"` で ADR 起票
3. `/spec <issue#>` で機能仕様
4. `/plan` でタスク構造化（or `/autopilot <issue#>` で一気通貫）
5. 実装
6. `/test` でテスト確認
7. `/review-multi` で 7観点並列レビュー
8. コミット（Conventional Commits 形式）
9. PR 作成
10. ⚠️ Merge は **人間** が行う

## 🎨 コードスタイル

- 命名は **意図が伝わる名前** を優先（`tmp`, `data`, `flag` 等の汎用名NG）
- マジックナンバーは定数化
- エラーは早期 return で扱う
- コメントは「**なぜ**」を書く（「**何を**」はコードが語る）

## 🧪 テスト方針

- **失敗するテストを先に書く** (TDD)
- ユニットテスト > 統合テスト > E2E の比率を維持
- フレーキーテストは即修正 or skip+Issue化

## 📝 コミット規則

詳細: [`docs/naming-conventions.md`](docs/naming-conventions.md)

Conventional Commits 形式:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Type: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`

## 📚 参照ドキュメント

意思決定の根拠は以下を参照（推測しない）:

- 重要な技術選定 → [`docs/decisions/`](docs/decisions/)
- 機能仕様 → [`docs/specs/<issue#>-*.md`](docs/specs/)
- システム構造 → [`docs/architecture/`](docs/architecture/)
- 要件定義 → [`docs/requirements/`](docs/requirements/)
- 命名規約 → [`docs/naming-conventions.md`](docs/naming-conventions.md)
- DocDD フロー → [`docs/workflows/docdd.md`](docs/workflows/docdd.md)
