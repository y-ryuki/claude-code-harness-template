# Security — セキュリティ設計

このテンプレは**ガードレール硬め**の方針で組まれています。本ドキュメントはその設計詳細と、ユーザーが理解すべきトレードオフを説明します。

## 🛡️ 3層防御モデル

```
┌────────────────────────────────────────────────┐
│ Layer 1: Permissions (allow/deny)              │  ← 静的ルール
├────────────────────────────────────────────────┤
│ Layer 2: PreToolUse / PostToolUse Hooks        │  ← 動的チェック
├────────────────────────────────────────────────┤
│ Layer 3: Native Sandbox / DevContainer         │  ← OS レベル隔離
└────────────────────────────────────────────────┘
```

各層は **独立して機能** し、1層が失敗しても他層で食い止める設計です。

---

## 🚨 想定脅威（Threat Model）

| 攻撃ベクタ | 経路 | 被害 | 防御層 |
|-----------|------|------|--------|
| Prompt Injection（直接） | 悪意あるユーザー入力 | 任意コマンド実行 | L1, L2 |
| Prompt Injection（間接） | WebFetch / MCP / README / Issue | データ流出、バックドア設置 | L2 (PostToolUse injection-scanner) |
| Secret Leakage | `.env` 自動読み込み → transcript 汚染 | APIキー漏洩 | L1 deny + L2 block-secrets |
| 危険コマンド実行 | `rm -rf ~`, `curl|bash`, fork bomb | データ消失・マルウェア注入 | L1 deny + L2 block-dangerous + L3 sandbox |
| 悪意ある MCP | 改ざん済みツール定義 | 任意コード実行 | L1 (`enableAllProjectMcpServers: false`) |
| Supply Chain | npm 依存関係のインストールスクリプト | ホスト侵害 | L3 DevContainer + Dependabot |
| Path Traversal (CVE-2025-54794) | `/tmp/allowed_dir_malicious` | 制限外ファイルアクセス | Claude Code 本体 v1.0.20+ で修正済み |
| Command Injection (CVE-2025-54795) | `echo "\"; <MALICIOUS>; echo \""` | 確認プロンプト回避 | Claude Code 本体 v1.0.20+ で修正済み |

---

## Layer 1: Permissions

### 設定ファイル

[`.claude/settings.json`](../.claude/settings.json) の `permissions` セクション。

### デフォルト方針

- `defaultMode`: `"default"`（最初のツール使用時に確認）
- `disableBypassPermissionsMode`: `"disable"` （`--dangerously-skip-permissions` 無効化）
- **allow リスト**: 必要十分な許可（git の読み取り系、npm/pnpm test/lint/build、ls/cat/grep、gh の読み取り系）
- **deny リスト**: 危険コマンド + secret ファイル

### 重要な注意

