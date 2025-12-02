# アーキテクチャ設計

## 概要

ActionSparkはRuby on Rails 7.2.2を基盤とした、標準的なMVCアーキテクチャを採用しています。
YouTube動画から学びを行動に変えるプラットフォームとして、Hotwire（Turbo + Stimulus）によるモダンなフロントエンド体験と、Sidekiqによるバックグラウンド処理を実現しています。

## アーキテクチャ全体像

```
┌─────────────────────────────────────────────────────────┐
│                    クライアント層                         │
│  ブラウザ (Turbo Drive + Turbo Frames + Stimulus)        │
│  stimulus-autocomplete (検索補完)                        │
└─────────────────────┬───────────────────────────────────┘
                      │ HTTP/WebSocket
┌─────────────────────▼───────────────────────────────────┐
│                   アプリケーション層                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ Controllers │  │   Models    │  │   Views     │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                │                │             │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐     │
│  │  Concerns   │  │   Helpers   │  │  Mailers    │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                バックグラウンド処理層                     │
│  ┌─────────────┐  ┌─────────────────────┐              │
│  │   Sidekiq   │  │ sidekiq-scheduler   │              │
│  │   (Worker)  │  │ (定期実行ジョブ)      │              │
│  └─────────────┘  └─────────────────────┘              │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                     データ層                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ PostgreSQL  │  │    Redis    │  │ CarrierWave │     │
│  │  (メインDB)  │  │ (Sidekiq用) │  │  (画像)     │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
```

## ディレクトリ構造

```
app/
├── controllers/
│   ├── application_controller.rb    # 基底コントローラー
│   ├── posts_controller.rb          # 投稿管理 + オートコンプリート
│   ├── achievements_controller.rb   # 達成記録
│   ├── comments_controller.rb       # コメント
│   ├── likes_controller.rb          # いいね
│   ├── users_controller.rb          # ユーザープロフィール
│   ├── user_badges_controller.rb    # バッジ表示
│   ├── home_controller.rb           # ホーム
│   ├── pages_controller.rb          # 静的ページ
│   └── users/                       # Devise関連
│       └── omniauth_callbacks_controller.rb
├── models/
│   ├── application_record.rb
│   ├── user.rb
│   ├── post.rb                      # YouTube URL、達成管理
│   ├── achievement.rb
│   ├── comment.rb
│   ├── like.rb
│   ├── reminder.rb                  # リマインダー
│   └── user_badge.rb
├── views/
│   ├── layouts/
│   ├── posts/
│   │   ├── index.html.erb
│   │   ├── show.html.erb
│   │   ├── autocomplete.html.erb    # オートコンプリート候補
│   │   └── ...
│   ├── shared/                      # パーシャル
│   ├── devise/                      # 認証画面
│   └── reminder_mailer/             # リマインダーメール
├── mailers/
│   └── reminder_mailer.rb           # リマインダー通知
├── jobs/
│   └── send_reminders_job.rb        # リマインダー送信ジョブ
├── javascript/
│   └── controllers/                 # Stimulus コントローラー
│       └── application.js           # Autocomplete登録
├── helpers/
│   ├── application_helper.rb
│   ├── posts_helper.rb              # カテゴリ表示等
│   └── badges_helper.rb             # バッジ表示
└── assets/
    └── stylesheets/

config/
├── routes.rb
├── importmap.rb                     # stimulus-autocomplete
├── sidekiq.yml                      # Sidekiq設定
└── sidekiq_scheduler.yml            # 定期実行スケジュール
```

## レイヤー責務

### Controller層

- HTTPリクエストの受信とレスポンス
- パラメータのバリデーション（Strong Parameters）
- 認証・認可のチェック
- ビューのレンダリング

```ruby
# PostsController - YouTube投稿管理
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :autocomplete]
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to @post, notice: '投稿を作成しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # オートコンプリート検索
  def autocomplete
    query = params[:q].to_s.strip
    if query.length >= 2
      @suggestions = Post
        .where("trigger_content ILIKE :q OR action_plan ILIKE :q", q: "%#{query}%")
        .limit(10)
        .pluck(:trigger_content, :action_plan)
        .flatten.compact.uniq
        .select { |s| s.downcase.include?(query.downcase) }
        .first(10)
    else
      @suggestions = []
    end
    render layout: false
  end

  private

  def post_params
    params.require(:post).permit(
      :youtube_url, :trigger_content, :action_plan, :category,
      reminder_attributes: [:id, :remind_time, :_destroy]
    )
  end
end
```

