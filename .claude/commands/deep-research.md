---
name: deep-research
description: 複数のdeep-researcherを並列起動してWeb反復探索。技術トレンド・ライブラリ比較・最新仕様調査に使う。
argument-hint: "<テーマ>"
allowed-tools: Read, Grep, Glob
---

# /deep-research: Web 深掘り調査

テーマ: $ARGUMENTS

## やること

### Step 1: テーマをサブクエリに分解（3-5個）

- **What**: 定義・概要
- **Why**: 重要性・課題
- **How**: 実装方法・ベストプラクティス
- **Trend**: 2025-2026年の最新動向
- **Comparison**: 代替手段との比較

### Step 2: 並列で `deep-researcher` を起動

サブクエリを 2-3 個ずつにグループ化し、`deep-researcher` サブエージェントを **並列** で起動する。`run_in_background: true` を使うこと。

各エージェントには:
- 担当サブクエリ
- 停止基準（独立ソース2+、合計5+、新規情報枯渇）
- Hard Limits（WebSearch 15回、WebFetch 10回）
- 出力フォーマット（Executive Summary + Findings + Sources）

を明示する。

### Step 3: 結果統合

全エージェント完了後:
1. ソース重複排除
2. 矛盾検出
3. 知識ギャップ特定

### Step 4: レポート生成

```markdown
---
created: YYYY-MM-DD
type: deep-research
topic: <テーマ>
---

# <テーマ>: Research Report

## Executive Summary
...

## Findings
### サブクエリ1
...

## Sources
| # | Title | URL |
|---|-------|-----|
```

保存先はユーザーに確認（デフォルト: `docs/research/`）。

### Step 5: サマリー表示

- 要約（5行以内）
- 保存先パス
- 主要ソース一覧
- 追加深掘りの提案