⚠️ **`deny` ルールには Claude Code 本体側の機能不全バグが過去複数回報告されています**（[Issue #6699](https://github.com/anthropics/claude-code/issues/6699) 等）。本テンプレは **Layer 2 の PreToolUse hook と二重防御** することで mitigate しています。`deny` ルール **単体に依存しないこと**。

### Web 系はデフォルト deny

`WebFetch`, `WebSearch` はデフォルトで使えません。`/deep-research` などで必要なときだけ session で確認する設計。

---

## Layer 2: Hooks

### PreToolUse: 危険コマンドブロック

[`.claude/hooks/block-dangerous.sh`](../.claude/hooks/block-dangerous.sh)

matcher: `Bash`

ブロック対象:

| カテゴリ | パターン | 重大度 |
|---------|---------|--------|
| 破壊系 | `rm -rf /`, `rm -rf ~`, `rm -rf *`, `rm -rf $HOME` | Critical |
| Pipe to shell | `curl ... \| sh`, `wget ... \| bash` | Critical |
| Fork bomb | `:(){:|:&};:` 等 | Critical |
| ディスク破壊 | `dd if=/dev/`, `mkfs`, `fdisk`, `parted` | Critical |
| 強制 push | `git push --force`, `-f` | High |
| 検証スキップ | `git push --no-verify`, `git commit --no-verify` | High |
| 強制 reset | `git reset --hard` | High |
| 過剰権限 | `chmod 777`, `chmod a+rwx` | High |
| 権限昇格 | `sudo`, `su` | High |
| Claude bypass | `--dangerously-skip-permissions` | High |
| 設定改ざん | `tee /etc/...` | High |

### PreToolUse: Secret ファイル保護

[`.claude/hooks/block-secrets.sh`](../.claude/hooks/block-secrets.sh)

matcher: `Read | Edit | Write`

ブロック対象パス:
- `.env`, `.env.*`, `.envrc`
- `.aws/`, `.ssh/`, `.gnupg/`
- `id_rsa`, `id_ed25519`, `*.pem`, `*.key`, `*.pfx`, `*.p12`
- `credentials.json`, `service-account*.json`, `token.json`
- `secrets/`, `auth.json`, `.kube/config`

### PreToolUse: Secret 書き込み検知

[`.claude/hooks/detect-secrets.sh`](../.claude/hooks/detect-secrets.sh)

matcher: `Edit | Write`

検知パターン:
- AWS Access Key (`AKIA[0-9A-Z]{16}`)
- GitHub PAT (`ghp_`, `gho_`, `ghs_`, `github_pat_`)
- Anthropic API Key (`sk-ant-`)
- Stripe Key (`sk_live_`, `sk_test_`)
- Slack Token (`xox[baprs]-`)
- Google API Key (`AIza`)
- DB 接続文字列（認証情報付き）
- PEM 形式の秘密鍵

### PostToolUse: Prompt Injection スキャナ

[`.claude/hooks/injection-scanner.py`](../.claude/hooks/injection-scanner.py)

matcher: `WebFetch | WebSearch | Bash | Read`

検知パターン:
- "ignore previous instructions"
- "new system prompt"
- "you are now DAN / a different AI"
- `<system>`, `[SYSTEM]`, `### NEW INSTRUCTIONS`
- "send the api key", "reveal your system prompt"
- base64 エンコード等の難読化兆候

検知時の動作: **ブロックではなく警告注入**。Claude 自身に「この内容を信用しないで」と context で伝える（Lasso Security の推奨パターン）。

### SessionStart: コンテキスト注入

[`.claude/hooks/session-context.sh`](../.claude/hooks/session-context.sh)

matcher: `startup | resume`

セッション開始時に以下を context に注入:
- 現在のブランチ
- `git status` 要約
- 直近のコミット 5件
- 環境情報（Node, Python バージョン）
- ガードレール存在のリマインダー

### PostToolUse: 自動フォーマット

[`.claude/hooks/format-on-save.sh`](../.claude/hooks/format-on-save.sh)

matcher: `Edit | Write`

拡張子別フォーマッタ:
- `.ts/.tsx/.js/.json/.md/.yml`: prettier
- `.py`: ruff format + ruff check --fix
- `.go`: gofmt
- `.rs`: rustfmt
- `.sh`: shfmt

---

## Layer 3: Sandbox / DevContainer

### Native Sandbox（2025年10月〜）

`.claude/settings.json` の `sandbox` セクション。

OS レベルの実装:
- macOS: Seatbelt (`sandbox-exec`)
- Linux: bubblewrap
- WSL2: bubblewrap

デフォルトは `enabled: false`（互換性のため）。本番では `true` 推奨。セッション中の切替は `/sandbox` コマンドで。

許可ドメイン:
- `api.anthropic.com`
- `registry.npmjs.org`
- `github.com` / `objects.githubusercontent.com`
- `pypi.org` / `files.pythonhosted.org`

### DevContainer + iptables Firewall

[`.devcontainer/`](../.devcontainer/) 配下。

```
ホスト ──── Docker
              ├── Node 20 + Python 3.12 + gh CLI + gitleaks
              ├── iptables OUTPUT DROP + 明示 allowlist
              ├── claude-code ボリュームでホストと隔離
              └── ~/.ssh, ~/.aws は bind mount しない
```

`init-firewall.sh` でデフォルト DROP + 明示 allowlist パターン。GitHub の IP レンジは meta API から動的取得。

#### ⚠️ DevContainer の限界

- **TLS インスペクションなし**: ドメインフロンティング攻撃で allowlist を回避される可能性
- **`--dangerously-skip-permissions`** をコンテナ内で使うと、コンテナ内認証情報が悪意あるプロジェクトに流出する可能性 → 使用禁止（hook でブロック済み）
- **`/var/run/docker.sock` の bind mount は厳禁**（ホスト侵害につながる）

---

## 🔐 Managed Settings（Enterprise）

Team / Enterprise プランでは組織レベルで強制可能:

```json
// /etc/claude-code/managed-settings.json (Linux)
// ~/Library/Application Support/ClaudeCode/managed-settings.json (macOS)
{
  "permissions": {
    "disableBypassPermissionsMode": "disable",
    "deny": ["WebSearch", "WebFetch"]
  },
  "allowManagedPermissionRulesOnly": true,
  "allowManagedHooksOnly": true,
  "strictKnownMarketplaces": []
}
```

`allowManagedPermissionRulesOnly: true` で **ユーザー設定が完全に無視され、組織ルールのみ適用** されます。

サンプル: [`examples/strict-managed-settings.json`](../examples/strict-managed-settings.json)

---

## 🔍 監査スクリプト

[`scripts/audit.sh`](../scripts/audit.sh) で 15 項目のスコアリング:

```
✅/❌  項目                                       重要度
✅    settings.json: disableBypassPermissionsMode  Critical
✅    PreToolUse: block-dangerous.sh 設定          Critical
✅    PreToolUse: block-secrets.sh 設定            Critical
✅    .env が .gitignore に含まれる                 Critical
...
合計スコア: 14/15 (9.3/10)
```

セキュリティ必須要素（Critical 項目）が不足している場合、スコア上限は 6.0/10 になります（dotforge 流）。

---

## 🚨 既知の制約

### 1. regex blocklist の限界

`python -c "import os; os.system('rm -rf /')"` のようなインタープリター経由は、コマンドラインの regex では検知できません。

**対策**: Sandbox / DevContainer の OS レベル制限を併用。

### 2. Prompt Injection は未解決問題

Anthropic 公式が「far from solved」と認めています。`injection-scanner.py` は警告にとどまり、完全防御は不可能。

**対策**: 信頼境界の意識（WebFetch 結果 / MCP 出力 / 外部 Issue は不信頼）。

### 3. `.env` 自動読み込み

Claude Code は dotenv 経由で `.env` を**ユーザー明示なしに**読み込みます。本テンプレは deny + hook で二重ブロックしていますが、CLI 本体が修正されない限り根本解決にはなりません。

**対策**: 最新版を使う（修正済みの可能性）+ シークレットを `.env` に置かず CI/CD の Secret 管理に置く。

### 4. MCP サーバーの信頼性

外部の MCP サーバーは任意コードを実行できます。`.mcp.json` で読み込む MCP は **信頼できるソースのみ** にしてください。

**対策**: `enableAllProjectMcpServers: false`（明示的に許可した MCP のみ） + Plugin Marketplace の信頼できるサーバーのみ使用。

---

## 🛠️ カスタマイズ

### ローカルで一時的に許可

`.claude/settings.local.json`（gitignore 対象）に追加:

```json
{
  "permissions": {
    "allow": ["Bash(docker compose up *)"]
  }
}
```

### Hook を無効化（非推奨）

ハードル高めに設計。本当に必要なら `.claude/settings.local.json` で:

```json
{
  "hooks": {
    "PreToolUse": []
  }
}
```

ただし、これは **テンプレの設計意図に反する行為** です。代わりに該当する allow を追加することを推奨。

---

## 📚 参考資料

- [Anthropic Claude Code Security docs](https://code.claude.com/docs/en/security)
- [claude-code-action security.md](https://github.com/anthropics/claude-code-action/blob/main/docs/security.md)
- [Lasso Security: Hidden Backdoor](https://www.lasso.security/blog/the-hidden-backdoor-in-claude-coding-assistant)
- [knostic.ai: .env leakage](https://www.knostic.ai/blog/claude-code-automatically-loads-env-secrets-without-telling-you)
- [CVE-2025-54794](https://nvd.nist.gov/vuln/detail/CVE-2025-54794)
- [CVE-2025-54795](https://nvd.nist.gov/vuln/detail/CVE-2025-54795)
