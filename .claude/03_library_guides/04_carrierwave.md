# CarrierWave 実装パターン

## 概要

ActionSparkにおけるCarrierWave（画像アップロードライブラリ）の設定と実装パターンを定義します。

## 基本設定

### Gemfile

```ruby
gem 'carrierwave'
gem 'mini_magick'  # 画像処理
gem 'fog-aws'      # S3ストレージ（本番用）
```

### アップローダー生成

```bash
rails generate uploader Image
```

### 基本設定

```ruby
# config/initializers/carrierwave.rb
CarrierWave.configure do |config|
  if Rails.env.production?
    config.storage = :fog
    config.fog_provider = 'fog/aws'
    config.fog_credentials = {
      provider:              'AWS',
      aws_access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
      aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region:                ENV['AWS_REGION']
    }
    config.fog_directory  = ENV['AWS_BUCKET']
    config.fog_public     = false
    config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" }
  else
    config.storage = :file
    config.enable_processing = Rails.env.test? ? false : true
  end
end
```

## アップローダー定義

### 画像アップローダー

```ruby
# app/uploaders/image_uploader.rb
class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  # ストレージ設定（initializerで設定）
  storage :file # または :fog

  # アップロード先ディレクトリ
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # 許可する拡張子
  def extension_allowlist
    %w[jpg jpeg gif png webp]
  end

  # 許可するContent-Type
  def content_type_allowlist
    %w[image/jpeg image/gif image/png image/webp]
  end

  # ファイルサイズ制限
  def size_range
    1..5.megabytes
  end

  # デフォルト画像
  def default_url(*args)
    "/images/fallback/#{[version_name, 'default.png'].compact.join('_')}"
  end

  # オリジナル画像の処理
  process :optimize
  process resize_to_limit: [1200, 1200]

  # サムネイル
  version :thumb do
    process resize_to_fill: [100, 100]
  end

  # 中サイズ
  version :medium do
    process resize_to_fit: [400, 400]
  end

  # カード用
  version :card do
    process resize_to_fill: [300, 200]
  end

  # 最適化処理
  def optimize
    manipulate! do |img|
      img.strip  # メタデータ削除
      img.auto_orient  # 回転補正
      img.quality '85'  # 品質
      img
    end
  end

  # ファイル名をランダム化（セキュリティ）
  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end
```

### アバターアップローダー

```ruby
# app/uploaders/avatar_uploader.rb
class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_allowlist
    %w[jpg jpeg gif png webp]
  end

  def size_range
    1..2.megabytes
  end

  def default_url(*args)
    "/images/default_avatar.png"
  end

  # 正方形にリサイズ
  process resize_to_fill: [200, 200]

  version :small do
    process resize_to_fill: [50, 50]
  end

  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end
```

## モデルへのマウント

### Post モデル

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  mount_uploader :image, ImageUploader

  # バリデーション
  validates :image,
    file_size: { less_than: 5.megabytes },
    file_content_type: { allow: ['image/jpeg', 'image/png', 'image/gif'] },
    if: :image?

  # 画像の有無
  def image?
    image.present?
  end
end
```

### User モデル

```ruby
# app/models/user.rb
class User < ApplicationRecord
  mount_uploader :avatar, AvatarUploader

  # OmniAuthからの画像URL取得
  def remote_avatar_url=(url)
    self.avatar = URI.parse(url).open if url.present?
  rescue OpenURI::HTTPError, URI::InvalidURIError => e
    Rails.logger.warn "[Avatar] Failed to download: #{e.message}"
  end
end
```

## ビューでの表示

### 画像表示

```erb
<%# サムネイル %>
<%= image_tag post.image.thumb.url, alt: 'サムネイル', class: 'rounded' if post.image? %>

<%# 中サイズ %>
<%= image_tag post.image.medium.url, alt: '画像', class: 'rounded-lg' if post.image? %>

<%# オリジナル（リンク付き） %>
<% if post.image? %>
  <%= link_to post.image.url, target: '_blank' do %>
    <%= image_tag post.image.medium.url, alt: '画像', class: 'cursor-pointer' %>
  <% end %>
<% end %>

<%# 遅延読み込み %>
<%= image_tag post.image.card.url, alt: '画像', loading: 'lazy', class: 'w-full' if post.image? %>
```

### アバター表示

```erb
<%# 通常 %>
<%= image_tag current_user.avatar.url, alt: current_user.name, class: 'w-10 h-10 rounded-full' %>

<%# 小サイズ %>
<%= image_tag current_user.avatar.small.url, alt: current_user.name, class: 'w-6 h-6 rounded-full' %>

<%# デフォルト画像付き %>
<%= image_tag(user.avatar.present? ? user.avatar.url : 'default_avatar.png',
    alt: user.name, class: 'rounded-full') %>
