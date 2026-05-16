---
name: spec
description: Issue 番号に紐づく機能仕様書 (Spec) を docs/specs/ に起票。Issue 本文から要点を抽出して雛形に埋める。
argument-hint: "<issue-number>"
allowed-tools: Read, Write, Bash(gh issue view *), Bash(ls docs/specs/*)
---

# /spec: 機能仕様書を起票

issue: $ARGUMENTS

## やること

1. **Issue 取得**:
   ```bash
   gh issue view $ARGUMENTS --json title,body,labels,milestone
   ```

2. **slug 生成**:
   - Issue タイトルから `<type>: ` を除去 → subject 抽出
   - subject を kebab-case 化

3. **ファイル作成**:
   ```bash
   FILE="docs/specs/${ARGUMENTS}-${SLUG}.md"
   cp docs/specs/template.md "$FILE"
   ```

4. **プレースホルダ置換**:
   - `<機能名>` → Issue title の subject 部分
   - `<番号>` → `$ARGUMENTS`
   - `YYYY-MM-DD` → 今日
   - `<担当者>` → Issue の assignees（あれば）

5. **Issue 本文を解析して自動入力**:
   - 「Goal」セクション: Issue 本文の最初の段落
   - 「User Stories」: Issue に書かれていれば抽出
   - 「Acceptance Criteria」: Issue 内の `- [ ]` チェックリスト

6. **ユーザーに次のアクション提示**:
   - Goal / Non-Goals を明確化
   - Edge Cases / Test Plan を埋める

## 出力

```markdown
✅ Spec created: docs/specs/<issue#>-<slug>.md

Issue: #<issue#> "<title>"
雛形に Issue 本文を反映済み。以下を埋めてください:

- [ ] Goal を1段落で明文化
- [ ] Non-Goals（やらないこと）
- [ ] User Stories
- [ ] Acceptance Criteria（検証可能な形）
- [ ] Edge Cases
- [ ] Test Plan
```

## ルール

1. **既存 Spec があれば** 上書きせず、`--force` フラグ要求
2. Issue が **closed** の場合は警告（既に実装済みのはず）
3. Issue 本文が空でも雛形は作る
