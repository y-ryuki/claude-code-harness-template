#!/usr/bin/env bats
# Exercise the registered Bash hooks, not only individual script entrypoints.

@test "configured Bash hooks deny a push to main through a feature refspec" {
    run python3 - "$BATS_TEST_DIRNAME/../.." <<'PY'
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys

root = Path(sys.argv[1]).resolve()
settings = json.loads((root / ".claude/settings.json").read_text())
payload = json.dumps({"cwd": str(root), "tool_name": "Bash",
                      "tool_input": {"command": "git push origin feat/123-fix:main"}})
denied = False
for group in settings["hooks"]["PreToolUse"]:
    if not re.fullmatch(group["matcher"], "Bash"):
        continue
    for hook in group["hooks"]:
        command = hook["command"].replace("${CLAUDE_PROJECT_DIR}", str(root))
        result = subprocess.run(shlex.split(command), input=payload, text=True,
                                capture_output=True, cwd=root)
        assert result.returncode in (0, 2), result.stderr
        decision = json.loads(result.stdout) if result.stdout.strip() else {}
        denied |= result.returncode == 2 or decision.get("hookSpecificOutput", {}).get("permissionDecision") == "deny"
assert denied, "Configured Bash hooks did not reject protected destination"
PY
    [ "$status" -eq 0 ]
}

@test "Git guard interpreter failure blocks the tool with exit 2" {
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    printf '%s\n' '#!/bin/sh' 'exit 1' > "$BATS_TEST_TMPDIR/bin/python3"
    chmod +x "$BATS_TEST_TMPDIR/bin/python3"
    run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" bash "$BATS_TEST_DIRNAME/../../.claude/hooks/block-merge.sh" <<< '{}'
    [ "$status" -eq 2 ]
}
