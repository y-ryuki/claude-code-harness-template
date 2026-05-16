#!/bin/bash
# PostToolUse hook: CLAUDE.md が変更されたら AGENTS.md に同期
# matcher: Edit|Write
# 動機: Codex CLI は AGENTS.md を読むため、CLAUDE.md と内容を一致させる

set -uo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# CLAUDE.md (project root) or .claude/CLAUDE.md が変更された場合に同期
case "$FILE_PATH" in
    */CLAUDE.md|CLAUDE.md|*/.claude/CLAUDE.md|.claude/CLAUDE.md)
        # 同期対象: ルートの CLAUDE.md と AGENTS.md
        if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
            # AGENTS.md のヘッダを追加してコピー
            {
                echo "<!-- AGENTS.md: auto-synced from CLAUDE.md by .claude/hooks/sync-agents-md.sh -->"
                echo "<!-- このファイルは Codex CLI 互換性のため CLAUDE.md と同期されています。直接編集せず、CLAUDE.md を編集してください。-->"
                echo ""
                cat "$PROJECT_DIR/CLAUDE.md"
            } > "$PROJECT_DIR/AGENTS.md.tmp" && mv "$PROJECT_DIR/AGENTS.md.tmp" "$PROJECT_DIR/AGENTS.md"

            # 通知（Claude のコンテキストには出さない、stderr のみ）
            echo "[sync-agents-md] CLAUDE.md → AGENTS.md synced" >&2
        fi
        ;;
esac

exit 0
