# Customization — テンプレのカスタマイズ

このテンプレはそのまま使うこともできますが、プロジェクトに合わせて拡張・調整することを想定しています。

## 🎨 カスタマイズの基本方針

### チーム共有設定 vs 個人設定

| 種別 | ファイル | gitignore | 用途 |
|------|---------|-----------|------|
| **チーム共有** | `.claude/settings.json` | ❌ コミット | プロジェクト全体のルール |
| **個人ローカル** | `.claude/settings.local.json` | ✅ | 個人の好み・一時的な許可 |
| **個人プロジェクト** | `CLAUDE.local.md` | ✅ | 個人のプロジェクト固有メモ |

---

## 📝 CLAUDE.md のカスタマイズ

`CLAUDE.md` はプロジェクトの**意思決定の伝達手段**です。**60〜80行以内** を厳守してください。

### 入れるべきもの

- プロジェクト固有のコマンド（`npm run dev`, `make test` 等）
- コードスタイルの規約（命名、フォーマッタ）
- 重要な技術選定（「ORM は Prisma を使う」「テストは Vitest」）
- 「**やってはいけない**」リスト
- 関連ファイルへの `@import`

### 入れないべきもの

- コードを読めば分かること
- 標準的なベストプラクティス（「クリーンコードを書け」等）
- 頻繁に変わる情報
- 詳細な手順書（→ Skills へ）

### @import で分割

```markdown
# CLAUDE.md

@.claude/CLAUDE.md
@docs/architecture.md
```

最大 5 階層まで再帰展開されます。

### IMPORTANT 強調

Claude は `IMPORTANT:` や `YOU MUST` 表記の遵守率が高い:

```markdown
IMPORTANT: 認証ロジックは src/auth/ 配下のみ。他のディレクトリに書かないこと。
```

---

## ⚙️ settings.json のカスタマイズ

### 新規 allow を追加

例: `docker compose` を使うプロジェクト:

```json
{
  "permissions": {
    "allow": [
      "Bash(docker compose up *)",
      "Bash(docker compose down *)",
      "Bash(docker compose logs *)",
      "Bash(docker compose exec *)"
    ]
  }
}
```

⚠️ `docker compose run` と `docker run` には任意コマンド実行リスクあり。慎重に。

### 新規 deny を追加

例: 特定のファイルを保護したい:

```json
{
  "permissions": {
    "deny": [
      "Read(//**/migration_history.sql)",
      "Edit(//**/migration_history.sql)",
      "Write(//**/migration_history.sql)"
    ]
  }
}
```

### Sandbox の有効化

本番運用では `enabled: true` 推奨:

```json
{
  "sandbox": {
    "enabled": true,
    "failIfUnavailable": true
  }
}
```

---

## 🪝 Hooks のカスタマイズ

### 新規フックの追加

`.claude/hooks/` にスクリプトを追加し、`settings.json` の `hooks` セクションに登録:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash ${CLAUDE_PROJECT_DIR}/.claude/hooks/your-new-hook.sh" }
        ]
      }
    ]
  }
}
```

### フックスクリプトの基本構造

```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
# tool_name や tool_input.command 等を取得
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')

# ブロックする場合
jq -n --arg reason "..." '{
    hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
    }
}'
exit 0

# 何もしない場合
exit 0
```

### exit code の意味

| code | 動作 |
|------|------|
| 0 | 成功、stdout の JSON をパース |
| 2 | **ブロック**（bypassPermissions でも無視できない） |
| その他 | 非ブロックエラー |

詳細: [`hooks-reference.md`](hooks-reference.md)

---

## 🤖 新規エージェントの追加

`.claude/agents/your-agent.md`:

```markdown
---
name: your-agent
description: いつ使うかの説明（Claude が自動委譲判定に使う）
tools: Read, Grep, Bash(npm test *)
model: sonnet
---

あなたは [役割] です。

## 役割
...

## 出力フォーマット
...

