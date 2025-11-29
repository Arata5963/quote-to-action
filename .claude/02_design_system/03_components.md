# コンポーネント設計

## 概要

ActionSparkで使用する共通UIコンポーネントの実装パターンを定義します。

## ボタン

### 基本ボタン

```erb
<%# プライマリボタン %>
<button class="bg-black text-white px-4 py-2 rounded-md hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black transition-colors">
  投稿する
</button>

<%# セカンダリボタン %>
<button class="bg-white text-black border border-black px-4 py-2 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black transition-colors">
  キャンセル
</button>

<%# ゴーストボタン %>
<button class="text-black px-4 py-2 rounded-md hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-black transition-colors">
  詳細
</button>
```

### サイズバリエーション

```erb
<%# Small %>
<button class="px-3 py-1.5 text-sm rounded">Small</button>

<%# Medium (default) %>
<button class="px-4 py-2 text-base rounded-md">Medium</button>

<%# Large %>
<button class="px-6 py-3 text-lg rounded-lg">Large</button>
```

### 達成ボタン（特殊）

```erb
<%# 未達成状態 %>
<button class="bg-yellow-400 text-black px-6 py-3 rounded-lg font-bold shadow-lg hover:bg-yellow-500 hover:shadow-xl active:scale-95 transform transition-all"
        data-controller="achievement"
        data-action="click->achievement#record">
  達成！
</button>

<%# 達成済み状態 %>
<button class="bg-emerald-500 text-white px-6 py-3 rounded-lg font-bold cursor-not-allowed" disabled>
  ✓ 今日は達成済み
</button>
```

### ボタンヘルパー（推奨）

```ruby
# app/helpers/button_helper.rb
module ButtonHelper
  def btn_primary(text, options = {})
    base_class = 'bg-black text-white px-4 py-2 rounded-md hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black transition-colors'
    options[:class] = [base_class, options[:class]].compact.join(' ')
    button_tag(text, options)
  end

  def btn_secondary(text, options = {})
    base_class = 'bg-white text-black border border-black px-4 py-2 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black transition-colors'
    options[:class] = [base_class, options[:class]].compact.join(' ')
    button_tag(text, options)
  end
end
```

## カード

### 投稿カード

```erb
<%# app/views/posts/_card.html.erb %>
<div class="bg-white rounded-lg shadow hover:shadow-md transition-shadow p-4">
  <%# ヘッダー %>
  <div class="flex items-center justify-between mb-3">
    <div class="flex items-center gap-2">
      <%= image_tag post.user.avatar_url, class: 'w-8 h-8 rounded-full', alt: post.user.name %>
      <span class="text-sm font-medium text-gray-900"><%= post.user.name %></span>
    </div>
    <span class="text-xs text-gray-500"><%= time_ago_in_words(post.created_at) %>前</span>
  </div>

  <%# コンテンツ %>
  <div class="space-y-2">
    <div class="flex items-start gap-2">
      <span class="text-lg"><%= category_icon(post.category) %></span>
      <p class="text-gray-800"><%= post.trigger_content %></p>
    </div>
    <div class="bg-gray-50 rounded p-3">
      <p class="text-sm text-gray-600">
        <span class="font-medium">Action:</span> <%= post.action_plan %>
      </p>
    </div>
  </div>

  <%# フッター %>
  <div class="flex items-center justify-between mt-4 pt-3 border-t border-gray-100">
    <div class="flex items-center gap-4">
      <%= render 'posts/like_button', post: post %>
      <%= link_to post_path(post), class: 'flex items-center gap-1 text-gray-500 hover:text-gray-700' do %>
        <svg class="w-5 h-5">...</svg>
        <span class="text-sm"><%= post.comments.count %></span>
      <% end %>
    </div>
    <div class="flex items-center gap-2">
      <span class="text-xl"><%= achievement_badge(post) %></span>
      <span class="text-sm text-gray-500"><%= post.achievement_count %></span>
    </div>
  </div>
</div>
```

### シンプルカード

```erb
<div class="bg-white rounded-lg shadow p-6">
  <h3 class="text-lg font-semibold text-gray-900 mb-2">タイトル</h3>
  <p class="text-gray-600">コンテンツ</p>
</div>
```

## フォーム

