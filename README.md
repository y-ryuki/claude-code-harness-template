# Claude Code Harness Template

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-blueviolet)](https://code.claude.com)
[![GitHub Template](https://img.shields.io/badge/GitHub-Template-2ea44f?logo=github)](https://github.com/new?template_name=claude-code-harness-template)

> **ガードレール硬め・セキュリティ最優先**で組まれた、Claude Code 用のハーネステンプレ。スマホ（Claude Code Web）からの開発フローもサポート。

Anthropic 公式ドキュメント・人気12リポ（claude-flow, claude-code-action, davila7/templates, SuperClaude, dotforge, scotthavird/template ほか）から得た知見をいいとこ取りで再構成。

---

## ✨ 特徴

| 領域 | 内容 |
|------|------|
| **🛡️ セキュリティ** | Permissions + PreToolUse Hooks + Native Sandbox の **3層防御**。`.env` 自動読み込み・危険コマンド・Prompt Injection を多層ブロック |
| **🤖 エージェント** | code-reviewer / security-reviewer / test-runner / deep-researcher など 6種の専門エージェントを同梱 |
| **⚡ コマンド** | `/plan` `/review` `/test` `/secure-audit` `/deep-research` の5基本コマンド |
| **📦 スキル** | `pr-summary` `commit-helper` `changelog-update` の動的注入スキル |
| **📱 スマホ開発** | Claude Code Web + `@claude` GitHub Action でスマホから Issue → PR の完結 |
| **🐳 DevContainer** | Node 20 + Python 3.12 + iptables ファイアウォール隔離 |
| **🧪 テスト** | bats-core で hooks ユニットテスト + Playwright で E2E（動画録画 + PR コメント自動投稿） |
| **🚀 CI/CD** | release-please による自動 semver / gitleaks シークレットスキャン / Dependabot |

---

## 🚀 Quick Start

### 方法1: GitHub Template から作成（推奨）

1. **このリポの「[Use this template](https://github.com/new?template_name=claude-code-harness-template)」**をクリック
2. 新規リポジトリ名を入力 → Create repository
3. ローカルに clone
4. セットアップスクリプト実行:
   ```bash
   cd <your-new-repo>
   ./scripts/setup.sh
   ```
5. Claude Code を起動:
   ```bash
   claude
   ```

### 方法2: 既存プロジェクトに導入

```bash
# 既存プロジェクトのルートで実行
curl -fsSL https://raw.githubusercontent.com/y-ryuki/claude-code-harness-template/main/scripts/install.sh | bash
```

### 方法3: 手動セットアップ

```bash
git clone https://github.com/y-ryuki/claude-code-harness-template.git my-project
cd my-project
rm -rf .git && git init
./scripts/setup.sh
```

---

## 📖 詳細な使い方

### 1️⃣ 初回セットアップ

#### Step 1.1: 依存ツールの確認

| ツール | 必須/推奨 | 用途 |
|--------|----------|------|
| Claude Code CLI | 必須 | 本テンプレの実行基盤（[インストール](https://code.claude.com/docs/en/quickstart)） |
| `gh` (GitHub CLI) | 推奨 | PR/Issue 操作 |
| `jq` | 必須 | フック内でJSON処理 |
| `gitleaks` | 推奨 | シークレットスキャン |
| Docker | 任意 | DevContainer 利用時 |

#### Step 1.2: API キー設定

ローカル CLI 用:
```bash
# 永続化したい場合のみ。Claude Code Web を主軸にする場合は不要
export ANTHROPIC_API_KEY="sk-ant-..."
```

GitHub Action 用:
```bash
gh secret set ANTHROPIC_API_KEY -b "sk-ant-..."
```

#### Step 1.3: setup.sh 実行

```bash
./scripts/setup.sh
```

実行内容:
- フックスクリプトに実行権限を付与
- `.gitignore` 確認・補強
- `gitleaks` の存在確認
- `settings.local.json` の雛形コピー（gitignore 対象）
- Git pre-commit hook の有効化

---

### 2️⃣ デスクトップでの日常的な使い方

#### `claude` でセッション開始

```bash
cd my-project
claude
```

`SessionStart` フックが自動実行され、以下がコンテキストに注入されます:
- 現在のブランチ
- `git status` の要約
- ステージング済みの変更
- 直近のコミット 5件

#### 基本コマンド

| コマンド | 用途 | 例 |
|---------|------|-----|
| `/plan` | 実装計画を立てる | `/plan ダークモード追加` |
| `/review` | コードレビュー | `/review` （現在の diff を対象） |
| `/test` | テスト実行 + 失敗分析 | `/test` |
| `/secure-audit` | セキュリティ監査 | `/secure-audit src/auth/` |
| `/deep-research` | Web 反復探索 | `/deep-research OAuth2のPKCEフロー` |

#### 専門エージェントの使い方

サブエージェントは Claude が自動的に判断して呼び出します。明示的に呼ぶ場合:

```
このPRをsecurity-reviewerでチェックして
```

```
test-runnerでテスト全部走らせて、失敗してるところだけまとめて
```

---

### 3️⃣ スマホからの開発フロー

本テンプレは **3軸のスマホ開発** をサポート:

#### 軸A: Claude Code Web（クラウド完結・推奨）

1. スマホブラウザで [claude.ai/code](https://claude.ai/code) を開く
2. このリポを GitHub 連携で開く
3. 自然言語で指示:
   > 「ログイン機能にダークモード設定を追加して、PR作って」
4. Claude がコード変更・PR 作成
5. GitHub Mobile でレビュー・マージ

**メリット**: ローカルマシン不要、5分でセットアップ
**制限**: 4 vCPU / 16GB RAM / 30GB Disk 上限、`~/.claude/` は引き継がない

#### 軸B: Remote Control（ローカル遠隔操作）

1. デスクトップで `claude` を起動
2. セッション内で `/config` → "Enable Remote Control" を ON
3. スマホの Claude アプリ（iOS/Android）でセッション URL を開く
4. スマホから承認・修正指示

**メリット**: コードがローカルに留まる、フル環境
**制限**: デスクトップ常時起動が必須

#### 軸C: GitHub Mobile + `@claude` Action

1. GitHub Mobile で Issue を開く
2. コメントで `@claude この機能を実装して` と書く
3. `.github/workflows/claude.yml` が自動起動
4. Claude が実装 → PR 作成
5. GitHub Mobile で diff レビュー・マージ

**メリット**: スマホだけで完結、チーム協業に最適
**事前準備**: `gh secret set ANTHROPIC_API_KEY` 済みであること

詳細: [`docs/mobile-development.md`](docs/mobile-development.md)

---

### 4️⃣ セキュリティ設定の理解

本テンプレは **3層防御**:

```
┌─────────────────────────────────────────┐
│ Layer 1: Permissions (allow/deny)       │  ← 静的ルール
├─────────────────────────────────────────┤
│ Layer 2: PreToolUse Hooks               │  ← 動的チェック（必須）
├─────────────────────────────────────────┤
│ Layer 3: Native Sandbox / DevContainer  │  ← OS レベル隔離
└─────────────────────────────────────────┘
```

#### デフォルトで何がブロックされるか

| カテゴリ | 例 |
|---------|-----|
| **Critical（即停止）** | `rm -rf /`, `rm -rf ~`, `curl ... \| sh`, fork bomb, `dd if=/dev/`, `mkfs` |
| **High（停止）** | `git push --force`, `git push --no-verify`, `chmod 777`, `sudo`, `--dangerously-skip-permissions` |
| **読み取り禁止** | `.env`, `.env.*`, `.aws/`, `.ssh/`, `credentials*`, `secrets/` |
| **書き込み検知** | AWS Key, GitHub Token, Stripe Key, Slack Token, Anthropic API Key |
| **Web系** | `WebFetch`, `WebSearch` はデフォルト deny（必要時のみ許可） |

#### bypassPermissions モードの無効化

`disableBypassPermissionsMode: "disable"` を設定済み。`--dangerously-skip-permissions` フラグも hook でブロックされます。

#### カスタマイズ

ローカル個人設定（gitignore対象）:
```bash
cp .claude/settings.local.json.example .claude/settings.local.json
# 編集して個人用 allow を追加
```

詳細: [`docs/security.md`](docs/security.md)

---

### 5️⃣ DevContainer（最も安全な実行環境）

VS Code / Cursor の DevContainer 機能でコンテナ内に隔離して実行:

```bash
# VS Code でこのリポを開く → "Reopen in Container"
# または Docker CLI で:
docker compose -f .devcontainer/docker-compose.yml up
```

`init-firewall.sh` により以下のドメインのみアクセス可能:
- `api.anthropic.com`
- `registry.npmjs.org`
- `github.com` / `objects.githubusercontent.com`
- `sentry.io` / `statsig.anthropic.com`

それ以外は **iptables で OUTPUT DROP**。

---

### 6️⃣ カスタマイズ

#### CLAUDE.md を編集

プロジェクト固有のルールを `CLAUDE.md` に追加。**60〜80行以内**を厳守。

#### 新規コマンドを追加

```bash
# .claude/commands/my-command.md を作成
# Claude Code 起動後に /my-command で実行可能
```

#### 新規エージェントを追加

```bash
# .claude/agents/my-agent.md を作成
# YAML frontmatter で name/description/tools/model を定義
```

詳細: [`docs/customization.md`](docs/customization.md)

---

## 📁 ディレクトリ構成

```
claude-code-harness-template/
├── .claude/                  # Claude Code 設定
│   ├── CLAUDE.md             # プロジェクト全体方針（@importでルートCLAUDE.mdから参照）
│   ├── settings.json         # hooks / permissions / sandbox
│   ├── settings.local.json.example
│   ├── .mcp.json.example     # MCP サーバー例
│   ├── commands/             # /plan /review /test /secure-audit /deep-research
│   ├── agents/               # 6種のサブエージェント
│   ├── skills/               # pr-summary / commit-helper / changelog-update
│   └── hooks/                # ガードレールスクリプト群
├── .devcontainer/            # Docker隔離環境 + iptables firewall
├── .github/                  # @claude Action / release-please / secret-scan
├── docs/                     # 詳細ドキュメント
├── scripts/                  # setup / audit / validate
├── examples/                 # 厳格設定例
├── CLAUDE.md                 # プロジェクトルートの CLAUDE.md
├── README.md                 # このファイル
├── LICENSE                   # MIT
├── SECURITY.md               # 脆弱性報告フロー
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── CHANGELOG.md
├── .gitignore
└── .gitleaks.toml
```

---

## 📚 ドキュメント

- [`docs/getting-started.md`](docs/getting-started.md) — 詳細セットアップ
- [`docs/security.md`](docs/security.md) — セキュリティ設計の詳細
- [`docs/customization.md`](docs/customization.md) — テンプレのカスタマイズ
- [`docs/mobile-development.md`](docs/mobile-development.md) — スマホ開発フロー詳細
- [`docs/hooks-reference.md`](docs/hooks-reference.md) — 各フックの仕様
- [`docs/testing.md`](docs/testing.md) — テスト戦略（bats + Playwright）
- [`docs/architecture.md`](docs/architecture.md) — 設計思想

---

## 🔒 セキュリティ

脆弱性を発見した場合は [`SECURITY.md`](SECURITY.md) のフローに従って報告してください。Issue には書かないでください。

---

## 🤝 Contributing

プルリクエスト歓迎です。詳細は [`CONTRIBUTING.md`](CONTRIBUTING.md) を参照。

---

## 📜 License

[MIT License](LICENSE) © 2026

---

## 🙏 Acknowledgements

本テンプレは以下のプロジェクトの知見を統合しています:

- [anthropics/claude-code](https://github.com/anthropics/claude-code) — 公式 CLI と DevContainer 設計
- [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action) — GitHub Action とセキュリティドキュメント
- [scotthavird/claude-code-template](https://github.com/scotthavird/claude-code-template) — 4層構造の実装リファレンス
- [luiseiman/dotforge](https://github.com/luiseiman/dotforge) — 監査スコアリング設計
- [lasso-security/claude-hooks](https://github.com/lasso-security/claude-hooks) — Prompt Injection スキャンパターン
- [CodyLunders/claude-code-hooks-library](https://github.com/CodyLunders/claude-code-hooks-library) — フックライブラリ

完全なリサーチレポートは内部ノート参照（46ソース・32検索・4並列エージェント調査）
