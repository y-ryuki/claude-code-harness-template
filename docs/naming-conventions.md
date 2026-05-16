# Naming Conventions

このプロジェクトの **Issue / Branch / Commit / PR** の命名規約。**統一感** と **自動化** のために守ってください。

## 🎯 統一スキーマ

すべての名前は `<type>` をベースに統一されます:

| Type | 用途 | 例 |
|------|------|-----|
| `feat` | 新機能 | `feat: add dark mode toggle` |
| `fix` | バグ修正 | `fix: prevent null deref in login` |
| `docs` | ドキュメントのみ | `docs: update getting-started` |
| `refactor` | 動作変更なしの整理 | `refactor: extract auth helper` |
| `test` | テスト追加・修正 | `test: cover OAuth callback` |
| `chore` | ビルド設定・依存更新 | `chore: bump prettier to 3.4` |
| `perf` | パフォーマンス改善 | `perf: memoize header render` |
| `ci` | CI/CD 設定変更 | `ci: add coverage upload` |
| `style` | 整形のみ | `style: apply prettier` |
| `build` | ビルドツール | `build: switch to vite 5` |

---

## 1️⃣ Issue タイトル

```
<type>: <subject>
```

ルール:
- subject は **動詞始まり**（add / fix / remove / update / improve …）
- subject は **50文字以内**
- 末尾にピリオド `.` をつけない
- バックティック `` ` `` でコードを示してOK

✅ 良い例:
- `feat: add dark mode toggle to login`
- `fix: prevent null deref in session middleware`
- `docs: add Codex compatibility guide`

❌ 悪い例:
- `Dark mode のバグを直す` → type なし
- `feat: Implemented the new feature.` → 命令形でない、末尾ピリオド
- `feat: Added super cool dark mode that users will love because it's awesome` → 長すぎ

---

## 2️⃣ Branch 名

```
<type>/<issue#>-<slug>
```

ルール:
- `issue#` は数字のみ（`#` は付けない）
- `slug` は **ケバブケース**（小文字 + `-` 区切り）
- subject を slug 化（記号削除、空白を `-` に）

✅ 良い例:
- `feat/123-add-dark-mode-toggle`
- `fix/145-prevent-null-deref-session`
- `docs/200-update-getting-started`

❌ 悪い例:
- `darkmode` → type も issue# もない
- `feat-123-dark-mode` → 区切りが `/` でない
- `Feat/123/Dark_Mode` → ケースが揃ってない、`/` 多用

### Issue なし作業の例外

緊急 hotfix で issue を切れない場合のみ:

```
hotfix/<YYYYMMDD>-<slug>
```

例: `hotfix/20260516-revert-broken-deploy`

---

## 3️⃣ Commit メッセージ

[Conventional Commits](https://www.conventionalcommits.org/) 形式:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### header（必須）

```
<type>(<scope>): <subject>
```

- `<type>`: 上の type 一覧から
- `<scope>` (任意): 影響範囲を1単語（`auth`, `api`, `ui`, `hooks`, `e2e` 等）
- `<subject>`: Issue タイトルと **同じルール**

### body（任意・推奨）

- 72文字で改行
- **「なぜ」** を書く（「何を」はコードが語る）
- 1つ空行を空けて header の下に

### footer（任意）

- 関連 Issue: `Refs: #123`
- クローズ: `Closes #123`（PR本文にも書く）
- Breaking change: `BREAKING CHANGE: ...`
- 共著: `Co-Authored-By: Name <email>`

✅ 完全な例:

```
feat(auth): add OAuth2 PKCE flow for mobile clients

PKCE prevents authorization code interception attacks on mobile,
which is the primary use case after we removed implicit grant
in ADR-0007. Tests cover both happy path and verifier mismatch.

Refs: #142
Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## 4️⃣ PR タイトル & 本文

### タイトル

```
<type>(<scope>): <subject>
```

Issue タイトルとほぼ同じ形式。**Issue があれば「Issue タイトル + (#N)」が定石**:

✅ 良い例:
- `feat: add dark mode toggle to login (#123)`
- `fix(auth): prevent null deref in session middleware (#145)`

### 本文

[`pull_request_template.md`](../.github/pull_request_template.md) に従う。**必須項目**:

1. **概要**: 1-3行
2. **動機 + Issue リンク**: `Refs: #N` または `Closes #N`
3. **変更内容**: チェックリスト
4. **検証**: テスト・手動確認
5. **Breaking Changes**: あり / なし
6. **セキュリティへの影響**

### Closes vs Refs

- `Closes #N` / `Fixes #N`: PR マージで Issue を自動クローズ
- `Refs: #N`: 関連付けのみ（クローズしない）

---

## 5️⃣ ADR / Spec 命名

### ADR

```
docs/decisions/<NNNN>-<kebab-title>.md
```

- `NNNN`: 4桁連番（`0001` から）
- `kebab-title`: ケバブケース

例: `docs/decisions/0002-use-prisma-for-orm.md`

### Spec

```
docs/specs/<issue#>-<kebab-slug>.md
```

例: `docs/specs/123-dark-mode-toggle.md`

### Requirements

```
docs/requirements/<topic-slug>.md
```

例: `docs/requirements/dark-mode.md`

---

## 🤖 自動化されているもの

このテンプレでは以下が自動チェックされます:

| チェック | 実装場所 |
|---------|---------|
| Commit メッセージ形式 | `commit-helper` Skill |
| Branch 名形式 | `branch-from-issue` Skill |
| PR タイトル形式 | PR テンプレート |
| Conventional Commits → semver | `release-please.yml` |
| 命名規約の検証テスト | `tests/conventions/test_naming.bats` |

`/autopilot <issue#>` を使えば、これらすべて自動で正しい命名になります。

---

## 📚 参考

- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
