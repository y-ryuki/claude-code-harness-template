---
description: Smoke testing rules — localhost-only, secret masking, dev server cleanup guarantee.
alwaysApply: true
---

# Smoke Testing

実装直後の動作確認は `/smoke` または `autopilot` の Step 6.5 で自動実行される。

## 実行範囲

| 変更分類 | 実行 |
|---|---|
| UI | `scripts/smoke-ui.sh` (Playwright `--grep @smoke`) |
| Backend | `scripts/smoke-api.sh` (`tests/smoke/api.json` を curl) |
| Both | 両方 |
| その他 | スキップ |

判定は `scripts/detect-change-scope.sh` が `git diff` から自動で行う。

## Security NEVERs

- NEVER smoke against URLs other than `localhost` / `127.0.0.1` — `smoke-api.sh` がブロック (exit 2)
- NEVER log full response bodies — `MAX_BODY_LINES=20` で truncate
- NEVER include real credentials in `tests/smoke/api.json` — テスト用ダミーのみ
- NEVER skip secret masking — `Bearer` / `sk-*` / `AKIA*` / `gh[pousr]_*` / `api_key` / `password` / `token` / JWT / Slack `xox*-*` は自動 mask
- NEVER leave dev server running — `trap` で TERM → 3秒待ち → KILL を保証
- NEVER bypass port-in-use check — 既存プロセスを絶対に kill しない (孤児プロセス誤殺防止)
- NEVER eval `SMOKE_DEV_CMD` — `read -ra DEV_ARGS <<<` で space split
- NEVER allow non-allowlisted HTTP methods — GET/HEAD/POST/PUT/PATCH/DELETE/OPTIONS のみ
- NEVER allow ports outside 1-65535 — 整数バリデーション必須
- NEVER follow redirects in smoke curl — `--proto '=http,https'` でスキーム固定、keep-alive 無効

## Process NEVERs

- NEVER commit `.smoke-results/` — `.gitignore` 済み
- NEVER paste raw response body into PR body — 必ず mask フィルタを通す
- NEVER block PR creation on smoke failure — 結果を PR に貼って人間判断
- NEVER hardcode the dev server port in tests — 環境変数 `SMOKE_PORT` 経由
- NEVER run smoke in CI without explicit timeout — ハング検知必須

## 運用

- 結果は `.smoke-results/api.md` / `.smoke-results/ui.md` に保存
- autopilot が PR body の「動作確認」セクションに `<details>` で折り畳んで転記
- smoke 失敗時も PR 作成は **継続** し、PR に "❌ smoke failed" を明示
- レビュアーは smoke 結果を必ず確認

## 環境変数

| 名前 | デフォルト | 検証 |
|---|---|---|
| `SMOKE_PORT` | `3000` | 整数 1-65535 |
| `SMOKE_DEV_CMD` | `npm run dev` | space split、第1 token は `command -v` で存在確認 |
| `SMOKE_TIMEOUT` | `120` | UI smoke 全体タイムアウト (秒) |
