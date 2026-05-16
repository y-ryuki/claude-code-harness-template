#!/bin/bash
# Initial setup script
# 実行: ./scripts/setup.sh

set -euo pipefail

cd "$(dirname "$0")/.."

echo "═══════════════════════════════════════════════"
echo "  Claude Code Harness Template Setup"
echo "═══════════════════════════════════════════════"
echo ""

# --- Step 1: 依存ツール確認 ---
echo "📦 [1/5] 依存ツールチェック..."

check_tool() {
    local tool="$1"
    local required="$2"
    if command -v "$tool" &>/dev/null; then
        echo "  ✅ $tool: $(command -v $tool)"
    else
        if [ "$required" = "required" ]; then
            echo "  ❌ $tool: 必須ですが見つかりません"
            return 1
        else
            echo "  ⚠️  $tool: 推奨ですが見つかりません"
        fi
    fi
}

MISSING=0
check_tool "claude" "required" || MISSING=1
check_tool "git" "required" || MISSING=1
check_tool "jq" "required" || MISSING=1
check_tool "node" "required" || MISSING=1
check_tool "gh" "recommended" || true
check_tool "gitleaks" "recommended" || true
check_tool "python3" "recommended" || true

if [ $MISSING -eq 1 ]; then
    echo ""
    echo "❌ 必須ツールが不足しています。インストールしてから再実行してください。"
    echo "   詳細: docs/getting-started.md"
    exit 1
fi

# --- Step 2: hook 実行権限 ---
echo ""
echo "🔧 [2/5] hook スクリプトに実行権限を付与..."
if [ -d .claude/hooks ]; then
    chmod +x .claude/hooks/*.sh 2>/dev/null || true
    chmod +x .claude/hooks/*.py 2>/dev/null || true
    echo "  ✅ .claude/hooks/ の実行権限を設定"
else
    echo "  ⚠️  .claude/hooks/ が見つかりません"
fi

if [ -d scripts ]; then
    chmod +x scripts/*.sh 2>/dev/null || true
fi
if [ -d .devcontainer ]; then
    chmod +x .devcontainer/*.sh 2>/dev/null || true
fi

# --- Step 3: .gitignore 確認 ---
echo ""
echo "🔒 [3/5] .gitignore のセキュリティチェック..."
REQUIRED_IGNORES=(
    ".env"
    ".claude/settings.local.json"
    "CLAUDE.local.md"
)
GITIGNORE_OK=1
for pattern in "${REQUIRED_IGNORES[@]}"; do
    if grep -qE "^${pattern//./\\.}\$|^${pattern//./\\.}$" .gitignore 2>/dev/null; then
        echo "  ✅ $pattern が gitignore 対象"
    else
        echo "  ⚠️  $pattern が gitignore に含まれていない可能性"
        GITIGNORE_OK=0
    fi
done

# --- Step 4: settings.local.json 雛形コピー ---
echo ""
echo "📝 [4/5] settings.local.json 雛形をコピー..."
if [ ! -f .claude/settings.local.json ] && [ -f .claude/settings.local.json.example ]; then
    cp .claude/settings.local.json.example .claude/settings.local.json
    echo "  ✅ .claude/settings.local.json を作成（gitignore 対象）"
else
    echo "  ⏭  既存ファイルあり、スキップ"
fi

# --- Step 5: 設定検証 ---
echo ""
echo "✅ [5/5] settings.json 検証..."
if jq empty .claude/settings.json 2>/dev/null; then
    echo "  ✅ settings.json は valid JSON"
else
    echo "  ❌ settings.json に JSON エラー"
    exit 1
fi

# --- 完了 ---
echo ""
echo "═══════════════════════════════════════════════"
echo "  ✨ セットアップ完了"
echo "═══════════════════════════════════════════════"
echo ""
echo "次のステップ:"
echo "  1. API キー設定（既に設定済みならスキップ）"
echo "     export ANTHROPIC_API_KEY=\"sk-ant-...\""
echo ""
echo "  2. Claude Code 起動"
echo "     claude"
echo ""
echo "  3. 動作確認: セッション内で以下を試す"
echo "     - SessionStart hook が context を出すか"
echo "     - 'rm -rf ~' を実行依頼 → ブロックされるか"
echo ""
echo "  4. GitHub リポジトリ設定"
echo "     - gh secret set ANTHROPIC_API_KEY"
echo "     - Branch protection 設定"
echo "     - .github/CODEOWNERS の <owner> を編集"
echo ""
echo "詳細: docs/getting-started.md"
