# セキュリティ設計

## 概要

ActionSparkにおけるセキュリティ対策の方針と実装パターンを定義します。

## セキュリティ原則

1. **最小権限の原則**: 必要最小限の権限のみ付与
2. **多層防御**: 複数のセキュリティ層で保護
3. **デフォルト拒否**: 明示的に許可されたもの以外は拒否
4. **安全な初期設定**: セキュアな設定をデフォルトに

## 認証（Authentication）

### Deviseによる認証

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  # パスワードの最小長
  config.password_length = 8..128

  # パスワードリセットトークンの有効期限
  config.reset_password_within = 6.hours

  # セッションのタイムアウト（任意）
  # config.timeout_in = 30.minutes

  # メール確認（本番で有効化推奨）
  # config.reconfirmable = true
end
```

### パスワード要件

- 最低8文字
- 大文字・小文字・数字を含む（推奨）
- 過去に使用したパスワードの再利用禁止（将来実装）

### OAuth認証

```ruby
# config/initializers/devise.rb
config.omniauth :google_oauth2,
  ENV['GOOGLE_CLIENT_ID'],
  ENV['GOOGLE_CLIENT_SECRET'],
  {
    scope: 'email,profile',
    prompt: 'select_account',
    image_aspect_ratio: 'square',
    image_size: 50
  }
```

## 認可（Authorization）

### current_userスコープの徹底

```ruby
# 良い例：current_userスコープを使用
class PostsController < ApplicationController
  def edit
    @post = current_user.posts.find(params[:id])
  end

  def update
    @post = current_user.posts.find(params[:id])
    # ...
  end

  def destroy
    @post = current_user.posts.find(params[:id])
    @post.destroy
    # ...
  end
end

# 悪い例：誰でもアクセス可能
class PostsController < ApplicationController
  def edit
    @post = Post.find(params[:id])  # 他人の投稿も編集可能になる
  end
end
```

### before_actionによる認証チェック

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!, except: [:index, :show]

  private

  def ensure_owner
    redirect_to root_path, alert: '権限がありません' unless @resource.user == current_user
  end
end

class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :ensure_owner, only: [:edit, :update, :destroy]

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def ensure_owner
    redirect_to @post, alert: '編集権限がありません' unless @post.user == current_user
  end
end
```

## CSRF対策

### Rails標準のCSRF保護

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end
```

### フォームでのトークン

```erb
<%# 自動でauthenticity_tokenが追加される %>
<%= form_with model: @post do |f| %>
  <%= f.text_area :trigger_content %>
  <%= f.submit %>
<% end %>
```

### Turbo/Ajax対応

```javascript
// app/javascript/application.js
import { Turbo } from "@hotwired/turbo-rails"

// CSRFトークンは自動的に送信される
```

## XSS対策

### 自動エスケープ

```erb
<%# 自動でHTMLエスケープされる %>
<%= @post.trigger_content %>

<%# 明示的にHTMLを許可する場合（危険） %>
<%# <%= raw @post.content %> %>
<%# <%= @post.content.html_safe %> %>
```

### Content Security Policy

```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https, :unsafe_inline
  end
end
```

## SQLインジェクション対策

### Active Recordの使用

```ruby
# 良い例：プレースホルダー使用
Post.where(category: params[:category])
Post.where('trigger_content LIKE ?', "%#{params[:q]}%")

# 悪い例：文字列連結（危険）
Post.where("category = '#{params[:category]}'")
```

### Ransackの安全な使用

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  # 検索可能なカラムを制限
  def self.ransackable_attributes(auth_object = nil)
    %w[trigger_content action_plan category created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end
end
```

## Strong Parameters

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
      # user_id は許可しない（current_userから設定）
    )
  end
end
```

## ファイルアップロード

### 許可する形式の制限

```ruby
# app/uploaders/image_uploader.rb
class ImageUploader < CarrierWave::Uploader::Base
  def extension_allowlist
    %w[jpg jpeg gif png webp]
  end

  def content_type_allowlist
    %w[image/jpeg image/gif image/png image/webp]
  end

  def size_range
    1..5.megabytes
  end
end
```

### ファイル名のサニタイズ

```ruby
# app/uploaders/image_uploader.rb
class ImageUploader < CarrierWave::Uploader::Base
  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
  end
end
```

## セッション管理

### セッション設定

```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: '_action_spark_session',
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
```

### ログアウト時のセッション破棄

```ruby
# Deviseが自動で処理
# sign_out時にセッションがリセットされる
```

## HTTPS

### 本番環境でのHTTPS強制

```ruby
# config/environments/production.rb
config.force_ssl = true
```

## 環境変数

### 機密情報の管理

```bash
# .env（.gitignoreに追加）
DATABASE_URL=postgres://...
SECRET_KEY_BASE=...
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

### credentials.yml.enc

```bash
# 編集
EDITOR="code --wait" rails credentials:edit

# 使用
Rails.application.credentials.google[:client_id]
```

## 脆弱性診断

### Brakeman

```bash
# 実行
bundle exec brakeman

# 出力形式指定
bundle exec brakeman -o brakeman-output.html -f html
```

### bundler-audit

```bash
# Gemの脆弱性チェック
bundle exec bundler-audit check --update
```

### CI/CDでの自動チェック

```yaml
# .github/workflows/security.yml
name: Security

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Brakeman
        run: bundle exec brakeman --no-pager
      - name: bundler-audit
        run: bundle exec bundler-audit check --update
```

## ログ・監査

### センシティブ情報のフィルタリング

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :password,
  :password_confirmation,
  :credit_card,
  :token,
  :secret
]
```

### 監査ログ（将来実装）

```ruby
# 重要な操作のログ記録
Rails.logger.info "[AUDIT] User #{current_user.id} deleted post #{@post.id}"
```

## チェックリスト

### 実装時の確認項目

- [ ] 認証が必要なアクションに`authenticate_user!`が設定されているか
- [ ] `current_user`スコープを使用しているか
- [ ] Strong Parametersで許可するパラメータを制限しているか
- [ ] ユーザー入力を直接SQLに埋め込んでいないか
- [ ] アップロードファイルの形式・サイズを制限しているか
- [ ] 機密情報を環境変数で管理しているか
- [ ] Brakemanの警告がないか

### リリース前の確認項目

- [ ] `force_ssl`が有効か
- [ ] `secret_key_base`が設定されているか
- [ ] デバッグ情報が無効化されているか
- [ ] エラーページが適切か
- [ ] CSPが設定されているか

---

*関連ドキュメント*: `03_api_design.md`, `05_error_handling.md`, `09_ci_cd.md`
