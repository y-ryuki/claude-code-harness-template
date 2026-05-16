# Feature Specs

機能仕様書のディレクトリ。

## いつ書くか

- 新機能の実装前（**`/autopilot` が自動生成**）
- 既存機能の仕様を文書化したいとき
- API エンドポイント・データモデル・UI フローを設計するとき

## ファイル命名

```
docs/specs/<issue#>-<kebab-slug>.md
```

例:
- `123-dark-mode-toggle.md`
- `145-oauth2-pkce-flow.md`

## 書き方

[`template.md`](template.md) をベースに。

`/spec` コマンドで雛形を生成可能:

```
/spec 123 ダークモード切り替え
```

## ADR との違い

| | Spec | ADR |
|---|------|-----|
| 何を書く | **何を作るか**（What） | **なぜそうするか**（Why） |
| 粒度 | 機能単位 | 技術選定・設計判断単位 |
| Issue 紐付け | 必須 | 任意 |
| 数 | 多い（機能ごと） | 少ない（重要決定のみ） |
| 寿命 | 機能リリースまで | 永続（supersede されるまで） |
