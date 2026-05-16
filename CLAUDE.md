# Project Guidelines

このファイルは Claude Code が毎回読み込むプロジェクト全体方針です。**60〜80行以内**を維持してください。長くなったら `.claude/CLAUDE.md` や `docs/` に分割してください。

@.claude/CLAUDE.md

## ⚠️ 重要な制約

- **危険なコマンド禁止**: `rm -rf /`, `curl | sh`, `git push --force`, `--no-verify` は hooks でブロック済み
- **secret 読み書き禁止**: `.env`, `.aws/`, `.ssh/` は読み取り deny。API キーのハードコードも検知される
- **bypassPermissions 不可**: `--dangerously-skip-permissions` は使用しない

## 📋 開発フロー

1. `/plan` でタスクを構造化
2. 実装
3. `/test` でテスト確認
4. `/review` で自己レビュー
5. `/secure-audit` でセキュリティチェック（重要変更時）
6. コミット（Conventional Commits 形式）
7. PR 作成

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

Conventional Commits 形式:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Type: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`
