# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.0 (2026-05-16)


### Features

* **docdd:** add DocDD + autopilot + multi-review + Codex compat + merge prohibition ([40bfd06](https://github.com/y-ryuki/claude-code-harness-template/commit/40bfd06e9358c38edf0dda4dd7507dc8e3fe4926))
* **docdd:** add DocDD + autopilot + multi-review + Codex compat + merge prohibition ([c57fdad](https://github.com/y-ryuki/claude-code-harness-template/commit/c57fdad3761a3b3a8199484ac77c24543e2b5765))
* initial template release ([a1ce32a](https://github.com/y-ryuki/claude-code-harness-template/commit/a1ce32ad8abac727f52586c95e3b1bad14cc070d))
* **test:** add bats hook tests + Playwright E2E + PR video comments ([ea77680](https://github.com/y-ryuki/claude-code-harness-template/commit/ea77680657a1a9776f098d7010a918c36097f4a8))


### Bug Fixes

* **ci:** make E2E sample stable + gitleaks ignore test fixtures ([52f1595](https://github.com/y-ryuki/claude-code-harness-template/commit/52f159591893f7be84d88ce1d278dcf710780a11))
* **ci:** make workflows green on first run ([f231337](https://github.com/y-ryuki/claude-code-harness-template/commit/f2313376d7e443aec149d0e42c44c2b870c6e94a))

## [Unreleased]

### Added
- Initial template release
- 3-layer defense: Permissions + PreToolUse Hooks + Native Sandbox
- 6 sub-agents: code-reviewer, security-reviewer, test-runner, deep-researcher, knowledge-explorer, docs-writer
- 5 commands: /plan, /review, /test, /secure-audit, /deep-research
- 3 skills: pr-summary, commit-helper, changelog-update
- DevContainer with Node 20 + Python 3.12 + iptables firewall
- GitHub Action for @claude mention workflow
- Mobile development guide (Claude Code Web / Remote Control / GitHub Mobile)
- bats-core unit tests for all hooks (rm -rf, secrets, injection scanner)
- Playwright E2E sample (video recording, screenshots, HTML report)
- E2E workflow with auto PR comment (test stats + artifact links)
- Testing docs (`docs/testing.md`)
- **DocDD (Document-Driven Development)** structure: requirements / decisions (MADR ADR) / specs / architecture (C4)
- **5 additional review agents**: architecture / performance / accessibility / maintainability / ux
- **`/review-multi`**: 7-agent parallel review with integrated report
- **`/autopilot <issue#>`**: Issue → Spec → impl → test → review → PR (Merge excluded)
- **`/adr`**, **`/spec`**, **`/requirements`**: DocDD doc scaffolders
- **Merge prohibition (3-layer)**: settings deny + `block-merge.sh` hook + CLAUDE.md rule
- **Codex CLI compatibility**: `AGENTS.md` auto-sync + `.codex/config.toml.example` + agents-sync workflow
- **Unified naming conventions**: Issue/Branch/Commit/PR with bats validation tests
- audit.sh expanded to 24 checks

## [0.1.0] - 2026-05-16

- Initial commit
