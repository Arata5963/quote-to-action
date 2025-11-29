# アーキテクチャ設計

## 概要

ActionSparkはRuby on Rails 7.2.2を基盤とした、標準的なMVCアーキテクチャを採用しています。

## アーキテクチャ全体像

```
┌─────────────────────────────────────────────────────────┐
│                    クライアント層                         │
│  ブラウザ (Turbo Drive + Turbo Frames + Stimulus)        │
└─────────────────────┬───────────────────────────────────┘
                      │ HTTP/WebSocket
┌─────────────────────▼───────────────────────────────────┐
│                   アプリケーション層                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ Controllers │  │   Models    │  │   Views     │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                │                │             │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐     │
│  │  Concerns   │  │   Helpers   │  │ ViewComponent│     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                     データ層                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ PostgreSQL  │  │    Redis    │  │  S3 (画像)   │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
```

## ディレクトリ構造

```
app/
├── controllers/
│   ├── application_controller.rb    # 基底コントローラー
│   ├── posts_controller.rb          # 投稿管理
│   ├── achievements_controller.rb   # 達成記録
│   ├── comments_controller.rb       # コメント
│   ├── likes_controller.rb          # いいね
│   └── users/                       # Devise関連
├── models/
│   ├── application_record.rb
│   ├── user.rb
│   ├── post.rb
│   ├── achievement.rb
│   ├── comment.rb
│   └── like.rb
├── views/
│   ├── layouts/
│   ├── posts/
│   ├── shared/                      # パーシャル
│   └── devise/                      # 認証画面
├── javascript/
│   └── controllers/                 # Stimulus コントローラー
├── helpers/
└── assets/
    └── stylesheets/
```

## レイヤー責務

### Controller層

- HTTPリクエストの受信とレスポンス
- パラメータのバリデーション（Strong Parameters）
- 認証・認可のチェック
- ビューのレンダリング

```ruby
# 良い例：シンプルで責務が明確
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to @post, notice: '投稿を作成しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def post_params
    params.require(:post).permit(:trigger_content, :action_plan, :category)
  end
end
```

### Model層

- ビジネスロジックの実装
- バリデーション
- アソシエーション
- スコープ
- コールバック

```ruby
# 良い例：モデルに適切なロジックを配置
class Post < ApplicationRecord
  belongs_to :user
  has_many :achievements, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy

  validates :trigger_content, presence: true, length: { maximum: 100 }
  validates :action_plan, presence: true, length: { maximum: 100 }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }

  def achieved_today_by?(user)
    achievements.exists?(user: user, achieved_on: Date.current)
  end
end
```

### View層

- プレゼンテーションロジック
- Turbo Frames/Streamsの活用
- パーシャルによる再利用

```erb
<%# 良い例：Turbo Frameでの部分更新 %>
<%= turbo_frame_tag dom_id(@post) do %>
  <div class="post-card">
    <%= render 'posts/content', post: @post %>
    <%= render 'posts/actions', post: @post %>
  </div>
<% end %>
```

## Concern設計

共通ロジックはConcernで切り出し、再利用性を高めます。

```ruby
# app/models/concerns/achievable.rb
module Achievable
  extend ActiveSupport::Concern

  included do
    has_many :achievements, dependent: :destroy
  end

  def total_achievements
    achievements.count
  end

  def achievement_badge
    case total_achievements
    when 0 then '☆'
    when 1 then '⭐'
    when 2 then '🔥'
    when 3 then '🏆'
    else '👑'
    end
  end
end
```

## Service Object（必要に応じて）

複雑なビジネスロジックはServiceオブジェクトに切り出します。

```ruby
# app/services/achievement_recorder.rb
class AchievementRecorder
  def initialize(user, post)
    @user = user
    @post = post
  end

  def call
    return { success: false, error: '本日は既に達成済みです' } if already_achieved_today?

    achievement = @post.achievements.create!(
      user: @user,
      achieved_on: Date.current
    )

    { success: true, achievement: achievement }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.message }
  end

  private

  def already_achieved_today?
    @post.achievements.exists?(user: @user, achieved_on: Date.current)
  end
end
```

## 設計原則

1. **Fat Model, Skinny Controller**: ビジネスロジックはModelに
2. **DRY**: 重複コードはConcernやHelperに
3. **KISS**: シンプルさを保つ
4. **Convention over Configuration**: Rails規約に従う

## 注意事項

- N+1問題を避けるため、`includes`を適切に使用
- コントローラーで直接モデルを操作せず、スコープを活用
- 複雑なクエリはスコープにまとめる
- Turbo Streams使用時はセキュリティに注意（broadcast先の制御）

---

*関連ドキュメント*: `02_database.md`, `03_api_design.md`
