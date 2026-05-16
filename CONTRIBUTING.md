# Contributing

このテンプレを改善するためのコントリビューションを歓迎します。

## 🚀 始め方

1. このリポを Fork
2. ブランチを切る: `git checkout -b feat/your-feature`
3. 変更を実装
4. テスト: `./scripts/audit.sh` で監査スコアを確認
5. コミット: Conventional Commits 形式
6. Push → PR 作成

## 📝 コミット規則

Conventional Commits 形式を厳守:

```
<type>(<scope>): <subject>
```

| Type | 用途 |
|------|------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `docs` | ドキュメントのみ |
| `refactor` | 動作変更なしのリファクタ |
| `test` | テスト追加・修正 |
| `chore` | ビルド設定・依存更新 |
| `perf` | パフォーマンス改善 |
| `ci` | CI 設定変更 |

例:
```
feat(hooks): add fork-bomb detection to block-dangerous.sh
fix(settings): allow Bash(npm test *) glob
docs(mobile): update Claude Code Web limitations
```

## 🔍 PR の要件

- [ ] `./scripts/audit.sh` が通る
- [ ] `gitleaks detect` が通る
- [ ] フック追加なら `docs/hooks-reference.md` も更新
- [ ] 新規エージェント/コマンド追加なら README にも追記
- [ ] BREAKING CHANGE は `BREAKING CHANGE:` フッターで明示

## 🧪 ローカル検証

```bash
# 設定検証
./scripts/validate-settings.sh

# 監査スコア確認
./scripts/audit.sh

# シークレットスキャン
gitleaks detect --source . --no-git
```

## 🐛 バグ報告

Issue テンプレートに従って報告してください。**セキュリティ脆弱性は [`SECURITY.md`](SECURITY.md) のフロー** で報告してください。

## 💡 機能提案

Feature Request テンプレートに従って提案してください。「いいとこ取り」の対象になる外部リポがあれば、リンクも添えてください。

## 📜 ライセンス

コントリビュートする内容は MIT ライセンスの下で公開されることに同意したものとみなされます。