### テキスト入力

```erb
<div class="space-y-1">
  <%= f.label :trigger_content, 'きっかけ', class: 'block text-sm font-medium text-gray-700' %>
  <%= f.text_area :trigger_content,
      rows: 3,
      class: 'mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-black focus:ring-black',
      placeholder: '心に響いた瞬間を記録...',
      maxlength: 100,
      data: { controller: 'character-counter', character_counter_max_value: 100 } %>
  <p class="text-xs text-gray-500 text-right">
    <span data-character-counter-target="count">0</span>/100
  </p>
</div>
```

### セレクトボックス

```erb
<div class="space-y-1">
  <%= f.label :category, 'カテゴリ', class: 'block text-sm font-medium text-gray-700' %>
  <%= f.select :category,
      Post.categories.keys.map { |c| [category_label(c), c] },
      {},
      class: 'mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-black focus:ring-black' %>
</div>
```

### ファイルアップロード

```erb
<div class="space-y-1">
  <%= f.label :image, '画像', class: 'block text-sm font-medium text-gray-700' %>
  <div class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md hover:border-gray-400 transition-colors">
    <div class="space-y-1 text-center">
      <svg class="mx-auto h-12 w-12 text-gray-400">...</svg>
      <div class="flex text-sm text-gray-600">
        <label class="relative cursor-pointer rounded-md font-medium text-black hover:text-gray-700">
          <span>ファイルを選択</span>
          <%= f.file_field :image, class: 'sr-only', accept: 'image/*' %>
        </label>
        <p class="pl-1">またはドラッグ＆ドロップ</p>
      </div>
      <p class="text-xs text-gray-500">PNG, JPG, GIF (5MBまで)</p>
    </div>
  </div>
</div>
```

### フォームエラー

```erb
<% if f.object.errors.any? %>
  <div class="bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
    <div class="flex">
      <svg class="h-5 w-5 text-red-400">...</svg>
      <div class="ml-3">
        <h3 class="text-sm font-medium text-red-800">
          <%= pluralize(f.object.errors.count, '件') %>のエラーがあります
        </h3>
        <ul class="mt-2 text-sm text-red-700 list-disc list-inside">
          <% f.object.errors.full_messages.each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>
    </div>
  </div>
<% end %>
```

## バッジ

### カテゴリバッジ

```erb
<%# app/helpers/category_helper.rb %>
<%
def category_badge(category)
  colors = {
    'text' => 'bg-blue-100 text-blue-800',
    'video' => 'bg-red-100 text-red-800',
    'audio' => 'bg-purple-100 text-purple-800',
    'conversation' => 'bg-green-100 text-green-800',
    'experience' => 'bg-yellow-100 text-yellow-800',
    'observation' => 'bg-orange-100 text-orange-800',
    'other' => 'bg-gray-100 text-gray-800'
  }

  content_tag :span, category_label(category),
    class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{colors[category]}"
end
%>
```

### ステータスバッジ

```erb
<%# 達成バッジ %>
<span class="inline-flex items-center px-2 py-1 rounded-full text-sm">
  <span class="text-lg mr-1"><%= achievement_badge(post) %></span>
  <span class="text-gray-600"><%= post.achievement_count %>回</span>
</span>
```

## モーダル

### 基本モーダル

```erb
<%# app/views/shared/_modal.html.erb %>
<div class="fixed inset-0 z-40 overflow-y-auto"
     data-controller="modal"
     data-action="keydown.esc->modal#close">
  <%# オーバーレイ %>
  <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity"
       data-action="click->modal#close"></div>

  <%# モーダルコンテンツ %>
  <div class="relative min-h-screen flex items-center justify-center p-4">
    <div class="relative bg-white rounded-xl shadow-xl max-w-lg w-full p-6">
      <%# 閉じるボタン %>
      <button class="absolute top-4 right-4 text-gray-400 hover:text-gray-500"
              data-action="click->modal#close">
        <svg class="h-6 w-6">...</svg>
      </button>

      <%# コンテンツ %>
      <%= yield %>
    </div>
  </div>
</div>
```

### 確認ダイアログ

