# 実装タスク一覧

**プロジェクト:** mitadake? - アウトプット機能の実装
**要件定義:** `.claude/04_adr/ADR-20250102-output-entries-design.md`
**開始日:** 2025年1月2日
**現在のフェーズ:** Phase 1

---

## 現在のステータス

- **実施中:** Phase 1
- **全体進捗:** 0/4 フェーズ完了

---

## 概要

### コンセプト
「YouTube動画を見ただけで終わらせない」- ダラダラ見を可視化し、行動への変換を促す

### データ構造
```
1動画 = 1投稿（Post）
複数のアウトプット = 複数エントリー（PostEntry）
```

### アウトプット3種類
| タイプ | 内容 | 必須項目 |
|--------|------|----------|
| 📝 メモ | テキスト入力 | content |
| 🎯 行動 | アクションプラン + 期日 | content, deadline |
| 🗑️ 特になし | タイムスタンプのみ | なし |

---

## Phase 1: データベース・モデル変更

**目的:** 1動画1投稿 + 複数エントリー構造への移行
**ステータス:** 未着手

### 1.1 マイグレーション作成

#### `create_post_entries.rb`

```ruby
# rails generate migration CreatePostEntries
class CreatePostEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :post_entries do |t|
      t.references :post, null: false, foreign_key: true
      t.integer :entry_type, null: false, default: 0
      t.text :content
      t.date :deadline
      t.datetime :achieved_at
      t.timestamps
    end

    add_index :post_entries, [:post_id, :created_at]
  end
end
```

- [ ] マイグレーションファイル作成
- [ ] `rails db:migrate` 実行
- [ ] `rails db:migrate:status` で確認

#### `add_youtube_video_id_to_posts.rb`

```ruby
# rails generate migration AddYoutubeVideoIdToPosts
class AddYoutubeVideoIdToPosts < ActiveRecord::Migration[7.2]
  def change
    # youtube_video_id は既存の youtube_url から抽出するため nullable で追加
    add_column :posts, :youtube_video_id, :string
    add_index :posts, [:user_id, :youtube_video_id], unique: true
  end
end
```

- [ ] マイグレーションファイル作成
- [ ] `rails db:migrate` 実行

### 1.2 既存データ移行

```ruby
# db/migrate/XXXXXX_migrate_posts_to_entries.rb
class MigratePostsToEntries < ActiveRecord::Migration[7.2]
  def up
    Post.find_each do |post|
      # youtube_video_id を抽出して設定
      post.update_column(:youtube_video_id, post.youtube_video_id)

      # 既存の action_plan を PostEntry に変換
      next if post.action_plan.blank?

      PostEntry.create!(
        post_id: post.id,
        entry_type: :action,
        content: post.action_plan,
        deadline: post.deadline,
        achieved_at: post.achieved_at
      )
    end
  end

  def down
    PostEntry.destroy_all
    Post.update_all(youtube_video_id: nil)
  end
end
```

- [ ] データ移行マイグレーション作成
- [ ] `rails db:migrate` 実行
- [ ] データ移行確認

### 1.3 PostEntry モデル作成

```ruby
# app/models/post_entry.rb
class PostEntry < ApplicationRecord
  belongs_to :post

  enum entry_type: {
    memo: 0,      # 📝 メモ
    action: 1,    # 🎯 行動
    nothing: 2    # 🗑️ 特になし
  }

  # バリデーション
  validates :entry_type, presence: true
  validates :content, presence: true, if: -> { memo? || action? }
  validates :deadline, presence: true, if: :action?

  # スコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :actions_not_achieved, -> { where(entry_type: :action, achieved_at: nil) }

  # 達成メソッド
  def achieved?
    achieved_at.present?
  end

  def achieve!
    update!(achieved_at: Time.current) if action? && !achieved?
  end
end
```

- [ ] モデルファイル作成
- [ ] バリデーション実装
- [ ] スコープ実装
- [ ] 達成メソッド実装

### 1.4 Post モデル変更

