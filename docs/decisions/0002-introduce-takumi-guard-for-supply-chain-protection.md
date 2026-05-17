# ADR-0002: Introduce Takumi Guard for supply chain protection

- **Status**: proposed
- **Date**: 2026-05-17
- **Deciders**: y-ryuki
- **Tags**: security, dependencies, supply-chain

## Context and Problem Statement

本テンプレートは AI コーディングエージェント (Claude Code) を前提とした開発ハーネスである。AI が自動で `npm install <pkg>` を実行するシナリオが構造的に存在するため、**供給チェーン攻撃 (typosquat / 悪性パッケージ / 乗っ取り)** のリスクが通常プロジェクトより高い。

現状の防御:

- `.claude/rules/deps.md` で `npm audit` 必須化 → 既知 advisory はカバーされるが、**advisory が出る前**の悪性パッケージは検出できない
- 危険コマンドの hooks ブロック → install そのものはブロックされない
- secret 読み取り deny → 流出経路は塞ぐが、悪性コードの実行はブロックしない

つまり「インストール後検出」はあるが「インストール前ブロック」が欠けている。

## Decision Drivers

1. **AI エージェントによる自動 install への防御** (最重要)
2. 既存ワークフローへの影響最小化
3. 設定の単純さ (1ファイルで完結)
4. 無料枠でカバーできること
5. 個人開発者でも導入可能 (アカウント作成不要)

## Considered Options

1. **Takumi Guard (shisho.dev)**: パッケージレジストリプロキシで悪性パッケージを 403 でブロック
2. **Socket.dev**: PR / CI 統合の依存スキャナ
3. **Snyk / GitHub Advanced Security**: 既知 advisory ベースの監査
4. **何もしない (現状維持)**: `npm audit` のみ

## Decision Outcome

**選ばれた選択肢**: **Option 1 (Takumi Guard)**

**理由**: インストール**前**の proactive ブロックを実現する唯一の選択肢。registry URL の差し替えだけで導入でき、メール認証トークン (`tg_anon_*`) で無料利用可能。AI エージェントが auto-install するシナリオに最もフィットする。

### Positive Consequences

- 悪性パッケージのインストールを 403 で物理的にブロック
- ダウンロード履歴に基づく事後通知 (advisory 公開時)
- npm/pnpm/yarn/pip/uv/poetry 横断で同一防御層
- 設定変更は registry URL のみで既存コードへの影響ゼロ
- 無料枠で必要機能をフルカバー

### Negative Consequences

- 外部サービス (shisho.dev / flatt.tech) への依存が増える
- registry プロキシ経由による微小なレイテンシ増
- トークン (`tg_anon_*` / `tg_org_*`) の管理責任が発生 → secret 扱い必須
- ブロックリスト網羅性は 100% ではない (補完防御の位置づけ)

## Pros and Cons of Each Option

### Option 1: Takumi Guard

**Description**: shisho.dev の registry proxy。`https://npm.flatt.tech/` 経由で install する。

**Pros**:
- インストール前ブロック (proactive)
- 設定が registry URL 1行のみ
- 無料 (メール認証で `tg_anon_*` 即時発行)
- マルチ言語対応 (npm/pip/poetry/uv 等)

**Cons**:
- 外部依存
- レイテンシ微増
- ブロックリスト依存 (未知の悪性 pkg は素通り)

### Option 2: Socket.dev

**Pros**: PR ベースの詳細スキャン、ふるまい解析もあり
**Cons**: GitHub PR フローへの統合が前提 → AI のローカル install では発動しない (本ユースケースに不適合)

### Option 3: Snyk / GHAS

**Pros**: 業界標準、advisory DB が広い
**Cons**: 既知 advisory ベース (出る前の悪性 pkg をブロックできない) → 現状の `npm audit` と同じ防御層

### Option 4: 現状維持

**Pros**: 何もしないコスト
**Cons**: AI 自動 install の固有リスクが未対処のまま

## Implementation Notes

### 適用範囲

- 本テンプレートの `package.json` に対して npm registry を Takumi Guard 経由に切替
- `.npmrc.example` を雛形として提供 (実トークンはコミットしない)
- `.npmrc` は `.gitignore` 対象 (token 流出防止)

### 導入手順 (人間が行う)

1. https://shisho.dev/ でメール認証して `tg_anon_*` トークン取得
2. `cp .npmrc.example .npmrc` してトークンを埋める
3. `npm install` で動作確認

### CI 対応 (将来)

CI 環境で `tg_org_*` (組織トークン / 有料) を使う場合は別 ADR で意思決定。当面はメール認証トークンで個人開発フローのみ保護。

### Security Notes

- `tg_*` トークンは **secret 扱い**。`.env*` 同様にコミット禁止
- `.gitignore` および hooks の deny ルールでカバー
- トークン漏洩時は shisho.dev コンソールで revoke

## Links

- External: [Takumi Guard 公式](https://shisho.dev/docs/ja/t/guard/)
- External: [Takumi Guard クイックスタート](https://shisho.dev/docs/ja/t/guard/quickstart/)
- External: [Takumi Guard 料金](https://shisho.dev/docs/ja/t/guard/billing/pricing)
- Relates to: [.claude/rules/deps.md](../../.claude/rules/deps.md)
