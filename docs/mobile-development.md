# Mobile Development — スマホからの開発フロー

このテンプレは **スマホ単独で開発が完結する** ことを目指して設計されています。本ドキュメントでは3軸のフローを詳しく解説します。

## 🎯 結論: どれを使えばいい？

| シーン | 推奨フロー |
|--------|-----------|
| 通勤中にちょっとした実装 | **A. Claude Code Web** |
| デスクトップ環境を活かしたい | **B. Remote Control** |
| 既存リポへの Issue 駆動開発 | **C. GitHub Mobile + @claude** |
| 緊急 hotfix | **C** が最速 |
| 新規プロジェクト立ち上げ | **A** が手軽 |

---

## 軸A: Claude Code Web（クラウド完結）

### 概要

[claude.ai/code](https://claude.ai/code) で動くクラウド版 Claude Code。Anthropic が管理する **隔離 VM** 上で実行され、ブラウザを閉じてもセッション継続。

### 必要なもの

- Claude.ai の Pro / Max / Team / Enterprise プラン（Research Preview）
- GitHub アカウント（リポ連携用）

### 制限（重要）

| 項目 | 値 |
|------|-----|
| CPU | 4 vCPU |
| RAM | 16GB |
| Disk | 30GB |
| `~/.claude/CLAUDE.md` | ❌ 利用不可 |
| ユーザー設定プラグイン | ❌ 利用不可 |
| `claude mcp add` | ❌ 利用不可 |
| AWS SSO 等の認証 | ❌ 利用不可 |
| `gh` CLI | ❌ プリインストールなし（setup script で追加可能） |

### 使い方

#### Step 1: ブラウザで開く

スマホで [claude.ai/code](https://claude.ai/code) を開いて、Claude.ai アカウントでログイン。

#### Step 2: リポを開く

GitHub OAuth 連携でこのリポを開く。

#### Step 3: 指示

自然言語で:
```
ログイン画面にダークモード切替ボタンを追加して
PR作成までやって
```

Claude が:
1. リポを VM 内で clone
2. コード変更
3. テスト実行
4. branch push
5. PR 作成

#### Step 4: PR を GitHub Mobile でレビュー

PR が作成されると GitHub Mobile の通知に届く（GitHub Mobile の Watching 設定が必要）。

#### Step 5: マージ

GitHub Mobile で diff 確認 → マージ。

### このテンプレでの制限への対応

**問題**: クラウド VM は `~/.claude/` を引き継がないため、ユーザーレベル設定が効かない。

**解決**: 本テンプレは **プロジェクトレベル**（`.claude/settings.json`, `.claude/hooks/`）に全設定を集約しているため、Web 版でも完全に動きます。

**問題**: `gh` CLI がプリインストールされていない。

**解決**: `.claude/hooks/session-context.sh` で `command -v gh` チェック + ない場合は警告メッセージ。必要なら setup script を作って初回に install する。

### コスト感

- セッション課金（Pro/Max プランの月額に含まれる範囲で使える）
- 長時間 idle で自動 sleep（料金節約）

---

## 軸B: Remote Control（ローカル遠隔操作）

### 概要

ローカルマシンの `claude` セッションを、スマホアプリ（iOS/Android）から **遠隔操作** する機能。コードはローカルに留まる。

### 必要なもの

- ローカルマシン（Mac/Linux/Windows）— **常時起動**
- Claude Code v2.0.60+
- Claude.ai モバイルアプリ
- 同一の Claude.ai アカウント

### 使い方

#### Step 1: ローカルで claude 起動

```bash
cd my-project
claude
```

#### Step 2: Remote Control を有効化

セッション内で:
```
/config
```

→ "Enable Remote Control for this session" を ON

または永続設定として `~/.claude/settings.json` に:
```json
{
  "remoteControl": {
    "enabled": true,
    "autoEnableOnStartup": true
  }
}
```

#### Step 3: セッション URL を取得

セッション内で表示される URL、または:
```bash
echo $CLAUDE_CODE_REMOTE_SESSION_ID
```

#### Step 4: スマホで開く

Claude.ai モバイルアプリでセッション URL を開く。

#### Step 5: 遠隔操作

スマホから:
- 承認 / 拒否
- 追加指示
- 進捗確認
- ファイル変更の確認

### メリット・デメリット

| メリット | デメリット |
|---------|-----------|
| コードがローカルに留まる（漏洩リスク低） | ローカルマシン常時起動が必要 |
| フル環境（`~/.claude/`, MCP 等が全部使える） | ネット切れで切断 |
| ホスト OS の認証情報を使える | スリープ復帰で再接続が必要なことがある |

### このテンプレでの利点

ローカルなのですべての hook + sandbox + DevContainer が完全に動作します。本テンプレを使う場合の **最高セキュリティ環境**。

---

## 軸C: GitHub Mobile + `@claude` Action

### 概要

Issue / PR のコメントで `@claude` とメンションすると、`anthropics/claude-code-action` が起動して自動実装。**スマホだけで完結** する Issue 駆動開発。

### 必要なもの

- GitHub Mobile アプリ（iOS/Android）
- `ANTHROPIC_API_KEY` を GitHub Secret に登録
- `.github/workflows/claude.yml`（本テンプレに同梱済み）

### セットアップ

#### Step 1: API キー登録

```bash
# デスクトップで一度だけ実行
gh secret set ANTHROPIC_API_KEY -b "sk-ant-..."
```

#### Step 2: Workflow が有効か確認

```bash
gh workflow list
# → "Claude Code" が表示されればOK
```

#### Step 3: GitHub Mobile アプリ設定

- 通知設定: Watching this repo
- 通知種別: Comments, PR reviews, Workflow runs

---

### 使い方

#### シナリオ A: スマホで Issue 作成 → 実装依頼

1. GitHub Mobile で **New Issue**
2. タイトル: `ダークモード切替の実装`
3. 本文:
   ```
   @claude

   ログイン画面にダークモード切替トグルを追加してほしい。
   - localStorageで保存
   - システム設定（prefers-color-scheme）をデフォルトに
   - Tailwind の dark: クラスを使う
   ```
4. Submit

→ `claude.yml` ワークフローが起動 → Claude が PR 作成

#### シナリオ B: PR レビューで修正依頼

1. GitHub Mobile で PR を開く
2. レビューコメントで:
   ```
   @claude このエラーハンドリング、try-catchじゃなくて
   Resultパターンで書き直して
   ```
3. Submit

→ Claude が PR にコミット追加

#### シナリオ C: 自動レビュー（push トリガー）

PR を opened/synchronize した時点で `.github/workflows/claude-review.yml` が自動レビュー。`@claude` メンション不要。

---

### セキュリティ規約（重要）

本テンプレの `claude.yml` は以下の制約付き:

```yaml
if: |
  (... author_association == 'OWNER' || == 'MEMBER' || == 'COLLABORATOR')
```

→ **OWNER / MEMBER / COLLABORATOR のみ** が `@claude` を起動可能。外部からの PR コメント経由の Prompt Injection を防止。

その他の規約:
- `permissions:` を最小限に絞り込み（`contents: write`, `pull-requests: write`, `issues: write`）
- `persist-credentials: false` で checkout
- `show_full_output: false` でセンシティブ情報の露出防止
- `pull_request_target` を使わない（信頼できない ref のチェックアウト回避）

### 制限

- GitHub Actions の **タイムアウト 30分** 以内に完了する必要あり
- リソースは GitHub runner 依存（ubuntu-latest: 2 vCPU / 7GB RAM / 14GB Disk）
- Action 実行ごとに **コスト** が発生（Actions 分数）

---

## 🎙️ 音声入力との組み合わせ

スマホの音声入力（iOS の Dictate / Android の Gboard）と組み合わせると、**ハンズフリー開発** が可能:

### 軸A での例

1. claude.ai/code を開く
2. プロンプト欄をタップ → 音声入力
3. 「ログイン画面にダークモード追加、PRまで作って」と話す
4. 送信

### 軸C での例

1. GitHub Mobile で Issue 開く
2. コメント欄で音声入力
3. 「@claude バグ修正お願い、エラーは ...」と話す

### Tips

- **短いプロンプト推奨**: 音声入力は長文だと誤認識が増える
- **専門用語は注意**: 「`useState`」「`async/await`」等は発音指示や `/plan` 経由で
- **CLAUDE.md に頻用パターン**: 「いつもの構成で」「いつものスタイルで」が通じる

---

## 📊 比較表

| 項目 | A: Claude Code Web | B: Remote Control | C: GitHub Mobile + Action |
|------|-------------------|------------------|--------------------------|
| セットアップ時間 | 5分 | 中 | 10分 |
| ローカルマシン必要 | ❌ | ✅（常時起動） | ❌ |
| コードの場所 | クラウド VM | ローカル | GitHub runner |
| `~/.claude/` 引き継ぎ | ❌ | ✅ | ❌ |
| MCP 利用 | ❌ | ✅ | ❌（要設定） |
| DevContainer | ❌ | ✅ | ❌ |
| コスト | プラン課金内 | プラン課金内 | Actions 分数 |
| 推奨度 | ★★★★★ | ★★★★☆ | ★★★★☆ |

---

## 🆘 トラブルシューティング

### Web 版で hook が動かない

`~/.claude/` は引き継がれないが、`.claude/` 配下はリポからコピーされるはず。`.claude/hooks/*.sh` の実行権限が落ちている可能性があるため、`postCreate` 等で `chmod +x` する。

### Remote Control が接続できない

```bash
# ローカル側でセッション ID 確認
echo $CLAUDE_CODE_REMOTE_SESSION_ID

# Claude.ai 認証が同じアカウントか確認
claude auth status
```

### GitHub Action がトリガーされない

- `@claude` メンションが正確か（`@Claude` や `@anthropic-claude` ではトリガーしない）
- author_association が OWNER/MEMBER/COLLABORATOR か
- `gh secret list` で `ANTHROPIC_API_KEY` 登録確認
- `gh run list` で実行履歴確認

---

## 📚 参考

- [Claude Code on the web (公式)](https://code.claude.com/docs/en/claude-code-on-the-web)
- [Remote Control (公式)](https://code.claude.com/docs/en/remote-control)
- [GitHub Actions (公式)](https://code.claude.com/docs/en/github-actions)
- [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action)
