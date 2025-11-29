# Devise 実装パターン

## 概要

ActionSparkにおけるDevise（認証ライブラリ）の設定と実装パターンを定義します。

## 基本設定

### インストール済みモジュール

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]
end
```

| モジュール | 機能 |
|------------|------|
| database_authenticatable | メール/パスワード認証 |
| registerable | ユーザー登録 |
| recoverable | パスワードリセット |
| rememberable | Remember Me |
| validatable | メール/パスワードバリデーション |
| omniauthable | OAuth認証 |

### Devise設定

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  # メール送信元
  config.mailer_sender = 'noreply@actionspark.example'

  # パスワード要件
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # Remember Me
  config.remember_for = 2.weeks

  # パスワードリセット
  config.reset_password_within = 6.hours

  # Turbo対応
  config.navigational_formats = ['*/*', :html, :turbo_stream]

  # OmniAuth
  config.omniauth :google_oauth2,
    Rails.application.credentials.dig(:google, :client_id),
    Rails.application.credentials.dig(:google, :client_secret),
    {
      scope: 'email,profile',
      prompt: 'select_account'
    }
end
```

## ルーティング

### 基本ルーティング

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    passwords: 'users/passwords',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
end
```

### 生成されるルート

| パス | アクション | 用途 |
|------|------------|------|
| /users/sign_in | sessions#new | ログインフォーム |
| /users/sign_out | sessions#destroy | ログアウト |
| /users/sign_up | registrations#new | 新規登録フォーム |
| /users/edit | registrations#edit | プロフィール編集 |
| /users/password/new | passwords#new | パスワードリセット申請 |
| /users/auth/google_oauth2 | - | Google OAuth |

## カスタムコントローラー

### SessionsController

```ruby
# app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  # Turbo対応
  def create
    super
  rescue BCrypt::Errors::InvalidHash
    flash[:alert] = 'ログインに失敗しました'
    redirect_to new_user_session_path
  end

  protected

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || posts_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end
end
```

### RegistrationsController

```ruby
# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :avatar])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :avatar])
  end

  def after_sign_up_path_for(resource)
    posts_path
  end

  def after_update_path_for(resource)
    user_path(resource)
  end

  # パスワードなしで更新可能
  def update_resource(resource, params)
    if params[:password].blank? && params[:password_confirmation].blank?
      params.delete(:password)
      params.delete(:password_confirmation)
      params.delete(:current_password)
      resource.update(params)
    else
      super
    end
  end
end
```

### OmniAuthCallbacksController

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      flash[:notice] = 'Googleアカウントでログインしました'
      sign_in_and_redirect @user, event: :authentication
    else
      session['devise.google_data'] = request.env['omniauth.auth'].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to root_path, alert: 'ログインに失敗しました'
  end
end
```

### OmniAuthユーザー作成

```ruby
# app/models/user.rb
class User < ApplicationRecord
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.remote_avatar_url = auth.info.image if auth.info.image.present?
    end
  end
end
```

## 認証ヘルパー

### コントローラーでの使用

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  # 一部アクションで認証不要
  before_action :authenticate_user!, except: [:index, :show]

  private

  # 現在のユーザー
  def current_user
    @current_user ||= super
  end

  # ログイン済みかどうか
  def user_signed_in?
    super
  end
end
```

### ビューでの使用

```erb
<% if user_signed_in? %>
  <p>こんにちは、<%= current_user.name %>さん</p>
  <%= link_to 'ログアウト', destroy_user_session_path, data: { turbo_method: :delete } %>
<% else %>
  <%= link_to 'ログイン', new_user_session_path %>
  <%= link_to '新規登録', new_user_registration_path %>
<% end %>
```

## ビューカスタマイズ

### ログインフォーム

```erb
<%# app/views/devise/sessions/new.html.erb %>
<h2 class="text-2xl font-bold text-center mb-6">ログイン</h2>

<%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
  <div class="space-y-4">
    <div>
      <%= f.label :email, 'メールアドレス', class: 'block text-sm font-medium text-gray-700' %>
      <%= f.email_field :email, autofocus: true, autocomplete: 'email',
          class: 'mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-black focus:ring-black' %>
    </div>

    <div>
      <%= f.label :password, 'パスワード', class: 'block text-sm font-medium text-gray-700' %>
      <%= f.password_field :password, autocomplete: 'current-password',
          class: 'mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-black focus:ring-black' %>
    </div>

    <% if devise_mapping.rememberable? %>
      <div class="flex items-center">
        <%= f.check_box :remember_me, class: 'h-4 w-4 rounded border-gray-300 text-black focus:ring-black' %>
        <%= f.label :remember_me, 'ログイン状態を保持', class: 'ml-2 text-sm text-gray-600' %>
      </div>
    <% end %>

    <div>
      <%= f.submit 'ログイン', class: 'w-full bg-black text-white px-4 py-2 rounded-md hover:bg-gray-800' %>
    </div>
  </div>
