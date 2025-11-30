# 学習日記: リマインダー機能の実装

**日付**: 2025年11月30日
**所要時間**: 約2時間
**難易度**: ★★★☆☆（中級）

---

## 1. 今日やったこと

投稿ごとにリマインダー時刻を設定し、毎日その時刻にメール通知を送る機能を実装した。

### 実装フェーズ一覧

| Phase | 内容 | 主な作業 |
|-------|------|----------|
| 1 | 環境構築 | Sidekiq, Redis, sidekiq-schedulerの導入 |
| 2 | DBマイグレーション | remindersテーブルの変更 |
| 3 | モデル層 | Reminder, Post, Userモデルの関連付け |
| 4 | メール機能 | ReminderMailerとビューの作成 |
| 5 | ジョブ実装 | ReminderCheckJobの作成 |
| 6 | UI実装 | フォームと詳細画面の更新 |
| 7 | テスト | RSpec各種スペックの作成 |

### 作成・変更したファイル一覧

```
【新規作成】
├── config/
│   ├── sidekiq.yml                    # Sidekiq設定
│   └── initializers/sidekiq.rb        # Redis接続設定
├── app/
│   ├── jobs/reminder_check_job.rb     # 毎分実行ジョブ
│   ├── mailers/reminder_mailer.rb     # メーラー
│   └── views/reminder_mailer/
│       ├── daily_reminder.html.erb    # HTMLメール
│       └── daily_reminder.text.erb    # テキストメール
├── db/migrate/
│   └── 20251130122658_modify_reminders_for_post_reminders.rb
├── spec/
│   ├── factories/reminders.rb
│   ├── models/reminder_spec.rb
│   ├── mailers/reminder_mailer_spec.rb
│   └── jobs/reminder_check_job_spec.rb
└── docs/adr/ADR-20251130-reminder-feature.md

【変更】
├── Gemfile                            # sidekiq追加
├── docker-compose.yml                 # redis, sidekiqサービス追加
├── config/
│   ├── application.rb                 # タイムゾーン、ActiveJob設定
│   ├── routes.rb                      # Sidekiq Web UI追加
│   └── locales/ja.yml                 # i18nキー追加
├── app/models/
│   ├── reminder.rb                    # 大幅更新
│   ├── post.rb                        # has_one :reminder追加
│   └── user.rb                        # has_many :reminders追加
├── app/controllers/posts_controller.rb
├── app/views/posts/
│   ├── _form.html.erb                 # リマインダーフィールド追加
│   └── show.html.erb                  # リマインダー状態表示追加
└── spec/requests/posts_spec.rb        # リマインダーテスト追加
```

---

## 2. 学んだ技術・概念

### Sidekiq / Redis / sidekiq-scheduler の役割

```
┌─────────────────────────────────────────────────────────────────┐
│                        全体の流れ                               │
└─────────────────────────────────────────────────────────────────┘

     ユーザー                    Webサーバー                Sidekiq
        │                           │                        │
        │   投稿作成リクエスト      │                        │
        │ ─────────────────────────>│                        │
        │                           │                        │
        │                           │ DBに保存               │
        │                           │─────────┐              │
        │                           │         │              │
        │                           │<────────┘              │
        │                           │                        │
        │   レスポンス              │                        │
        │ <─────────────────────────│                        │
        │                           │                        │
        │                           │                        │
                                                             │
     ┌───────────────────────────────────────────────────────┘
     │  毎分、sidekiq-schedulerがReminderCheckJobを起動
     ▼
┌──────────────────────────────────────────────────────────────┐
│  ReminderCheckJob                                            │
│  ├─ 現在時刻を取得（例: 08:00）                              │
│  ├─ remind_time = 08:00 のReminderをDBから検索              │
│  ├─ 達成済み投稿は除外                                       │
│  └─ 該当するReminderごとにメール送信をキューに追加           │
└──────────────────────────────────────────────────────────────┘
                    │
                    ▼
            ┌───────────────┐
            │    Redis      │  ← ジョブのキュー（待ち行列）を管理
            │  （メモリDB）  │
            └───────────────┘
                    │
                    ▼
            ┌───────────────┐
            │   Sidekiq     │  ← Redisからジョブを取り出して実行
            │  （ワーカー）  │
            └───────────────┘
                    │
                    ▼
            メール送信完了
```

#### 各コンポーネントの役割

