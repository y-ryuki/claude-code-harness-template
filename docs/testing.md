# Testing — テスト戦略

このテンプレは **2層のテスト** を持ちます:

```
┌─────────────────────────────────────────────────┐
│ Layer 1: Hook Unit Tests (bats-core)            │
│   - .claude/hooks/*.sh, *.py の動作検証          │
│   - 危険コマンド検知、secret ブロック、injection等  │
├─────────────────────────────────────────────────┤
│ Layer 2: E2E Tests (Playwright)                 │
│   - ブラウザ操作の自動化                          │
│   - 動画録画 + スクショ + HTMLレポート             │
│   - PR コメントに結果自動投稿                     │
└─────────────────────────────────────────────────┘
```

---

## 🧪 Layer 1: Hook ユニットテスト

### フレームワーク: bats-core

[bats-core](https://github.com/bats-core/bats-core) は Bash テスティングフレームワーク。各 hook が「**何を許可・何をブロック**」するかをコードで明示する。

### テストファイル

```
tests/hooks/
├── test_block_dangerous.bats       # 危険コマンドブロッカー
├── test_block_secrets.bats         # secret ファイル保護
├── test_detect_secrets.bats        # secret 書き込み検知
└── test_injection_scanner.bats     # prompt injection 検知
```

### ローカル実行

#### bats のインストール

```bash
# macOS
brew install bats-core

# Linux (Ubuntu/Debian)
sudo apt install bats

# その他: https://bats-core.readthedocs.io/en/stable/installation.html
```

#### テスト実行

```bash
# 全 hook テスト
npm run test:hooks
# or
bats tests/hooks/

# 単一ファイル
bats tests/hooks/test_block_dangerous.bats

# 詳細出力
bats --verbose-run tests/hooks/

# TAP 形式
bats --tap tests/hooks/
```

### 期待される出力

```
✓ blocks: rm -rf /
✓ blocks: rm -rf ~
✓ blocks: curl pipe to bash
...
✓ allows: ls -la
✓ allows: git status
...

99 tests, 0 failures
```

### 新しいテストの追加

例: 新しい `block-dangerous` パターンを追加した場合、対応するテストも追加:

```bash
# tests/hooks/test_block_dangerous.bats

@test "blocks: my new pattern" {
    run run_hook "my dangerous command"
    assert_blocked
}
```

---

## 🎭 Layer 2: E2E テスト

### フレームワーク: Playwright

[Playwright](https://playwright.dev/) は Microsoft 製のブラウザ自動化テスト。**動画録画・スクショ・トレース** が標準機能。

### 構成

```
tests/e2e/
├── playwright.config.ts        # 設定（録画ON、HTMLレポート、JSON出力）
├── specs/
│   └── example.spec.ts         # サンプルテスト
├── fixtures/                   # テスト用フィクスチャ
├── playwright-report/          # HTMLレポート（gitignore）
├── test-results/               # 動画・スクショ・トレース（gitignore）
└── test-results.json           # 統計（PR コメントで使用）
```

### ローカル実行

#### 初回セットアップ

```bash
# 依存インストール
npm install

# Playwright ブラウザインストール
npm run playwright:install
# or
npx playwright install --with-deps chromium
```

#### テスト実行

```bash
# ヘッドレスで実行（CI と同じ）
npm run test:e2e

# ブラウザ可視で実行（デバッグ用）
npm run test:e2e:headed

# Playwright Inspector で1ステップずつ
npm run test:e2e:debug

# HTML レポートを開く
npm run test:e2e:report
```

### 録画とアーティファクト

| 種別 | 場所 | CI/ローカル |
|------|------|-----------|
| **動画 (.webm)** | `tests/e2e/test-results/<test>/video.webm` | CI: 全実行 / ローカル: 失敗時 |
| **スクショ (.png)** | `tests/e2e/test-results/<test>/test-failed-N.png` | 失敗時 + 明示 `page.screenshot()` |
| **トレース (.zip)** | `tests/e2e/test-results/<test>/trace.zip` | リトライ時 |
| **HTML レポート** | `tests/e2e/playwright-report/index.html` | 常時 |
| **JSON 統計** | `tests/e2e/test-results.json` | 常時 |

### 明示的にスクショを取る

PR コメントに貼りたい重要シーンは、テスト内で明示的に:

```typescript
await page.screenshot({
  path: 'test-results/01-login-form.png',
  fullPage: true,
});
```

### PR コメントの自動投稿

`.github/workflows/e2e.yml` が PR に以下のようなコメントを自動投稿:

```markdown
## 🎭 E2E Test Results

**Status**: ✅ Passed

| Metric | Count |
|--------|-------|
| ✅ Passed | 8 |
| ❌ Failed | 0 |
| ⏭ Skipped | 1 |
| ⚠️ Flaky | 0 |
| ⏱ Duration | 23.5s |

### 📹 Artifacts
- 🎬 [動画 & スクリーンショット](.../actions/runs/.../artifacts)
- 📊 [HTML Report](.../actions/runs/.../artifacts)
```

artifact から動画 (.webm) と HTML レポートを DL 可能。

### 動画を PR にインライン表示したい場合

GitHub PR コメントに動画ファイルを直接埋め込むことはできません（容量制限と仕様の問題）。
以下の代替案があります:

| 方法 | 手順 | 永続性 |
|------|------|-------|
| **GitHub Issue/PR 直接アップ** | コメント編集で動画ファイルをドラッグ&ドロップ（10MB制限） | ✅ |
| **GitHub Pages** | `e2e.yml` を拡張して GitHub Pages にデプロイ | ✅ |
| **artifact ダウンロード** | 現在の実装。リンクをコメントに貼る | 14日間 |
| **外部ストレージ** | S3 / R2 / Vercel Blob にアップ | 設定次第 |

現在のテンプレは **artifact 方式**（最もシンプルで権限も最小）。永続化が必要なら GitHub Pages か外部ストレージを追加してください。

### 動画ファイルが大きい場合

Playwright デフォルトは VP8 (.webm)。1分のテストで 1-5MB 程度。
さらに小さくしたい場合は `playwright.config.ts` で:

```typescript
use: {
  video: {
    mode: 'on',
    size: { width: 1280, height: 720 },  // デフォルト 1280x720
  },
}
```

---

## 🚦 CI 統合

### `.github/workflows/test-hooks.yml`

- トリガー: `.claude/hooks/**`, `tests/hooks/**`, `.claude/settings.json` の変更時
- 内容:
  1. bats-core セットアップ
  2. jq + python3 インストール
  3. hooks に実行権限付与
  4. `bats tests/hooks/` 実行
  5. `validate-settings.sh` 実行
  6. `audit.sh` 実行

### `.github/workflows/e2e.yml`

- トリガー: 全 push / pull_request / 手動
- 内容:
  1. Node 20 セットアップ
  2. `npm ci` / `npm install`
  3. Playwright ブラウザインストール
  4. `playwright test` 実行（失敗してもジョブ継続）
  5. レポート + 動画を artifact として保存（14日）
  6. JSON 統計をパース
  7. PR コメントに結果投稿（既存コメントがあれば更新）
  8. テストが失敗してたらジョブも失敗化

### Branch Protection で必須化

```bash
gh api -X PUT "/repos/{owner}/{repo}/branches/main/protection" --input - <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["bats-tests", "e2e"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 1 }
}
EOF
```

---

## 🛠️ テストカバレッジを測りたい

bash のカバレッジは [kcov](https://github.com/SimonKagstrom/kcov) で取れる:

```bash
kcov --include-pattern=.claude/hooks coverage tests/hooks/
```

ただし、本テンプレは bats でカバレッジ計測は同梱していません。必要なら `kcov` を追加してください。

Playwright のコードカバレッジは [Playwright coverage API](https://playwright.dev/docs/api/class-coverage) で取得可能（テスト対象のアプリ側で計装が必要）。

---

## 🆘 トラブルシューティング

### bats が見つからない

```bash
brew install bats-core    # macOS
apt install bats          # Debian/Ubuntu
```

### Playwright が起動しない

```bash
# ブラウザ未インストール
npx playwright install --with-deps chromium

# 依存ライブラリ不足（Linux）
sudo npx playwright install-deps
```

### CI で動画が録画されない

`playwright.config.ts` の `video` 設定が `'on'` になっているか確認:
```typescript
video: process.env.CI ? 'on' : 'retain-on-failure',
```

### PR コメントが投稿されない

- `permissions: pull-requests: write` が workflow にあるか確認
- `GITHUB_TOKEN` の権限（リポジトリ設定 → Actions → General → Workflow permissions）

---

## 📚 参考

- [bats-core ドキュメント](https://bats-core.readthedocs.io/)
- [Playwright Docs](https://playwright.dev/)
- [Playwright Best Practices](https://playwright.dev/docs/best-practices)
- [GitHub Actions: actions/github-script](https://github.com/actions/github-script)
