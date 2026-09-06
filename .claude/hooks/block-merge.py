#!/usr/bin/env python3
"""Guard direct Git/gh commands; never execute the requested command."""
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys

PROTECTED = {"main", "master", "develop", "release"}
PUSH_FLAGS = {
    "-u", "--set-upstream", "-n", "--dry-run", "--porcelain",
    "-v", "--verbose", "-q", "--quiet", "--atomic", "--force-with-lease",
}
FEATURE_REF = r"(?:feat|fix|docs|refactor|test|chore|perf|ci|hotfix|style|build)/[A-Za-z0-9_./-]+"


def config_values(cwd, key):
    result = subprocess.run(
        ["git", "-C", str(cwd), "config", "--get-all", key],
        capture_output=True, text=True, timeout=3,
    )
    if result.returncode not in (0, 1):
        raise ValueError("Cannot verify the Git push configuration.")
    return result.stdout.splitlines()


def check_push(args, cwd, overridden, allow_shorthand):
    if overridden:
        raise ValueError("Push with environment/config overrides is not allowed.")
    positional = []
    options_done = False
    for arg in args:
        if arg == "--" and not options_done:
            options_done = True
        elif arg.startswith("-") and not options_done:
            if arg not in PUSH_FLAGS:
                raise ValueError("Bulk or ambiguous push options are not allowed.")
        else:
            positional.append(arg)
    if len(positional) < 2:
        raise ValueError("Specify a named remote and an explicit feature refspec.")
    remote, *refspecs = positional
    if not re.fullmatch(r"[A-Za-z0-9_.-]+", remote):
        raise ValueError("Use a named remote for guarded pushes.")
    for refspec in refspecs:
        if not re.fullmatch(r"[A-Za-z0-9_./~^:-]+", refspec):
            raise ValueError("Use a literal, non-forced feature refspec.")
        source, separator, destination = refspec.partition(":")
        if not source or ":" in destination:
            raise ValueError("Deletion or invalid refspec is not allowed.")
        if not separator:
            if not allow_shorthand:
                raise ValueError("Compound commands require an explicit source:destination.")
            if config_values(cwd, f"remote.{remote}.push"):
                raise ValueError("Configured mapping requires an explicit source:destination.")
            destination = source
        if destination.startswith("refs/heads/"):
            destination = destination[len("refs/heads/"):]
        elif destination.startswith("heads/"):
            destination = destination[len("heads/"):]
        if destination in PROTECTED or destination.startswith("release/"):
            raise ValueError("Pushing to protected branches is reserved for humans.")
        if not re.fullmatch(FEATURE_REF, destination):
            raise ValueError("Specify a literal feature-branch destination; symbolic refs are not allowed.")


def inspect(command, cwd, allow_shorthand=True):
    # Preserve conservative blocking inside shell wrappers and quoted snippets.
    if re.search(r"\bgh\s+pr\s+merge\b|\bgit\s+merge\b", command):
        raise ValueError("Merge is reserved for humans.")
    if re.search(r"\bgh\s+pr\s+review\b[^\n]*--approve", command):
        raise ValueError("AI agents must not approve PRs.")
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()\n")
    lexer.whitespace = " \t\r"
    lexer.whitespace_split = True
    segments, segment = [], []
    for token in lexer:
        if token and all(char in ";&|()\n" for char in token):
            if segment:
                segments.append(segment)
                segment = []
        else:
            segment.append(token)
    if segment:
        segments.append(segment)
    simple_command = len(segments) == 1 and allow_shorthand
    for words in segments:
        overridden = False
        while words and ("=" in words[0] or words[0] in ("env", "command", "--")):
            overridden = overridden or words[0] == "env" or "=" in words[0]
            words = words[1:]
        if not words:
            continue
        # Recognize literal shell -c scripts without evaluating their contents.
        if Path(words[0]).name in ("bash", "sh", "zsh", "dash", "ksh"):
            for index, option in enumerate(words[1:], 1):
                if option.startswith("-") and "c" in option and index + 1 < len(words):
                    inspect(words[index + 1], cwd, allow_shorthand=False)
                    break
        if words[0] == "eval":
            inspect(" ".join(words[1:]), cwd, allow_shorthand=False)
        # shlex is not a Bash AST. Scan literal git tokens even after then/do or
        # a comment, and require explicit destinations in nontrivial contexts.
        git_positions = [i for i, word in enumerate(words) if Path(word).name == "git"]
        for git_index in git_positions:
            check_git(words[git_index + 1:], cwd, overridden,
                      simple_command and git_index == 0)
        executable, *args = words
        if Path(executable).name == "gh" and args[:2] == ["pr", "merge"]:
            raise ValueError("PR merge is reserved for humans.")
        if Path(executable).name == "gh" and args[:2] == ["pr", "review"]:
            if "--approve" in args or "-a" in args:
                raise ValueError("AI agents must not approve PRs.")


def check_git(args, cwd, overridden, allow_shorthand):
    git_cwd = cwd
    while args and args[0].startswith("-"):
        option = args.pop(0)
        if option == "-C" and args:
            directory = args.pop(0)
            if re.search(r"[$`~]", directory):
                overridden = True
            git_cwd = (Path(git_cwd) / directory).resolve()
        elif option in ("-c", "--git-dir", "--work-tree", "--config-env"):
            overridden = True
            if args:
                args.pop(0)
        elif option not in ("--no-pager", "--paginate", "--literal-pathspecs"):
            overridden = True
    if not args:
        return
    if args[0] == "merge":
        raise ValueError("Git merge is reserved for humans.")
    if args[0] == "push":
        check_push(args[1:], git_cwd, overridden, allow_shorthand)


def main():
    try:
        payload = json.load(sys.stdin)
        command = payload.get("tool_input", {}).get("command", "")
        cwd = payload.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
        inspect(command, cwd)
    except (ValueError, TypeError, AttributeError, OSError, subprocess.SubprocessError) as error:
        reason = str(error) if isinstance(error, ValueError) else "Git guard failed; tool denied."
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse", "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }}))


if __name__ == "__main__":
    main()