| コンポーネント | 役割 | 例え |
|----------------|------|------|
| **Redis** | ジョブを一時的に保管するメモリDB | 「注文票を入れる箱」 |
| **Sidekiq** | Redisからジョブを取り出して実行するワーカー | 「注文を処理するシェフ」 |
| **sidekiq-scheduler** | 定期的にジョブをキューに追加 | 「毎分注文を出すタイマー」 |

### ActiveJob のアダプタ設定

```ruby
# config/application.rb
config.active_job.queue_adapter = :sidekiq
```

**なぜこれが必要？**

ActiveJobはRailsの「ジョブ処理の共通インターフェース」。バックエンド（実際にジョブを処理する仕組み）を差し替え可能にしている。

```
ActiveJob（共通API）
    │
    ├── :async      ← 開発用（メモリ内で即実行）
    ├── :sidekiq    ← 本番用（Redis + ワーカー）
    ├── :solid_queue ← Rails 8標準
    └── :delayed_job ← 古い選択肢
```

### ネステッドアトリビュート（accepts_nested_attributes_for）

親モデルのフォームから子モデルを一緒に作成・更新する仕組み。

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  has_one :reminder, dependent: :destroy
  accepts_nested_attributes_for :reminder, allow_destroy: true, reject_if: :all_blank
end
```

#### オプションの意味

| オプション | 効果 |
|------------|------|
| `allow_destroy: true` | `_destroy: "1"` を送ると子レコードを削除 |
| `reject_if: :all_blank` | 全項目が空なら子レコードを作成しない |

#### フォームでの使い方

```erb
<%= form.fields_for :reminder do |reminder_form| %>
  <%= reminder_form.time_field :remind_time %>
  <%= reminder_form.check_box :_destroy %>  <%# 削除用チェックボックス %>
<% end %>
```

#### コントローラーでの許可

```ruby
def post_params
  params.require(:post).permit(
    :trigger_content, :action_plan,
    reminder_attributes: [:id, :remind_time, :_destroy]  # ネストしたパラメータ
  )
end
```

### ActionMailer の使い方

```ruby
# app/mailers/reminder_mailer.rb
class ReminderMailer < ApplicationMailer
  def daily_reminder(reminder)
    @reminder = reminder
    @user = reminder.user
    @post = reminder.post

    mail(
      to: @user.email,
      subject: I18n.t("reminder_mailer.daily_reminder.subject")
    )
  end
end
```

**ポイント**:
- メソッド名がメールのアクション名になる
- `@変数` はビュー（`.html.erb`, `.text.erb`）で使える
- `mail()` でメールを構築して返す

### Docker Compose でのマルチコンテナ構成

```yaml
# docker-compose.yml
services:
  web:           # Railsアプリ
    depends_on:
      - db
      - redis    # Redisが起動してからwebを起動

  db:            # PostgreSQL
    image: postgres:15

  redis:         # Redis（Sidekiq用）
    image: redis:7-alpine

  sidekiq:       # Sidekiqワーカー
    command: bundle exec sidekiq -C config/sidekiq.yml
    depends_on:
      - db
      - redis
```

**`depends_on` の意味**:
「このサービスが起動する前に、指定したサービスを先に起動してね」という指示。

---

## 3. 重要なコードと解説

### 3.1 Reminderモデルのスコープ

```ruby
# app/models/reminder.rb

# 指定時刻（HH:MM）に該当するリマインダーを取得
scope :at_time, ->(time) {
  where(remind_time: time.beginning_of_minute..time.end_of_minute)
}

# 達成済みでない投稿のリマインダーのみ
scope :active, -> {
  joins(:post).where(posts: { achieved_at: nil })
}

# 送信対象（指定時刻かつアクティブ）
scope :sendable_at, ->(time) { at_time(time).active }
```

**なぜ `beginning_of_minute..end_of_minute` を使う？**

データベースには秒まで保存されるため、`08:00:00`〜`08:00:59` の範囲で検索する必要がある。

```ruby
time = Time.zone.parse("08:00:30")
time.beginning_of_minute  # => 08:00:00
time.end_of_minute        # => 08:00:59
```

### 3.2 user_id を自動設定するコールバック

```ruby
# app/models/reminder.rb
before_validation :set_user_from_post

private

def set_user_from_post
  self.user ||= post&.user
