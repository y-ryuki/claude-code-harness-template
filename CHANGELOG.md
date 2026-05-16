# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
