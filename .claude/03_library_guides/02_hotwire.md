# Hotwire 実装パターン

## 概要

ActionSparkにおけるHotwire（Turbo + Stimulus）の実装パターンを定義します。

## Turbo Drive

### 基本動作

Turbo Driveはデフォルトで有効になり、すべてのリンクとフォーム送信をAjax化します。

```erb
<%# 通常のリンク（Turbo Driveが自動適用） %>
<%= link_to '投稿一覧', posts_path %>

<%# Turboを無効化したい場合 %>
<%= link_to '外部リンク', 'https://example.com', data: { turbo: false } %>
```

### フォーム送信

```erb
<%# 通常のフォーム %>
<%= form_with model: @post do |f| %>
  <%= f.text_area :trigger_content %>
  <%= f.submit %>
<% end %>

<%# Turboを無効化（ファイルダウンロードなど） %>
<%= form_with url: export_path, data: { turbo: false } do |f| %>
  <%= f.submit 'エクスポート' %>
<% end %>
```

### リダイレクト

```ruby
# コントローラーでのリダイレクト（通常通り）
def create
  @post = current_user.posts.build(post_params)
  if @post.save
    redirect_to @post, notice: '投稿を作成しました'
  else
    render :new, status: :unprocessable_entity
  end
end
```

### HTTPメソッド

```erb
<%# DELETEメソッド %>
<%= link_to '削除', post_path(@post), data: { turbo_method: :delete } %>

<%# 確認ダイアログ付き %>
<%= link_to '削除', post_path(@post),
    data: { turbo_method: :delete, turbo_confirm: '本当に削除しますか？' } %>
```

## Turbo Frames

### 基本的な使い方

```erb
<%# 親ページ %>
<%= turbo_frame_tag 'post_form' do %>
  <%= link_to '編集', edit_post_path(@post) %>
<% end %>

<%# 編集ページ（edit.html.erb） %>
<%= turbo_frame_tag 'post_form' do %>
  <%= form_with model: @post do |f| %>
    ...
  <% end %>
<% end %>
```

### DOM ID を使用

```erb
<%# 一覧での各アイテム %>
<% @posts.each do |post| %>
  <%= turbo_frame_tag dom_id(post) do %>
    <%= render 'post', post: post %>
  <% end %>
<% end %>

<%# 編集後に置き換え %>
<%= turbo_frame_tag dom_id(@post) do %>
  <%= render 'post', post: @post %>
<% end %>
```

### 遅延読み込み

```erb
<%# 遅延読み込み %>
<%= turbo_frame_tag 'comments',
    src: post_comments_path(@post),
    loading: :lazy do %>
  <div class="animate-pulse">
    <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
    <div class="h-4 bg-gray-200 rounded w-1/2"></div>
  </div>
<% end %>
```

### フレーム外への遷移

```erb
<%# フレーム内からページ全体を更新 %>
<%= link_to '詳細', post_path(@post), data: { turbo_frame: '_top' } %>

<%# 別のフレームを更新 %>
<%= link_to '編集', edit_post_path(@post), data: { turbo_frame: 'modal' } %>
```

## Turbo Streams

### レスポンス形式

```ruby
class PostsController < ApplicationController
  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @post }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

### Turbo Stream テンプレート

```erb
<%# app/views/posts/create.turbo_stream.erb %>

<%# 一覧の先頭に追加 %>
<%= turbo_stream.prepend 'posts' do %>
  <%= render @post %>
<% end %>

<%# フラッシュメッセージ更新 %>
<%= turbo_stream.update 'flash' do %>
  <%= render 'shared/flash', notice: '投稿を作成しました' %>
<% end %>

<%# フォームをリセット %>
<%= turbo_stream.replace 'new_post' do %>
  <%= render 'posts/form', post: Post.new %>
<% end %>
```

### アクション一覧

| アクション | 動作 |
|------------|------|
| append | 対象の末尾に追加 |
| prepend | 対象の先頭に追加 |
| replace | 対象全体を置換 |
| update | 対象の中身を更新 |
| remove | 対象を削除 |
| before | 対象の前に挿入 |
| after | 対象の後に挿入 |

### 実装例：いいねボタン

```ruby
# app/controllers/likes_controller.rb
class LikesController < ApplicationController
  def create
    @post = Post.find(params[:post_id])
    @like = @post.likes.build(user: current_user)

    if @like.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @post }
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @like = current_user.likes.find_by!(post_id: params[:post_id])
    @post = @like.post
    @like.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  end
end
```

```erb
<%# app/views/likes/create.turbo_stream.erb %>
<%= turbo_stream.replace dom_id(@post, :like_button) do %>
  <%= render 'posts/like_button', post: @post %>
<% end %>

<%# app/views/likes/destroy.turbo_stream.erb %>
<%= turbo_stream.replace dom_id(@post, :like_button) do %>
  <%= render 'posts/like_button', post: @post %>
<% end %>
```

```erb
<%# app/views/posts/_like_button.html.erb %>
<%= turbo_frame_tag dom_id(post, :like_button) do %>
  <% if current_user&.liked?(post) %>
    <%= button_to post_like_path(post),
        method: :delete,
        class: 'flex items-center gap-1 text-red-500' do %>
      <svg class="w-5 h-5 fill-current">...</svg>
      <span><%= post.likes.count %></span>
    <% end %>
  <% else %>
    <%= button_to post_likes_path(post),
        class: 'flex items-center gap-1 text-gray-500 hover:text-red-500' do %>
      <svg class="w-5 h-5">...</svg>
      <span><%= post.likes.count %></span>
    <% end %>
  <% end %>
