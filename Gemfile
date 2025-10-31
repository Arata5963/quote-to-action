# Gemの取得元を指定（RubyGemsの公式リポジトリ）
source "https://rubygems.org"

# ===== Rails基本フレームワーク =====
gem "rails", "~> 8.1.1"           # Ruby on Railsフレームワーク本体

# ===== アセット管理・フロントエンド =====
gem "propshaft"                    # 静的ファイル（CSS/JS/画像）の配信ツール
gem "importmap-rails"              # ES6モジュールのインポート管理
gem "turbo-rails"                  # ページ高速化（SPA風の動作）
gem "stimulus-rails"               # JavaScriptフレームワーク
gem "jbuilder"                     # JSON API構築ツール

# ===== 認証機能 =====
gem "devise"                       # ユーザー認証システム（ログイン・新規登録など）
gem "omniauth-google-oauth2"              # （SNSログイン）
gem "omniauth-rails_csrf_protection"      # （セキュリティ）

# ===== データベース・サーバー =====
gem "pg", "~> 1.1"                # PostgreSQLデータベース接続
gem "puma", ">= 5.0"              # Webサーバー

# ===== OS依存ライブラリ =====
gem "tzinfo-data", platforms: %i[ windows jruby ]  # Windows/JRuby環境用のタイムゾーンデータ

# ===== パフォーマンス・バックグラウンド処理 =====
gem "solid_cache"                  # 高速キャッシュシステム
gem "solid_queue"                  # バックグラウンドジョブ処理
gem "solid_cable"                  # WebSocket通信（リアルタイム機能）
gem "bootsnap", require: false     # Rails起動高速化

# ===== 画像アップロード機能 =====
gem "carrierwave"                  # ファイルアップロード管理
gem "fog-aws"                      # AWS S3との連携
gem "mini_magick"                  # 画像リサイズ・変換処理
gem "kaminari", "~> 1.2"           # ページネーション機能
gem "ransack", "~> 4.0"            # 検索機能
gem "meta-tags"


# ===== 開発・テスト環境専用 =====
group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"  # デバッグツール
  gem "brakeman", require: false                                        # セキュリティ脆弱性チェック
  gem "rubocop-rails-omakase", require: false                         # コード品質チェック
  gem "bundler-audit", require: false
  gem "rspec-rails", "~> 7.1"           # RSpec 本体（Rails 統合）
  gem "factory_bot_rails", "~> 6.4"    # テストデータ作成（Fixture の代替）
  gem "faker", "~> 3.5"                # ダミーデータ生成
end

# ===== 開発環境専用 =====
group :development do
  gem "web-console"                # ブラウザ上でのデバッグコンソール
  gem "letter_opener_web", "~> 2.0"  # 開発環境でメールをブラウザで確認
  gem "ruby-lsp", require: false          # LSP本体
  gem "ruby-lsp-rails", require: false    # Rails向け拡張（ActiveRecordの推論が強くなる）
end

# ===== テスト環境専用 =====
group :test do
  gem "capybara"                   # ブラウザ操作の自動テスト
  gem "selenium-webdriver"         # Webブラウザ自動操作ドライバー
  gem "shoulda-matchers", "~> 6.4"
  gem "database_cleaner-active_record"
  gem "simplecov", require: false
  gem "webmock"
  gem "vcr"
end
gem "tailwindcss-rails", "~> 4.3"
