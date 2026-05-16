---
name: review
description: 現在の変更（git diff）をcode-reviewerエージェントに依頼してレビューする。
argument-hint: "[base-branch]"
allowed-tools: Read, Bash(git diff *), Bash(git log *)
---

# /review: コードレビュー

base: ${1:-HEAD~1}

## やること

1. `git diff $1` で変更内容を確認
2. `code-reviewer` サブエージェントを起動
3. レビュー結果を整理して提示

サブエージェント `code-reviewer` を起動し、以下を依頼してください:

- 現在の作業ブランチと指定された base（デフォルト `HEAD~1`）の diff をレビュー
- Must Fix / Should Fix / Nit / Good に分類
- 各指摘に file:line と修正案を付ける
- 総合判定（APPROVE / REQUEST CHANGES / COMMENT）

レビュー結果を表示後、ユーザーに「修正してほしい箇所はありますか？」と問いかけて次のアクションを決めてください。
