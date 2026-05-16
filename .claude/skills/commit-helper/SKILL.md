---
name: commit-helper
description: ステージング済みの変更を Conventional Commits 形式でコミットメッセージを提案する。コミット直前に使う。
argument-hint: "[scope]"
allowed-tools: Bash(git diff *), Bash(git status), Bash(git log -5)
---

# Commit Helper

## Context (auto-injected)

- ステージング状況: !`git status --short`
- ステージング済み diff: !`git diff --cached`
- 直近のコミット履歴（コミットスタイル参考用）: !`git log --oneline -5`

## Task

上記のステージング済み変更を分析し、**Conventional Commits 形式** のコミットメッセージ案を **3パターン** 提示してください。

### 形式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type の選択基準

| Type | 用途 |
|------|------|
| feat | 新機能 |
| fix | バグ修正 |
| docs | ドキュメントのみ |
| refactor | 動作変更なしのリファクタ |
| test | テスト追加・修正 |
| chore | ビルド設定・依存更新 |
| perf | パフォーマンス改善 |
| ci | CI 設定変更 |

### Subject ルール

- 50 文字以内
- 命令形（"add", "fix", "update"）または日本語
- ピリオドで終わらない
- 何を **なぜ** 変えたか（What だけでなく Why も）

### Body ルール

- 72 文字で改行
- 「**なぜ**」その変更が必要か
- 関連 Issue を `Refs: #123` で記載

## 出力例

```markdown
## 提案1（推奨）

\`\`\`
feat(auth): add OAuth2 PKCE flow for mobile clients

PKCE prevents authorization code interception attacks on mobile,
which is the primary use case after we removed implicit grant.

Refs: #142
\`\`\`

## 提案2

...

## 提案3

...

選択するか、修正案を教えてください。
```

ステージング済みの変更がなければ「ステージングするファイルを指定してください」と返す。
