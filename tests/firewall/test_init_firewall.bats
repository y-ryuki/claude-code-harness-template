#!/usr/bin/env bats
# Run the production script against command stubs: no sudo, HTTP, DNS, or firewall changes.

setup() {
    FIREWALL_SCRIPT="$BATS_TEST_DIRNAME/../../.devcontainer/init-firewall.sh"
    export FIREWALL_STUB_STATE="$BATS_TEST_TMPDIR/policies.json"
    export FIREWALL_STUB_LOG="$BATS_TEST_TMPDIR/commands.jsonl"
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cp "$BATS_TEST_DIRNAME/fixtures/command_stub.py" "$BATS_TEST_TMPDIR/bin/stub"
    chmod +x "$BATS_TEST_TMPDIR/bin/stub"
    local command
    for command in iptables ip6tables getent curl sudo ip ipset wget; do
        ln -s stub "$BATS_TEST_TMPDIR/bin/$command"
    done
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
    unset FIREWALL_STUB_FAIL FIREWALL_STUB_DNS FIREWALL_STUB_META
    python3 - <<'PY'
import json
import os
from pathlib import Path
policies = {tool: dict.fromkeys(("INPUT", "OUTPUT", "FORWARD"), "ACCEPT")
            for tool in ("iptables", "ip6tables")}
Path(os.environ["FIREWALL_STUB_STATE"]).write_text(json.dumps(policies))
Path(os.environ["FIREWALL_STUB_LOG"]).touch()
PY
}

run_firewall() {
    # Fail closed if a stub is ever accidentally absent from this test environment.
    local command
    for command in iptables ip6tables getent curl; do
        [ "$(command -v "$command")" = "$BATS_TEST_TMPDIR/bin/$command" ] || return 99
    done
    bash "$FIREWALL_SCRIPT"
}

assert_drop_policies() {
    python3 - <<'PY'
import json
import os
from pathlib import Path
state = json.loads(Path(os.environ["FIREWALL_STUB_STATE"]).read_text())
assert all(value == "DROP" for family in state.values() for value in family.values()), state
PY
}

assert_no_open_window() {
    python3 - <<'PY'
import json
import os
from pathlib import Path
events = [json.loads(line) for line in Path(os.environ["FIREWALL_STUB_LOG"]).read_text().splitlines()]
for event in events:
    args = event["args"]
    if "-P" in args:
        assert args[args.index("-P") + 2] == "DROP", event
    else:
        assert all(value == "DROP" for family in event["policies"].values()
                   for value in family.values()), event
PY
}

@test "firewall: mixed GitHub IPv4/IPv6 metadata succeeds with both families closed first" {
    run run_firewall
    [ "$status" -eq 0 ]
    assert_drop_policies
    assert_no_open_window
    python3 - <<'PY'
import json
import os
from pathlib import Path
events = [json.loads(line) for line in Path(os.environ["FIREWALL_STUB_LOG"]).read_text().splitlines()]
lookups = [event for event in events if event["command"] == "getent"]
assert lookups and all(event["args"][0] == "ahostsv4" for event in lookups), lookups
assert any(event["command"] == "iptables" and "192.30.252.0/22" in event["args"] for event in events)
for event in events:
    if event["command"] == "ip6tables" and "-A" in event["args"]:
        assert "lo" in event["args"], event
    if event["command"] == "iptables":
        assert not ("-t" in event["args"] and "nat" in event["args"]
                    and ("-F" in event["args"] or "-X" in event["args"])), event
for chain in ("INPUT", "OUTPUT"):
    assert any(event["command"] == "iptables" and chain in event["args"]
               and "--ctstate" in event["args"] and "ESTABLISHED" in " ".join(event["args"])
               for event in events), chain
request = next(event["args"] for event in events if event["command"] == "curl")
assert request[0] in ("-q", "--disable"), request
assert "--max-time" in request and "--connect-timeout" in request, request
assert "--fail" in request or any(arg.startswith("-") and not arg.startswith("--") and "f" in arg
                                  for arg in request), request
PY
}

@test "firewall: repeated initialization never opens default policies" {
    run run_firewall
    [ "$status" -eq 0 ]
    run run_firewall
    [ "$status" -eq 0 ]
    assert_drop_policies
    assert_no_open_window
}

@test "firewall: failed DNS lookup exits with DROP policies retained" {
    export FIREWALL_STUB_DNS=failure
    run run_firewall
    [ "$status" -ne 0 ]
    assert_drop_policies
    assert_no_open_window
}

@test "firewall: empty DNS lookup exits with DROP policies retained" {
    export FIREWALL_STUB_DNS=empty
    run run_firewall
    [ "$status" -ne 0 ]
    assert_drop_policies
    assert_no_open_window
}

@test "firewall: failed metadata request exits with DROP policies retained" {
    export FIREWALL_STUB_META=failure
    run run_firewall
    [ "$status" -ne 0 ]
    assert_drop_policies
    assert_no_open_window
}

@test "firewall: empty metadata exits with DROP policies retained" {
    export FIREWALL_STUB_META=empty
    run run_firewall
    [ "$status" -ne 0 ]
    assert_drop_policies
    assert_no_open_window
}

@test "firewall: malformed metadata exits with DROP policies retained" {
    export FIREWALL_STUB_META=invalid
    run run_firewall
    [ "$status" -ne 0 ]
    assert_drop_policies
    assert_no_open_window
}

@test "firewall: metadata missing GitHub ranges exits with DROP policies retained" {
    export FIREWALL_STUB_META=missing
    run run_firewall
    [ "$status" -ne 0 ]
    assert_drop_policies
    assert_no_open_window
}

@test "firewall: failed rule append exits with DROP policies retained" {
    export FIREWALL_STUB_FAIL='iptables -A OUTPUT -d 192.0.2.10 -p tcp --dport 443 -j ACCEPT'
    run run_firewall
    [ "$status" -ne 0 ]
    assert_drop_policies
    assert_no_open_window
}

@test "firewall: failed default-policy command aborts before flushing or external commands" {
    export FIREWALL_STUB_FAIL='iptables -P OUTPUT DROP'
    run run_firewall
    [ "$status" -ne 0 ]
    python3 - <<'PY'
import json
import os
from pathlib import Path
events = [json.loads(line) for line in Path(os.environ["FIREWALL_STUB_LOG"]).read_text().splitlines()]
assert events
for event in events:
    assert event["command"] in ("iptables", "ip6tables") and "-P" in event["args"], event
PY
}