```ruby
# app/models/post.rb に追加
class Post < ApplicationRecord
  has_many :post_entries, dependent: :destroy

  # ユニーク制約（同じユーザー × 同じ動画で1投稿）
  validates :youtube_video_id, uniqueness: { scope: :user_id }

  # 動画IDでPostを検索または作成
  def self.find_or_initialize_by_video(user:, youtube_url:)
    video_id = extract_video_id(youtube_url)
    post = find_or_initialize_by(user: user, youtube_video_id: video_id)
    post.youtube_url = youtube_url if post.new_record?
    post
  end

  # エントリー関連のヘルパー
  def latest_entry
    post_entries.recent.first
  end

  def entries_count
    post_entries.count
  end

  def has_action_entries?
    post_entries.where(entry_type: :action).exists?
  end

  private

  def self.extract_video_id(url)
    # 既存の youtube_video_id メソッドを流用
    # ...
  end
end
```

- [ ] `has_many :post_entries` 追加
- [ ] `youtube_video_id` のユニーク制約追加
- [ ] `find_or_initialize_by_video` メソッド追加
- [ ] エントリー関連ヘルパー追加

### 1.5 テスト作成

```ruby
# spec/models/post_entry_spec.rb
RSpec.describe PostEntry, type: :model do
  describe 'associations' do
    it { should belong_to(:post) }
  end

  describe 'validations' do
    context 'when entry_type is memo' do
      subject { build(:post_entry, entry_type: :memo) }
      it { should validate_presence_of(:content) }
    end

    context 'when entry_type is action' do
      subject { build(:post_entry, entry_type: :action) }
      it { should validate_presence_of(:content) }
      it { should validate_presence_of(:deadline) }
    end

    context 'when entry_type is nothing' do
      subject { build(:post_entry, entry_type: :nothing, content: nil) }
      it { should be_valid }
    end
  end

  describe '#achieve!' do
    # ...
  end
end
```

- [ ] `spec/models/post_entry_spec.rb` 作成
- [ ] `spec/factories/post_entries.rb` 作成
- [ ] Post モデルテスト更新

### 完了条件

- [ ] すべてのマイグレーションが正常に実行
- [ ] 既存データが PostEntry に移行されている
- [ ] RSpec テストが通る（80%以上カバレッジ）
- [ ] RuboCop → All green
- [ ] Brakeman → All green

---

## Phase 2: 投稿フォーム変更

**目的:** アウトプット3種類の選択UIと投稿フローの実装
**依存:** Phase 1 完了
**ステータス:** 未着手

### 2.1 投稿フォームUI

#### アウトプット種類選択

```erb
<%# app/views/posts/_entry_type_selector.html.erb %>
<div data-controller="entry-form" class="space-y-4">
  <%# アウトプット種類選択（ラジオボタン風カード） %>
  <div class="grid grid-cols-3 gap-3">
    <label class="cursor-pointer">
      <input type="radio" name="entry_type" value="memo"
             data-entry-form-target="typeRadio"
             data-action="entry-form#changeType"
             class="sr-only peer">
      <div class="p-4 rounded-lg border-2 peer-checked:border-blue-500 peer-checked:bg-blue-50 text-center">
        <span class="text-2xl">📝</span>
        <p class="text-sm font-medium mt-1">メモ</p>
      </div>
    </label>

    <label class="cursor-pointer">
      <input type="radio" name="entry_type" value="action"
             data-entry-form-target="typeRadio"
             data-action="entry-form#changeType"
             class="sr-only peer">
      <div class="p-4 rounded-lg border-2 peer-checked:border-orange-500 peer-checked:bg-orange-50 text-center">
        <span class="text-2xl">🎯</span>
        <p class="text-sm font-medium mt-1">行動</p>
      </div>
    </label>

    <label class="cursor-pointer">
      <input type="radio" name="entry_type" value="nothing"
             data-entry-form-target="typeRadio"
             data-action="entry-form#changeType"
             class="sr-only peer">
      <div class="p-4 rounded-lg border-2 peer-checked:border-gray-500 peer-checked:bg-gray-50 text-center">
        <span class="text-2xl">🗑️</span>
        <p class="text-sm font-medium mt-1">特になし</p>
      </div>
    </label>
  </div>

  <%# 動的フィールド（entry_typeに応じて表示切替） %>
  <div data-entry-form-target="fields">
    <%# Stimulus で動的に表示 %>
  </div>
</div>
```

- [ ] アウトプット種類選択UI作成
- [ ] 種類ごとの入力フィールド作成
- [ ] Stimulus コントローラー作成

### 2.2 Stimulus コントローラー

