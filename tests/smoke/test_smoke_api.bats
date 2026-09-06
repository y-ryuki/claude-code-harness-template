#!/usr/bin/env bats
# Security regressions. curl is always a recording stub: no network requests.

setup() {
    SMOKE_SCRIPT="${SMOKE_API_TEST_SCRIPT:-$BATS_TEST_DIRNAME/../../scripts/smoke-api.sh}"
    CASE_DIR=$(mktemp -d "$BATS_TEST_TMPDIR/api-smoke.XXXXXX")
    mkdir -p "$CASE_DIR/bin"
    export SMOKE_CURL_CALLS="$CASE_DIR/curl-calls.jsonl"
    export SMOKE_STUB_STATUS=200
    export SMOKE_STUB_EXIT=0
    export SMOKE_STUB_BODY='SYNTHETIC_RESPONSE_BODY'
    export SMOKE_STUB_STDERR=''
    cat > "$CASE_DIR/bin/curl" <<'PY'
#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

args = sys.argv[1:]
with open(os.environ["SMOKE_CURL_CALLS"], "a") as calls:
    calls.write(json.dumps(args) + "\n")

output_file = None
write_out = ""
for index, arg in enumerate(args):
    if arg in ("-o", "--output"):
        output_file = args[index + 1]
    elif arg.startswith("--output="):
        output_file = arg.split("=", 1)[1]
    elif arg in ("-w", "--write-out"):
        write_out = args[index + 1]

body = os.environ["SMOKE_STUB_BODY"]
if output_file is None or output_file == "-":
    sys.stdout.write(body)
elif output_file != "/dev/null":
    Path(output_file).write_text(body)

status = os.environ["SMOKE_STUB_STATUS"]
write_out = write_out.replace("%{http_code}", status)
write_out = write_out.replace("%{response_code}", status)
write_out = write_out.replace("%{time_total}", "0.012345")
write_out = write_out.replace("%{url_effective}", args[-1])
write_out = write_out.replace("\\n", "\n").replace("\\t", "\t")
sys.stdout.write(write_out)
sys.stderr.write(os.environ["SMOKE_STUB_STDERR"])
sys.exit(int(os.environ["SMOKE_STUB_EXIT"]))
PY
    chmod +x "$CASE_DIR/bin/curl"
    export PATH="$CASE_DIR/bin:$PATH"
    cd "$CASE_DIR"
}

write_config() {
    jq -n --arg base "$1" --argjson requests "$2" \
        '{baseUrl: $base, requests: $requests}' > config.json
}

assert_no_curl() {
    [ ! -s "$SMOKE_CURL_CALLS" ]
}

assert_not_reported() {
    [[ "$output" != *"$1"* ]] || return 1
    if [ -f .smoke-results/api.md ]; then
        ! grep -Fq -- "$1" .smoke-results/api.md
    fi
}

@test "rejects authority override before any earlier valid request is sent" {
    write_config 'http://localhost:3000' '[
        {"name":"valid first", "path":"/health", "headers":{"X-Test":"dummy"}, "body":"dummy"},
        {"name":"override", "method":"DELETE", "path":"@outside.invalid/delete", "headers":{"X-Test":"dummy"}, "body":"dummy"}
    ]'

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 2 ]
    assert_no_curl
}

@test "rejects external base URL without echoing credentials from it" {
    write_config 'https://outside.invalid/?token=SYNTHETIC_URL_SECRET' '[{"path":"/health"}]'

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 2 ]
    assert_no_curl
    assert_not_reported SYNTHETIC_URL_SECRET
}

@test "rejects base URL query and fragment delimiters before sending requests" {
    local base
    for base in 'http://localhost:3000?' 'http://localhost:3000/#'; do
        write_config "$base" '[{"path":"/health"}]'
        run bash "$SMOKE_SCRIPT" config.json
        [ "$status" -eq 2 ]
        assert_no_curl
    done
}

@test "accepts localhost and 127.0.0.1 paths and query strings with empty headers and body" {
    local base
    for base in 'http://localhost:3000' 'http://127.0.0.1:3000'; do
        write_config "$base" '[{"path":"/health?detail=full&limit=1", "expectStatus":200}]'

        run bash "$SMOKE_SCRIPT" config.json

        [ "$status" -eq 0 ]
        python3 - "$SMOKE_CURL_CALLS" "$base/health?detail=full&limit=1" <<'PY'
import json
import sys
calls = [json.loads(line) for line in open(sys.argv[1])]
assert calls[-1][-1] == sys.argv[2], calls[-1]
PY
    done
}

@test "sends method headers and literal body without curl config or redirects" {
    write_config 'http://localhost:3000' '[{
        "method":"POST", "path":"/items?source=smoke", "expectStatus":200,
        "headers":{"Content-Type":"application/json", "X-Test":"synthetic header"},
        "body":"{\"name\":\"@literal-file-name\"}"
    }]'

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 0 ]
    python3 - "$SMOKE_CURL_CALLS" <<'PY'
import json
import sys
calls = [json.loads(line) for line in open(sys.argv[1])]
assert len(calls) == 1, calls
args = calls[0]
assert args[0] == "-q", args
assert "--no-location" in args, args
assert args[args.index("--max-redirs") + 1] == "0", args
assert args[args.index("--noproxy") + 1] == "*", args
assert args[args.index("--proto") + 1] == "=http,https", args
assert args[args.index("--resolve") + 1] == "localhost:3000:127.0.0.1", args
assert not any(arg in args for arg in ("-L", "--location", "--location-trusted")), args
assert args[args.index("-X") + 1] == "POST", args
headers = [args[i + 1] for i, arg in enumerate(args) if arg in ("-H", "--header")]
assert "Content-Type: application/json" in headers, headers
assert "X-Test: synthetic header" in headers, headers
assert args[args.index("--data-raw") + 1] == '{"name":"@literal-file-name"}', args
assert args[-1] == "http://localhost:3000/items?source=smoke", args
PY
}