end
```

**なぜこれが必要？**

ネステッドアトリビュートでReminderを作成する際、`user_id` が設定されない。
投稿（Post）の所有者（user）から自動で設定することで、コントローラーの処理をシンプルに保てる。

### 3.3 ReminderCheckJob

```ruby
# app/jobs/reminder_check_job.rb
class ReminderCheckJob < ApplicationJob
  queue_as :default

  def perform
    # 日本時間で現在時刻を取得
    current_time = Time.current.in_time_zone("Tokyo")

    # 該当時刻のリマインダーを取得（達成済み除外）
    reminders = Reminder.sendable_at(current_time).includes(:user, :post)

    # 各リマインダーに対してメール送信をキューに追加
    reminders.find_each do |reminder|
      ReminderMailer.daily_reminder(reminder).deliver_later
    end
  end
end
```

**ポイント**:
- `deliver_later` でメール送信を非同期キューに追加（即座に送信しない）
- `includes(:user, :post)` でN+1問題を回避
- `find_each` で大量レコードをバッチ処理

### 3.4 sidekiq-scheduler の設定

```yaml
# config/sidekiq.yml
:scheduler:
  :schedule:
    reminder_check_job:
      cron: "* * * * *"           # 毎分実行
      class: ReminderCheckJob
      queue: default
```

**cron式の読み方**:
```
* * * * *
│ │ │ │ │
│ │ │ │ └─ 曜日（0-6, 0=日曜）
│ │ │ └─── 月（1-12）
│ │ └───── 日（1-31）
│ └─────── 時（0-23）
└───────── 分（0-59）

例:
"* * * * *"     → 毎分
"0 * * * *"     → 毎時0分
"0 8 * * *"     → 毎日8:00
"0 8 * * 1"     → 毎週月曜8:00
```

---

## 4. つまずいたポイント

### 4.1 bundle install の反映にはコンテナ再ビルドが必要だった

**症状**:
```
Could not find gem 'sidekiq (~> 7.2)' in locally installed gems.
```

**原因**:
Gemfileを変更しても、Dockerコンテナ内のgemは自動更新されない。

**解決策**:
```bash
# 方法1: コンテナ内でbundle install
docker compose exec web bundle install

# 方法2: イメージを再ビルド（より確実）
docker compose build --no-cache
docker compose up
```

### 4.2 ネステッドアトリビュートでuser_idが設定されない

**症状**:
投稿と一緒にリマインダーを作成しようとすると、`user_id` が `nil` でバリデーションエラーになる。

**原因**:
`accepts_nested_attributes_for` はフォームから送られたパラメータのみ設定する。
`user_id` はフォームに含まれていないため設定されない。

**解決策**:
モデルに `before_validation` コールバックを追加して、投稿の所有者を自動設定。

```ruby
before_validation :set_user_from_post

def set_user_from_post
  self.user ||= post&.user
end
```

### 4.3 テストで `travel_to` が使えない

**症状**:
```
NoMethodError: undefined method `travel_to'
```

**原因**:
`travel_to` は `ActiveSupport::Testing::TimeHelpers` のメソッド。
デフォルトではRSpecに含まれていない。

**解決策**:
```ruby
RSpec.describe ReminderCheckJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers  # 追加

  it "sends emails" do
    travel_to Time.zone.parse("08:00:30") do
      # テスト内容
    end
  end
end
```

---

## 5. 次回やること

### 動作確認

```bash
# 1. コンテナ起動
docker compose up --build

# 2. マイグレーション実行
docker compose exec web rails db:migrate

# 3. Sidekiq Web UIで確認
# http://localhost:3000/sidekiq にアクセス

# 4. 実際に投稿を作成してリマインダー設定

# 5. Railsコンソールで手動テスト
docker compose exec web rails c
> user = User.first
> post = user.posts.first
> reminder = post.create_reminder!(remind_time: Time.current)
> ReminderMailer.daily_reminder(reminder).deliver_now

# 6. letter_openerでメール確認
# http://localhost:3000/letter_opener
```

### 本番環境のRedis設定（Upstash）

1. Upstash（https://upstash.com）でRedisインスタンスを作成
2. 環境変数に `REDIS_URL` を設定
3. 本番用の `config/initializers/sidekiq.rb` を調整

```ruby
# 本番環境用（SSL対応）
redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } }
end
```

---

## 6. 感想・気づき

（後で記入）

---

## 参考リンク

- [Sidekiq Wiki](https://github.com/sidekiq/sidekiq/wiki)
- [sidekiq-scheduler](https://github.com/sidekiq-scheduler/sidekiq-scheduler)
- [Rails ガイド: Action Mailer](https://railsguides.jp/action_mailer_basics.html)
- [Rails ガイド: Active Job](https://railsguides.jp/active_job_basics.html)
