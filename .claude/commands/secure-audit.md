---
name: secure-audit
description: security-reviewerエージェントでセキュリティ監査を実行。OWASP Top10 + Claude Code 特有の脅威をチェック。
argument-hint: "[ファイル/ディレクトリ or 'diff' で git diff のみ]"
allowed-tools: Read, Grep, Glob, Bash(git diff *), Bash(npm audit *), Bash(pip-audit *)
---

# /secure-audit: セキュリティ監査

scope: ${1:-diff}

## やること

1. `security-reviewer` サブエージェントを起動
2. 監査結果を表で整理
3. Critical/High があれば修正を提案

サブエージェント `security-reviewer` を起動し、以下を依頼してください:

- 引数で指定されたスコープ（`diff` なら直近の変更）を監査
- OWASP Top 10 + Claude Code 特有（Prompt Injection, secret leakage, 危険コマンド）を全数チェック
- Critical / High / Medium / Low に分類
- CWE/OWASP ID 付き
- 攻撃シナリオ（PoC）が想像できる場合は記載

Critical/High が出た場合は「即修正しますか？」と確認。
