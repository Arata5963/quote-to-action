# Sidekiq 実装パターン

## 概要

Sidekiqは、Redisをバックエンドとした高性能なバックグラウンドジョブ処理ライブラリです。
mitadake?では、リマインダー通知の定期実行に使用しています。

## 使用ライブラリ

| ライブラリ | バージョン | 用途 |
|-----------|-----------|------|
| sidekiq | ~> 7.0 | バックグラウンドジョブ処理 |
| sidekiq-scheduler | ~> 5.0 | 定期実行ジョブ（cron形式） |

## セットアップ

### Gemfile

```ruby
gem 'sidekiq', '~> 7.0'
gem 'sidekiq-scheduler', '~> 5.0'
```

### Redis設定

```ruby
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end
```

### Sidekiq設定

```yaml
# config/sidekiq.yml
:concurrency: 5
:queues:
  - default
  - mailers
```

### スケジューラ設定

```yaml
# config/sidekiq_scheduler.yml
send_reminders:
  cron: '* * * * *'  # 毎分実行
  class: SendRemindersJob
  queue: default
  description: 'リマインダー通知を送信'
```

### スケジューラ有効化

```ruby
# config/initializers/sidekiq.rb に追加
require 'sidekiq-scheduler'

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(Rails.root.join('config', 'sidekiq_scheduler.yml'))
    SidekiqScheduler::Scheduler.instance.reload_schedule!
  end
end
```

## ジョブの実装

### 基本的なジョブ

```ruby
# app/jobs/send_reminders_job.rb
class SendRemindersJob < ApplicationJob
  queue_as :default

  def perform
    # 現在時刻に該当し、達成済みでない投稿のリマインダーを取得
    reminders = Reminder.sendable.includes(:user, :post)

    reminders.find_each do |reminder|
      ReminderMailer.reminder_email(reminder).deliver_later
    end

    Rails.logger.info "[SendRemindersJob] #{reminders.count}件のリマインダーを送信"
  end
end
```

**Reminderモデルのスコープ**:
```ruby
class Reminder < ApplicationRecord
  # 現在時刻に該当するリマインダーを取得
  scope :due_now, -> {
    now = Time.current
    where(remind_at: now.beginning_of_minute..now.end_of_minute)
  }

  # 達成済みでない投稿のリマインダーのみ
  scope :active, -> { joins(:post).where(posts: { achieved_at: nil }) }

  # 送信対象（現在時刻かつアクティブ）
  scope :sendable, -> { due_now.active }
end
```

### メーラー

```ruby
# app/mailers/reminder_mailer.rb
class ReminderMailer < ApplicationMailer
  def reminder_email(reminder)
    @reminder = reminder
    @user = reminder.user
    @post = reminder.post

    mail(
      to: @user.email,
      subject: "【mitadake?】アクションプランのリマインダー"
    )
  end
end
```

### メールテンプレート

```erb
<%# app/views/reminder_mailer/reminder_email.html.erb %>
<h1><%= @user.name || @user.email %>さん</h1>

<p>アクションプランの実践時間です！</p>

<div style="background: #f3f4f6; padding: 16px; border-radius: 8px;">
  <h2><%= @post.youtube_title %></h2>
  <p><strong>アクションプラン:</strong> <%= @post.action_plan %></p>
</div>

<p>
  <%= link_to '投稿を確認する', post_url(@post) %>
</p>
```

## 開発環境での実行

### Docker Compose

```yaml
# docker-compose.yml
services:
  web:
    # ...
    depends_on:
      - db
      - redis

  sidekiq:
    build: .
    command: bundle exec sidekiq
    volumes:
      - .:/app
    depends_on:
      - db
      - redis
    environment:
      REDIS_URL: redis://redis:6379/0

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

### Procfile.dev

```
web: bin/rails server -p 3000 -b '0.0.0.0'
sidekiq: bundle exec sidekiq
```

### bin/dev で起動

```bash
# foreman または overmind を使用
bin/dev
```

## 本番環境（Render）

### render.yaml

```yaml
services:
  - type: worker
    name: sidekiq
    env: docker
    dockerfilePath: ./Dockerfile
    dockerCommand: bundle exec sidekiq
    envVars:
      - key: REDIS_URL
        fromService:
          type: redis
          name: redis
          property: connectionString
```

## Sidekiq Web UI

開発環境でジョブの状態を確認できます。

### ルーティング設定

```ruby
# config/routes.rb
require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  if Rails.env.development?
    mount Sidekiq::Web, at: '/sidekiq'
  end
end
```

### アクセス

```
http://localhost:3000/sidekiq
```

## ジョブのテスト

### RSpec設定

```ruby
# spec/rails_helper.rb
require 'sidekiq/testing'
Sidekiq::Testing.fake!  # ジョブをキューに追加するだけ（実行しない）
```

### ジョブのテスト

```ruby
# spec/jobs/send_reminders_job_spec.rb
require 'rails_helper'

RSpec.describe SendRemindersJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }
    let!(:reminder) do
      create(:reminder, user: user, post: post, remind_at: Time.current)
    end

    it 'リマインダーメールを送信する' do
      expect {
        described_class.perform_now
      }.to have_enqueued_mail(ReminderMailer, :reminder_email)
    end

    it '該当時刻のリマインダーのみ処理する' do
      other_reminder = create(:reminder, remind_at: 1.hour.from_now)

      expect {
        described_class.perform_now
      }.to have_enqueued_mail(ReminderMailer, :reminder_email).once
    end

    it '達成済み投稿のリマインダーは処理しない' do
      post.update!(achieved_at: Time.current)

      expect {
        described_class.perform_now
      }.not_to have_enqueued_mail(ReminderMailer, :reminder_email)
    end
  end
end
```

## トラブルシューティング

### ジョブが実行されない

1. Sidekiqプロセスが起動しているか確認
   ```bash
   docker compose ps
   ```

2. Redisに接続できているか確認
   ```bash
   docker compose exec redis redis-cli ping
   # => PONG
   ```

3. スケジューラが読み込まれているか確認
   - Sidekiq Web UI の Recurring Jobs タブを確認

### メールが送信されない

1. メール設定を確認
   ```ruby
   # config/environments/development.rb
   config.action_mailer.delivery_method = :letter_opener_web
   ```

2. letter_opener_web で確認
   ```
   http://localhost:3000/letter_opener
   ```

### ジョブがエラーで失敗する

1. Sidekiq Web UI の Retries / Dead タブを確認
2. エラーログを確認
   ```bash
   docker compose logs sidekiq
   ```

## ベストプラクティス

### 1. 冪等性を保つ

```ruby
# 良い例：同じジョブが複数回実行されても問題ない
def perform(user_id)
  user = User.find_by(id: user_id)
  return unless user  # ユーザーが存在しない場合はスキップ

  # 処理
end
```

### 2. 小さなジョブに分割

```ruby
# 悪い例：大量のレコードを一度に処理
def perform
  User.all.each { |u| send_email(u) }
end

# 良い例：個別のジョブに分割
def perform
  User.find_each do |user|
    SendEmailJob.perform_later(user.id)
  end
end
```

### 3. タイムアウトを考慮

```ruby
class LongRunningJob < ApplicationJob
  sidekiq_options retry: 3, dead: false

  def perform
    # 長時間処理
  end
end
```

---

*最終更新: 2025-12-10*

*関連ドキュメント*: `../01_technical_design/01_architecture.md`