<% end %>
```

### 実装例：達成ボタン

```ruby
# app/controllers/achievements_controller.rb
class AchievementsController < ApplicationController
  def create
    @post = Post.find(params[:post_id])
    @achievement = @post.achievements.build(
      user: current_user,
      achieved_on: Date.current
    )

    if @achievement.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @post }
      end
    else
      head :unprocessable_entity
    end
  end
end
```

```erb
<%# app/views/achievements/create.turbo_stream.erb %>
<%= turbo_stream.replace dom_id(@post, :achievement) do %>
  <%= render 'posts/achievement_section', post: @post.reload %>
<% end %>
```

## Stimulus

### コントローラー基本構造

```javascript
// app/javascript/controllers/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static values = { name: String }

  connect() {
    console.log("Hello controller connected")
  }

  greet() {
    this.outputTarget.textContent = `Hello, ${this.nameValue}!`
  }
}
```

```erb
<div data-controller="hello" data-hello-name-value="World">
  <button data-action="click->hello#greet">挨拶</button>
  <span data-hello-target="output"></span>
</div>
```

### 文字数カウンター

```javascript
// app/javascript/controllers/character_counter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "count"]
  static values = { max: Number }

  connect() {
    this.update()
  }

  update() {
    const count = this.inputTarget.value.length
    this.countTarget.textContent = count

    if (count > this.maxValue) {
      this.countTarget.classList.add('text-red-500')
    } else {
      this.countTarget.classList.remove('text-red-500')
    }
  }
}
```

```erb
<div data-controller="character-counter" data-character-counter-max-value="100">
  <%= f.text_area :trigger_content,
      data: {
        character_counter_target: 'input',
        action: 'input->character-counter#update'
      } %>
  <span data-character-counter-target="count">0</span>/100
</div>
```

### Flashメッセージの自動非表示

```javascript
// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { removeAfter: { type: Number, default: 5000 } }

  connect() {
    if (this.removeAfterValue > 0) {
      setTimeout(() => this.remove(), this.removeAfterValue)
    }
  }

  remove() {
    this.element.classList.add('opacity-0', 'transition-opacity', 'duration-300')
    setTimeout(() => this.element.remove(), 300)
  }
}
```

### ドロップダウンメニュー

```javascript
// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    this.menuTarget.classList.toggle('hidden')
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add('hidden')
    }
  }

  connect() {
    document.addEventListener('click', this.hide.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.hide.bind(this))
  }
}
```

```erb
<div data-controller="dropdown" class="relative">
  <button data-action="click->dropdown#toggle">
    メニュー
  </button>
  <div data-dropdown-target="menu" class="hidden absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg">
    <%= link_to 'プロフィール', user_path(current_user) %>
    <%= link_to 'ログアウト', destroy_user_session_path, data: { turbo_method: :delete } %>
  </div>
</div>
```

### モーダル

```javascript
// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    document.body.classList.add('overflow-hidden')
  }

  disconnect() {
    document.body.classList.remove('overflow-hidden')
  }

  close() {
    this.element.remove()
  }

  // Escキーで閉じる
  closeWithKeyboard(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }
}
```

### 達成アニメーション

```javascript
// app/javascript/controllers/achievement_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "badge"]

  celebrate() {
    // バッジをアニメーション
    this.badgeTarget.classList.add('animate-bounce')
    setTimeout(() => {
      this.badgeTarget.classList.remove('animate-bounce')
    }, 1000)

    // 紙吹雪エフェクト（オプション）
    this.showConfetti()
  }

  showConfetti() {
    // 簡易的な紙吹雪
    const colors = ['#FACC15', '#10B981', '#3B82F6']
    for (let i = 0; i < 50; i++) {
      const confetti = document.createElement('div')
      confetti.style.cssText = `
        position: fixed;
        width: 10px;
        height: 10px;
        background: ${colors[Math.floor(Math.random() * colors.length)]};
        top: ${Math.random() * 100}%;
        left: ${Math.random() * 100}%;
        animation: fall 3s linear forwards;
      `
      document.body.appendChild(confetti)
      setTimeout(() => confetti.remove(), 3000)
    }
  }
}
```

## ベストプラクティス

### Turbo Frame vs Turbo Stream

| 状況 | 推奨 |
|------|------|
| 単一要素の更新 | Turbo Frame |
| 複数要素の同時更新 | Turbo Stream |
| インライン編集 | Turbo Frame |
| リスト操作（追加/削除） | Turbo Stream |

### パフォーマンス

```erb
<%# 遅延読み込みを活用 %>
<%= turbo_frame_tag 'comments', src: comments_path, loading: :lazy %>

<%# 不要な場合はTurboを無効化 %>
<%= link_to '大きなファイル', file_path, data: { turbo: false } %>
```

### エラーハンドリング

```ruby
def create
  @post = current_user.posts.build(post_params)

  if @post.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  else
    # 422ステータスが重要
    render :new, status: :unprocessable_entity
  end
end
```

---

*関連ドキュメント*: `01_devise.md`, `../01_technical_design/03_api_design.md`
