# Requirements

要件定義書のディレクトリ。**ビジネス/プロダクト要件** を記録します。

## Spec との違い

| | Requirements | Spec |
|---|--------------|------|
| 観点 | **誰が・なぜ・何が嬉しい**（Who/Why/What） | **どう作るか**（How） |
| 主筆者 | プロダクトオーナー、企画 | エンジニア |
| 粒度 | 機能/エピック単位 | 機能/ストーリー単位 |
| 出口 | Spec への落とし込み | 実装 |
| Issue 紐付け | エピック Issue | 子 Issue |

## いつ書くか

- 大きな機能（エピック）を立ち上げるとき
- ステークホルダー間で合意を取る必要があるとき
- ペルソナ / ジョブストーリーを整理したいとき

## ファイル命名

```
docs/requirements/<topic-slug>.md
```

例:
- `dark-mode.md`
- `oauth-login.md`
- `team-collaboration.md`
