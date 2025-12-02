# ActionSpark - Claude Code 開発ガイド

このファイルはClaude Codeがプロジェクト全体を理解し、一貫性のある開発を行うための統括ドキュメントです。

## プロジェクト概要

- **プロジェクト名**: ActionSpark（アクションスパーク）
- **概要**: きっかけを行動に変える行動変革プラットフォーム
- **技術スタック**: Ruby on Rails 7.2.2 / PostgreSQL / Hotwire / Tailwind CSS

## クイックリファレンス

### タスク別ドキュメントマップ

| タスク | 参照ドキュメント |
|--------|------------------|
| 新機能の実装 | `01_technical_design/01_architecture.md`, `01_technical_design/02_database.md` |
| API実装 | `01_technical_design/03_api_design.md` |
| 画面実装 | `01_technical_design/04_screen_flow.md`, `02_design_system/` |
| テスト作成 | `01_technical_design/08_test_strategy.md` |
| スタイリング | `02_design_system/01_design_tokens.md`, `02_design_system/03_components.md` |
| Devise関連 | `03_library_guides/01_devise.md` |
| Hotwire実装 | `03_library_guides/02_hotwire.md` |
| 検索機能 | `03_library_guides/03_ransack.md` |
| 画像アップロード | `03_library_guides/04_carrierwave.md` |
| Git操作・PR作成 | `01_technical_design/10_git_workflow.md` |
| 設計決定の記録 | `04_adr/` |

## ドキュメント構成

```
.claude/
├── 00_project/
│   └── 01_appcadia_concept_requirements.md  # コンセプト・要件定義
├── 01_technical_design/
│   ├── 01_architecture.md                   # アーキテクチャ設計
│   ├── 02_database.md                       # データベース設計
│   ├── 03_api_design.md                     # API設計
│   ├── 04_screen_flow.md                    # 画面遷移
│   ├── 05_error_handling.md                 # エラーハンドリング
│   ├── 06_security.md                       # セキュリティ
│   ├── 07_performance.md                    # パフォーマンス
│   ├── 08_test_strategy.md                  # テスト戦略
│   ├── 09_ci_cd.md                          # CI/CD
│   └── 10_git_workflow.md                   # Gitワークフロー
├── 02_design_system/
│   ├── 01_design_tokens.md                  # デザイントークン
│   ├── 02_design_principles.md              # デザイン原則
│   ├── 03_components.md                     # コンポーネント設計
│   └── 04_layouts.md                        # レイアウトシステム
├── 03_library_guides/
│   ├── 01_devise.md                         # Devise実装パターン
│   ├── 02_hotwire.md                        # Hotwire実装パターン
│   ├── 03_ransack.md                        # Ransack実装パターン
│   └── 04_carrierwave.md                    # CarrierWave実装パターン
├── 04_adr/                                   # ADR（設計決定記録）
│   └── ADR-YYYYMMDD-xxx.md
└── 05_learning/                              # 学習記録
    └── YYYY-MM-DD-xxx.md
```

## 開発時の基本ルール

### コーディング規約

1. **Ruby**: RuboCopに従う（`.rubocop.yml`参照）
2. **命名規則**:
   - Model/Controller: CamelCase
   - メソッド/変数: snake_case
   - 定数: SCREAMING_SNAKE_CASE
3. **コメント**: 日本語可、複雑なロジックには必須

### Git運用

- **ブランチ戦略**: GitHub Flow
  - `main`: 本番環境
  - `feature/*`: 機能開発
  - `fix/*`: バグ修正
- **コミットメッセージ**: 日本語可、Conventional Commits推奨
  - `feat:` 新機能
  - `fix:` バグ修正
  - `refactor:` リファクタリング
  - `test:` テスト
  - `docs:` ドキュメント

### テスト

- **テストフレームワーク**: RSpec
- **カバレッジ目標**: 80%以上
- **必須テスト**:
  - Model: バリデーション、アソシエーション、スコープ
  - Controller: 各アクション、認証・認可
  - System: 主要ユーザーフロー

### セキュリティ

- 必ず`current_user`スコープを使用
- Strong Parametersを適切に設定
- Brakemanの警告をゼロに保つ

## 頻出コマンド

```bash
# 開発サーバー起動
docker compose up

# テスト実行
docker compose exec web rspec

# RuboCop実行
docker compose exec web rubocop

# マイグレーション
docker compose exec web rails db:migrate

# コンソール
docker compose exec web rails c
```

## 重要ファイルパス

| 種類 | パス |
|------|------|
| ルーティング | `config/routes.rb` |
| モデル | `app/models/` |
| コントローラー | `app/controllers/` |
| ビュー | `app/views/` |
| Stimulus | `app/javascript/controllers/` |
| スタイル | `app/assets/stylesheets/` |
| テスト | `spec/` |
| 国際化 | `config/locales/` |

## 注意事項

- 実装前に必ず関連ドキュメントを参照すること
- デザインシステムに定義されたカラー・スペーシングを使用すること
- 新規機能は必ずテストを作成すること
- セキュリティ関連の実装は`01_technical_design/06_security.md`を必ず参照

---

*最終更新: 2025-12-02*
