# パフォーマンス設計

## 概要

ActionSparkのパフォーマンス目標と最適化戦略を定義します。

## パフォーマンス目標

| 指標 | 目標値 | 測定方法 |
|------|--------|----------|
| ページ読み込み時間（TTFB） | 200ms以下 | NewRelic / Render Metrics |
| First Contentful Paint | 1.5秒以下 | Lighthouse |
| Largest Contentful Paint | 2.5秒以下 | Lighthouse |
| Time to Interactive | 3秒以下 | Lighthouse |
| サーバーレスポンス | 100ms以下 | rails_performance |

## データベース最適化

### N+1問題の解決

```ruby
# 悪い例：N+1クエリ発生
def index
  @posts = Post.all
end
# ビューで @posts.each { |p| p.user.name } → N回のクエリ

# 良い例：includes使用
def index
  @posts = Post.includes(:user, :achievements, :likes, :comments)
               .recent
               .page(params[:page])
end
```

### Bullet Gemの導入

```ruby
# Gemfile (開発環境)
group :development do
  gem 'bullet'
end

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true
end
```

### インデックス設計

```ruby
# 頻繁に検索されるカラムにインデックス
class AddIndexesToPosts < ActiveRecord::Migration[7.2]
  def change
    add_index :posts, :category
    add_index :posts, :created_at
    add_index :posts, [:user_id, :created_at]
  end
end
```

### Counter Cache

```ruby
# app/models/achievement.rb
class Achievement < ApplicationRecord
  belongs_to :post, counter_cache: :achievement_count
end

# counter_cacheによりカウントクエリが不要になる
@post.achievement_count  # 追加クエリなし
```

### データベースレベルの最適化

```sql
-- PostgreSQL設定（本番環境）
-- shared_buffers = 256MB
-- effective_cache_size = 768MB
-- work_mem = 16MB
```

## フロントエンド最適化

### Asset Pipeline / Propshaft

```ruby
# config/environments/production.rb
config.assets.compile = false
config.assets.digest = true
config.assets.css_compressor = :sass
```

### Turbo / Hotwire活用

```erb
<%# 部分更新でページ全体の再読み込みを回避 %>
<%= turbo_frame_tag "posts" do %>
  <%= render @posts %>
<% end %>

<%# 遅延読み込み %>
<%= turbo_frame_tag "comments", src: post_comments_path(@post), loading: :lazy do %>
  <div class="animate-pulse">読み込み中...</div>
<% end %>
```

### 画像最適化

```ruby
# app/uploaders/image_uploader.rb
class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  # リサイズ
  version :thumb do
    process resize_to_fill: [100, 100]
  end

  version :medium do
    process resize_to_fit: [400, 400]
  end

  # WebP変換（対応ブラウザ向け）
  version :webp do
    process convert: 'webp'
  end

  # 品質調整
  process :optimize

  def optimize
    manipulate! do |img|
      img.strip
      img.quality '85'
      img
    end
  end
end
```

```erb
<%# 適切なサイズの画像を使用 %>
<%= image_tag @post.image.thumb.url, loading: 'lazy', class: 'thumbnail' %>
```

### CSS/JavaScript

```javascript
// app/javascript/application.js
// 必要なものだけimport
import "@hotwired/turbo-rails"
import "./controllers"

// 不要なimportは削除
```

```css
/* app/assets/stylesheets/application.tailwind.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* 未使用のCSSはpurge */
```

```javascript
// tailwind.config.js
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
  ],
  // ...
}
```

## キャッシュ戦略

### Fragment Cache

```erb
<%# app/views/posts/_post.html.erb %>
<% cache post do %>
  <div class="post-card">
    <%= post.trigger_content %>
    <%= post.action_plan %>
    <span><%= post.achievement_count %> 達成</span>
  </div>
<% end %>
```

### Russian Doll Caching

```erb
<%# app/views/posts/index.html.erb %>
<% cache ['posts', @posts.maximum(:updated_at)] do %>
  <% @posts.each do |post| %>
    <% cache post do %>
      <%= render post %>
    <% end %>
  <% end %>
<% end %>
```

### Redis Cache Store

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  expires_in: 1.hour
}
```

### HTTP Caching

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
    fresh_when @post
  end

  def index
    @posts = Post.recent.limit(20)
    expires_in 5.minutes, public: true
  end
end
```

## バックグラウンドジョブ

### Active Job設定

```ruby
# config/application.rb
config.active_job.queue_adapter = :sidekiq
```

### 重い処理の非同期化

```ruby
# app/jobs/image_process_job.rb
class ImageProcessJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find(post_id)
    post.image.recreate_versions! if post.image.present?
  end
end

# 使用
ImageProcessJob.perform_later(@post.id)
```

## ページネーション

### Kaminariの設定

```ruby
# config/initializers/kaminari_config.rb
Kaminari.configure do |config|
  config.default_per_page = 20
  config.max_per_page = 100
  config.window = 2
  config.outer_window = 1
end
```

### 無限スクロール

```erb
<%# app/views/posts/index.html.erb %>
<div id="posts" data-controller="infinite-scroll"
     data-infinite-scroll-url-value="<%= posts_path(format: :turbo_stream) %>">
  <%= render @posts %>
</div>

<%= turbo_frame_tag "pagination" do %>
  <%= paginate @posts %>
<% end %>
```

## モニタリング

### rails_performance Gem

```ruby
# Gemfile
gem 'rails_performance'

# config/initializers/rails_performance.rb
RailsPerformance.setup do |config|
  config.redis = Redis.new(url: ENV['REDIS_URL'])
  config.duration = 4.hours
  config.enabled = Rails.env.production?
end
```

### ログによる計測

```ruby
# 重い処理の計測
def heavy_operation
  result = nil
  time = Benchmark.measure do
    result = perform_operation
  end
  Rails.logger.info "[Performance] heavy_operation: #{time.real.round(3)}s"
  result
end
```

### アラート設定

```ruby
# 遅いクエリの検出
# config/environments/production.rb
config.active_record.warn_on_records_fetched_greater_than = 1000
```

## チェックリスト

### 実装時の確認項目

- [ ] `includes`でN+1を解消しているか
- [ ] 適切なインデックスが設定されているか
- [ ] Fragment Cacheを活用しているか
- [ ] 画像が適切にリサイズされているか
- [ ] 不要なアセットが読み込まれていないか

### リリース前の確認項目

- [ ] Bullet Gemで警告がないか
- [ ] Lighthouse スコアが目標値を満たしているか
- [ ] 本番環境でのレスポンス時間が目標値以内か

## パフォーマンス改善手順

1. **測定**: ボトルネックを特定
2. **分析**: 原因を調査
3. **改善**: 最適化を実施
4. **検証**: 効果を測定
5. **継続**: 定期的にモニタリング

---

*関連ドキュメント*: `01_architecture.md`, `02_database.md`, `09_ci_cd.md`
