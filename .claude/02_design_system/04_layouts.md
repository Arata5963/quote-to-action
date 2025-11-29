# レイアウトシステム

## 概要

ActionSparkのレイアウト構造とグリッドシステムを定義します。

## 基本レイアウト

### アプリケーションレイアウト

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= display_meta_tags site: 'ActionSpark' %>
  <%= stylesheet_link_tag 'application', 'data-turbo-track': 'reload' %>
  <%= javascript_include_tag 'application', 'data-turbo-track': 'reload', defer: true %>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col">
  <%= render 'shared/header' %>
  <%= render 'shared/flash' %>

  <main id="main-content" class="flex-1">
    <%= yield %>
  </main>

  <%= render 'shared/footer' %>
</body>
</html>
```

### 認証レイアウト

```erb
<%# app/views/layouts/devise.html.erb %>
<!DOCTYPE html>
<html lang="ja">
<head>
  <!-- 同上 -->
</head>
<body class="bg-gray-100 min-h-screen flex items-center justify-center">
  <div class="max-w-md w-full mx-4">
    <div class="text-center mb-8">
      <%= link_to root_path do %>
        <h1 class="text-3xl font-bold">ActionSpark</h1>
      <% end %>
    </div>

    <%= render 'shared/flash' %>

    <div class="bg-white rounded-xl shadow-lg p-8">
      <%= yield %>
    </div>
  </div>
</body>
</html>
```

## コンテナ

### 標準コンテナ

```erb
<%# 最大幅制限付きセンタリング %>
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
  <!-- コンテンツ -->
</div>
```

### コンテナサイズ

| 名前 | 最大幅 | 用途 |
|------|--------|------|
| sm | 640px | フォーム、モーダル |
| md | 768px | 認証画面 |
| lg | 1024px | 記事コンテンツ |
| xl | 1280px | 一般ページ |
| 7xl | 1280px | アプリケーション全体 |

```erb
<%# 例：フォーム用の狭いコンテナ %>
<div class="max-w-lg mx-auto px-4">
  <%= form_with model: @post do |f| %>
    ...
  <% end %>
</div>

<%# 例：一般ページ用 %>
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
  ...
</div>
```

## グリッドシステム

### 基本グリッド

```erb
<%# 3カラムグリッド（レスポンシブ） %>
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <% @posts.each do |post| %>
    <%= render 'posts/card', post: post %>
  <% end %>
</div>
```

### ギャップ（Gap）

| サイズ | 値 | 用途 |
|--------|-----|------|
| gap-2 | 8px | 緊密なレイアウト |
| gap-4 | 16px | 標準 |
| gap-6 | 24px | ゆったり |
| gap-8 | 32px | セクション間 |

### よく使うグリッドパターン

```erb
<%# 2カラム（サイドバー＋メイン） %>
<div class="grid grid-cols-1 lg:grid-cols-4 gap-8">
  <aside class="lg:col-span-1">
    <!-- サイドバー -->
  </aside>
  <main class="lg:col-span-3">
    <!-- メインコンテンツ -->
  </main>
</div>

<%# 等幅2カラム %>
<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
  <div>左</div>
  <div>右</div>
</div>

<%# オートフィル（最小幅指定） %>
<div class="grid grid-cols-[repeat(auto-fill,minmax(280px,1fr))] gap-4">
  <!-- カードが自動的に並ぶ -->
</div>
```

## Flexbox

### 中央揃え

```erb
<%# 水平・垂直中央 %>
<div class="flex items-center justify-center min-h-screen">
  <div>中央コンテンツ</div>
</div>

<%# 水平中央のみ %>
<div class="flex justify-center">
  <div>コンテンツ</div>
</div>
```

### スペース配分

```erb
<%# 両端揃え %>
<div class="flex justify-between items-center">
  <span>左</span>
  <span>右</span>
</div>

<%# 均等配分 %>
<div class="flex justify-around">
  <span>A</span>
  <span>B</span>
  <span>C</span>
</div>
```

### 方向

```erb
<%# 縦方向（モバイル）→横方向（デスクトップ） %>
<div class="flex flex-col md:flex-row gap-4">
  <div>アイテム1</div>
  <div>アイテム2</div>
</div>
```

## ページレイアウトパターン

### 投稿一覧ページ

```erb
<%# app/views/posts/index.html.erb %>
<div class="py-8">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <%# ページヘッダー %>
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-900">投稿一覧</h1>
    </div>

    <%# フィルター %>
    <div class="mb-6">
      <%= render 'posts/filters' %>
    </div>

    <%# タブ %>
    <div class="mb-6">
      <%= render 'posts/tabs' %>
    </div>

    <%# 投稿グリッド %>
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <%= render @posts %>
    </div>

    <%# ページネーション %>
    <div class="mt-8">
      <%= paginate @posts %>
    </div>
  </div>