<% end %>

<div class="mt-6">
  <div class="relative">
    <div class="absolute inset-0 flex items-center">
      <div class="w-full border-t border-gray-300"></div>
    </div>
    <div class="relative flex justify-center text-sm">
      <span class="px-2 bg-white text-gray-500">または</span>
    </div>
  </div>

  <div class="mt-6">
    <%= button_to 'Googleでログイン', user_google_oauth2_omniauth_authorize_path,
        method: :post, data: { turbo: false },
        class: 'w-full flex items-center justify-center gap-3 bg-white border border-gray-300 rounded-md px-4 py-2 hover:bg-gray-50' %>
  </div>
</div>

<div class="mt-6 text-center text-sm">
  <%= link_to '新規登録', new_registration_path(resource_name), class: 'text-gray-600 hover:text-black' %>
  <span class="mx-2">|</span>
  <%= link_to 'パスワードを忘れた', new_password_path(resource_name), class: 'text-gray-600 hover:text-black' %>
</div>
```

### 新規登録フォーム

```erb
<%# app/views/devise/registrations/new.html.erb %>
<h2 class="text-2xl font-bold text-center mb-6">新規登録</h2>

<%= form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f| %>
  <%= render 'devise/shared/error_messages', resource: resource %>

  <div class="space-y-4">
    <div>
      <%= f.label :name, '名前', class: 'block text-sm font-medium text-gray-700' %>
      <%= f.text_field :name, autofocus: true,
          class: 'mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-black focus:ring-black' %>
    </div>

    <div>
      <%= f.label :email, 'メールアドレス', class: 'block text-sm font-medium text-gray-700' %>
      <%= f.email_field :email, autocomplete: 'email',
          class: 'mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-black focus:ring-black' %>
    </div>

    <div>
      <%= f.label :password, 'パスワード', class: 'block text-sm font-medium text-gray-700' %>
      <%= f.password_field :password, autocomplete: 'new-password',
          class: 'mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-black focus:ring-black' %>
      <p class="mt-1 text-xs text-gray-500">8文字以上</p>
    </div>

    <div>
      <%= f.label :password_confirmation, 'パスワード（確認）', class: 'block text-sm font-medium text-gray-700' %>
      <%= f.password_field :password_confirmation, autocomplete: 'new-password',
          class: 'mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-black focus:ring-black' %>
    </div>

    <div>
      <%= f.submit '登録する', class: 'w-full bg-black text-white px-4 py-2 rounded-md hover:bg-gray-800' %>
    </div>
  </div>
<% end %>

<div class="mt-6 text-center text-sm">
  <%= link_to 'ログインはこちら', new_session_path(resource_name), class: 'text-gray-600 hover:text-black' %>
</div>
```

## テスト

### FactoryBot

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    name { 'テストユーザー' }
  end
end
```

### Request Spec

```ruby
# spec/requests/user_authentication_spec.rb
require 'rails_helper'

RSpec.describe 'User Authentication', type: :request do
  describe 'POST /users/sign_in' do
    let(:user) { create(:user) }

    context '正しい認証情報の場合' do
      it 'ログインできる' do
        post user_session_path, params: {
          user: { email: user.email, password: 'password123' }
        }
        expect(response).to redirect_to(posts_path)
      end
    end

    context '不正な認証情報の場合' do
      it 'ログインできない' do
        post user_session_path, params: {
          user: { email: user.email, password: 'wrong' }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /users/sign_out' do
    let(:user) { create(:user) }

    it 'ログアウトできる' do
      sign_in user
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)
    end
  end
end
```

### System Spec

```ruby
# spec/system/authentication_spec.rb
require 'rails_helper'

RSpec.describe '認証', type: :system do
  let(:user) { create(:user) }

  describe 'ログイン' do
    it 'メールとパスワードでログインできる' do
      visit new_user_session_path

      fill_in 'メールアドレス', with: user.email
      fill_in 'パスワード', with: 'password123'
      click_button 'ログイン'

      expect(page).to have_content('ログインしました')
    end
  end
end
```

## トラブルシューティング

### よくある問題

| 問題 | 原因 | 解決策 |
|------|------|--------|
| Turboでリダイレクトが動かない | navigational_formats未設定 | `config.navigational_formats = ['*/*', :html, :turbo_stream]` |
| OAuthでエラー | コールバックURL不一致 | Google Cloud Consoleで設定確認 |
| ログアウトできない | HTTPメソッドの問題 | `data: { turbo_method: :delete }` |

---

*関連ドキュメント*: `../01_technical_design/06_security.md`, `02_hotwire.md`
