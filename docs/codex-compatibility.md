# Codex Compatibility

このテンプレは **OpenAI Codex CLI** と **Claude Code** の **両方で動作** します。同じプロジェクトを両ツールで扱えます。

## 🤝 互換性の仕組み

### 1. AGENTS.md ↔ CLAUDE.md 自動同期

| ツール | 読み込むファイル |
|--------|----------------|
| Claude Code | `CLAUDE.md` |
| Codex CLI | `AGENTS.md` |

**同期方法**: `.claude/hooks/sync-agents-md.sh` が `CLAUDE.md` 変更時に自動で `AGENTS.md` にコピー。

CI でも `claude-review.yml` で同期チェック可能。

### 2. 共通ドキュメント

両ツールが読む（CLAUDE.md / AGENTS.md から `@import` 参照）:

- `docs/naming-conventions.md` — 命名規約
- `docs/workflows/docdd.md` — 開発フロー
- `docs/decisions/` — ADR
- `docs/specs/` — 機能仕様

### 3. Codex 専用設定

`.codex/config.toml.example` をベースに、利用者個人の設定を `~/.codex/config.toml` に書く（gitignore 対象）。

```bash
mkdir -p ~/.codex
cp .codex/config.toml.example ~/.codex/config.toml
# 編集
$EDITOR ~/.codex/config.toml
```

## 🚀 Codex CLI でのセットアップ

```bash
# Codex CLI インストール（最新版確認: https://github.com/openai/codex）
npm install -g @openai/codex

# 動作確認
codex --version

# このリポで起動
cd <project>
codex
```

起動時に自動で `AGENTS.md` が読み込まれ、Claude Code と同じガイドラインに従います。

## ⚠️ Claude Code との挙動差

| 機能 | Claude Code | Codex CLI | 備考 |
|------|------------|-----------|------|
| Project file | `CLAUDE.md` + `.claude/CLAUDE.md` | `AGENTS.md` | hook で同期 |
| Hooks | `.claude/hooks/*` (PreToolUse/PostToolUse) | `~/.codex/config.toml` の `guardrails.deny_commands` | 同等ルール |
| Subagents | `.claude/agents/*.md` | 直接 spawn 機能はない（プロンプトで指示） | カスタムロールとして書ける |
| Slash commands | `.claude/commands/*.md` | プロンプトに記述 | `/autopilot` 相当は手動 |
| Skills | `.claude/skills/*/SKILL.md` | プロンプトに記述 | 〃 |
| Sandbox | Native sandbox + DevContainer | `sandbox.mode` 設定 | どちらも OS レベル |
| Permission | `permissions.allow/deny` in settings.json | `guardrails.deny_commands` | 重複ルール |

## 🔒 セキュリティルール（両ツール共通）

`docs/security.md` の3層防御は両方に適用:

| 層 | Claude Code | Codex CLI |
|----|------------|-----------|
| 静的ルール | `.claude/settings.json` | `~/.codex/config.toml` の `guardrails` |
| 動的チェック | PreToolUse hook | 内蔵承認モード |
| OS 隔離 | Native Sandbox / DevContainer | `sandbox.mode = "workspace-write"` |

特に **Merge 禁止** は両ツールで設定済み:

- Claude Code: `block-merge.sh` hook で `gh pr merge` / `git merge` / main 直 push をブロック
- Codex CLI: `guardrails.deny_commands` で同じパターンをブロック

## 🔄 開発フロー（両ツール共通）

`docs/workflows/docdd.md` の DocDD フロー:

1. Issue → Requirements / ADR / Spec
2. 実装 → テスト → 多角レビュー → PR

Claude Code の `/autopilot` 相当を Codex で実行する場合は、`AGENTS.md` 内の手順をプロンプトで明示:

```
AGENTS.md の DocDD フローに従って Issue #123 を実装してください。
PR 作成までで停止してください（Merge は禁止）。
```

## 📚 参考

- [OpenAI Codex GitHub](https://github.com/openai/codex)
- [Anthropic Claude Code](https://code.claude.com/)
- [AGENTS.md spec](https://github.com/openai/codex)（Codex の AGENTS.md の扱い）