```javascript
// app/javascript/controllers/entry_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeRadio", "fields", "memoFields", "actionFields"]

  connect() {
    this.updateFields()
  }

  changeType() {
    this.updateFields()
  }

  updateFields() {
    const selectedType = this.getSelectedType()

    // すべて非表示
    this.hideAllFields()

    // 選択されたタイプのフィールドを表示
    switch(selectedType) {
      case 'memo':
        this.showMemoFields()
        break
      case 'action':
        this.showActionFields()
        break
      case 'nothing':
        // 入力フィールドなし
        break
    }
  }

  getSelectedType() {
    const checked = this.typeRadioTargets.find(r => r.checked)
    return checked ? checked.value : null
  }

  // ...
}
```

- [ ] `entry_form_controller.js` 作成
- [ ] タイプ切り替え機能実装
- [ ] フィールド表示/非表示制御

### 2.3 PostsController 変更

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def create
    # 1. 動画IDでPostを検索または作成
    @post = Post.find_or_initialize_by_video(
      user: current_user,
      youtube_url: post_params[:youtube_url]
    )

    # 2. Postを保存（新規の場合）
    if @post.new_record?
      @post.save!
    end

    # 3. PostEntryを作成
    @entry = @post.post_entries.build(entry_params)

    if @entry.save
      redirect_to @post, notice: entry_success_message(@entry)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def entry_params
    params.require(:post_entry).permit(:entry_type, :content, :deadline)
  end

  def entry_success_message(entry)
    case entry.entry_type
    when 'memo' then 'メモを記録しました'
    when 'action' then 'アクションプランを設定しました'
    when 'nothing' then '視聴を記録しました'
    end
  end
end
```

- [ ] `create` アクション変更
- [ ] `find_or_initialize_by_video` 使用
- [ ] PostEntry 作成処理追加

### 2.4 クリップボード自動検出

```javascript
// app/javascript/controllers/clipboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  async connect() {
    await this.checkClipboard()
  }

  async checkClipboard() {
    try {
      const text = await navigator.clipboard.readText()
      if (this.isYoutubeUrl(text)) {
        this.inputTarget.value = text
        // 自動でYouTube情報を取得
        this.dispatch("urlDetected", { detail: { url: text } })
      }
    } catch (err) {
      // クリップボードアクセス拒否時は何もしない
      console.log("Clipboard access denied")
    }
  }

  isYoutubeUrl(text) {
    const pattern = /^(https?:\/\/)?(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)/
    return pattern.test(text)
  }
}
```

- [ ] `clipboard_controller.js` 作成
- [ ] YouTube URL検出機能
- [ ] フォールバック対応（手動入力）

### 完了条件

- [ ] アウトプット3種類の選択UIが動作
- [ ] 種類に応じた入力フィールドが表示
- [ ] 同じ動画への投稿が既存Postに紐付く
- [ ] クリップボード自動検出が動作
- [ ] RSpec テスト通過

---

## Phase 3: 詳細ページ・追記機能

**目的:** エントリー一覧表示とインライン追記UI
**依存:** Phase 2 完了
**ステータス:** 未着手

### 3.1 詳細ページUI

```erb
<%# app/views/posts/show.html.erb %>
<div class="max-w-2xl mx-auto">
  <%# YouTube埋め込み %>
  <div class="aspect-video rounded-lg overflow-hidden">
    <iframe src="<%= @post.youtube_embed_url %>" ...></iframe>
  </div>

  <%# エントリー一覧（タイムライン形式） %>
  <div class="mt-6 space-y-4">
    <h2 class="text-lg font-bold">アウトプット履歴</h2>

    <% @post.post_entries.recent.each do |entry| %>
      <%= render 'post_entries/entry_card', entry: entry %>
    <% end %>
  </div>

  <%# 追記ボタン %>
  <div class="mt-6" data-controller="inline-form">
    <button data-action="inline-form#toggle"
            class="w-full py-3 border-2 border-dashed rounded-lg text-gray-500 hover:border-gray-400">
      + 追記する
    </button>

    <%# インライン展開フォーム %>
    <div data-inline-form-target="form" class="hidden mt-4">
      <%= render 'post_entries/form', post: @post %>
    </div>
  </div>
