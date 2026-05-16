---
name: requirements
description: 大きな機能エピックの要件定義書を docs/requirements/ に起票。ペルソナ・ジョブストーリー・成功指標を整理。
argument-hint: "<topic-slug>"
allowed-tools: Read, Write, Bash(ls docs/requirements/*)
---

# /requirements: 要件定義書を起票

topic: $ARGUMENTS

## やること

1. **既存チェック**:
   ```bash
   FILE="docs/requirements/${ARGUMENTS}.md"
   [ -f "$FILE" ] && echo "既存あり: $FILE" && exit 1
   ```

2. **ファイル作成**:
   ```bash
   cp docs/requirements/template.md "$FILE"
   ```

3. **プレースホルダ置換**:
   - `<機能名>` → `$ARGUMENTS`（kebab → Title Case 化）
   - `YYYY-MM-DD` → 今日

4. **ユーザーに次のアクション提示**:
   ```
   ✅ Requirements created: docs/requirements/<topic>.md

   埋めてください:
   - [ ] Vision (1段落、ユーザー視点)
   - [ ] Background / Context
   - [ ] Target Users / Personas
   - [ ] Job Stories（When/I want to/So I can）
   - [ ] Success Metrics（定量指標）
   - [ ] In Scope / Out of Scope
   - [ ] Risks and Open Questions
   - [ ] Stakeholders

   次のステップ:
   - 必要に応じて ADR を起票: /adr "<title>"
   - 子 Issue を立てる: gh issue create
   - 各 Issue で Spec を作る: /spec <issue#>
   ```

## ルール

1. **トピック単位** で起票（複数機能をまとめない）
2. Vision は **ユーザー視点** で書く
3. Stakeholder approval が必要なら Status を draft で開始
