# エラーハンドリング

## 概要

ActionSparkにおけるエラーハンドリングの方針と実装パターンを定義します。

## エラー分類

### HTTPエラー

| コード | 名称 | 発生条件 | 対応 |
|--------|------|----------|------|
| 400 | Bad Request | 不正なリクエスト | エラーメッセージ表示 |
| 401 | Unauthorized | 未認証 | ログイン画面へリダイレクト |
| 403 | Forbidden | 認可エラー | 権限エラー画面 |
| 404 | Not Found | リソースが存在しない | 404画面 |
| 422 | Unprocessable Entity | バリデーションエラー | フォームエラー表示 |
| 500 | Internal Server Error | サーバー内部エラー | 500画面 |

### アプリケーションエラー

| 種類 | 例 | 対応 |
|------|-----|------|
| バリデーションエラー | 必須項目未入力 | インラインエラー表示 |
| ビジネスロジックエラー | 1日1回達成制限 | Flash メッセージ |
| 外部サービスエラー | 画像アップロード失敗 | ユーザーへ通知、リトライ促進 |

## 実装パターン

### ApplicationController

```ruby
class ApplicationController < ActionController::Base
  # 共通エラーハンドリング
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::RoutingError, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  private

  def not_found
    respond_to do |format|
      format.html { render 'errors/404', status: :not_found, layout: 'error' }
      format.json { render json: { error: 'Not Found' }, status: :not_found }
      format.turbo_stream { render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash', locals: { alert: 'ページが見つかりません' }) }
    end
  end

  def unprocessable_entity(exception)
    @errors = exception.record.errors
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: { errors: @errors }, status: :unprocessable_entity }
    end
  end
end
```

### Deviseエラー

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  # カスタムエラーメッセージ
  config.navigational_formats = ['*/*', :html, :turbo_stream]
end

# app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  def create
    super
  rescue => e
    flash[:alert] = 'ログインに失敗しました'
    redirect_to new_user_session_path
  end
end
```

### バリデーションエラー表示

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  validates :trigger_content, presence: { message: 'きっかけを入力してください' },
                              length: { maximum: 100, message: '100文字以内で入力してください' }
  validates :action_plan, presence: { message: 'アクションプランを入力してください' },
                          length: { maximum: 100, message: '100文字以内で入力してください' }
end
```

```erb
<%# app/views/shared/_form_errors.html.erb %>
<% if object.errors.any? %>
  <div class="bg-red-50 border border-red-200 rounded-lg p-4 mb-4" role="alert">
    <div class="flex">
      <div class="flex-shrink-0">
        <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
        </svg>
      </div>
      <div class="ml-3">
        <h3 class="text-sm font-medium text-red-800">
          <%= pluralize(object.errors.count, "件のエラー") %>があります
        </h3>
        <ul class="mt-2 text-sm text-red-700 list-disc list-inside">
          <% object.errors.full_messages.each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>
    </div>
  </div>
<% end %>
```

### Flashメッセージ

```ruby
# app/controllers/posts_controller.rb
def create
  @post = current_user.posts.build(post_params)
  if @post.save
    redirect_to @post, notice: '投稿を作成しました'
  else
    flash.now[:alert] = '投稿の作成に失敗しました'
    render :new, status: :unprocessable_entity
  end
end
```

```erb
<%# app/views/shared/_flash.html.erb %>
<div id="flash">
  <% flash.each do |type, message| %>
    <% bg_class = type == 'notice' ? 'bg-green-50 border-green-200 text-green-800' : 'bg-red-50 border-red-200 text-red-800' %>
    <div class="<%= bg_class %> border rounded-lg p-4 mb-4"
         data-controller="flash"
         data-flash-remove-after-value="5000">
      <div class="flex justify-between items-center">
        <span><%= message %></span>
        <button data-action="flash#remove" class="text-current opacity-50 hover:opacity-100">
          <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </div>
  <% end %>
</div>
```

### Stimulus Flash Controller

```javascript
// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { removeAfter: Number }

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

## エラーページ

### 404ページ

```erb
<%# app/views/errors/404.html.erb %>
<div class="min-h-screen flex items-center justify-center bg-gray-100">
  <div class="text-center">
    <h1 class="text-6xl font-bold text-gray-900">404</h1>
    <p class="mt-4 text-xl text-gray-600">ページが見つかりません</p>
    <p class="mt-2 text-gray-500">
      お探しのページは存在しないか、移動した可能性があります。
    </p>
    <div class="mt-6">
      <%= link_to 'トップページへ', root_path, class: 'btn btn-primary' %>
    </div>
  </div>
</div>
```

### 500ページ

```erb
<%# app/views/errors/500.html.erb %>
<div class="min-h-screen flex items-center justify-center bg-gray-100">
  <div class="text-center">
    <h1 class="text-6xl font-bold text-gray-900">500</h1>
    <p class="mt-4 text-xl text-gray-600">サーバーエラーが発生しました</p>
    <p class="mt-2 text-gray-500">
      しばらく時間をおいて再度お試しください。
    </p>
    <div class="mt-6">
      <%= link_to '再読み込み', root_path, class: 'btn btn-primary' %>
    </div>
  </div>
</div>
```

## ログ設計

### ログレベル

| レベル | 用途 |
|--------|------|
| DEBUG | 開発時の詳細情報 |
| INFO | 通常の処理情報 |
| WARN | 警告（処理は継続） |
| ERROR | エラー（処理失敗） |
| FATAL | 致命的エラー |

### ログ出力例

```ruby
class AchievementsController < ApplicationController
  def create
    @achievement = @post.achievements.build(user: current_user, achieved_on: Date.current)

    if @achievement.save
      Rails.logger.info "[Achievement] Created: user=#{current_user.id}, post=#{@post.id}"
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @post }
      end
    else
      Rails.logger.warn "[Achievement] Failed: user=#{current_user.id}, post=#{@post.id}, errors=#{@achievement.errors.full_messages}"
      head :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "[Achievement] Exception: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    raise
  end
end
```

## 外部サービスエラー

### 画像アップロード（CarrierWave + S3）

```ruby
class PostsController < ApplicationController
  def create
    @post = current_user.posts.build(post_params)

    begin
      if @post.save
        redirect_to @post, notice: '投稿を作成しました'
      else
        render :new, status: :unprocessable_entity
      end
    rescue CarrierWave::IntegrityError => e
      flash.now[:alert] = '画像形式が不正です。JPG, PNG, GIF形式でアップロードしてください。'
      render :new, status: :unprocessable_entity
    rescue Fog::AWS::Storage::Error => e
      Rails.logger.error "[S3] Upload failed: #{e.message}"
      flash.now[:alert] = '画像のアップロードに失敗しました。しばらく後に再度お試しください。'
      render :new, status: :unprocessable_entity
    end
  end
end
```

## テスト

### エラーハンドリングのテスト

```ruby
# spec/requests/posts_spec.rb
RSpec.describe 'Posts', type: :request do
  describe 'GET /posts/:id' do
    context '存在しないIDの場合' do
      it '404を返す' do
        get post_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /posts' do
    context 'バリデーションエラーの場合' do
      it '422を返す' do
        sign_in user
        post posts_path, params: { post: { trigger_content: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
```

---

*関連ドキュメント*: `03_api_design.md`, `06_security.md`, `08_test_strategy.md`
