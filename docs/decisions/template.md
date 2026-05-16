# ADR-NNNN: <タイトル>

- **Status**: proposed | accepted | rejected | deprecated | superseded by [ADR-NNNN](NNNN-xxx.md)
- **Date**: YYYY-MM-DD
- **Deciders**: <人物名 or チーム名>
- **Issue**: #<番号>（あれば）
- **Tags**: <カテゴリ、例: backend, security, performance>

## Context and Problem Statement

<どんな状況で、何が問題か。背景情報を含める。2-5段落。>

例: 認証フローの実装にあたって、セッション管理の方式を選定する必要がある。現状は Cookie ベースで実装されているが、モバイルアプリ連携を考えると JWT の検討も必要。

## Decision Drivers

判断にあたって重視する要素（順序は重要度順）:

- <要素1: 例「モバイル/SPA との互換性」>
- <要素2: 例「セキュリティ（XSS/CSRF耐性）」>
- <要素3: 例「実装・運用のシンプルさ」>
- <要素4: 例「スケーラビリティ」>

## Considered Options

検討した選択肢:

1. **Option A**: <選択肢1の名前>
2. **Option B**: <選択肢2の名前>
3. **Option C**: <選択肢3の名前>

## Decision Outcome

**選ばれた選択肢**: **Option X**

**理由**: <この選択肢を選んだ主要な理由を2-3文で>

### Positive Consequences

- <ポジティブな影響1>
- <ポジティブな影響2>

### Negative Consequences

- <ネガティブな影響1>
- <ネガティブな影響2>
- <受け入れたリスクや負債>

## Pros and Cons of Each Option

### Option A: <名前>

**Description**: <選択肢の説明>

**Pros**:
- <利点1>
- <利点2>

**Cons**:
- <欠点1>
- <欠点2>

### Option B: <名前>

(同上)

### Option C: <名前>

(同上)

## Implementation Notes

実装上の注意点や、移行計画があれば:

- <注意点1>
- <移行ステップ>

## Links

- Relates to: [ADR-NNNN](NNNN-xxx.md)
- Supersedes: [ADR-NNNN](NNNN-xxx.md)（あれば）
- External: <参考URL>