</div>
```

- [ ] エントリー一覧表示
- [ ] タイムライン形式UI
- [ ] 追記ボタン配置

### 3.2 エントリーカード

```erb
<%# app/views/post_entries/_entry_card.html.erb %>
<div class="p-4 rounded-lg bg-white border">
  <div class="flex items-start gap-3">
    <%# タイプアイコン %>
    <span class="text-2xl">
      <% case entry.entry_type %>
      <% when 'memo' %>📝
      <% when 'action' %>🎯
      <% when 'nothing' %>🗑️
      <% end %>
    </span>

    <div class="flex-1">
      <%# コンテンツ %>
      <% if entry.content.present? %>
        <p class="text-gray-900"><%= entry.content %></p>
      <% else %>
        <p class="text-gray-400 italic">見ただけ</p>
      <% end %>

      <%# メタ情報 %>
      <div class="mt-2 flex items-center gap-4 text-sm text-gray-500">
        <span><%= time_ago_in_words(entry.created_at) %>前</span>

        <% if entry.action? && entry.deadline %>
          <span class="<%= entry.achieved? ? 'text-green-600' : 'text-orange-600' %>">
            <% if entry.achieved? %>
              ✓ 達成済み
            <% else %>
              期日: <%= l(entry.deadline, format: :short) %>
            <% end %>
          </span>
        <% end %>
      </div>
    </div>

    <%# 達成ボタン（actionタイプのみ） %>
    <% if entry.action? && !entry.achieved? %>
      <%= button_to achieve_post_entry_path(@post, entry),
                    method: :patch,
                    class: "px-3 py-1 bg-green-500 text-white rounded-full text-sm" do %>
        達成！
      <% end %>
    <% end %>
  </div>
</div>
```

- [ ] エントリーカードUI作成
- [ ] タイプ別表示切り替え
- [ ] 達成ボタン配置

### 3.3 インライン追記フォーム

```javascript
// app/javascript/controllers/inline_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  toggle() {
    this.formTarget.classList.toggle("hidden")
  }

  close() {
    this.formTarget.classList.add("hidden")
  }
}
```

- [ ] `inline_form_controller.js` 作成
- [ ] 展開/折りたたみ機能
- [ ] 投稿後の自動閉じ

### 3.4 PostEntriesController

```ruby
# app/controllers/post_entries_controller.rb
class PostEntriesController < ApplicationController
  before_action :set_post

  def create
    @entry = @post.post_entries.build(entry_params)
    @entry.save!

    respond_to do |format|
      format.html { redirect_to @post, notice: success_message }
      format.turbo_stream
    end
  end

  def achieve
    @entry = @post.post_entries.find(params[:id])
    @entry.achieve!

    respond_to do |format|
      format.html { redirect_to @post, notice: '達成おめでとうございます！' }
      format.turbo_stream
    end
  end

  private

  def set_post
    @post = current_user.posts.find(params[:post_id])
  end

  def entry_params
    params.require(:post_entry).permit(:entry_type, :content, :deadline)
  end
end
```

- [ ] `create` アクション実装
- [ ] `achieve` アクション実装
- [ ] Turbo Stream 対応

### 3.5 ルーティング

```ruby
# config/routes.rb
resources :posts do
  resources :post_entries, only: [:create] do
    member do
      patch :achieve
    end
  end
end
```

- [ ] ルーティング追加

### 完了条件

- [ ] 詳細ページでエントリー一覧が表示される
- [ ] インライン追記フォームが動作する
- [ ] 達成ボタンが動作する
- [ ] Turbo Stream でリアルタイム更新

---

## Phase 4: 一覧ページ・UI調整

**目的:** note.com風デザインとエントリー情報表示
**依存:** Phase 3 完了
**ステータス:** 未着手

### 4.1 一覧ページのカード更新

```erb
<%# app/views/posts/_post_card_note.html.erb %>
<article class="group">
  <%# サムネイル %>
  <%= link_to post_path(post), class: "block" do %>
    <div class="aspect-video rounded overflow-hidden bg-gray-100 relative">
      <%= image_tag post.youtube_thumbnail_url(size: :mqdefault), ... %>

      <%# エントリー数バッジ %>
      <% if post.entries_count > 1 %>
        <span class="absolute top-2 right-2 px-2 py-0.5 bg-black/60 text-white text-xs rounded-full">
          <%= post.entries_count %>回
        </span>
      <% end %>
    </div>
  <% end %>

  <div class="pt-2">
    <%# 最新エントリーのプレビュー %>
    <% if post.latest_entry %>
      <div class="flex items-center gap-1 text-xs text-gray-500">
        <span>
          <% case post.latest_entry.entry_type %>
          <% when 'memo' %>📝
          <% when 'action' %>🎯
          <% when 'nothing' %>🗑️
          <% end %>
        </span>
        <span class="truncate">
          <%= post.latest_entry.content.presence || '見ただけ' %>
        </span>
      </div>
    <% end %>

    <%# ... 既存のユーザー情報など %>
  </div>
