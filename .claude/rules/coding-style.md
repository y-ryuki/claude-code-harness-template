---
description: Coding style — naming, comments, control flow, prohibited patterns.
alwaysApply: true
---

# Coding Style

## Naming

- **意図が伝わる名前** を優先（`tmp`, `data`, `flag`, `info`, `manager`, `helper`, `util` 等の汎用名 NG）
- 関数名は動詞句（`fetchUser`, `validateInput`）、変数名は名詞句（`userList`, `requestTimeout`）
- bool は `is`, `has`, `can`, `should`, `did` で始める（`isActive`, `hasPermission`）
- 略語は一般的なもののみ（`URL`, `ID`, `HTTP` は OK。`usrSvc`, `cfg` は NG）

## Constants

- マジックナンバーは定数化（時間・サイズ・上限値は特に）
- 同一文字列リテラルが 2 箇所以上で使われたら定数化
- 環境依存値（URL, パス, 認証情報）は環境変数か config に分離

## Control Flow

- エラーは **早期 return** で扱う（ネストを浅く保つ）
- ガード節を関数の先頭に書く
- ハッピーパスは関数の末尾に置く

## Comments

- コメントは **「なぜ」** を書く（「何を」はコードが語る）
- 自明な what コメントは書かない（`// increment i` のような）
- TODO/FIXME を残すなら **必ず Issue 番号** を併記（`// TODO(#123): ...`）
- コメントアウトでコードを残さない — git で取り戻せる

## Prohibited Patterns

- NEVER use `any` (TypeScript) / `Any` (Python) without justification comment
- NEVER write functions longer than ~50 lines — 分割を検討
- NEVER nest deeper than 3 levels — 早期 return / 関数抽出で平坦化
- NEVER duplicate logic in 3+ places — 抽象化を検討（ただし 2 箇所では抽象化しない）
- NEVER catch errors silently — `catch (e) {}` 禁止。最低でも log
- NEVER hardcode URLs, paths, credentials, magic strings
- NEVER leave commented-out code in commits
- NEVER use `console.log` / `print` for production logging — proper logger を使う