```erb
<%= turbo_frame_tag 'modal' do %>
  <div class="fixed inset-0 z-40 overflow-y-auto" data-controller="modal">
    <div class="fixed inset-0 bg-black bg-opacity-50"></div>
    <div class="relative min-h-screen flex items-center justify-center p-4">
      <div class="bg-white rounded-xl shadow-xl max-w-md w-full p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-2">削除の確認</h3>
        <p class="text-gray-600 mb-6">この投稿を削除しますか？この操作は取り消せません。</p>
        <div class="flex gap-3 justify-end">
          <%= link_to 'キャンセル', posts_path, class: 'btn btn-secondary' %>
          <%= button_to '削除', post_path(@post), method: :delete, class: 'btn bg-red-600 text-white hover:bg-red-700' %>
        </div>
      </div>
    </div>
  </div>
<% end %>
```

## ナビゲーション

### ヘッダー

```erb
<header class="bg-white border-b border-gray-200 sticky top-0 z-20">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="flex justify-between h-16">
      <%# ロゴ %>
      <%= link_to root_path, class: 'flex items-center' do %>
        <span class="text-xl font-bold">ActionSpark</span>
      <% end %>

      <%# ナビゲーション %>
      <nav class="hidden md:flex items-center gap-4">
        <%= link_to '投稿一覧', posts_path, class: 'text-gray-600 hover:text-black' %>
        <% if user_signed_in? %>
          <%= link_to new_post_path, class: 'btn btn-primary' do %>
            + 投稿する
          <% end %>
        <% end %>
      </nav>

      <%# ユーザーメニュー %>
      <div class="flex items-center">
        <% if user_signed_in? %>
          <%= render 'shared/user_dropdown' %>
        <% else %>
          <%= link_to 'ログイン', new_user_session_path, class: 'btn btn-secondary' %>
        <% end %>
      </div>
    </div>
  </div>
</header>
```

### タブ

```erb
<div class="border-b border-gray-200">
  <nav class="flex gap-8">
    <%= link_to '全体', posts_path,
        class: "py-4 px-1 border-b-2 font-medium text-sm #{@tab == 'all' ? 'border-black text-black' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}" %>
    <%= link_to '自分の投稿', posts_path(tab: 'mine'),
        class: "py-4 px-1 border-b-2 font-medium text-sm #{@tab == 'mine' ? 'border-black text-black' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}" %>
  </nav>
</div>
```

## アラート/通知

### Flash メッセージ

```erb
<%# app/views/shared/_flash.html.erb %>
<div id="flash" class="fixed top-4 right-4 z-50 space-y-2">
  <% flash.each do |type, message| %>
    <%
      styles = {
        'notice' => 'bg-emerald-50 border-emerald-200 text-emerald-800',
        'alert' => 'bg-red-50 border-red-200 text-red-800',
        'info' => 'bg-blue-50 border-blue-200 text-blue-800'
      }
    %>
    <div class="<%= styles[type] || styles['info'] %> border rounded-lg p-4 shadow-lg max-w-sm"
         data-controller="flash"
         data-flash-remove-after-value="5000">
      <div class="flex items-start gap-3">
        <span class="flex-1"><%= message %></span>
        <button data-action="click->flash#remove" class="opacity-50 hover:opacity-100">
          <svg class="w-4 h-4">...</svg>
        </button>
      </div>
    </div>
  <% end %>
</div>
```

## ページネーション

```erb
<%# app/views/shared/_pagination.html.erb %>
<nav class="flex items-center justify-center gap-2 my-8">
  <%= paginate @posts, theme: 'tailwind' %>
</nav>
```

### Kaminari Tailwindテーマ

```erb
<%# app/views/kaminari/_paginator.html.erb %>
<nav class="flex items-center gap-1">
  <%= first_page_tag unless current_page.first? %>
  <%= prev_page_tag unless current_page.first? %>
  <% each_page do |page| %>
    <% if page.left_outer? || page.right_outer? || page.inside_window? %>
      <%= page_tag page %>
    <% elsif !page.was_truncated? %>
      <%= gap_tag %>
    <% end %>
  <% end %>
  <%= next_page_tag unless current_page.last? %>
  <%= last_page_tag unless current_page.last? %>
</nav>
```

---

*関連ドキュメント*: `01_design_tokens.md`, `02_design_principles.md`, `04_layouts.md`
