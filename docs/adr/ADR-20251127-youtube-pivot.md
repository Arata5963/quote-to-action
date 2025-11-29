# ADR-20251127: YouTube特化へのコンセプトピボット

## ステータス
**提案（Proposed）**

## 日付
2025-11-27

---

## コンテキスト

### 背景
ActionSparkは当初「本の引用からアクションプランを作る」というコンセプトでスタートした。その後、間口を広げて「きっかけ（何でもOK）→ アクションプラン」という形に変更したが、時間が経つにつれて以下の問題が顕在化した。

### 現状の問題
1. **方向性が曖昧** - 「きっかけ」という括りが広すぎて、アプリの説明が難しい
2. **投稿内容がバラつく** - 何を投稿すればいいか迷う
3. **差別化が不明確** - 「メモアプリと何が違う？」と言われる

### 開発者自身の課題
- YouTubeで情報を得ることが多い
- ただコンテンツを消費してしまい、時間を無駄にした経験がある
- ためになる内容をアクションプランに落とし込みたい

---

## 決定事項

### コンセプト変更

```
【Before】
きっかけ（何でもOK）→ アクションプラン

【After】
YouTube動画 → 学び → アクションプラン → 達成
```

**新しいワンフレーズ:**
> 「見て終わり」を「やってみる」に変える

### 主要な変更点

| 項目 | Before | After |
|------|--------|-------|
| 対象コンテンツ | 何でもOK | YouTube動画のみ |
| URL入力 | 任意（related_url） | 必須（youtube_url） |
| 画像 | 手動アップロード | サムネイル自動取得 |
| 達成方式 | 習慣型（1日1回、何度でも） | タスク型（1回のみ） |
| カテゴリ | 独自定義（7種類） | YouTube公式（15種類） |
| 既存データ | - | リセット（削除） |

---

## 詳細設計

### 1. Postモデルの変更

#### 1.1 カラム変更

```ruby
# Before
t.string "related_url"  # 任意
t.integer "category"    # 独自enum（0-6）

# After
t.string "youtube_url", null: false  # 必須
t.integer "category"                  # YouTube公式enum
t.datetime "achieved_at"              # 達成日時（タスク型）
```

#### 1.2 カテゴリEnum変更

```ruby
# Before
enum :category, {
  text: 0,
  video: 1,
  audio: 2,
  conversation: 3,
  experience: 4,
  observation: 5,
  other: 6
}

# After（YouTube公式カテゴリ）
enum :category, {
  film_animation: 1,
  autos_vehicles: 2,
  music: 10,
  pets_animals: 15,
  sports: 17,
  travel_events: 19,
  gaming: 20,
  people_blogs: 22,
  comedy: 23,
  entertainment: 24,
  news_politics: 25,
  howto_style: 26,
  education: 27,
  science_technology: 28,
  nonprofits_activism: 29
}
```

#### 1.3 バリデーション追加

```ruby
class Post < ApplicationRecord
  # YouTube URL必須
  validates :youtube_url, presence: true
  validates :youtube_url, format: {
    with: /\A(https?:\/\/)?(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)[\w-]+/,
    message: "は有効なYouTube URLを入力してください"
  }

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

  # 達成済みかどうか
  def achieved?
    achieved_at.present?
  end
end
```

### 2. Achievementモデルの変更

#### 2.1 タスク型への変更

```ruby
# Before: 習慣型（1日1回、何度でも達成可能）
validates :post_id, uniqueness: { scope: [:user_id, :awarded_at] }

# After: タスク型（1投稿につき1回のみ）
validates :post_id, uniqueness: { scope: :user_id }
```

#### 2.2 代替案：Achievementテーブル廃止

Postに`achieved_at`カラムを持たせることで、Achievementテーブルを廃止する選択肢もある。

```ruby
# Post側で達成管理
class Post < ApplicationRecord
  def achieve!
    update!(achieved_at: Time.current) unless achieved?
  end

  def achieved?
    achieved_at.present?
  end
end
```

**採用案:** Achievementテーブルを残す（将来の拡張性を考慮）

### 3. マイグレーション計画

```ruby
# Step 1: 既存データ削除
class ResetForYoutubePivot < ActiveRecord::Migration[7.2]
  def up
    # 既存データを全削除
    Achievement.delete_all
    Like.delete_all
    Comment.delete_all
    Post.delete_all
    UserBadge.delete_all
  end

  def down
    # データは復元不可
    raise ActiveRecord::IrreversibleMigration
  end
end

# Step 2: スキーマ変更
class ModifyPostsForYoutube < ActiveRecord::Migration[7.2]
  def change
    # カラム名変更
    rename_column :posts, :related_url, :youtube_url
    
    # NOT NULL制約追加
    change_column_null :posts, :youtube_url, false
    
    # 達成日時カラム追加
    add_column :posts, :achieved_at, :datetime, null: true
    
    # imageカラム削除（サムネイル自動取得のため不要）
    remove_column :posts, :image, :string
  end
end

# Step 3: Achievementのユニーク制約変更
class ModifyAchievementsForTaskType < ActiveRecord::Migration[7.2]
  def change
    # 旧インデックス削除
    remove_index :achievements, name: "idx_unique_daily_achievements"
    
    # 新インデックス追加（user_id + post_id のみ）
    add_index :achievements, [:user_id, :post_id], unique: true
    
    # awarded_atカラムをachieved_atにリネーム
    rename_column :achievements, :awarded_at, :achieved_at
  end
end
```

