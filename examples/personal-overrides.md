# CLAUDE.local.md の例

このファイルは `CLAUDE.local.md` の **書き方の例** です。実際の `CLAUDE.local.md` は **gitignore 対象** で、個人のローカル設定として使ってください。

---

## 個人の好み

- 出力言語: 日本語優先（英語は技術用語のみ）
- 説明スタイル: 結論先出し、根拠は後
- コードコメント: 「なぜ」を1行のみ

## 個人ショートカット

- 「いつもの構成」= Next.js + Prisma + Tailwind + Vitest
- 「いつものスタイル」= Conventional Commits + 関数命名は動詞始まり

## 個人の禁止事項

- `console.log` のコミット禁止（PR 前に必ず除去）
- `any` 型の使用禁止（unknown を使う）
- 1ファイル 300 行を超えたら分割を検討

## 自分のローカル環境メモ

- Node version: 20.11.0
- パッケージマネージャ: pnpm
- IDE: Cursor (VS Code 拡張で Claude Code 連携)

## 進行中のタスクメモ

(ここに今気になってる課題などを書く)

- [ ] auth 周りのテストカバレッジが低い
- [ ] DB migration の運用ルールを決める

---

⚠️ このファイルは **gitignore 対象** です。チーム共有したいルールは `CLAUDE.md` または `docs/` に書いてください。
