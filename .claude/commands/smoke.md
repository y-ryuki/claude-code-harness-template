---
name: smoke
description: 変更スコープを検出し、UI なら E2E (@smoke)、Backend なら API curl を localhost で実行して .smoke-results/ に結果を出す。セキュリティ最優先（localhost 限定 / API結果の本文非掲載 / dev server cleanup 保証）。
argument-hint: "[ui|api|all|auto]  (省略時は auto)"
allowed-tools: Read, Glob, Grep, Bash(bash scripts/smoke-ui.sh), Bash(bash scripts/smoke-ui.sh *), Bash(bash scripts/smoke-api.sh), Bash(bash scripts/smoke-api.sh *), Bash(bash scripts/detect-change-scope.sh), Bash(bash scripts/detect-change-scope.sh *), Bash(cat .smoke-results/*)
---

# /smoke: 動作確認

scope: ${1:-auto}

## 手順

1. **スコープ判定**
   - `${1:-auto}` が `auto` → `bash scripts/detect-change-scope.sh` で判定 (`ui` / `backend` / `both` / `other`)
   - 明示指定 (`ui` / `api` / `all`) → そのまま使う

2. **実行**
   | 判定 | 実行コマンド |
   |---|---|
   | `ui` | `bash scripts/smoke-ui.sh` |
   | `backend` / `api` | `bash scripts/smoke-api.sh` |
   | `both` / `all` | 両方 (UI → API の順) |
   | `other` | skip して終了 |

3. **結果表示**
   - `cat .smoke-results/api.md` (該当時)
   - `cat .smoke-results/ui.md` (該当時)

## セキュリティ・安全面（実装側で保証済み）

- **localhost 限定**: 全リクエストの最終URLをPythonで事前検証。不正設定は通信前に exit 2。curl設定・proxy・redirectは無効
- **API結果の公開範囲**: ステータスと成功/失敗のみ。応答本文・ヘッダー・curlエラー・リクエストの任意文字列は保存/表示しない
- **dev server cleanup**: `trap EXIT INT TERM HUP` で必ず TERM → KILL
- **既存プロセス保護**: ポート使用中なら **絶対に kill せず** abort
- **timeout**: API=10s/req、UI=120s 全体
- **method allowlist**: GET/HEAD/POST/PUT/PATCH/DELETE/OPTIONS のみ
- **`DEV_CMD` は eval せず** space split で配列化（コマンドインジェクション防止）
- **port は整数 1-65535** のみ

## 失敗時

- smoke が失敗しても **PR 作成 / 後続処理は止めない**。結果を `.smoke-results/` に残し、autopilot が PR body に「❌ smoke failed」を明示する
- 人間レビュアーが最終判断

## 結果ファイル

| ファイル | 内容 |
|---|---|
| `.smoke-results/api.md` | API smoke のHTTPステータスと成功/失敗（本文非掲載） |
| `.smoke-results/ui.md` | UI smoke 結果サマリ |
| `.smoke-results/dev-server.log` | dev server の出力（debug 用） |
| `.smoke-results/playwright.log` | Playwright の出力 |

すべて `.gitignore` 済み（コミットされない）。