@test "never prints successful response bodies" {
    write_config 'http://localhost:3000' '[{"path":"/health", "headers":{"X-Test":"dummy"}, "body":"dummy"}]'

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 0 ]
    assert_not_reported SYNTHETIC_RESPONSE_BODY
}

@test "never prints failed response bodies or synthetic API keys" {
    export SMOKE_STUB_STATUS=500
    export SMOKE_STUB_BODY='{"message":"SYNTHETIC_RESPONSE_BODY sk-ant-api03-1234567890abcdefghijk"}'
    write_config 'http://localhost:3000' '[{"path":"/health", "headers":{"X-Test":"dummy"}, "body":"dummy"}]'

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 1 ]
    assert_not_reported SYNTHETIC_RESPONSE_BODY
    assert_not_reported sk-ant-api03-1234567890abcdefghijk
    [ -f .smoke-results/api.md ]
    grep -q '500' .smoke-results/api.md
}

@test "never prints curl error text or response headers" {
    export SMOKE_STUB_EXIT=7
    export SMOKE_STUB_STATUS=000
    export SMOKE_STUB_STDERR=$'SYNTHETIC_CURL_ERROR\nAuthorization: SYNTHETIC_HEADER_SECRET\n'
    write_config 'http://localhost:3000' '[{"path":"/health", "headers":{"X-Test":"dummy"}, "body":"dummy"}]'

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 1 ]
    assert_not_reported SYNTHETIC_CURL_ERROR
    assert_not_reported SYNTHETIC_HEADER_SECRET
    assert_not_reported SYNTHETIC_RESPONSE_BODY
}

@test "invalid JSON removes previous successful report and exits before curl" {
    mkdir -p .smoke-results
    printf '%s\n' 'STALE_SUCCESS_MARKER: 1 passed / 0 failed' > .smoke-results/api.md
    printf '%s\n' '{ invalid json SYNTHETIC_PARSE_SECRET' > config.json

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 2 ]
    assert_no_curl
    assert_not_reported STALE_SUCCESS_MARKER
    assert_not_reported SYNTHETIC_PARSE_SECRET
}

@test "rejects missing empty and non-array requests instead of reporting a pass" {
    local requests
    for requests in null '[]' '{}'; do
        write_config 'http://localhost:3000' "$requests"

        run bash "$SMOKE_SCRIPT" config.json

        [ "$status" -eq 2 ]
        assert_no_curl
    done
    printf '%s\n' '{"baseUrl":"http://localhost:3000"}' > config.json

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 2 ]
    assert_no_curl
}

@test "invalid later request is rejected before the valid first request executes" {
    write_config 'http://localhost:3000' '[
        {"path":"/health", "headers":{"X-Test":"dummy"}, "body":"dummy"},
        {"path":"/items", "method":"TRACE"}
    ]'

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 2 ]
    assert_no_curl
}

@test "keeps array query strings and braces literal instead of expanding extra requests" {
    write_config 'http://localhost:3000' '[{"path":"/items?ids[]=1&label={one,two}", "expectStatus":200}]'

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 0 ]
    python3 - "$SMOKE_CURL_CALLS" <<'PY'
import json
import sys
calls = [json.loads(line) for line in open(sys.argv[1])]
assert len(calls) == 1, calls
args = calls[0]
assert "--globoff" in args, args
assert args[-1] == "http://localhost:3000/items?ids[]=1&label={one,two}", args
PY
}

@test "never reports names URL queries request headers or request bodies" {
    export SMOKE_STUB_STATUS=500
    write_config 'http://localhost:3000' '[{
        "name":"SYNTHETIC_NAME_SECRET", "path":"/items?token=SYNTHETIC_QUERY_SECRET",
        "headers":{"Authorization":"Bearer SYNTHETIC_REQUEST_HEADER_SECRET"},
        "body":"SYNTHETIC_REQUEST_BODY_SECRET", "expectStatus":200
    }]'

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 1 ]
    assert_not_reported SYNTHETIC_NAME_SECRET
    assert_not_reported SYNTHETIC_QUERY_SECRET
    assert_not_reported SYNTHETIC_REQUEST_HEADER_SECRET
    assert_not_reported SYNTHETIC_REQUEST_BODY_SECRET
}

@test "serializes a JSON body and omits an explicitly null body" {
    write_config 'http://127.0.0.1:3000' '[
        {"path":"/items", "method":"POST", "body":{"items":[1,2],"enabled":false}},
        {"path":"/health", "body":null}
    ]'

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 0 ]
    python3 - "$SMOKE_CURL_CALLS" <<'PY'
import json
import sys
calls = [json.loads(line) for line in open(sys.argv[1])]
assert len(calls) == 2, calls
body = calls[0][calls[0].index("--data-raw") + 1]
assert json.loads(body) == {"items": [1, 2], "enabled": False}, body
assert not any(arg in calls[1] for arg in ("--data-raw", "--data", "-d")), calls[1]
PY
}

@test "rejects unencodable later request arguments before any curl call" {
    python3 - <<'PY'
import json
from pathlib import Path
Path("config.json").write_text(json.dumps({
    "baseUrl": "http://localhost:3000",
    "requests": [
        {"path": "/health"},
        {"path": "/items", "method": "POST", "body": "SYNTHETIC_" + chr(0xD800)},
    ],
}))
PY

    run bash "$SMOKE_SCRIPT" config.json

    [ "$status" -eq 2 ]
    assert_no_curl
    assert_not_reported Traceback
}
