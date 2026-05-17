#!/usr/bin/env bash
# smoke-api.sh — local-only API smoke test runner
#
# Security:
#   - baseUrl は http(s)://localhost or http(s)://127.0.0.1 のみ
#   - レスポンス body のシークレット様パターンを自動 mask
#   - --max-time / --connect-timeout で必ずタイムアウト
#   - レスポンス body は最大 N 行で truncate
#   - redirect 追従無効 (--proto '=http,https')
#
# Usage:
#   bash scripts/smoke-api.sh [config.json]
#
# Exit codes:
#   0 = all passed
#   1 = some failed (結果は .smoke-results/api.md に出力)
#   2 = config error / security violation

set -euo pipefail
IFS=$'\n\t'

CONFIG="${1:-tests/smoke/api.json}"
RESULTS_DIR=".smoke-results"
RESULTS_FILE="$RESULTS_DIR/api.md"
TIMEOUT_SEC=10
CONNECT_TIMEOUT=5
MAX_BODY_LINES=20

mkdir -p "$RESULTS_DIR"

if [ ! -f "$CONFIG" ]; then
  echo "❌ smoke config not found: $CONFIG" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq is required but not installed" >&2
  exit 2
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "❌ curl is required but not installed" >&2
  exit 2
fi

BASE_URL=$(jq -r '.baseUrl // empty' "$CONFIG")

# === SECURITY: localhost / 127.0.0.1 only ===
if [ -z "$BASE_URL" ]; then
  echo "❌ SECURITY: baseUrl is empty in $CONFIG" >&2
  exit 2
fi

if ! echo "$BASE_URL" | grep -qE '^https?://(localhost|127\.0\.0\.1)(:[0-9]+)?(/.*)?$'; then
  echo "❌ SECURITY: baseUrl must be http(s)://localhost or http(s)://127.0.0.1" >&2
  echo "   got: '$BASE_URL'" >&2
  echo "❌ Refusing to make requests to external hosts." >&2
  exit 2
fi

# シークレットマスク
mask_secrets() {
  sed -E \
    -e 's/(Bearer )[A-Za-z0-9._\-]{8,}/\1***MASKED***/g' \
    -e 's/(sk-)[A-Za-z0-9]{16,}/\1***MASKED***/g' \
    -e 's/(AKIA)[A-Z0-9]{16,}/\1***MASKED***/g' \
    -e 's/(gh[pousr]_)[A-Za-z0-9_]{30,}/\1***MASKED***/g' \
    -e 's/(eyJ[A-Za-z0-9_-]{10,})\.[A-Za-z0-9_.-]+/\1.***MASKED***/g' \
    -e 's/("(api_?key|password|secret|token|client_secret|access_?token|refresh_?token)" *: *")[^"]+/\1***MASKED***/gi' \
    -e 's/(xox[abprs]-)[A-Za-z0-9-]+/\1***MASKED***/g'
}

# 結果ファイル初期化
{
  echo "# 📡 API Smoke Results"
  echo ""
  echo "- **baseUrl**: \`$BASE_URL\`"
  echo "- **timestamp**: $(date -u +%FT%TZ)"
  echo "- **config**: \`$CONFIG\`"
  echo ""
  echo "| # | Name | Method | Path | Expected | Actual | Result |"
  echo "|---|---|---|---|---|---|---|"
} > "$RESULTS_FILE"

pass=0
fail=0
idx=0
fail_details=""

while IFS= read -r req; do
  idx=$((idx + 1))
  name=$(echo "$req" | jq -r '.name // "(unnamed)"')
  method=$(echo "$req" | jq -r '.method // "GET"' | tr '[:lower:]' '[:upper:]')
  path=$(echo "$req" | jq -r '.path // "/"')
  expect=$(echo "$req" | jq -r '.expectStatus // 200')
  body=$(echo "$req" | jq -r '.body // empty')
  headers_json=$(echo "$req" | jq -c '.headers // {}')

  # method ホワイトリスト
  case "$method" in
    GET|HEAD|POST|PUT|PATCH|DELETE|OPTIONS) ;;
    *)
      echo "| $idx | \`$name\` | $method | \`$path\` | $expect | - | ❌ invalid method |" >> "$RESULTS_FILE"
      fail=$((fail + 1))
      continue
      ;;
  esac

  # ヘッダー組み立て (Authorization 等は smoke では使わない想定だが受ける)
  header_args=()
  while IFS= read -r line; do
    [ -n "$line" ] && header_args+=("-H" "$line")
  done < <(echo "$headers_json" | jq -r 'to_entries[] | "\(.key): \(.value)"')

  body_args=()
  if [ -n "$body" ]; then
    body_args+=("--data-raw" "$body")
  fi

  # curl 実行 (timeout / redirect 追従無効 / proto 制限)
  set +e
  response=$(curl -sS \
    --max-time "$TIMEOUT_SEC" \
    --connect-timeout "$CONNECT_TIMEOUT" \
    --proto '=http,https' \
    --no-keepalive \
    -X "$method" \
    "${header_args[@]}" \
    "${body_args[@]}" \
    -w '\n---STATUS---\n%{http_code}' \
    "$BASE_URL$path" 2>&1)
  curl_exit=$?
  set -e

  if [ $curl_exit -ne 0 ]; then
    status="000"
    resp_body="curl error (exit=$curl_exit): $(echo "$response" | head -n 3)"
  else
    status=$(echo "$response" | tail -n1)
    resp_body=$(echo "$response" | sed '/^---STATUS---$/,$d')
  fi

  if [ "$status" = "$expect" ]; then
    result="✅"
    pass=$((pass + 1))
  else
    result="❌"
    fail=$((fail + 1))
    body_summary=$(echo "$resp_body" | mask_secrets | head -n "$MAX_BODY_LINES")
    fail_details+=$'\n\n### ❌ #'"$idx $name"$'\n\n```\n'"$body_summary"$'\n```\n'
  fi

  echo "| $idx | \`$name\` | $method | \`$path\` | $expect | $status | $result |" >> "$RESULTS_FILE"

done < <(jq -c '.requests[]' "$CONFIG")

{
  echo ""
  echo "**Summary**: $pass passed / $fail failed"
  if [ -n "$fail_details" ]; then
    echo ""
    echo "## Failure details"
    echo "$fail_details"
  fi
} >> "$RESULTS_FILE"

cat "$RESULTS_FILE"

if [ "$fail" -gt 0 ]; then
  exit 1
fi
