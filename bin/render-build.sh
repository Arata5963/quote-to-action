#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Starting build process..."

# Ruby と Bundler のバージョンを確認
echo "Ruby version: $(ruby -v)"
echo "Bundler version: $(bundle -v)"

# gems をインストール
echo "Installing gems..."
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install

# アセットをプリコンパイル
echo "Precompiling assets..."
bundle exec rails assets:precompile

# データベースマイグレーションを実行
echo "Running database migrations..."
bundle exec rails db:migrate

# SolidQueueのスキーマをロード（テーブルがない場合のみ）
echo "Loading SolidQueue schema..."
bundle exec rails db:schema:load:queue 2>/dev/null || echo "SolidQueue schema already loaded"

echo "Build completed successfully!"