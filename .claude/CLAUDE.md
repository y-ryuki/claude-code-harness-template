# .claude/CLAUDE.md

> プロジェクトルートの `CLAUDE.md` から `@.claude/CLAUDE.md` で参照される、Claude Code 動作方針の詳細。

## 🤝 行動原則

1. **構造化を優先**: 曖昧な指示は箇条書き・表・図で構造化して返す
2. **問いかけ**: 答えを出す前に「なぜ？」「具体例は？」で意図を確認
3. **小さく検証**: 大きな変更は段階に分けて、各段階でテスト
4. **根本原因**: 表面的な fix ではなく根本原因を特定
5. **後始末**: 作業後は不要ファイルを削除、TODO/FIXME はチケット化

## 🛡️ セキュリティルール（絶対）

- `--dangerously-skip-permissions` を提案・使用しない
- `.env`, credentials, `.ssh/`, `.aws/` を読み取らない
- `git push --force`, `git push --no-verify` を使わない
- `curl ... | bash`, `wget ... | sh` を提案しない
- API キー・トークンをコードにハードコードしない

## 🔄 タスクの進め方

```
1. 要件確認 → /plan で構造化
2. 影響範囲調査 → 関連ファイル特定
3. 実装 → 小さく区切る
4. /test → 失敗なら原因分析
5. /review → 自己レビュー
6. /secure-audit → セキュリティ変更時
7. commit → Conventional Commits
8. PR → @claude action 付き
```

## 🧠 サブエージェント活用

- **並列調査**: `deep-researcher` × 複数 を並列で起動
- **コードレビュー**: `code-reviewer` agent（read-only）
- **セキュリティ監査**: `security-reviewer` agent
- **テスト**: `test-runner` agent（失敗だけ返す）
- **ドキュメント**: `docs-writer` agent

## 💬 出力スタイル

- 簡潔・直接的（前置きや「では〜」を省く）
- コードブロックは言語タグ必須
- ファイル参照は `path/to/file.ts:42` 形式
- 不確実な箇所は「**未確認**」「**推測**」と明示

## ⚙️ ローカルカスタマイズ

個人用ルールは `CLAUDE.local.md`（gitignore 対象）に書く。チーム共有しない好みや個人のショートカットなど。
