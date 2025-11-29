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
│ name        │   └──→│ trigger_... │  │
│ avatar      │       │ action_plan │  │
│ encrypted.. │   ┌──→│ category    │  │
└─────────────┘   │   │ image       │  │
      │           │   │ related_url │  │
      │           │   │ achievement │  │
      ▼           │   └─────────────┘  │
┌─────────────┐   │         │          │
│ Achievement │   │         │          │
├─────────────┤   │         ▼          │
│ id          │   │   ┌─────────────┐  │
│ user_id     │───┘   │   Comment   │  │
│ post_id     │───────├─────────────┤  │
│ achieved_on │       │ id          │  │
└─────────────┘       │ user_id     │──┘
                      │ post_id     │───┐
┌─────────────┐       │ content     │   │
│    Like     │       └─────────────┘   │
├─────────────┤              │          │
│ id          │              ▼          │
│ user_id     │───────────────────────┐ │
│ post_id     │───────────────────────┼─┘
└─────────────┘                       │
                                      ▼
```

## テーブル定義

### users

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| email | string | NOT NULL, UNIQUE | メールアドレス |
| encrypted_password | string | NOT NULL | 暗号化パスワード |
| name | string | | 表示名 |
| avatar | string | | アバター画像パス |
| reset_password_token | string | UNIQUE | パスワードリセット用 |
| reset_password_sent_at | datetime | | リセットメール送信日時 |
| remember_created_at | datetime | | Remember Me用 |
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
| trigger_content | text | NOT NULL | きっかけ（1-100文字） |
| action_plan | text | NOT NULL | アクションプラン（1-100文字） |
| category | integer | NOT NULL, DEFAULT 0 | カテゴリ（enum） |
| image | string | | 画像パス |
| related_url | string | | 関連URL |
| achievement_count | integer | DEFAULT 0 | 達成回数（counter_cache） |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `index_posts_on_user_id`
- `index_posts_on_category`
- `index_posts_on_created_at`

**カテゴリEnum定義**:
```ruby
enum category: {
  text: 0,        # テキスト
  video: 1,       # 映像
  audio: 2,       # 音声
  conversation: 3, # 対話
  experience: 4,   # 体験
  observation: 5,  # 日常
  other: 6        # その他
}
```

### achievements

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| user_id | bigint | FK, NOT NULL | 達成ユーザー |
| post_id | bigint | FK, NOT NULL | 対象投稿 |
| achieved_on | date | NOT NULL | 達成日 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `index_achievements_on_user_id`
- `index_achievements_on_post_id`
- `index_achievements_on_user_id_and_post_id_and_achieved_on` (unique) - 1日1回制限

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

## マイグレーション規約

### 命名規則

```ruby
# 良い例
rails g migration AddCategoryToPosts category:integer
rails g migration CreateAchievements user:references post:references achieved_on:date

# 悪い例
rails g migration UpdatePosts  # 何を更新するか不明
```

### カラム追加時

```ruby
class AddCategoryToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :category, :integer, null: false, default: 0
    add_index :posts, :category
  end
end
```

### 外部キー制約

```ruby
class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.text :content, null: false

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
@posts = Post.includes(:user, :comments, :likes).recent
```

### Counter Cache

```ruby
# Post モデルに achievement_count を持たせる
class Achievement < ApplicationRecord
  belongs_to :post, counter_cache: :achievement_count
end
```

### スコープの活用

```ruby
class Post < ApplicationRecord
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(achievement_count: :desc) }
  scope :by_category, ->(cat) { where(category: cat) if cat.present? }
  scope :with_associations, -> { includes(:user, :achievements, :comments, :likes) }
end
```

## バックアップ・リストア

### 本番環境（Render）

```bash
# バックアップ作成
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d).sql

# リストア
psql $DATABASE_URL < backup_20251120.sql
```

### 開発環境（Docker）

```bash
# バックアップ
docker compose exec db pg_dump -U postgres action_spark_development > backup.sql

# リストア
docker compose exec -T db psql -U postgres action_spark_development < backup.sql
```

---

*関連ドキュメント*: `01_architecture.md`, `06_security.md`
