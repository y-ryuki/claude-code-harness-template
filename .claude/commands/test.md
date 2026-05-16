---
name: test
description: test-runnerエージェントでテストを実行し、失敗だけを抽出して原因分析を返す。
argument-hint: "[テストパス or パターン]"
allowed-tools: Read, Glob, Bash(npm run test *), Bash(npm test *), Bash(pnpm test *), Bash(pytest *), Bash(go test *), Bash(cargo test *)
---

# /test: テスト実行

scope: ${1:-all}

## やること

1. プロジェクトのテストランナーを判定
2. `test-runner` サブエージェントを起動
3. 失敗のみを抽出して報告

サブエージェント `test-runner` を起動し、以下を依頼してください:

- 引数があれば対象を絞ってテスト実行
- 失敗テストのみ抽出
- 各失敗に対して: エラーメッセージ / 推定原因 / 修正案
- フレーキーが疑われるテストには `[FLAKY?]` マーク

失敗があれば、続けて修正するか確認。
