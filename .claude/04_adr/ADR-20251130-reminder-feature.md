# ADR-20251130: リマインダー機能の実装

## ステータス

Accepted（承認済み）

## コンテキスト

ActionSparkは、ユーザーがYouTube動画から得た気づきをアクションプランに変換し、実行を継続するためのプラットフォームである。ユーザーが設定したアクションプランを忘れずに実行するために、毎日指定時刻にメールで通知するリマインダー機能が必要とされた。

### 要件

1. 投稿ごとにリマインダー時刻を設定可能
2. 毎日指定時刻にメール通知を送信
3. 達成済みの投稿（`post.achieved? == true`）は通知をスキップ
4. 1投稿につき1リマインダーのみ設定可能

## 決定

### 技術スタック選定

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| Sidekiq + sidekiq-scheduler | Yes | 高パフォーマンス、Redis活用、cron式スケジューリング対応 |
| Solid Queue | No | Rails標準だがスケジューラ機能が限定的 |
| Whenever (cron) | No | コンテナ環境との相性が悪い |

### アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Compose                          │
├─────────────┬─────────────┬─────────────┬─────────────────┤
│     web     │   sidekiq   │    redis    │       db        │
│   (Rails)   │  (Worker)   │  (Queue)    │  (PostgreSQL)   │
└─────────────┴─────────────┴─────────────┴─────────────────┘
        │              │            │
        │              │            │
        ▼              ▼            ▼
   PostsController  ReminderCheckJob  Reminder Model
        │              │                   │
        │              │                   │
        ▼              ▼                   ▼
   Reminder作成/更新  毎分実行 → 該当時刻のReminder取得 → メール送信
```

### データモデル

```ruby
# reminders テーブル
create_table "reminders" do |t|
  t.bigint "user_id", null: false      # ユーザー（冗長だが検索効率のため保持）
  t.bigint "post_id", null: false      # 対象投稿
  t.time "remind_time", null: false    # 通知時刻（HH:MM）
  t.timestamps

  t.index ["user_id", "post_id"], unique: true  # ユニーク制約
end
```

### 主要コンポーネント

1. **Reminder モデル** (`app/models/reminder.rb`)
   - バリデーション：remind_time必須、user+post一意性、投稿者チェック
   - スコープ：`at_time`、`active`、`sendable_at`

2. **ReminderCheckJob** (`app/jobs/reminder_check_job.rb`)
   - 毎分実行（sidekiq-schedulerで設定）
   - 日本時間で現在時刻をチェック
   - 該当するリマインダーに対してメール送信をenqueue

3. **ReminderMailer** (`app/mailers/reminder_mailer.rb`)
   - HTML/テキストのマルチパートメール
   - 投稿内容とアクションプランを表示

4. **UI** (`app/views/posts/_form.html.erb`, `show.html.erb`)
   - 投稿フォームにtime_fieldを追加
   - 詳細画面にリマインダー状態を表示

## 影響

### 正の影響

- ユーザーのアクション継続率向上が期待できる
- 投稿ごとの柔軟な時刻設定が可能
- 達成済み投稿の自動スキップにより不要な通知を削減

### 負の影響

- Redisサービスの追加によるインフラコスト増加
- sidekiqコンテナの追加によるリソース消費
- 毎分のジョブ実行によるDB負荷（軽微）

### 考慮事項

- **タイムゾーン**: 日本時間（JST）固定で実装。将来的にユーザーごとのタイムゾーン対応が必要な場合は要改修
- **スケーラビリティ**: リマインダー数が増加した場合、バッチサイズの調整やシャーディングが必要になる可能性
- **メール配信**: 開発環境ではletter_opener_webで確認、本番環境ではSMTP設定が必要

## 代替案

### 1. Push通知

Webプッシュ通知も検討したが、以下の理由でメール通知を選択：
- ブラウザ許可が必要でユーザー体験が複雑
- モバイルアプリがない現状ではメールのほうがリーチが広い
- 実装コストがメールより高い

### 2. ユーザー単位のグローバルリマインダー

投稿ごとではなくユーザー単位で1つの時刻を設定する方式も検討したが：
- 投稿ごとに異なる時刻を設定したいニーズに対応できない
- 将来的な拡張性（投稿ごとの頻度設定など）を考慮して投稿単位を選択

## 関連ドキュメント

- [Sidekiq Wiki](https://github.com/sidekiq/sidekiq/wiki)
- [sidekiq-scheduler README](https://github.com/sidekiq-scheduler/sidekiq-scheduler)
- `.claude/01_technical_design/08_test_strategy.md`

## 変更履歴

| 日付 | 変更内容 |
|------|----------|
| 2025-11-30 | 初版作成 |
