# Smoke Tests

`autopilot` (Step 6.5) と `/smoke` slash command が使う、実装直後の最小限の動作確認テスト群。

## 構成

| ファイル | 役割 |
|---|---|
| `api.json` | API スモーク定義（HTTP メソッド・パス・期待ステータス） |
| `../e2e/specs/*.smoke.spec.ts` | UI スモーク Playwright テスト（`@smoke` タグ付き） |
| `../../scripts/smoke-api.sh` | API runner (**localhost 限定**) |
| `../../scripts/smoke-ui.sh` | UI runner (dev server 起動 + Playwright) |
| `../../scripts/detect-change-scope.sh` | git diff から UI / Backend / Both / Other を判定 |

## セキュリティ・安全面

- **baseUrl は `localhost` / `127.0.0.1` のみ許可** — `smoke-api.sh` が起動時に検証 (違反は exit 2)
- **シークレット自動 mask** — Bearer / sk-* / AKIA* / gh[pousr]_* / `api_key` / `password` / `token` / JWT / Slack `xox*-*`
- **dev server cleanup 保証** — `trap` で TERM → 3秒待ち → KILL
- **既存ポート使用中なら abort** — 孤児プロセスを誤って kill しない
- **timeout 必須** — API=10s/req、UI=120s 全体
- **redirect 追従無効** — `curl --proto '=http,https' --no-keepalive`
- **method ホワイトリスト** — GET/HEAD/POST/PUT/PATCH/DELETE/OPTIONS のみ許可
- **`DEV_CMD` は eval せず space split** — `read -ra DEV_ARGS <<<` (コマンドインジェクション防止)
- **port 入力は整数のみ** — 1-65535 範囲外は exit 2
- **レスポンス body は最大 20 行で truncate** — ログ肥大 / 機密漏洩防止

## 使い方

```bash
# 手動
bash scripts/smoke-api.sh                  # tests/smoke/api.json を実行
bash scripts/smoke-ui.sh                    # @smoke タグの Playwright を実行

# slash command (推奨)
/smoke           # auto-detect
/smoke ui
/smoke api
/smoke all
```

## 環境変数

| 名前 | デフォルト | 説明 |
|---|---|---|
| `SMOKE_PORT` | `3000` | dev server のポート (1-65535) |
| `SMOKE_DEV_CMD` | `npm run dev` | dev server 起動コマンド (space split される) |
| `SMOKE_TIMEOUT` | `120` | UI smoke 全体タイムアウト (秒) |

## 結果

`.smoke-results/` に markdown で保存（`.gitignore` 済み）：

- `api.md` — API smoke の結果テーブル + 失敗詳細
- `ui.md` — UI smoke の Pass/Fail 集計
- `dev-server.log` — dev server の出力ログ (失敗時の debug 用)
- `playwright.log` — Playwright の出力ログ

`autopilot` が PR body の「動作確認」セクションに `<details>` で折り畳んで転記する。

## API smoke の書き方

`api.json` の `requests[]` に追加：

```json
{
  "name": "create user",
  "method": "POST",
  "path": "/api/users",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"name\":\"smoke-test\",\"email\":\"smoke@test.local\"}",
  "expectStatus": 201
}
```

⚠️ **`body` に実際のシークレットを書かないこと**。テスト用ダミーのみ。

## UI smoke の書き方

`tests/e2e/specs/` 配下に `*.smoke.spec.ts` を作り、テスト名に `@smoke` タグを含める：

```typescript
test('home loads @smoke', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/.+/);
});
```

`scripts/smoke-ui.sh` が `--grep @smoke` でフィルタ実行する。
