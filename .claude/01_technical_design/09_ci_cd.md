# CI/CD設計

## 概要

ActionSparkのCI/CDパイプライン設計を定義します。GitHub ActionsとRenderを使用します。

## CI/CDフロー

```
┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
│  Push   │ → │   CI    │ → │  Review │ → │  Deploy │
│         │   │  Tests  │   │   PR    │   │ (Render)│
└─────────┘   └─────────┘   └─────────┘   └─────────┘
```

## GitHub Actions設定

### ワークフロー構成

```
.github/
└── workflows/
    ├── ci.yml          # メインCI（テスト・Lint）
    └── security.yml    # セキュリティチェック
```

### メインCIワークフロー

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      redis:
        image: redis:7
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    env:
      RAILS_ENV: test
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/action_spark_test
      REDIS_URL: redis://localhost:6379/0

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'yarn'

      - name: Install dependencies
        run: |
          yarn install --frozen-lockfile
          bundle install

      - name: Setup database
        run: |
          bin/rails db:create
          bin/rails db:schema:load

      - name: Compile assets
        run: bin/rails assets:precompile

      - name: Run tests
        run: bundle exec rspec --format progress --format RspecJunitFormatter --out tmp/rspec_results.xml

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: tmp/rspec_results.xml

  lint:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: RuboCop
        run: bundle exec rubocop --parallel

      - name: ERB Lint
        run: bundle exec erblint --lint-all

  security:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Brakeman
        run: bundle exec brakeman --no-pager

      - name: bundler-audit
        run: |
          bundle exec bundler-audit check --update
```

### セキュリティワークフロー

```yaml
# .github/workflows/security.yml
name: Security

on:
  schedule:
    - cron: '0 0 * * 1'  # 毎週月曜日
  workflow_dispatch:

jobs:
  audit:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: bundler-audit
        run: bundle exec bundler-audit check --update

      - name: Create issue on failure
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: '[Security] Gem脆弱性が検出されました',
              body: 'bundler-auditで脆弱性が検出されました。\n詳細はActionsログを確認してください。'
            })
```

## Render設定

### render.yaml

```yaml
# render.yaml
services:
  - type: web
    name: action-spark
    env: ruby
    plan: free
    buildCommand: |
      bundle install
      yarn install
      bin/rails assets:precompile
      bin/rails db:migrate
    startCommand: bin/rails server
    healthCheckPath: /health
    envVars:
      - key: RAILS_MASTER_KEY
        sync: false
      - key: DATABASE_URL
        fromDatabase:
          name: action-spark-db
          property: connectionString
      - key: REDIS_URL
        fromService:
          name: action-spark-redis
          type: redis
          property: connectionString

databases:
  - name: action-spark-db
    databaseName: action_spark_production
    plan: free

redisServices:
  - name: action-spark-redis
    plan: free
```

### ヘルスチェックエンドポイント

```ruby
# config/routes.rb
get 'health', to: 'health#show'

# app/controllers/health_controller.rb
class HealthController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    ActiveRecord::Base.connection.execute('SELECT 1')
    render json: { status: 'ok' }, status: :ok
  rescue => e
    render json: { status: 'error', message: e.message }, status: :service_unavailable
  end
end
```

## デプロイフロー

### 自動デプロイ（main）

1. PRがmainにマージされる
2. GitHub ActionsでCIが実行される
3. CI成功後、Renderが自動デプロイ
4. マイグレーション実行
5. アセットコンパイル
6. サーバー起動

### 手動デプロイ

```bash
# Render CLIを使用
render deploy --service action-spark
```

## 環境変数管理

### 必須環境変数

| 変数名 | 説明 | 設定場所 |
|--------|------|----------|
| RAILS_MASTER_KEY | credentials復号化キー | Render |
| DATABASE_URL | PostgreSQL接続URL | Render (自動) |
| REDIS_URL | Redis接続URL | Render (自動) |
| GOOGLE_CLIENT_ID | Google OAuth | Render |
| GOOGLE_CLIENT_SECRET | Google OAuth | Render |
| AWS_ACCESS_KEY_ID | S3アクセス | Render |
| AWS_SECRET_ACCESS_KEY | S3アクセス | Render |
| AWS_REGION | S3リージョン | Render |
| AWS_BUCKET | S3バケット名 | Render |

### GitHub Secretsの設定

```
Settings > Secrets and variables > Actions > New repository secret
```

## ブランチ保護ルール

### mainブランチ

```yaml
# ブランチ保護設定
- Require a pull request before merging
  - Require approvals: 1
- Require status checks to pass before merging
  - Required checks: test, lint, security
- Require branches to be up to date before merging
- Do not allow bypassing the above settings
```

## モニタリング

### Renderダッシュボード

- デプロイ履歴
- ログ
- メトリクス（CPU、メモリ）
- アラート設定

### ログ確認

```bash
# Render CLI
render logs --service action-spark --tail

# または、Renderダッシュボードで確認
```

## ロールバック

### Renderでのロールバック

1. Renderダッシュボード > Deploys
2. 以前のデプロイを選択
3. "Rollback" をクリック

### データベースのロールバック

```bash
# 最新のマイグレーションを取り消す
bin/rails db:rollback

# 特定のバージョンまで戻す
bin/rails db:migrate:down VERSION=20251120000000
```

## トラブルシューティング

### CIが失敗する場合

1. GitHub Actionsのログを確認
2. ローカルで同じテストを実行
3. 環境変数の設定を確認

### デプロイが失敗する場合

1. Renderのログを確認
2. ビルドコマンドの実行結果を確認
3. 環境変数を確認
4. データベース接続を確認

### よくある問題

| 問題 | 原因 | 解決策 |
|------|------|--------|
| テスト失敗 | 依存関係の問題 | `bundle install`を確認 |
| アセットエラー | Node.js/Yarn | `yarn install`を確認 |
| DB接続エラー | DATABASE_URL | 環境変数を確認 |
| マイグレーション失敗 | スキーマ不整合 | `db:schema:load`を実行 |

## チェックリスト

### PRマージ前

- [ ] CIがすべてパスしている
- [ ] コードレビューが完了している
- [ ] マイグレーションファイルが含まれている場合、ロールバック可能か確認
- [ ] 環境変数の追加が必要な場合、Renderに設定済み

### デプロイ後

- [ ] ヘルスチェックが成功している
- [ ] 主要機能が動作している
- [ ] エラーログに問題がない

---

*関連ドキュメント*: `08_test_strategy.md`, `06_security.md`
