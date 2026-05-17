#!/usr/bin/env bash
# smoke-ui.sh — local UI smoke (Playwright with @smoke grep)
#
# Security & Safety:
#   - dev server を background 起動し trap で必ず cleanup
#   - 既存ポート使用中なら abort (孤児プロセスを誤って kill しない)
#   - DEV_CMD は eval せず space split (コマンドインジェクション防止)
#   - 全体 timeout で playwright をハング防止
#
# Env:
#   SMOKE_PORT     (default: 3000)
#   SMOKE_DEV_CMD  (default: "npm run dev")
#   SMOKE_TIMEOUT  (default: 120 秒、Playwright 全体)
#
# Exit codes:
#   0 = all passed
#   1 = some tests failed (結果は .smoke-results/ui.md に出力)
#   2 = setup error (port busy / server timeout / dev cmd not found)

set -euo pipefail
IFS=$'\n\t'

PORT="${SMOKE_PORT:-3000}"
DEV_CMD="${SMOKE_DEV_CMD:-npm run dev}"
TIMEOUT_SEC="${SMOKE_TIMEOUT:-120}"
WAIT_INTERVAL=2
WAIT_MAX=30
RESULTS_DIR=".smoke-results"
RESULTS_FILE="$RESULTS_DIR/ui.md"
DEV_LOG="$RESULTS_DIR/dev-server.log"

# === SECURITY: port は整数のみ許可 ===
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
  echo "❌ SECURITY: invalid SMOKE_PORT: '$PORT' (must be 1-65535)" >&2
  exit 2
fi

mkdir -p "$RESULTS_DIR"

# === SAFETY: port が既に LISTEN なら abort ===
if command -v lsof >/dev/null 2>&1; then
  if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "❌ SAFETY: port $PORT is already in use. Kill the existing process first." >&2
    lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >&2 || true
    exit 2
  fi
fi

# DEV_CMD を eval せず space split で配列化 (コマンドインジェクション対策)
read -ra DEV_ARGS <<< "$DEV_CMD"

if [ "${#DEV_ARGS[@]}" -eq 0 ]; then
  echo "❌ SMOKE_DEV_CMD is empty" >&2
  exit 2
fi

# dev cmd の最初の token が存在することを確認
if ! command -v "${DEV_ARGS[0]}" >/dev/null 2>&1; then
  echo "❌ command not found: ${DEV_ARGS[0]}" >&2
  exit 2
fi

echo "🚀 Starting dev server: ${DEV_ARGS[*]} (port $PORT)"
"${DEV_ARGS[@]}" > "$DEV_LOG" 2>&1 &
DEV_PID=$!

# === CLEANUP guarantee (trap で必ず kill) ===
cleanup() {
  local exit_code=$?
  if kill -0 "$DEV_PID" 2>/dev/null; then
    echo "🧹 Stopping dev server (pid $DEV_PID)"
    kill -TERM "$DEV_PID" 2>/dev/null || true
    # graceful → force escalation
    for _ in 1 2 3; do
      kill -0 "$DEV_PID" 2>/dev/null || break
      sleep 1
    done
    kill -KILL "$DEV_PID" 2>/dev/null || true
  fi
  exit "$exit_code"
}
trap cleanup EXIT INT TERM HUP

# サーバー起動を待つ
echo "⏳ Waiting for server on port $PORT (max $((WAIT_INTERVAL * WAIT_MAX))s)..."
ready=false
for i in $(seq 1 "$WAIT_MAX"); do
  if curl -sS --max-time 2 --proto '=http,https' "http://localhost:$PORT" >/dev/null 2>&1; then
    echo "✅ Server ready (attempt $i)"
    ready=true
    break
  fi
  # dev server が即死したら待たない
  if ! kill -0 "$DEV_PID" 2>/dev/null; then
    echo "❌ Dev server process died unexpectedly" >&2
    tail -n 30 "$DEV_LOG" >&2 || true
    exit 2
  fi
  sleep "$WAIT_INTERVAL"
done

if ! $ready; then
  echo "❌ Dev server did not start within $((WAIT_INTERVAL * WAIT_MAX))s" >&2
  echo "--- last 30 lines of $DEV_LOG ---" >&2
  tail -n 30 "$DEV_LOG" >&2 || true
  exit 2
fi

# Playwright smoke 実行 (timeout 付き)
echo "🎭 Running Playwright smoke (--grep @smoke)..."
PW_LOG="$RESULTS_DIR/playwright.log"
set +e
timeout "$TIMEOUT_SEC" npx playwright test \
  --config tests/e2e/playwright.config.ts \
  --grep "@smoke" \
  --reporter=list,json > "$PW_LOG" 2>&1
PW_EXIT=$?
set -e

# 結果整形
{
  echo "# 🎬 UI Smoke Results"
  echo ""
  echo "- **timestamp**: $(date -u +%FT%TZ)"
  echo "- **dev server**: \`${DEV_ARGS[*]}\` (port $PORT)"
  echo "- **filter**: \`@smoke\`"
  echo ""
} > "$RESULTS_FILE"

if [ -f tests/e2e/test-results.json ]; then
  PASSED=$(jq '.stats.expected // 0' tests/e2e/test-results.json)
  FAILED=$(jq '.stats.unexpected // 0' tests/e2e/test-results.json)
  SKIPPED=$(jq '.stats.skipped // 0' tests/e2e/test-results.json)
  FLAKY=$(jq '.stats.flaky // 0' tests/e2e/test-results.json)
  DURATION=$(jq '(.stats.duration // 0) / 1000 | floor' tests/e2e/test-results.json)
  {
    echo "| Metric | Count |"
    echo "|---|---|"
    echo "| ✅ Passed | $PASSED |"
    echo "| ❌ Failed | $FAILED |"
    echo "| ⏭ Skipped | $SKIPPED |"
    echo "| ⚠️ Flaky | $FLAKY |"
    echo "| ⏱ Duration | ${DURATION}s |"
  } >> "$RESULTS_FILE"
else
  {
    echo "_no test-results.json produced (検証用テストが無いか playwright がクラッシュ)_"
    echo ""
    echo "--- last 30 lines of playwright.log ---"
    echo '```'
    tail -n 30 "$PW_LOG" 2>/dev/null || true
    echo '```'
  } >> "$RESULTS_FILE"
fi

cat "$RESULTS_FILE"
exit "$PW_EXIT"
