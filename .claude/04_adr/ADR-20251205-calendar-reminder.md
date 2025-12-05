# ADR-20251205: カレンダー指定リマインダーへの変更

## ステータス

Accepted

## コンテキスト

現在のリマインダー機能は「毎日同じ時刻に通知」する設計になっている。しかし、ActionSparkは「YouTube動画から学んだことを行動に変える」プラットフォームであり、タスク型の設計との整合性を考えると、「特定日時に1回だけ通知」する方が適切である。

### 現状の問題点

1. **毎日通知は過剰**: アクションプランは継続的なタスクではなく、特定の行動を促すものが多い
2. **達成後も通知が続く**: 達成済みでも通知が止まらない（手動で無効化が必要）
3. **time型の制限**: 日付を指定できないため、柔軟性に欠ける

### 変更の動機

- タスク管理アプリとしての使いやすさ向上
- 「この日までにやる」という明確な目標設定
- 通知後の自動削除によるクリーンな状態維持

## 決定

### 1. データ構造の変更

```
remind_time (time型) → remind_at (datetime型)
```

### 2. 動作の変更

- 指定日時に1回だけメール送信
- 送信後はリマインダーを自動削除
- 過去の日時は設定不可（バリデーション）

### 3. UI変更

- HTML標準の `datetime-local` 入力を使用
- 最小値を現在時刻に設定

## 影響

### 破壊的変更

- 既存のリマインダーは全て削除される（time → datetime への変換は不可能なため）

### マイグレーション戦略

1. 既存リマインダーを全削除
2. `remind_time` カラムを削除
3. `remind_at` カラムを追加

### 影響を受けるファイル

- `app/models/reminder.rb`
- `app/jobs/reminder_check_job.rb`
- `app/controllers/posts_controller.rb`
- `app/views/posts/_form.html.erb`
- `app/views/posts/show.html.erb`
- `config/locales/ja.yml`
- `spec/models/reminder_spec.rb`
- `spec/jobs/reminder_check_job_spec.rb`
- `spec/factories/reminders.rb`

## 代替案

### 案1: remind_time を維持しつつ remind_date を追加

- メリット: 既存データを保持可能
- デメリット: 複雑性が増す、毎日通知と1回通知の混在

### 案2: 繰り返し設定をオプション化

- メリット: 両方のユースケースに対応
- デメリット: UIが複雑化、実装コスト増

→ シンプルさを優先し、1回通知に統一する決定を採用

## 日付

2025-12-05
