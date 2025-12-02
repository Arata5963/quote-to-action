# Git ワークフロー

## 概要
機能追加・バグ修正時の標準Gitフローを定義します。

## ブランチ命名規則

| プレフィックス | 用途 | 例 |
|---------------|------|-----|
| `feature/` | 新機能追加 | `feature/autocomplete` |
| `fix/` | バグ修正 | `fix/login-error` |
| `chore/` | 設定変更・リファクタリング | `chore/update-deps` |

## コミットメッセージ形式

```
type: 説明

- 変更点1
- 変更点2
- 変更点3
```

### type の種類

| type | 説明 |
|------|------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `refactor` | リファクタリング |
| `docs` | ドキュメント |
| `test` | テスト |
| `chore` | 設定変更・その他 |

## 標準フロー手順

### 1. 作業開始前

```bash
# mainブランチを最新化
git checkout main
git pull origin main

# 作業ブランチを作成
git checkout -b feature/<機能名>
```

### 2. 作業完了後

```bash
# 変更をステージング
git add .

# コミット
git commit -m "feat: <機能の説明>

- 変更点1
- 変更点2
- 変更点3"

# リモートにプッシュ
git push -u origin feature/<機能名>
```

### 3. PR作成

```bash
gh pr create --title "feat: <機能名>" --body "## 概要
<変更内容の説明>

## 変更点
- 変更点1
- 変更点2

## テスト
- [ ] テストが通ること"
```

### 4. マージ後のクリーンアップ

```bash
# PRをマージ
gh pr merge --merge

# mainに戻る
git checkout main
git pull origin main

# ローカルブランチを削除
git branch -d feature/<機能名>

# リモートブランチを削除
git push origin --delete feature/<機能名>
```

## Claude Code への依頼テンプレート

機能実装完了後、以下のプロンプトを使用してください：

```
<機能名>の実装が完了しました。
.claude/01_technical_design/10_git_workflow.md に従ってGitフローを実行してください。
ブランチ名: feature/<機能名>
```

---

*最終更新: 2025-12-02*