### 4. フィールド名

| フィールド | 変更 | 説明 |
|------------|------|------|
| trigger_content | 維持 | 響いたポイント・学び |
| action_plan | 維持 | 実践する行動 |
| related_url | youtube_url に変更 | YouTube動画URL（必須化） |

### 5. View変更

#### 5.1 投稿フォーム

```erb
<%# Before %>
<%= f.text_field :related_url, placeholder: "関連URL（任意）" %>

<%# After %>
<%= f.url_field :youtube_url, 
    placeholder: "https://www.youtube.com/watch?v=...",
    required: true %>
```

#### 5.2 投稿一覧のサムネイル表示

```erb
<%# Before %>
<% if post.image.present? %>
  <%= image_tag post.image.url %>
<% end %>

<%# After %>
<%= image_tag post.youtube_thumbnail_url, 
    alt: "動画サムネイル",
    class: "w-full aspect-video object-cover" %>
```

#### 5.3 達成ボタン

```erb
<%# Before: 毎日押せる %>
<% if post.achievements.today.exists?(user: current_user) %>
  <%= button_to "達成済み", post_achievement_path(post, achievement), method: :delete %>
<% else %>
  <%= button_to "達成！", post_achievements_path(post), method: :post %>
<% end %>

<%# After: 1回のみ %>
<% if post.achieved? %>
  <span class="badge">✅ 達成済み（<%= l post.achieved_at, format: :short %>）</span>
<% else %>
  <%= button_to "達成！", post_achievements_path(post), method: :post %>
<% end %>
```

---

## i18n対応

```yaml
# config/locales/ja.yml
ja:
  activerecord:
    models:
      post: 投稿
    attributes:
      post:
        youtube_url: YouTube URL
        trigger_content: 響いたポイント
        action_plan: アクションプラン
        category: カテゴリ
        achieved_at: 達成日時
  
  enums:
    post:
      category:
        film_animation: 映画・アニメ
        autos_vehicles: 車・乗り物
        music: 音楽
        pets_animals: ペット・動物
        sports: スポーツ
        travel_events: 旅行・イベント
        gaming: ゲーム
        people_blogs: 人物・ブログ
        comedy: コメディ
        entertainment: エンターテイメント
        news_politics: ニュース・政治
        howto_style: ハウツー・スタイル
        education: 教育
        science_technology: 科学・テクノロジー
        nonprofits_activism: 非営利・社会活動
```

---

## 実装順序

### Phase 1: 基盤変更（破壊的変更）
1. [ ] 既存データのバックアップ（念のため）
2. [ ] 既存データ削除のマイグレーション実行
3. [ ] Postモデルのスキーマ変更
4. [ ] Achievementモデルのスキーマ変更
5. [ ] Enumの再定義

### Phase 2: モデル層
6. [ ] PostモデルのYouTube URL検証追加
7. [ ] YouTube動画ID抽出メソッド実装
8. [ ] サムネイルURL取得メソッド実装
9. [ ] 達成ロジック変更（タスク型）
10. [ ] i18nファイル更新

### Phase 3: View層
11. [ ] 投稿フォーム変更（URL必須化）
12. [ ] 投稿一覧のサムネイル表示
13. [ ] 投稿詳細のサムネイル表示
14. [ ] 達成ボタンUI変更
15. [ ] カテゴリ選択UIの更新

### Phase 4: テスト・仕上げ
16. [ ] RSpecテスト更新
17. [ ] 使い方ページ更新
18. [ ] ランディングページ更新
19. [ ] 手動E2Eテスト

---

## リスクと対策

| リスク | 影響 | 対策 |
|--------|------|------|
| 既存データ削除 | 過去の記録が消える | 事前告知、バックアップ取得 |
| YouTube URL検証失敗 | 投稿できない | エラーメッセージを明確に |
| サムネイル取得失敗 | 画像が表示されない | フォールバック画像を用意 |
| 短縮URL対応 | youtu.be 形式で失敗 | 正規表現で両方対応 |

---

## 将来の拡張可能性

1. **YouTube API連携** - 動画タイトル・説明文の自動取得
2. **他プラットフォーム対応** - TikTok、Vimeo、Podcast等
3. **お気に入りチャンネル登録** - よく見るチャンネルを保存
4. **履歴から選択** - 過去に使ったURLの再利用

---

## 決定の根拠

1. **開発者自身がターゲット** - 自分が使いたいアプリを作る
2. **方向性の明確化** - 「YouTube動画から行動を作る」と一言で説明可能
3. **技術的にシンプル** - サムネイル取得がAPIなしで可能
4. **見た目の統一感** - 全投稿にサムネイル画像がある状態を保証

---

## 参考

- YouTube Video Categories: https://developers.google.com/youtube/v3/docs/videoCategories
- YouTube サムネイルURL形式: `https://img.youtube.com/vi/{VIDEO_ID}/{SIZE}.jpg`