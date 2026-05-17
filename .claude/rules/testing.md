---
description: Testing strategy — TDD, test pyramid, flaky test policy, prohibited patterns.
alwaysApply: true
---

# Testing

## Strategy

- **失敗するテストを先に書く** (TDD)
- **ユニット > 統合 > E2E** の比率を維持（テストピラミッド）
- カバレッジ目標より「変更頻度の高い箇所」を優先

## Test Quality

- テスト名は **「何を検証しているか」** を文章で表現（`should reject expired tokens`）
- **Arrange-Act-Assert** 構造を保つ（または Given-When-Then）
- テスト同士が独立（実行順序に依存しない・状態を共有しない）
- 1 テスト 1 振る舞い検証（複数アサーションは関連していることが明確な場合のみ）

## Flaky Tests

- フレーキーテストは発見次第 **即修正 or skip + Issue 化**
- 「再実行すれば通る」で放置しない — 数週間後にデバッグ困難になる
- 時刻・乱数・並行処理に依存するテストは固定化（freeze time / seed / 同期プリミティブ）

## Mocking

- 境界（外部 API, DB, ファイルシステム）のみ mock
- 自分のコードを mock するのは設計が悪いサイン
- mock の戻り値で「実装の存在を保証」するだけのテストを書かない

## E2E

| 用途 | ツール | エントリポイント |
|---|---|---|
| **回帰テスト** (CI) | Playwright | `npm run test:e2e` |
| **デバッグ** (ローカル) | Playwright | `npm run test:e2e:headed` / `:debug` |
| **レポート閲覧** | Playwright | `npm run test:e2e:report` |
| **アドホック操作** (Claude セッション内) | Claude in Chrome (MCP) | `mcp__Claude_in_Chrome__*` |

- 設定: [tests/e2e/playwright.config.ts](../../tests/e2e/playwright.config.ts)
- CI: [.github/workflows/e2e.yml](../../.github/workflows/e2e.yml)
- **PR への録画**: CI で `.webm` → `.gif` 変換、`e2e-snapshots` branch に push、PR コメントに **インライン表示**
- UI / frontend 変更時は **回帰テスト** と **手動スモーク** の両方を通す

## Prohibited Patterns

- NEVER skip tests without an Issue link（`// skip: see #123`）
- NEVER use `sleep()` / `setTimeout` to wait for async — proper sync primitive を使う
- NEVER assert on implementation details — public API / 振る舞いを検証
- NEVER share mutable state between tests (global vars, シングルトン汚染)
- NEVER commit code without running tests locally first
- NEVER use `if` in tests — 分岐は別テストに分離
- NEVER catch errors in tests just to make them green