```

### アップロードフォーム

```erb
<%= form_with model: @post, local: true do |f| %>
  <div class="space-y-4">
    <%# 画像プレビュー %>
    <% if @post.image? %>
      <div class="mb-4">
        <%= image_tag @post.image.thumb.url, class: 'rounded' %>
        <label class="flex items-center gap-2 text-sm text-gray-600 mt-2">
          <%= f.check_box :remove_image %>
          画像を削除
        </label>
      </div>
    <% end %>

    <%# ファイル選択 %>
    <div>
      <%= f.label :image, '画像', class: 'block text-sm font-medium text-gray-700' %>
      <div class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md hover:border-gray-400 transition-colors"
           data-controller="image-preview">
        <div class="space-y-1 text-center">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 48 48">
            <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          <div class="flex text-sm text-gray-600">
            <label class="relative cursor-pointer rounded-md font-medium text-black hover:text-gray-700">
              <span>ファイルを選択</span>
              <%= f.file_field :image,
                  class: 'sr-only',
                  accept: 'image/jpeg,image/png,image/gif,image/webp',
                  data: { action: 'change->image-preview#preview', image_preview_target: 'input' } %>
            </label>
            <p class="pl-1">またはドラッグ＆ドロップ</p>
          </div>
          <p class="text-xs text-gray-500">PNG, JPG, GIF, WebP (5MBまで)</p>
        </div>
      </div>
      <%# プレビュー表示エリア %>
      <div data-image-preview-target="preview" class="mt-4 hidden">
        <img src="" alt="プレビュー" class="max-w-xs rounded-lg">
      </div>
    </div>

    <%= f.submit '投稿する', class: 'btn btn-primary' %>
  </div>
<% end %>
```

### プレビュー用Stimulus

```javascript
// app/javascript/controllers/image_preview_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  preview() {
    const file = this.inputTarget.files[0]
    if (!file) return

    // ファイルサイズチェック
    if (file.size > 5 * 1024 * 1024) {
      alert('ファイルサイズは5MB以下にしてください')
      this.inputTarget.value = ''
      return
    }

    // プレビュー表示
    const reader = new FileReader()
    reader.onload = (e) => {
      const img = this.previewTarget.querySelector('img')
      img.src = e.target.result
      this.previewTarget.classList.remove('hidden')
    }
    reader.readAsDataURL(file)
  }
}
```

## コントローラー

### Strong Parameters

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  private

  def post_params
    params.require(:post).permit(
      :trigger_content,
      :action_plan,
      :category,
      :image,
      :remove_image,  # 画像削除用
      :related_url
    )
  end
end

# app/controllers/users/registrations_controller.rb
def configure_account_update_params
  devise_parameter_sanitizer.permit(:account_update, keys: [:name, :avatar, :remove_avatar])
end
```

## エラーハンドリング

### アップロードエラー

```ruby
# app/controllers/posts_controller.rb
def create
  @post = current_user.posts.build(post_params)

  begin
    if @post.save
      redirect_to @post, notice: '投稿を作成しました'
    else
      render :new, status: :unprocessable_entity
    end
  rescue CarrierWave::IntegrityError => e
    @post.errors.add(:image, '画像形式が不正です。JPG, PNG, GIF形式でアップロードしてください。')
    render :new, status: :unprocessable_entity
  rescue CarrierWave::ProcessingError => e
    Rails.logger.error "[CarrierWave] Processing error: #{e.message}"
    @post.errors.add(:image, '画像の処理に失敗しました。')
    render :new, status: :unprocessable_entity
  end
end
```

### バリデーション

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  mount_uploader :image, ImageUploader

  validate :image_size_validation

  private

  def image_size_validation
    if image.present? && image.file.size > 5.megabytes
      errors.add(:image, 'は5MB以下にしてください')
    end
  end
end
```

## S3設定（本番環境）

### 環境変数

```bash
# .env.production
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=ap-northeast-1
AWS_BUCKET=actionspark-production
```

### CORS設定

S3バケットのCORS設定:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST"],
    "AllowedOrigins": ["https://actionspark.example"],
    "ExposeHeaders": []
  }
]
```

## テスト

### ファクトリ

```ruby
# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    association :user
    trigger_content { 'テスト' }
    action_plan { 'テスト' }

    trait :with_image do
      image { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/test.jpg'), 'image/jpeg') }
    end
  end
end
```

### テストファイル

```bash
mkdir -p spec/fixtures/files
# 小さなテスト用画像を配置
```

### Request Spec

```ruby
# spec/requests/posts_spec.rb
RSpec.describe 'Posts', type: :request do
  describe 'POST /posts' do
    let(:user) { create(:user) }
    let(:image) { fixture_file_upload('test.jpg', 'image/jpeg') }

    before { sign_in user }

    it '画像付きで投稿できる' do
      post posts_path, params: {
        post: {
          trigger_content: 'テスト',
          action_plan: 'テスト',
          image: image
        }
      }

      expect(Post.last.image).to be_present
    end
  end
end
```

## パフォーマンス

### バックグラウンド処理

```ruby
# app/jobs/image_process_job.rb
class ImageProcessJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find(post_id)
    post.image.recreate_versions! if post.image.present?
  end
end
```

### CDN設定

```ruby
# config/initializers/carrierwave.rb
CarrierWave.configure do |config|
  if Rails.env.production?
    config.asset_host = ENV['CDN_HOST']  # CloudFront等
  end
end
```

---

*関連ドキュメント*: `../01_technical_design/07_performance.md`, `../02_design_system/03_components.md`
