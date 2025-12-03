# データベース設計

## 概要

PostgreSQLを使用し、正規化されたリレーショナルデータベース設計を採用しています。

## ER図

```
┌─────────────┐       ┌─────────────┐
│    User     │       │    Post     │
├─────────────┤       ├─────────────┤
│ id          │───┐   │ id          │
│ email       │   │   │ user_id     │←─┐
│ name        │   └──→│ youtube_url │  │
│ avatar      │       │ trigger_... │  │
│ encrypted.. │   ┌──→│ action_plan │  │
└─────────────┘   │   │ category    │  │
      │           │   │ achieved_at │  │
      │           │   └─────────────┘  │
      ▼           │         │          │
┌─────────────┐   │         │          │
│ Achievement │   │         ▼          │
├─────────────┤   │   ┌─────────────┐  │
│ id          │   │   │   Comment   │  │
│ user_id     │───┘   ├─────────────┤  │
│ post_id     │───────│ id          │  │
│ achieved_at │       │ user_id     │──┘
└─────────────┘       │ post_id     │───┐
                      │ content     │   │
┌─────────────┐       └─────────────┘   │
│    Like     │              │          │
├─────────────┤              ▼          │
│ id          │       ┌─────────────┐   │
│ user_id     │───────│  Reminder   │   │
│ post_id     │───────├─────────────┤   │
└─────────────┘       │ id          │   │
                      │ user_id     │───┤
┌─────────────┐       │ post_id     │───┘
│  UserBadge  │       │ remind_time │
├─────────────┤       └─────────────┘
│ id          │
│ user_id     │
│ badge_type  │
└─────────────┘
```

## テーブル定義

### users

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| email | string | NOT NULL, UNIQUE | メールアドレス |
| encrypted_password | string | NOT NULL | 暗号化パスワード |
| name | string | | 表示名 |
| avatar | string | | アバター画像パス（CarrierWave） |
| reset_password_token | string | UNIQUE | パスワードリセット用 |
| reset_password_sent_at | datetime | | リセットメール送信日時 |
| remember_created_at | datetime | | Remember Me用 |
| provider | string | | OAuthプロバイダ |
| uid | string | | OAuthユーザーID |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `index_users_on_email` (unique)
- `index_users_on_reset_password_token` (unique)

### posts

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| user_id | bigint | FK, NOT NULL | 投稿者 |
| youtube_url | string | NOT NULL | YouTube動画URL |
| youtube_title | string | | YouTube動画タイトル（API自動取得） |
| youtube_channel_name | string | | YouTubeチャンネル名（API自動取得） |
| trigger_content | text | NOT NULL | 響いたポイント（1-100文字） |
| action_plan | text | NOT NULL | アクションプラン（1-100文字） |
| category | integer | NOT NULL | カテゴリ（YouTube公式enum） |
| achieved_at | datetime | | 達成日時（タスク型） |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `index_posts_on_user_id`
- `index_posts_on_category`
- `index_posts_on_created_at`

**カテゴリEnum定義（YouTube公式）**:
```ruby
enum :category, {
  film_animation: 1,      # 映画・アニメ
  autos_vehicles: 2,      # 車・乗り物
  music: 10,              # 音楽
  pets_animals: 15,       # ペット・動物
  sports: 17,             # スポーツ
  travel_events: 19,      # 旅行・イベント
  gaming: 20,             # ゲーム
  people_blogs: 22,       # 人物・ブログ
  comedy: 23,             # コメディ
  entertainment: 24,      # エンターテイメント
  news_politics: 25,      # ニュース・政治
  howto_style: 26,        # ハウツー・スタイル
  education: 27,          # 教育
  science_technology: 28, # 科学・テクノロジー
  nonprofits_activism: 29 # 非営利・社会活動
}
```

