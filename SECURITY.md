# Security Policy

## 脆弱性の報告

このテンプレートに脆弱性を見つけた場合、**GitHub Issue には書かないでください**。

### 報告方法

1. GitHub の **Private Vulnerability Reporting** を使用（リポ → Security タブ → Report a vulnerability）
2. もしくは、リポオーナーの GitHub プロフィールに記載のメールアドレスへ直接連絡

### 含めてほしい情報

- 脆弱性の概要
- 影響範囲（どのファイル / どのフック / どのコマンド）
- 再現手順
- 想定される被害
- 修正案（あれば）

### 対応SLA

| 重大度 | 初動 | 修正 |
|--------|------|------|
| Critical | 24時間以内 | 7日以内 |
| High | 3日以内 | 14日以内 |
| Medium | 7日以内 | 30日以内 |
| Low | 14日以内 | 次回リリース時 |

## このテンプレ自体の既知の制約

### 設計上の限界

- **regex blocklist の限界**: `python -c "..."` のようなインタープリター経由は検知できません。DevContainer + Sandbox の併用を推奨します。
- **`deny` ルールの履歴**: Claude Code 本体に過去 `deny` 機能不全バグの報告例あり（[Issue #6699](https://github.com/anthropics/claude-code/issues/6699) ほか）。本テンプレは PreToolUse hook と二重防御することで mitigate しています。
- **`.env` 自動読み込み**: Claude Code 本体が dotenv 経由で読み込む挙動があります。`deny` + hook で二重ブロックしていますが、CVE 修正済みバージョンの利用を前提とします。
- **Prompt Injection は未解決問題**: Anthropic 公式が "far from solved" と認めています。PostToolUse スキャナで検知警告のみ。完全防御は不可能。

### 関連 CVE

- [CVE-2025-54794](https://nvd.nist.gov/vuln/detail/CVE-2025-54794) — Path Traversal (修正: v0.2.111 / v1.0.20+)
- [CVE-2025-54795](https://nvd.nist.gov/vuln/detail/CVE-2025-54795) — Command Injection (修正: v0.2.111 / v1.0.20+)

**本テンプレ利用前に Claude Code 本体を最新版にアップデートしてください**:

```bash
npm install -g @anthropic-ai/claude-code@latest
claude --version
```

## ベストプラクティス

このテンプレを使う側のあなたも:

- ✅ Claude Code 本体を常に最新版に
- ✅ `gh secret` で API キー管理（コード内に書かない）
- ✅ Branch protection 設定（main 直 push 禁止 + PR review 必須）
- ✅ Dependabot 有効化
- ✅ GitHub Secret Scanning 有効化
- ✅ DevContainer 利用（信頼できないコードを扱う場合）
- ❌ `--dangerously-skip-permissions` を使わない
- ❌ `~/.ssh` や `~/.aws` をコンテナに bind mount しない
