# Ransack 実装パターン

## 概要

ActionSparkにおけるRansack（検索ライブラリ）の設定と実装パターンを定義します。

## 基本設定

### インストール

```ruby
# Gemfile
gem 'ransack'
```

### モデル設定

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  # 検索可能な属性を制限（セキュリティ対策）
  def self.ransackable_attributes(auth_object = nil)
    %w[trigger_content action_plan category created_at]
  end

  # 検索可能なアソシエーション
  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end
end

# app/models/user.rb
class User < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil)
    %w[name email created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
```

## 基本的な検索

### コントローラー

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @q = Post.ransack(params[:q])
    @posts = @q.result(distinct: true)
               .includes(:user, :achievements)
               .recent
               .page(params[:page])
  end
end
```

### ビュー（検索フォーム）

```erb
<%# app/views/posts/_search_form.html.erb %>
<%= search_form_for @q, url: posts_path, method: :get,
    html: { class: 'flex gap-2' } do |f| %>

  <%# フリーワード検索 %>
  <div class="flex-1">
    <%= f.search_field :trigger_content_or_action_plan_cont,
        placeholder: 'キーワードで検索...',
        class: 'w-full rounded-md border-gray-300 shadow-sm focus:border-black focus:ring-black' %>
  </div>

  <%= f.submit '検索', class: 'bg-black text-white px-4 py-2 rounded-md hover:bg-gray-800' %>
<% end %>
```

## 検索条件（Predicate）

### よく使う検索条件

| 条件 | 説明 | 例 |
|------|------|-----|
| `_eq` | 等しい | `category_eq` |
| `_not_eq` | 等しくない | `category_not_eq` |
| `_cont` | 含む（LIKE） | `trigger_content_cont` |
| `_start` | 前方一致 | `name_start` |
| `_end` | 後方一致 | `name_end` |
| `_lt` | より小さい | `created_at_lt` |
| `_lteq` | 以下 | `created_at_lteq` |
| `_gt` | より大きい | `created_at_gt` |
| `_gteq` | 以上 | `created_at_gteq` |
| `_in` | いずれかに一致 | `category_in` |
| `_null` | NULLかどうか | `image_null` |
| `_present` | 存在するか | `image_present` |

### 複数フィールド検索

```erb
<%# OR検索（いずれかに含む） %>
<%= f.search_field :trigger_content_or_action_plan_cont %>

<%# AND検索（両方に含む） %>
<%= f.search_field :trigger_content_cont %>
<%= f.search_field :action_plan_cont %>
```

## カテゴリフィルター

### セレクトボックス

```erb
<%= f.select :category_eq,
    options_for_select([
      ['すべて', ''],
      ['📝 テキスト', 'text'],
      ['🎥 映像', 'video'],
      ['🎧 音声', 'audio'],
      ['💬 対話', 'conversation'],
      ['✨ 体験', 'experience'],
      ['👀 日常', 'observation'],
      ['📁 その他', 'other']
    ], params.dig(:q, :category_eq)),
    {},
    class: 'rounded-md border-gray-300' %>
```

### タブ/チップ形式

```erb
<%# app/views/posts/_category_filter.html.erb %>
<div class="flex flex-wrap gap-2">
  <%= link_to 'すべて', posts_path,
      class: "px-3 py-1 rounded-full text-sm #{params.dig(:q, :category_eq).blank? ? 'bg-black text-white' : 'bg-gray-200 text-gray-700 hover:bg-gray-300'}" %>

  <% Post.categories.keys.each do |category| %>
    <%= link_to category_label(category),
        posts_path(q: { category_eq: category }),
        class: "px-3 py-1 rounded-full text-sm #{params.dig(:q, :category_eq) == category ? 'bg-black text-white' : 'bg-gray-200 text-gray-700 hover:bg-gray-300'}" %>
  <% end %>
</div>
```

## 日付範囲検索

```erb
<div class="flex gap-2 items-center">
  <%= f.date_field :created_at_gteq,
      class: 'rounded-md border-gray-300' %>
  <span>〜</span>
  <%= f.date_field :created_at_lteq,
      class: 'rounded-md border-gray-300' %>
</div>
```

## ソート

### リンクヘルパー

```erb
<table>
  <thead>
    <tr>
      <th><%= sort_link(@q, :created_at, '作成日') %></th>
      <th><%= sort_link(@q, :achievement_count, '達成数') %></th>
    </tr>
  </thead>
</table>
```

### カスタムソート

```erb
<%# ソートセレクトボックス %>
<%= f.select :s,
    options_for_select([
      ['新しい順', 'created_at desc'],
      ['古い順', 'created_at asc'],
      ['達成数順', 'achievement_count desc']
    ], @q.sorts.first&.name),
    {},
    class: 'rounded-md border-gray-300' %>
```

## オートコンプリート検索

### Stimulus コントローラー

```javascript
// app/javascript/controllers/autocomplete_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)

    const query = this.inputTarget.value.trim()
    if (query.length < 2) {
      this.hideResults()
      return
    }

    this.timeout = setTimeout(() => {
      this.fetchResults(query)
    }, 300)
  }

  async fetchResults(query) {
    const url = `${this.urlValue}?q[trigger_content_or_action_plan_cont]=${encodeURIComponent(query)}`

    try {
      const response = await fetch(url, {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })
      const html = await response.text()
      this.resultsTarget.innerHTML = html
      this.showResults()
    } catch (error) {
      console.error('Search failed:', error)
    }
  }

  showResults() {
    this.resultsTarget.classList.remove('hidden')
  }

  hideResults() {
    this.resultsTarget.classList.add('hidden')
  }

  // 結果外をクリックしたら非表示
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }
}
```

### ビュー

```erb
<%# 検索フォーム %>
<div data-controller="autocomplete"
     data-autocomplete-url-value="<%= posts_path %>"
     class="relative">
  <input type="text"
         data-autocomplete-target="input"
         data-action="input->autocomplete#search"
         placeholder="検索..."
         class="w-full rounded-md border-gray-300">

  <div data-autocomplete-target="results"
       class="hidden absolute top-full left-0 right-0 bg-white border rounded-md shadow-lg mt-1 max-h-60 overflow-auto z-50">
  </div>
</div>
```

### 検索結果パーシャル

```erb
<%# app/views/posts/_search_results.html.erb %>
<% if @posts.any? %>
  <ul class="divide-y divide-gray-100">
    <% @posts.limit(5).each do |post| %>
      <li>
        <%= link_to post_path(post),
            class: 'block px-4 py-2 hover:bg-gray-50' do %>
          <p class="text-sm font-medium text-gray-900 truncate">
            <%= post.trigger_content %>
          </p>
          <p class="text-xs text-gray-500 truncate">
            <%= post.action_plan %>
          </p>
        <% end %>
      </li>
    <% end %>
  </ul>
<% else %>
  <p class="px-4 py-2 text-sm text-gray-500">
    結果が見つかりません
  </p>
<% end %>
```

## 高度な検索

### カスタムスコープ

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  # カスタムRansacker
  ransacker :achieved_recently do
    Arel.sql("(SELECT COUNT(*) FROM achievements WHERE achievements.post_id = posts.id AND achievements.achieved_on > '#{1.week.ago.to_date}')")
  end

  # Ransackで使用可能
  def self.ransackable_attributes(auth_object = nil)
    super + ['achieved_recently']
  end
end
```

### 関連テーブルの検索

```erb
<%# ユーザー名で検索 %>
<%= f.search_field :user_name_cont, placeholder: 'ユーザー名' %>
```

```ruby
# コントローラー
@q = Post.ransack(params[:q])
@posts = @q.result.includes(:user)
```

### 複雑な条件

```ruby
# コントローラーで条件を追加
def index
  @q = Post.ransack(params[:q])
  @posts = @q.result

  # 自分の投稿のみ
  @posts = @posts.where(user: current_user) if params[:mine]

  # 達成済みのみ
  if params[:achieved]
    @posts = @posts.joins(:achievements)
                   .where(achievements: { user: current_user })
                   .distinct
  end

  @posts = @posts.includes(:user).recent.page(params[:page])
end
```

## 検索フォームの保持

```erb
<%# 検索条件をリンクに引き継ぐ %>
<%= link_to 'CSVエクスポート', posts_path(format: :csv, q: params[:q]) %>

<%# ページネーションでも保持 %>
<%= paginate @posts, params: params.permit(:q).to_h %>
```

## テスト

### Request Spec

```ruby
# spec/requests/posts_spec.rb
RSpec.describe 'Posts', type: :request do
  describe 'GET /posts' do
    let!(:post1) { create(:post, trigger_content: 'プログラミング') }
    let!(:post2) { create(:post, trigger_content: 'デザイン') }

    it 'キーワードで検索できる' do
      get posts_path, params: { q: { trigger_content_cont: 'プログラミング' } }

      expect(response.body).to include('プログラミング')
      expect(response.body).not_to include('デザイン')
    end

    it 'カテゴリで絞り込める' do
      post1.update(category: :text)
      post2.update(category: :video)

      get posts_path, params: { q: { category_eq: 'text' } }

      expect(response.body).to include(post1.trigger_content)
      expect(response.body).not_to include(post2.trigger_content)
    end
  end
end
```

## セキュリティ

### 許可する属性の制限

```ruby
# 必ず ransackable_attributes を定義する
def self.ransackable_attributes(auth_object = nil)
  # 許可する属性のみ
  %w[trigger_content action_plan category created_at]
  # 以下は許可しない
  # - id, user_id（IDによる推測攻撃防止）
  # - updated_at（不要）
end
```

### SQLインジェクション対策

Ransackは内部でサニタイズを行いますが、カスタムRansackerを使用する場合は注意が必要です。

```ruby
# 悪い例（危険）
ransacker :custom do
  Arel.sql(params[:column])  # SQLインジェクションの可能性
end

# 良い例
ransacker :custom do
  Arel.sql("posts.achievement_count")  # 固定値
end
```

---

*関連ドキュメント*: `02_hotwire.md`, `../01_technical_design/02_database.md`
