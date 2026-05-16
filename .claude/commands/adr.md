---
name: adr
description: 新規 ADR (Architecture Decision Record) を MADR 形式で起票。連番自動採番、template.md ベース。
argument-hint: "<title>"
allowed-tools: Read, Write, Bash(ls docs/decisions/*), Bash(date *)
---

# /adr: ADR 起票

title: $ARGUMENTS

## やること

1. **次の連番取得**:
   ```bash
   NEXT_NUM=$(ls docs/decisions/ 2>/dev/null | grep -E '^[0-9]{4}-' | sort | tail -1 | grep -oE '^[0-9]{4}' | awk '{printf "%04d", $1+1}')
   # 既存なし → 0001、最大が 0042 → 0043
   ```

2. **slug 生成**:
   ```bash
   SLUG=$(echo "$ARGUMENTS" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-\|-$//g')
   # "Use Prisma for ORM" → "use-prisma-for-orm"
   ```

3. **ファイル作成**:
   ```bash
   FILE="docs/decisions/${NEXT_NUM}-${SLUG}.md"
   cp docs/decisions/template.md "$FILE"
   ```

4. **テンプレ内のプレースホルダ置換**:
   - `ADR-NNNN` → `ADR-${NEXT_NUM}`
   - `<タイトル>` → `$ARGUMENTS`
   - `Date: YYYY-MM-DD` → 今日の日付
   - `Status: ...` → `Status: proposed`

5. **README.md に追記**:
   `docs/decisions/README.md` の「既存 ADR 一覧」表に新行を追加:
   ```
   | [NNNN](NNNN-slug.md) | <title> | proposed | YYYY-MM-DD |
   ```

6. **ユーザーに次のアクション提示**:
   - Context / Decision Drivers / Considered Options を埋める
   - 関連 Issue があれば `Issue: #N` を設定

## 出力

```markdown
✅ ADR-NNNN created: docs/decisions/NNNN-<slug>.md

次のステップ:
1. Context and Problem Statement を書く
2. Considered Options を列挙
3. Decision Outcome で選定理由を明記
4. Status を accepted に更新（合意後）
```

## ルール

1. 連番は **欠番禁止**（4桁ゼロパディング）
2. slug は **英数字 + ハイフン** のみ
3. **既存 ADR と重複する slug** があれば「-v2」などのサフィックス
4. template.md は **改変しない**（コピーのみ）
