# Gemの取得元を指定（RubyGemsの公式リポジトリ）
source "https://rubygems.org"

# ===== Rails基本フレームワーク =====
gem "rails", "~> 7.2.2"           # Ruby on Railsフレームワーク本体

# ===== アセット管理・フロントエンド =====
gem "propshaft"                    # 静的ファイル（CSS/JS/画像）の配信ツール
gem "importmap-rails"              # ES6モジュールのインポート管理
gem "turbo-rails"                  # ページ高速化（SPA風の動作）
gem "stimulus-rails"               # JavaScriptフレームワーク
gem "jbuilder"                     # JSON API構築ツール

# ===== 認証機能 =====
gem "devise"                       # ユーザー認証システム（ログイン・新規登録など）

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

# ===== 開発・テスト環境専用 =====
group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"  # デバッグツール
  gem "brakeman", require: false                                        # セキュリティ脆弱性チェック
  gem "rubocop-rails-omakase", require: false                         # コード品質チェック
end

# ===== 開発環境専用 =====
group :development do
  gem "web-console"                # ブラウザ上でのデバッグコンソール
end

# ===== テスト環境専用 =====
group :test do
  gem "capybara"                   # ブラウザ操作の自動テスト
  gem "selenium-webdriver"         # Webブラウザ自動操作ドライバー
end
gem "tailwindcss-rails", "~> 4.3"
