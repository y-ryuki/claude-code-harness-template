---
name: review-multi
description: 7並列の多角的レビュー。code / security / architecture / performance / accessibility / maintainability / ux の各エージェントを同時起動し、統合レポートを返す。
argument-hint: "[base-branch or 'HEAD~N']"
allowed-tools: Read, Grep, Glob, Bash(git diff *), Bash(git log *)
---

# /review-multi: 多角的レビュー

base: ${1:-HEAD~1}

## やること

`git diff $1` の変更内容に対して、**7つの専門レビュアー** を **並列** で起動。各レビュアーは独立した観点で評価。

### 並列起動するエージェント

| # | エージェント | 観点 | model |
|---|------------|------|-------|
| 1 | code-reviewer | 正確性 / 可読性 / 規約遵守 | sonnet |
| 2 | security-reviewer | OWASP Top 10 / Claude Code 特有脅威 | sonnet |
| 3 | architecture-reviewer | レイヤー / 責務 / 依存方向 | sonnet |
| 4 | performance-reviewer | N+1 / バンドル / レンダリング | sonnet |
| 5 | accessibility-reviewer | WCAG 2.1 AA / WAI-ARIA | sonnet |
| 6 | maintainability-reviewer | 命名 / 複雑度 / テスト | sonnet |
| 7 | ux-reviewer | フィードバック / エラー / マイクロコピー | sonnet |

## 実行手順

1. **base 確認**: `git diff $1 --stat` で変更規模を確認
2. **並列起動**: 上記7エージェントを **Task tool で同時起動** (`run_in_background: true`)
   - 各エージェントには **担当観点のみ** を依頼
   - 各エージェントには **同じ diff 範囲** を渡す
3. **完了待機**: 全エージェントの完了通知を受信
4. **統合**: 結果を以下の構造でまとめる

## 統合レポートフォーマット

```markdown
## 🔍 Multi-Angle Review Summary

**Base**: `$1` (XX files changed, +YYY -ZZZ lines)
**Reviewers**: 7 agents (parallel)

### 総合判定

| 観点 | 判定 | Critical | High | 詳細 |
|------|------|---------|------|------|
| 🔧 Code | APPROVE | 0 | 1 | ... |
| 🔒 Security | REQUEST CHANGES | 1 | 2 | ... |
| 🏛️ Architecture | APPROVE | 0 | 0 | ... |
| ⚡ Performance | COMMENT | 0 | 2 | ... |
| ♿ Accessibility | REQUEST CHANGES | 2 | 1 | ... |
| 🔧 Maintainability | COMMENT | 0 | 0 | ... |
| 🎨 UX | APPROVE | 0 | 1 | ... |

### 🚨 Blockers（マージ前に必須）
1. **[Security]** `src/auth/...`: SQL injection 可能性
2. **[Accessibility]** `LoginForm.tsx`: `<div onclick>` をボタンに

### 🟡 推奨修正
- ...

### 💡 ナイスtoハブ
- ...

### 詳細レポート

<details>
<summary>🔧 Code Review</summary>
... (code-reviewer の出力をそのまま)
</details>

<details>
<summary>🔒 Security Review</summary>
...
</details>

(以下7つ全部 details ブロックで)
```

## 統合ロジック

- 1つでも **REQUEST CHANGES** があれば全体は **REQUEST CHANGES**
- 全部 APPROVE → 全体 APPROVE
- 残りは COMMENT

## 出力後アクション

1. Blockers があれば「**修正してから再度 /review-multi を**」と案内
2. Blockers なし → 「**PR 作成可能**。`/autopilot` で続行 or 手動で `gh pr create`」

## ルール

1. **必ず並列起動**（直列実行禁止、時間がかかりすぎる）
2. **diff 範囲は全エージェントで統一**
3. 統合レポートは **読みやすさ最優先**（詳細は折りたたみ）
4. 7エージェントすべてが完了するまで結果をまとめない
