# Requirements: <機能名 / エピック名>

- **Status**: draft | review | approved | in-progress | shipped
- **Owner**: <PM / プロダクトオーナー>
- **Created**: YYYY-MM-DD
- **Epic**: #<番号>
- **Related Specs**: [docs/specs/...]

## Vision

1段落で「これによって何が実現されるか」を語る。**ユーザー視点**。

> 例: ユーザーが自分の目の状態・好み・利用環境に合わせて UI のテーマを選べることで、長時間の利用でも快適にサービスを使える状態を実現する。

## Background / Context

なぜ今これをやるのか:

- 現状の課題: <例: ユーザーから「夜間使うと眩しい」というフィードバックが多い>
- 業界トレンド: <例: Apple/Google のシステムダークモードが普及、ユーザー期待が高い>
- ビジネス機会: <例: アクセシビリティ対応で B2G/B2B 案件の獲得>

## Target Users / Personas

| ペルソナ | 特徴 | このフィーチャーで得るもの |
|---------|------|-----------------------|
| 夜間利用者 | 22:00以降に主に利用 | 目の疲れ軽減 |
| 視覚過敏ユーザー | 明るい背景が苦手 | アクセシビリティ向上 |
| 開発者 | 日常的にダークモードを好む | 統一感、慣れた UI |

## Job Stories

```
When <situation>,
I want to <motivation>,
So I can <expected outcome>.
```

例:
1. **When** 夜間にスマホで使う、**I want to** UI を暗く、**So I can** 目の疲れを減らせる
2. **When** プロフィール設定する、**I want to** テーマを保存、**So I can** 毎回設定し直さなくて済む

## Success Metrics

定量指標:

| 指標 | 目標値 | 計測方法 |
|------|--------|---------|
| ダークモード採用率 | リリース後 30日で 20%+ | Analytics |
| ナイトタイム DAU | +5% | Analytics |
| アクセシビリティスコア | 90+ | Lighthouse |

## Scope

### In Scope（やる）

- ログイン画面のテーマ切替
- localStorage への永続化
- システム設定の尊重（初回のみ）

### Out of Scope（やらない）

- ❌ 個別カラーカスタマイズ（テーマ作成機能）
- ❌ サーバー側保存（クロスデバイス同期）
- ❌ 高コントラストモード（次のフェーズ）

## Constraints

- **デザイン**: 既存デザインシステムの semantic colors のみ使用
- **技術**: Tailwind の `dark:` クラス前提
- **法務**: WAI-ARIA / WCAG 2.1 AA 準拠必須
- **タイムライン**: 2 sprint 以内（4週）

## Risks and Open Questions

| リスク | 影響 | 対策 |
|--------|------|------|
| 既存スクショとの整合性が崩れる | Marketing と要調整 | リリース前にマーケに通知 |
| サードパーティウィジェットがダーク対応してない | UX劣化 | 段階リリース・該当箇所をライト固定 |

### Open Questions

- [ ] アイコンセットがダークモードに耐えるか確認
- [ ] PWA のスプラッシュは別途対応が必要か

## Stakeholders

| Role | Name | Approval Required |
|------|------|------------------|
| PM | <name> | ✅ |
| Design Lead | <name> | ✅ |
| Eng Lead | <name> | ✅ |
| Legal | <name> | ⚠️ Accessibility のみ |

## Decisions Log

意思決定の履歴。詳細は ADR へ:

- 2026-05-16: テーマ実装方式に Tailwind `dark:` クラスを採用 → [ADR-0002](../decisions/0002-xxx.md)
- ...

## Implementation Plan

1. **Phase 1**: ログイン画面のみ（このリリース）
2. **Phase 2**: アプリ全体に拡張
3. **Phase 3**: 高コントラストモード
