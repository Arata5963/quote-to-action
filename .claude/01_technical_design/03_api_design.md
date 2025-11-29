# API設計

## 概要

ActionSparkはRails標準のRESTful設計に従い、Hotwire（Turbo）を活用した非同期通信を行います。

## ルーティング設計

### リソース一覧

| リソース | パス | 主な用途 |
|----------|------|----------|
| Posts | `/posts` | 投稿管理 |
| Achievements | `/posts/:post_id/achievements` | 達成記録 |
| Comments | `/posts/:post_id/comments` | コメント |
| Likes | `/posts/:post_id/likes` | いいね |
| Users | `/users/:id` | ユーザープロフィール |

### routes.rb 設計

```ruby
Rails.application.routes.draw do
  # Devise（認証）
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  # メインリソース
  resources :posts do
    resources :achievements, only: [:create, :destroy]
    resources :comments, only: [:create, :destroy]
    resources :likes, only: [:create, :destroy]
  end

  # ユーザープロフィール
  resources :users, only: [:show, :edit, :update]

  # 静的ページ
  root 'posts#index'
  get 'about', to: 'static_pages#about'
  get 'terms', to: 'static_pages#terms'
  get 'privacy', to: 'static_pages#privacy'
end
```

## RESTfulアクション設計

### PostsController

| アクション | HTTPメソッド | パス | 用途 |
|------------|--------------|------|------|
| index | GET | /posts | 投稿一覧 |
| show | GET | /posts/:id | 投稿詳細 |
| new | GET | /posts/new | 投稿作成フォーム |
| create | POST | /posts | 投稿作成 |
| edit | GET | /posts/:id/edit | 投稿編集フォーム |
| update | PATCH/PUT | /posts/:id | 投稿更新 |
| destroy | DELETE | /posts/:id | 投稿削除 |

### レスポンス形式

#### HTML（通常リクエスト）

```ruby
def create
  @post = current_user.posts.build(post_params)
  if @post.save
    redirect_to @post, notice: '投稿を作成しました'
  else
    render :new, status: :unprocessable_entity
  end
end
```

#### Turbo Stream（非同期リクエスト）

```ruby
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
```

```erb
<%# app/views/posts/create.turbo_stream.erb %>
<%= turbo_stream.prepend "posts" do %>
  <%= render @post %>
<% end %>

<%= turbo_stream.update "flash" do %>
  <%= render 'shared/flash', notice: '投稿を作成しました' %>
<% end %>
```

## パラメータ設計

### Strong Parameters

```ruby
class PostsController < ApplicationController
  private

  def post_params
    params.require(:post).permit(
      :trigger_content,
      :action_plan,
      :category,
      :image,
      :related_url
    )
  end
end
```

### 検索パラメータ（Ransack）

```ruby
def index
  @q = Post.ransack(params[:q])
  @posts = @q.result
             .includes(:user, :achievements)
             .recent
             .page(params[:page])
end
```

許可するパラメータ:
- `q[trigger_content_or_action_plan_cont]`: フリーワード検索
- `q[category_eq]`: カテゴリ絞り込み
- `q[user_id_eq]`: ユーザー絞り込み

## エラーレスポンス

### HTTPステータスコード

| コード | 用途 |
|--------|------|
| 200 | 成功 |
| 201 | 作成成功 |
| 302 | リダイレクト |
| 400 | Bad Request |
| 401 | 認証エラー |
| 403 | 認可エラー |
| 404 | Not Found |
| 422 | Validation Error |
| 500 | サーバーエラー |

### バリデーションエラー

```ruby
def create
  @post = current_user.posts.build(post_params)
  if @post.save
    redirect_to @post
  else
    # 422ステータスでフォームを再レンダリング
    render :new, status: :unprocessable_entity
  end
end
```

### 認証・認可エラー

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found
    render file: Rails.public_path.join('404.html'),
           status: :not_found,
           layout: false
  end
end
```

## Turbo Frame設計

### Frame ID命名規則

```erb
<%# リスト系 %>
<%= turbo_frame_tag "posts" %>
<%= turbo_frame_tag "comments" %>

<%# 個別アイテム %>
<%= turbo_frame_tag dom_id(@post) %>
<%= turbo_frame_tag dom_id(@comment) %>

<%# 特定コンポーネント %>
<%= turbo_frame_tag "post_#{@post.id}_actions" %>
<%= turbo_frame_tag "flash" %>
```

### 遅延読み込み

```erb
<%= turbo_frame_tag "recent_posts", src: posts_path(recent: true), loading: :lazy do %>
  <%= render 'shared/loading' %>
<% end %>
```

## API実装例

### 達成記録（Achievement）

```ruby
class AchievementsController < ApplicationController
  before_action :authenticate_user!

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

  def destroy
    @achievement = current_user.achievements.find(params[:id])
    @post = @achievement.post
    @achievement.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  end
end
```

### いいね（Like）

```ruby
class LikesController < ApplicationController
  before_action :authenticate_user!

  def create
    @post = Post.find(params[:post_id])
    @like = @post.likes.build(user: current_user)

    respond_to do |format|
      if @like.save
        format.turbo_stream
        format.html { redirect_to @post }
      else
        format.html { redirect_to @post, alert: '既にいいね済みです' }
      end
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

## セキュリティ考慮事項

1. **CSRF保護**: Rails標準のauthenticity_tokenを必ず使用
2. **認証チェック**: `before_action :authenticate_user!`
3. **認可チェック**: 必ず`current_user`スコープを使用
4. **パラメータ制限**: Strong Parametersで許可リスト方式

```ruby
# 良い例：current_userスコープ
@post = current_user.posts.find(params[:id])

# 悪い例：誰でも編集可能になる
@post = Post.find(params[:id])
```

---

*関連ドキュメント*: `01_architecture.md`, `04_screen_flow.md`, `06_security.md`