**YouTube関連メソッド**:
```ruby
class Post < ApplicationRecord
  # YouTube動画ID抽出
  def youtube_video_id
    return nil unless youtube_url.present?

    if youtube_url.include?("youtube.com/watch")
      URI.parse(youtube_url).query&.split("&")
         &.find { |p| p.start_with?("v=") }
         &.delete_prefix("v=")
    elsif youtube_url.include?("youtu.be/")
      youtube_url.split("youtu.be/").last&.split("?")&.first
    end
  end

  # サムネイルURL取得
  def youtube_thumbnail_url(size: :mqdefault)
    return nil unless youtube_video_id
    "https://img.youtube.com/vi/#{youtube_video_id}/#{size}.jpg"
  end

  # 埋め込みURL取得
  def youtube_embed_url
    return nil unless youtube_video_id
    "https://www.youtube.com/embed/#{youtube_video_id}"
  end
end
```

### achievements

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| user_id | bigint | FK, NOT NULL | 達成ユーザー |
| post_id | bigint | FK, NOT NULL | 対象投稿 |
| achieved_at | datetime | NOT NULL | 達成日時 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `index_achievements_on_user_id`
- `index_achievements_on_post_id`
- `index_achievements_on_user_id_and_post_id` (unique) - タスク型（1投稿1達成）

### reminders

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| user_id | bigint | FK, NOT NULL | リマインダー対象ユーザー |
| post_id | bigint | FK, NOT NULL | 対象投稿 |
| remind_time | time | NOT NULL | 通知時刻（HH:MM） |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `index_reminders_on_user_id`
- `index_reminders_on_post_id`

### comments

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| user_id | bigint | FK, NOT NULL | コメント者 |
| post_id | bigint | FK, NOT NULL | 対象投稿 |
| content | text | NOT NULL | コメント内容（max 500文字） |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `index_comments_on_user_id`
- `index_comments_on_post_id`

### likes

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| user_id | bigint | FK, NOT NULL | いいねしたユーザー |
| post_id | bigint | FK, NOT NULL | 対象投稿 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `index_likes_on_user_id_and_post_id` (unique)
- `index_likes_on_post_id`

### user_badges

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| user_id | bigint | FK, NOT NULL | バッジ所有ユーザー |
| badge_type | integer | NOT NULL | バッジ種類（enum） |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

## アソシエーション

```ruby
class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :achievements, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :reminders, dependent: :destroy
  has_many :user_badges, dependent: :destroy
end

class Post < ApplicationRecord
  belongs_to :user
  has_many :achievements, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_one :reminder, dependent: :destroy

  accepts_nested_attributes_for :reminder, allow_destroy: true
end

class Reminder < ApplicationRecord
  belongs_to :user
  belongs_to :post
end
```

## マイグレーション規約

### 命名規則

```ruby
# 良い例
rails g migration AddYoutubeUrlToPosts youtube_url:string
rails g migration CreateReminders user:references post:references remind_time:time

# 悪い例
rails g migration UpdatePosts  # 何を更新するか不明
```

### カラム追加時

```ruby
class AddYoutubeUrlToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :youtube_url, :string, null: false
    add_index :posts, :youtube_url
  end
end
```

### 外部キー制約

```ruby
class CreateReminders < ActiveRecord::Migration[7.2]
  def change
    create_table :reminders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.time :remind_time, null: false

      t.timestamps
    end
  end
end
```

## クエリ最適化

### N+1問題の回避

```ruby
# 悪い例
@posts = Post.all
# ビューで@posts.each { |p| p.user.name } するとN+1

# 良い例
@posts = Post.includes(:user, :comments, :likes, :achievements).recent
```

### スコープの活用

```ruby
class Post < ApplicationRecord
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(cat) { where(category: cat) if cat.present? }
  scope :with_associations, -> { includes(:user, :achievements, :comments, :likes) }
  scope :achieved, -> { where.not(achieved_at: nil) }
  scope :not_achieved, -> { where(achieved_at: nil) }
end
```

## バックアップ・リストア

### 本番環境（Render）

```bash
# バックアップ作成
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d).sql

# リストア
psql $DATABASE_URL < backup_20251202.sql
```

### 開発環境（Docker）

```bash
# バックアップ
docker compose exec db pg_dump -U postgres action_spark_development > backup.sql

# リストア
docker compose exec -T db psql -U postgres action_spark_development < backup.sql
```

---

*最終更新: 2025-12-03*

*関連ドキュメント*: `01_architecture.md`, `06_security.md`