</article>
```

- [ ] エントリー数バッジ追加
- [ ] 最新エントリープレビュー追加
- [ ] タイプ別アイコン表示

### 4.2 空状態のUI

```erb
<%# 投稿がない場合 %>
<div class="py-16 text-center">
  <span class="text-6xl">📺</span>
  <p class="mt-4 text-gray-500">まだアウトプットがありません</p>
  <p class="text-sm text-gray-400 mt-1">YouTube動画を見たら記録してみましょう</p>
  <%= link_to new_post_path, class: "mt-4 inline-block px-6 py-2 bg-orange-500 text-white rounded-full" do %>
    最初のアウトプットを記録
  <% end %>
</div>
```

- [ ] 空状態UI作成
- [ ] CTAボタン配置

### 完了条件

- [ ] note.com風デザインが適用されている
- [ ] エントリー数が表示される
- [ ] 最新エントリーのプレビューが表示される
- [ ] レスポンシブ対応

---

## テスト要件

### RSpec

- [ ] `spec/models/post_entry_spec.rb`
  - [ ] バリデーションテスト（タイプ別）
  - [ ] `achieve!` メソッドテスト
  - [ ] スコープテスト

- [ ] `spec/models/post_spec.rb`
  - [ ] `find_or_initialize_by_video` テスト
  - [ ] ユニーク制約テスト
  - [ ] エントリー関連メソッドテスト

- [ ] `spec/requests/posts_spec.rb`
  - [ ] 新規投稿（3タイプ）
  - [ ] 同じ動画への追記

- [ ] `spec/requests/post_entries_spec.rb`
  - [ ] 追記機能
  - [ ] 達成機能

- [ ] `spec/system/post_flow_spec.rb`
  - [ ] E2E投稿フロー

### 静的解析

- [ ] RuboCop → All green
- [ ] Brakeman → All green

---

## i18n

```yaml
# config/locales/ja.yml
ja:
  activerecord:
    models:
      post_entry: アウトプット
    attributes:
      post_entry:
        entry_type: タイプ
        content: 内容
        deadline: 期日
        achieved_at: 達成日時
    enums:
      post_entry:
        entry_type:
          memo: メモ
          action: 行動
          nothing: 特になし

  post_entries:
    entry_types:
      memo:
        label: メモ
        icon: 📝
        description: 気づきや学びを記録
      action:
        label: 行動
        icon: 🎯
        description: やることを決めて実行
      nothing:
        label: 特になし
        icon: 🗑️
        description: 見ただけを記録

    messages:
      created:
        memo: メモを記録しました
        action: アクションプランを設定しました
        nothing: 視聴を記録しました
      achieved: 達成おめでとうございます！
```

- [ ] モデル翻訳追加
- [ ] enum翻訳追加
- [ ] メッセージ翻訳追加

---

## 追加機能（実装済み）

- [x] タイトル検索（YouTube API）
  - `YoutubeService.search_videos` メソッド追加
  - `PostsController#youtube_search` アクション追加
  - 投稿フォームにタイトル検索UI追加（`youtube_search_controller.js`）
- [x] 満足度機能
  - `PostEntry` に `satisfaction_rating` カラム追加（1-5の5段階評価）
  - 投稿フォームに星評価UI追加（`rating_controller.js`）
  - エントリーカードに満足度表示
- [x] 統計・分析ダッシュボード（`/stats`）
  - 視聴動画数、アウトプット数、達成率、連続記録
  - アウトプットタイプ別内訳
  - 満足度分布
  - 過去30日間の活動グラフ
  - よく見るチャンネルTOP5


---

## 履歴

- 2025-01-02: 初版作成
