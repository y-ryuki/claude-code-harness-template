# ADR-0001: Record architecture decisions

- **Status**: accepted
- **Date**: 2026-05-16
- **Deciders**: テンプレート作者
- **Tags**: documentation, process

## Context and Problem Statement

ソフトウェアプロジェクトでは、後から「なぜこの技術を採用したのか」「なぜこの構造にしたのか」が分からなくなり、後継者や将来の自分が無駄に再検討するコストが発生する。

特に AI コーディングエージェントが関わる開発では、**意思決定の根拠を文書化** しないと、Claude/Codex が過去の決定と矛盾する提案をしてしまうリスクがある。

## Decision Drivers

- 軽量で書きやすい（Markdown のみ）
- ツールから参照しやすい（コードとリポジトリ内で管理）
- 標準化されている
- AI エージェントが context として読みやすい

## Considered Options

1. **MADR** (Markdown Architectural Decision Records)
2. **Lightweight ADR**（Michael Nygard の元祖形式）
3. **RFC 形式**（IETF 風の重量級）
4. **何もしない**

## Decision Outcome

**選ばれた選択肢**: **Option 1 (MADR)**

**理由**: MADR は軽量さと網羅性のバランスが良く、ツール対応（[adr-tools](https://github.com/npryce/adr-tools), [log4brains](https://github.com/thomvaill/log4brains)）も豊富。AI エージェントが読みやすい構造化された Markdown。

### Positive Consequences

- 過去の意思決定が辿れる
- 新メンバー/AI エージェントのオンボーディングが速い
- 同じ議論を繰り返さなくて済む
- `/adr` コマンドで簡単に起票できる

### Negative Consequences

- 書く手間が増える（軽量だが0ではない）
- メンテナンスを怠ると陳腐化する

## Implementation Notes

- 新規 ADR は `/adr "タイトル"` コマンドで起票
- 命名: `NNNN-kebab-case-title.md`
- Status の遷移ルールは [`README.md`](README.md) 参照

## Links

- [MADR Official](https://adr.github.io/madr/)
- [adr.github.io](https://adr.github.io/)
- [テンプレート](template.md)
