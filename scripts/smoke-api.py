#!/usr/bin/env python3
"""Run validated loopback requests and publish status-only evidence."""
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from urllib.parse import urlsplit

METHODS = {"GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}
REPORT = Path(".smoke-results/api.md")


def valid_url_text(value):
    return isinstance(value, str) and not re.search(r"[\x00-\x20\x7f\\]", value)


def prepare_requests(config):
    if not isinstance(config, dict):
        raise ValueError
    base = config.get("baseUrl")
    if not valid_url_text(base):
        raise ValueError
    origin = urlsplit(base)
    if (origin.scheme not in ("http", "https")
            or origin.hostname not in ("localhost", "127.0.0.1")
            or origin.username is not None or origin.password is not None
            or "?" in base or "#" in base or origin.port == 0):
        raise ValueError
    requests = config.get("requests")
    if not isinstance(requests, list) or not requests:
        raise ValueError
    prepared = []
    for request in requests:
        if not isinstance(request, dict):
            raise ValueError
        path = request.get("path", "/")
        if (not valid_url_text(path) or not path.startswith("/")
                or path.startswith("//") or "#" in path):
            raise ValueError
        url = base.rstrip("/") + path
        target = urlsplit(url)
        if ((target.scheme, target.hostname, target.port)
                != (origin.scheme, origin.hostname, origin.port)
                or target.username is not None or target.password is not None):
            raise ValueError
        method = request.get("method", "GET")
        if not isinstance(method, str) or method.upper() not in METHODS:
            raise ValueError
        method = method.upper()
        expected = request.get("expectStatus", 200)
        if type(expected) is not int or not 100 <= expected <= 599:
            raise ValueError
        headers = request.get("headers", {})
        if not isinstance(headers, dict):
            raise ValueError
        args = [
            "curl", "-q", "-sS", "--globoff", "--no-location", "--max-redirs", "0",
            "--proto", "=http,https", "--noproxy", "*",
            "--max-time", "10", "--connect-timeout", "5",
            "--output", os.devnull, "-w", "%{http_code}", "-X", method,
        ]
        if method == "HEAD":
            args.append("--head")
        if target.hostname == "localhost":
            port = target.port or (443 if target.scheme == "https" else 80)
            args += ["--resolve", f"localhost:{port}:127.0.0.1"]
        for name, value in headers.items():
            if (not re.fullmatch(r"[!#$%&'*+.^_`|~0-9A-Za-z-]+", name)
                    or not isinstance(value, str) or re.search(r"[\x00-\x1f\x7f]", value)):
                raise ValueError
            args += ["-H", f"{name}: {value}"]
        body = request.get("body")
        if body is not None:
            body = body if isinstance(body, str) else json.dumps(body)
            if "\x00" in body:
                raise ValueError
            args += ["--data-raw", body]
        args.append(url)
        # Subprocess encodes argv only at execution time; validate every request now.
        for arg in args:
            os.fsencode(arg)
        prepared.append((args, method, expected))
    return prepared


def main():
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    # Replace stale success before parsing; never include untrusted config text.
    failure = "# API Smoke Results\n\nConfiguration error: no requests sent.\n"
    REPORT.write_text(failure)
    try:
        config_path = sys.argv[1] if len(sys.argv) > 1 else "tests/smoke/api.json"
        prepared = prepare_requests(json.loads(Path(config_path).read_text()))
        if not shutil.which("curl"):
            raise ValueError
    except (ValueError, TypeError, OSError):
        print(failure, end="")
        return 2
    lines = [
        "# API Smoke Results", "",
        f"- Timestamp: {datetime.now(timezone.utc).isoformat()}",
        "- Response bodies, headers, request data and curl errors are omitted.", "",
        "| # | Method | Expected | Actual | Result |",
        "|---|---|---|---|---|",
    ]
    passed = 0
    for index, (args, method, expected) in enumerate(prepared, 1):
        try:
            # Discard bodies inside curl and stderr at the process boundary.
            result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                    text=True, timeout=12)
            actual = result.stdout.strip()
            if result.returncode != 0 or not re.fullmatch(r"[1-5][0-9]{2}", actual):
                actual = "000"
        except (OSError, subprocess.TimeoutExpired):
            actual = "000"
        success = actual == str(expected)
        passed += int(success)
        lines.append(f"| {index} | {method} | {expected} | {actual} | {'PASS' if success else 'FAIL'} |")
    failed = len(prepared) - passed
    lines += ["", f"**Summary**: {passed} passed / {failed} failed", ""]
    report = "\n".join(lines)
    REPORT.write_text(report)
    print(report, end="")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
