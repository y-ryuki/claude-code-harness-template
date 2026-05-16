---
name: agents-sync
description: CLAUDE.md と AGENTS.md の同期状態を確認し、差分があれば AGENTS.md を更新する。手動同期や CI チェックで使う。
allowed-tools: Read, Edit, Write, Bash(diff *), Bash(test *)
---

# Agents Sync

## Context (auto-injected)

- CLAUDE.md exists: !`test -f CLAUDE.md && echo yes || echo no`
- AGENTS.md exists: !`test -f AGENTS.md && echo yes || echo no`
- diff: !`diff <(tail -n +4 AGENTS.md 2>/dev/null) CLAUDE.md 2>/dev/null | head -30 || echo "no diff or files missing"`

## Task

CLAUDE.md と AGENTS.md の同期状態を確認し、必要なら同期してください。

### 同期ルール

- `AGENTS.md` の **先頭3行はヘッダコメント**（自動同期である旨）
- 4行目以降は `CLAUDE.md` と **完全一致** すべき
- 不一致なら AGENTS.md を更新（CLAUDE.md は touch しない）

### 同期コード

```bash
{
    echo "<!-- AGENTS.md: auto-synced from CLAUDE.md by .claude/hooks/sync-agents-md.sh -->"
    echo "<!-- このファイルは Codex CLI 互換性のため CLAUDE.md と同期されています。直接編集せず、CLAUDE.md を編集してください。-->"
    echo ""
    cat CLAUDE.md
} > AGENTS.md.tmp && mv AGENTS.md.tmp AGENTS.md
```

### 出力パターン

#### A. 完全同期済み

```markdown
✅ CLAUDE.md と AGENTS.md は同期済みです。
- CLAUDE.md: XXX bytes
- AGENTS.md: YYY bytes (header 含む)
```

#### B. 同期が必要

```markdown
⚠️ AGENTS.md が CLAUDE.md より古いです。

差分（先頭30行）:
<diff>

➜ AGENTS.md を更新しますか？ (Yes/No)
```

#### C. AGENTS.md が存在しない

```markdown
❌ AGENTS.md が存在しません。
新規作成しますか？
```

## ルール

1. **CLAUDE.md を変更しない**（同期方向は CLAUDE.md → AGENTS.md のみ）
2. **AGENTS.md の手動編集を検知** したら警告（CLAUDE.md と乖離している場合）
3. CI で `agents-sync` を実行して同期チェック可能
