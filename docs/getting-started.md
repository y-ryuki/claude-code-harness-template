# Getting Started — 詳細セットアップガイド

このガイドでは、Claude Code Harness Template を使い始めるまでの **手順を一切省略せず** に説明します。

## 📋 前提条件

### 必須

| ツール | 最低バージョン | 確認方法 |
|--------|--------------|---------|
| Claude Code CLI | 最新（v0.2.111+ / v1.0.20+） | `claude --version` |
| Git | 2.30+ | `git --version` |
| jq | 1.6+ | `jq --version` |
| Node.js | 20+ | `node --version` |

### 推奨

| ツール | 用途 |
|--------|------|
| `gh` (GitHub CLI) | PR/Issue 操作 |
| `gitleaks` | シークレットスキャン |
| Docker | DevContainer 利用 |
| VS Code or Cursor | DevContainer のフロントエンド |

### Claude Code CLI のインストール

```bash
# npm 経由
npm install -g @anthropic-ai/claude-code@latest

# 確認
claude --version
# → 1.0.20 以上であること（CVE-2025-54794/54795 修正後）
```

⚠️ **古いバージョンには既知の脆弱性（CVE-2025-54794/54795）があります。必ず最新版を使ってください。**

---

## 🚀 セットアップ

### Step 1: テンプレからリポジトリ作成

#### オプション A: GitHub Template ボタン（推奨）

1. このリポジトリ（`<owner>/claude-code-harness-template`）を開く
2. 緑の **「Use this template」** → **「Create a new repository」**
3. リポジトリ名・公開範囲を選択
4. **「Create repository」**

#### オプション B: clone してから git 履歴をリセット

```bash
git clone https://github.com/<owner>/claude-code-harness-template.git my-project
cd my-project
rm -rf .git
git init
git add .
git commit -m "chore: initial commit from template"
```

#### オプション C: ローカルプロジェクトに導入（部分的）

```bash
# 既存プロジェクトのルートで
curl -fsSL https://raw.githubusercontent.com/<owner>/claude-code-harness-template/main/scripts/install.sh | bash
# ↑ 注意: pipe-to-shell は本テンプレでは推奨しません
#   セキュリティ重視なら手動で必要ファイルだけコピーしてください
```

---

### Step 2: ローカル環境のセットアップ

```bash
cd my-project
./scripts/setup.sh
```

実行される内容:

1. `.claude/hooks/*.sh` `.claude/hooks/*.py` に **実行権限付与**
2. `.gitignore` に重要パターンが含まれているか確認
3. `gitleaks` の存在確認 + 警告
4. `settings.local.json.example` をコピーして `settings.local.json` を作成（gitignore 対象）
5. `git config core.hooksPath .githooks` 設定（pre-commit hook 有効化）

---

### Step 3: API キーの設定

#### ローカル CLI で使う場合

```bash
# 一時的（シェル終了で消える）
export ANTHROPIC_API_KEY="sk-ant-..."

# 永続化（zshの場合）
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.zshrc
source ~/.zshrc
```

🚨 **絶対にコードや `.env`（チェックインされる可能性のあるファイル）に書かないこと。**

#### GitHub Action で使う場合

```bash
gh secret set ANTHROPIC_API_KEY -b "sk-ant-..."

# 確認
gh secret list
```

#### Claude Code Web で使う場合

API キー設定不要。`claude.ai/code` にログイン済みなら自動的に使われます。

---

### Step 4: 初回起動と動作確認

```bash
claude
```

セッション開始時に `SessionStart` フックが動き、以下のようなコンテキストが表示されるはず:

```
## Session Context
**Branch**: main
**Uncommitted changes**: 0 files
**Recent commits**: ...
**Environment**:
- Node: v20.x.x
- Python: Python 3.x.x
⚠️ Reminder: This template enforces strict guardrails...
```

#### 動作確認テスト

セッション内で以下を試して、ガードレールが効いていることを確認:

```
ターミナルで rm -rf ~ を実行してみて
```

→ Claude は実行を拒否、もしくは hook がブロックする旨を表示するはずです。

```
.env ファイルの中身を見せて
```

→ Claude は読み取りを拒否、または hook がブロック。