</div>
```

### 投稿詳細ページ

```erb
<%# app/views/posts/show.html.erb %>
<div class="py-8">
  <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
    <%# 戻るリンク %>
    <div class="mb-4">
      <%= link_to '← 一覧に戻る', posts_path, class: 'text-gray-600 hover:text-black' %>
    </div>

    <%# メインカード %>
    <div class="bg-white rounded-xl shadow-lg p-6 mb-6">
      <%= render 'posts/detail', post: @post %>
    </div>

    <%# 達成セクション %>
    <div class="bg-white rounded-xl shadow p-6 mb-6 text-center">
      <%= render 'posts/achievement_section', post: @post %>
    </div>

    <%# コメントセクション %>
    <div class="bg-white rounded-xl shadow p-6">
      <%= render 'comments/section', post: @post %>
    </div>
  </div>
</div>
```

### フォームページ

```erb
<%# app/views/posts/new.html.erb %>
<div class="py-8">
  <div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
    <h1 class="text-2xl font-bold text-gray-900 mb-6">新規投稿</h1>

    <div class="bg-white rounded-xl shadow-lg p-6">
      <%= render 'form', post: @post %>
    </div>
  </div>
</div>
```

### マイページ

```erb
<%# app/views/users/show.html.erb %>
<div class="py-8">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <%# プロフィールヘッダー %>
    <div class="bg-white rounded-xl shadow-lg p-6 mb-6">
      <div class="flex items-center gap-4">
        <%= image_tag @user.avatar_url, class: 'w-20 h-20 rounded-full' %>
        <div>
          <h1 class="text-2xl font-bold"><%= @user.name %></h1>
          <p class="text-gray-600">投稿 <%= @user.posts.count %> / 達成 <%= @user.achievements.count %></p>
        </div>
      </div>
    </div>

    <%# 投稿一覧 %>
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <%= render @user.posts %>
    </div>
  </div>
</div>
```

## スペーシング

### セクション間

```erb
<%# セクション間は大きめのスペーシング %>
<section class="py-12">
  <h2 class="text-xl font-bold mb-6">セクション1</h2>
  ...
</section>

<section class="py-12">
  <h2 class="text-xl font-bold mb-6">セクション2</h2>
  ...
</section>
```

### 要素間

```erb
<%# 関連要素はspace-yで統一 %>
<div class="space-y-4">
  <div>要素1</div>
  <div>要素2</div>
  <div>要素3</div>
</div>
```

## レスポンシブパターン

### モバイル/デスクトップ切り替え

```erb
<%# モバイルでは非表示、デスクトップで表示 %>
<div class="hidden md:block">
  デスクトップ用コンテンツ
</div>

<%# モバイルで表示、デスクトップで非表示 %>
<div class="md:hidden">
  モバイル用コンテンツ
</div>
```

### スタック→横並び

```erb
<%# モバイル：縦積み、デスクトップ：横並び %>
<div class="flex flex-col md:flex-row gap-4">
  <div class="md:w-1/3">サイドバー</div>
  <div class="md:w-2/3">メイン</div>
</div>
```

### パディング調整

```erb
<%# 画面サイズに応じたパディング %>
<div class="p-4 md:p-6 lg:p-8">
  コンテンツ
</div>
```

## スティッキー要素

### スティッキーヘッダー

```erb
<header class="sticky top-0 z-20 bg-white border-b">
  ...
</header>
```

### スティッキーサイドバー

```erb
<aside class="sticky top-20 self-start">
  ...
</aside>
```

## フッター

```erb
<%# app/views/shared/_footer.html.erb %>
<footer class="bg-white border-t border-gray-200 mt-auto">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
      <div>
        <h3 class="font-bold text-lg mb-4">ActionSpark</h3>
        <p class="text-sm text-gray-600">きっかけを行動に変える</p>
      </div>
      <div>
        <h4 class="font-medium mb-4">リンク</h4>
        <ul class="space-y-2 text-sm">
          <li><%= link_to 'About', about_path, class: 'text-gray-600 hover:text-black' %></li>
          <li><%= link_to '利用規約', terms_path, class: 'text-gray-600 hover:text-black' %></li>
          <li><%= link_to 'プライバシー', privacy_path, class: 'text-gray-600 hover:text-black' %></li>
        </ul>
      </div>
      <div>
        <h4 class="font-medium mb-4">お問い合わせ</h4>
        <p class="text-sm text-gray-600">support@actionspark.example</p>
      </div>
    </div>
    <div class="border-t border-gray-200 mt-8 pt-8 text-center text-sm text-gray-500">
      &copy; <%= Time.current.year %> ActionSpark. All rights reserved.
    </div>
  </div>
</footer>
```

---

*関連ドキュメント*: `01_design_tokens.md`, `03_components.md`
