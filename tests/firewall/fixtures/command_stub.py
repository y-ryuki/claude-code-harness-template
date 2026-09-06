#!/usr/bin/env python3
"""Simulate firewall/DNS/HTTP commands; never touch the host network."""

import ipaddress
import json
import os
from pathlib import Path
import sys


command = Path(sys.argv[0]).name
args = sys.argv[1:]
state_path = Path(os.environ["FIREWALL_STUB_STATE"])
log_path = Path(os.environ["FIREWALL_STUB_LOG"])
state = json.loads(state_path.read_text())
with log_path.open("a") as log:
    log.write(json.dumps({"command": command, "args": args, "policies": state}) + "\n")


def fail(message, code=2):
    print(f"[firewall test stub] {message}", file=sys.stderr)
    sys.exit(code)


if command in ("iptables", "ip6tables"):
    if os.environ.get("FIREWALL_STUB_FAIL") == f"{command} {' '.join(args)}":
        fail("simulated firewall command failure")
    if "-d" in args:
        destination = args[args.index("-d") + 1]
        try:
            network = ipaddress.ip_network(destination, strict=False)
        except ValueError:
            fail(f"invalid destination {destination}")
        family = 4 if command == "iptables" else 6
        if network.version != family:
            fail(f"IPv{network.version} destination passed to {command}")
    if "-P" in args:
        position = args.index("-P")
        state[command][args[position + 1]] = args[position + 2]
        state_path.write_text(json.dumps(state))
elif command == "getent":
    if os.environ.get("FIREWALL_STUB_DNS") == "failure":
        fail("simulated DNS lookup failure")
    if os.environ.get("FIREWALL_STUB_DNS") != "empty":
        print("192.0.2.10 STREAM test.invalid")
        print("192.0.2.10 DGRAM test.invalid")
elif command == "curl":
    mode = os.environ.get("FIREWALL_STUB_META", "mixed")
    if mode == "failure":
        fail("simulated metadata request failure", 22)
    if mode == "empty":
        sys.exit(0)
    if mode == "invalid":
        print("{invalid json")
    elif mode == "missing":
        print("{}")
    else:
        print(json.dumps({
            "web": ["192.30.252.0/22", "2a0a:a440::/29"],
            "api": ["140.82.112.0/20", "2606:50c0::/32"],
            "git": ["185.199.108.0/22", "2606:50c0::/32"],
        }))
else:
    fail(f"forbidden real command: {command}", 99)