```
APIキーを README に書いて
```

→ `sk-ant-...` パターンを `detect-secrets.sh` がブロック。

---

### Step 5: GitHub リポジトリのセットアップ

#### Branch Protection

`main` ブランチを保護:

```bash
# Web UI で:
# Settings → Branches → Add rule
# - Require a pull request before merging ✅
# - Require approvals: 1+
# - Require status checks to pass ✅
# - Include administrators ✅
```

または CLI で:

```bash
gh api -X PUT "/repos/{owner}/{repo}/branches/main/protection" \
  --input - <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["validate-settings", "audit-score", "gitleaks"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1
  },
  "restrictions": null
}
EOF
```

#### Secret Scanning + Dependabot を有効化

```
Settings → Security → Code security and analysis
- Dependency graph: ON
- Dependabot alerts: ON
- Dependabot security updates: ON
- Secret scanning: ON (有料プランで)
- Push protection: ON
```

#### CODEOWNERS を編集

`.github/CODEOWNERS` の `<owner>` を自分の GitHub ID に置換:

```
* @your-github-username
```

#### Template化（公開する場合）

```
Settings → General → Template repository ✅
```

---

## 🎮 最初のタスクを実行してみる

### サンプル1: 新規ファイル作成

```
claudeセッション内:
> README の最後にQuickStart の英語版を追加して
```

→ Claude が `README.md` を編集。`PostToolUse` フックの `format-on-save.sh` が prettier を走らせる。

### サンプル2: テスト実行

```
> /test
```

→ `test-runner` エージェントが起動。失敗のみを抽出して返す。

### サンプル3: PR レビュー

```
> /review
```

→ `code-reviewer` エージェントが直近の diff をレビュー。

### サンプル4: セキュリティ監査

```
> /secure-audit src/auth/
```

→ `security-reviewer` エージェントが指定ディレクトリを監査。

### サンプル5: 深掘り調査

```
> /deep-research Cursorとの統合方法
```

→ `deep-researcher` エージェントが並列で Web 探索。

---

## 🐳 DevContainer で起動（最高セキュリティ）

### VS Code / Cursor で

1. リポを開く
2. **「Reopen in Container」** をクリック（コマンドパレットからも可: `Dev Containers: Reopen in Container`）
3. 初回はビルドに 3-5 分かかる
4. 自動的に `init-firewall.sh` が走り、iptables で OUTPUT DROP + ホワイトリスト適用
5. コンテナ内のターミナルで `claude` 起動

### コンテナ内の制限

- 許可ドメインのみアクセス可能（`api.anthropic.com`, `registry.npmjs.org`, `github.com` 等）
- ホストの `~/.ssh`, `~/.aws` は bind mount されない
- `~/.claude/` はコンテナ専用ボリューム（ホストと隔離）

---

## 📱 スマホからの開発

→ [`mobile-development.md`](mobile-development.md) を参照

---

## 🆘 よくあるトラブル

### `bash: jq: command not found`

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Windows (WSL推奨)
sudo apt install jq
```

### Hooks が動かない

```bash
# 実行権限の確認
ls -l .claude/hooks/
# → -rwxr-xr-x になっているか

# 手動で付与
chmod +x .claude/hooks/*.sh .claude/hooks/*.py
```

### `Permission denied: init-firewall.sh`

DevContainer 内で:
```bash
sudo /usr/local/bin/init-firewall.sh
```

通常は `postStartCommand` で自動実行されるはずなので、ログ確認:
```bash
docker logs <container-id>
```

### `settings.json` の deny ルールが効かない

PreToolUse hook がバックアップ防御として動くはずです。両方確認:

```bash
# settings の検証
./scripts/validate-settings.sh

# hook が実行権限を持っているか
ls -l .claude/hooks/block-dangerous.sh
```

それでも効かない場合は Claude Code を最新版にアップデート:

```bash
npm install -g @anthropic-ai/claude-code@latest
```

---

## 🔗 次のステップ

- [セキュリティ設計の詳細](security.md)
- [テンプレのカスタマイズ](customization.md)
- [スマホ開発フロー](mobile-development.md)
- [各フックの仕様](hooks-reference.md)
- [設計思想](architecture.md)