### Model層

- ビジネスロジックの実装
- バリデーション
- アソシエーション
- スコープ
- YouTube関連メソッド

```ruby
class Post < ApplicationRecord
  belongs_to :user
  has_many :achievements, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_one :reminder, dependent: :destroy

  accepts_nested_attributes_for :reminder, allow_destroy: true

  validates :youtube_url, presence: true
  validates :trigger_content, presence: true, length: { maximum: 100 }
  validates :action_plan, presence: true, length: { maximum: 100 }

  scope :recent, -> { order(created_at: :desc) }

  # YouTube動画ID抽出
  def youtube_video_id
    # URLからVideo IDを抽出
  end

  # サムネイルURL取得
  def youtube_thumbnail_url(size: :mqdefault)
    "https://img.youtube.com/vi/#{youtube_video_id}/#{size}.jpg"
  end

  # 埋め込みURL取得
  def youtube_embed_url
    "https://www.youtube.com/embed/#{youtube_video_id}"
  end

  # 達成済みかどうか
  def achieved?
    achieved_at.present?
  end
end
```

### バックグラウンド処理層

リマインダー通知などの非同期処理を担当。

```ruby
# app/jobs/send_reminders_job.rb
class SendRemindersJob < ApplicationJob
  queue_as :default

  def perform
    current_time = Time.current.strftime("%H:%M")
    reminders = Reminder.where(remind_time: current_time)
                        .includes(:user, :post)

    reminders.each do |reminder|
      ReminderMailer.reminder_email(reminder).deliver_later
    end
  end
end
```

```yaml
# config/sidekiq_scheduler.yml
send_reminders:
  cron: '* * * * *'  # 毎分実行
  class: SendRemindersJob
  queue: default
```

### View層

- プレゼンテーションロジック
- Turbo Frames/Streamsの活用
- stimulus-autocompleteによる検索補完

```erb
<%# オートコンプリート付き検索フォーム %>
<div data-controller="autocomplete"
     data-autocomplete-url-value="<%= autocomplete_posts_path %>"
     data-autocomplete-min-length-value="2">
  <%= f.search_field :trigger_content_or_action_plan_cont,
        data: { autocomplete_target: "input" } %>
  <ul data-autocomplete-target="results" hidden></ul>
</div>
```

## 主要フロー

### 投稿作成フロー

```
1. ユーザーがYouTube URLを入力
2. フォームで trigger_content, action_plan, category を入力
3. オプションでリマインダー時刻を設定
4. PostsController#create で保存
5. Reminder も nested_attributes で同時作成
```

### リマインダー通知フロー

```
1. sidekiq-scheduler が毎分 SendRemindersJob を実行
2. 現在時刻と一致する remind_time を持つ Reminder を取得
3. 各リマインダーに対して ReminderMailer でメール送信
4. ユーザーがメールを受信し、投稿を確認
```

### オートコンプリートフロー

```
1. ユーザーが検索ボックスに2文字以上入力
2. stimulus-autocomplete が /posts/autocomplete?q=xxx にリクエスト
3. PostsController#autocomplete が候補を返却
4. ドロップダウンに候補を表示
5. 選択すると検索ボックスに反映
```

## 設計原則

1. **Fat Model, Skinny Controller**: ビジネスロジックはModelに
2. **DRY**: 重複コードはConcernやHelperに
3. **KISS**: シンプルさを保つ
4. **Convention over Configuration**: Rails規約に従う
5. **非同期処理の分離**: 時間のかかる処理はSidekiqへ

## 注意事項

- N+1問題を避けるため、`includes`を適切に使用
- コントローラーで直接モデルを操作せず、スコープを活用
- 複雑なクエリはスコープにまとめる
- リマインダー等の定期処理はSidekiqで実行
- YouTube URLのバリデーションを適切に実装

---

*最終更新: 2025-12-02*

*関連ドキュメント*: `02_database.md`, `03_api_design.md`, `../03_library_guides/05_sidekiq.md`
