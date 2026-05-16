#!/bin/bash
# DevContainer 作成後の初期化
set -euo pipefail

echo "[post-create] Setting up workspace..."

# フックスクリプトに実行権限
if [ -d .claude/hooks ]; then
    chmod +x .claude/hooks/*.sh .claude/hooks/*.py 2>/dev/null || true
    echo "[post-create] ✅ Hook scripts made executable"
fi

# scripts に実行権限
if [ -d scripts ]; then
    chmod +x scripts/*.sh 2>/dev/null || true
fi

# git config（コミット署名推奨だが、ユーザー次第）
git config --global init.defaultBranch main
git config --global pull.rebase false

echo "[post-create] ✅ Setup complete"
echo ""
echo "Next steps:"
echo "  1. Set your Anthropic API key: export ANTHROPIC_API_KEY=..."
echo "  2. Start Claude Code: claude"
echo "  3. Verify hooks are loaded: try a harmless command first"