## ルール
...
```

### 設計原則

1. **単一責任**: 1エージェント = 1種類のタスク
2. **明確な description**: Claude 本体が委譲判定に使う
3. **最小権限**: 不要な tools は付与しない
4. **モデル選択**: 軽い検索は haiku、レビューは sonnet、難しい設計は opus

### 動作確認

```
このコードを your-agent でチェックして
```

→ Claude が `your-agent` を起動するはず

---

## 📚 新規コマンドの追加

`.claude/commands/your-cmd.md`:

```markdown
---
name: your-cmd
description: いつ使うか
argument-hint: "<引数>"
allowed-tools: Read, Bash(...)
---

# /your-cmd: タイトル

引数: $ARGUMENTS

## やること
1. ...
2. ...
```

セッション内で `/your-cmd <args>` で呼び出せます。

---

## 🛠️ 新規スキルの追加

`.claude/skills/your-skill/SKILL.md`:

```markdown
---
name: your-skill
description: 説明
argument-hint: "[引数]"
allowed-tools: Bash(...)
context: fork
agent: general-purpose
---

# Your Skill

## Context (auto-injected)
- Git status: !`git status --short`

## Task
上記コンテキストを元に...
```

### Skill vs Command vs Subagent の選択

| 判断基準 | CLAUDE.md | Skill | Subagent | Slash Command |
|---------|-----------|-------|----------|---------------|
| 毎セッション必要 | ✅ | ❌ | ❌ | ❌ |
| 手動トリガー可 | ❌ | ✅ | ✅（間接） | ✅ |
| 独立コンテキスト | ❌ | `context:fork`で可 | ✅ | ❌ |
| 動的データ注入（`!command`） | ❌ | ✅ | ❌ | ❌ |
| サポートファイル | ❌ | ✅ | ❌ | ❌ |

---

## 🐳 DevContainer のカスタマイズ

### 追加ツールのインストール

`.devcontainer/Dockerfile`:

```dockerfile
# 既存の RUN apt-get install の後に追加
RUN apt-get update && apt-get install -y --no-install-recommends \
    your-tool \
  && rm -rf /var/lib/apt/lists/*
```

### 許可ドメインの追加

`.devcontainer/init-firewall.sh` の `ALLOWED_DOMAINS` 配列に追加:

```bash
ALLOWED_DOMAINS=(
    "api.anthropic.com"
    # ...既存
    "your-internal-api.company.com"
)
```

### VS Code 拡張の追加

`.devcontainer/devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "anthropic.claude-code",
        "your-publisher.your-extension"
      ]
    }
  }
}
```

---

## 🔄 CI/CD のカスタマイズ

### `claude.yml` の trigger をカスタマイズ

例: `@bot-name` でもトリガー:

```yaml
if: |
  contains(github.event.comment.body, '@claude') ||
  contains(github.event.comment.body, '@bot-name')
```

例: 特定ラベルが付いた Issue のみ:

```yaml
if: |
  contains(github.event.issue.labels.*.name, 'ai-help')
```

### `claude-review.yml` のプロンプトをカスタマイズ

`prompt:` セクションを編集して、プロジェクト固有のレビュー観点を追加:

```yaml
prompt: |
  このPRをレビューしてください。

  ## プロジェクト固有のチェック
  - DDD のレイヤー違反がないか（ドメイン層から infrastructure を import していないか）
  - API レスポンスの型が `src/types/api.ts` と整合しているか
  - i18n キーが i18n ファイルに追加されているか
```

---

## 📦 不要な機能の削除

このテンプレは「全部入り」なので、不要な機能を削除して軽量化することもできます:

### Skills を全部削除

```bash
rm -rf .claude/skills/
```

### Deep Research を削除

```bash
rm .claude/commands/deep-research.md
rm .claude/agents/deep-researcher.md
```

### GitHub Action を削除

```bash
rm -rf .github/workflows/claude.yml
rm -rf .github/workflows/claude-review.yml
```

### DevContainer を削除

```bash
rm -rf .devcontainer/
```

---

## 📖 詳細ガイド

- [Hooks Reference](hooks-reference.md) — 各フックの仕様
- [Security](security.md) — セキュリティ設計
- [Architecture](architecture.md) — 設計思想
