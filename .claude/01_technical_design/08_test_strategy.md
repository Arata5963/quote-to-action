# テスト戦略

## 概要

ActionSparkにおけるテスト方針と実装パターンを定義します。

## テスト目標

- **カバレッジ目標**: 80%以上
- **テストピラミッド**: Unit > Integration > E2E
- **CI実行時間**: 5分以内

## テストフレームワーク

| 種類 | ツール |
|------|--------|
| ユニットテスト | RSpec |
| ファクトリ | FactoryBot |
| フィクスチャ | FactoryBot traits |
| モック | RSpec mocks |
| カバレッジ | SimpleCov |
| システムテスト | Capybara + Selenium |

## ディレクトリ構造

```
spec/
├── factories/              # FactoryBot定義
│   ├── users.rb
│   ├── posts.rb
│   ├── achievements.rb
│   ├── comments.rb
│   └── likes.rb
├── models/                 # モデルスペック
│   ├── user_spec.rb
│   ├── post_spec.rb
│   ├── achievement_spec.rb
│   ├── comment_spec.rb
│   └── like_spec.rb
├── requests/               # リクエストスペック
│   ├── posts_spec.rb
│   ├── achievements_spec.rb
│   ├── comments_spec.rb
│   └── likes_spec.rb
├── system/                 # システムスペック
│   ├── posts_spec.rb
│   ├── authentication_spec.rb
│   └── user_profile_spec.rb
├── support/                # サポートファイル
│   ├── factory_bot.rb
│   ├── devise.rb
│   └── capybara.rb
└── rails_helper.rb
```

## Factory定義

### 基本ファクトリ

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    name { 'テストユーザー' }

    trait :with_avatar do
      avatar { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/avatar.jpg')) }
    end
  end
end

# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    association :user
    trigger_content { '良い本を読んだ' }
    action_plan { '毎日15分読書する' }
    category { :text }

    trait :video do
      trigger_content { '感動的な動画を見た' }
      category { :video }
    end

    trait :with_image do
      image { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/test.jpg')) }
    end

    trait :with_achievements do
      after(:create) do |post|
        create_list(:achievement, 3, post: post)
      end
    end
  end
end

# spec/factories/achievements.rb
FactoryBot.define do
  factory :achievement do
    association :user
    association :post
    achieved_on { Date.current }
  end
end

# spec/factories/comments.rb
FactoryBot.define do
  factory :comment do
    association :user
    association :post
    content { 'がんばってください！' }
  end
end

# spec/factories/likes.rb
FactoryBot.define do
  factory :like do
    association :user
    association :post
  end
end
```

## モデルスペック

### テスト項目

- バリデーション
- アソシエーション
- スコープ
- インスタンスメソッド
- クラスメソッド

### 実装例

```ruby
# spec/models/post_spec.rb
require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:achievements).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:likes).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:trigger_content) }
    it { is_expected.to validate_length_of(:trigger_content).is_at_most(100) }
    it { is_expected.to validate_presence_of(:action_plan) }
    it { is_expected.to validate_length_of(:action_plan).is_at_most(100) }
  end

  describe 'scopes' do
    describe '.recent' do
      it '作成日時の降順で返す' do
        old_post = create(:post, created_at: 1.day.ago)
        new_post = create(:post, created_at: 1.hour.ago)

        expect(Post.recent).to eq([new_post, old_post])
      end
    end

    describe '.by_category' do
      it '指定カテゴリの投稿のみ返す' do
        text_post = create(:post, category: :text)
        video_post = create(:post, category: :video)

        expect(Post.by_category(:text)).to eq([text_post])
      end
    end
  end

  describe '#achieved_today_by?' do
    let(:post) { create(:post) }
    let(:user) { create(:user) }

    context '本日達成済みの場合' do
      before { create(:achievement, post: post, user: user, achieved_on: Date.current) }

      it 'trueを返す' do
        expect(post.achieved_today_by?(user)).to be true
      end
    end

    context '未達成の場合' do
      it 'falseを返す' do
        expect(post.achieved_today_by?(user)).to be false
      end
    end
  end

  describe '#achievement_badge' do
    let(:post) { create(:post) }

    it '達成回数に応じたバッジを返す' do
      expect(post.achievement_badge).to eq('☆')

      create(:achievement, post: post)
      post.reload
      expect(post.achievement_badge).to eq('⭐')
    end
  end
end
```

```ruby
# spec/models/achievement_spec.rb
require 'rails_helper'

RSpec.describe Achievement, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:post).counter_cache(:achievement_count) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:achieved_on) }

    describe 'uniqueness' do
      subject { build(:achievement) }
      it { is_expected.to validate_uniqueness_of(:achieved_on).scoped_to(:user_id, :post_id) }
    end
  end

  describe '1日1回制限' do
    let(:user) { create(:user) }
    let(:post) { create(:post) }

    it '同一日に同じ投稿に2回達成できない' do
      create(:achievement, user: user, post: post, achieved_on: Date.current)
      duplicate = build(:achievement, user: user, post: post, achieved_on: Date.current)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:achieved_on]).to include('はすでに存在します')
    end

    it '別の日には達成できる' do
      create(:achievement, user: user, post: post, achieved_on: Date.yesterday)
      new_achievement = build(:achievement, user: user, post: post, achieved_on: Date.current)

      expect(new_achievement).to be_valid
    end
  end
end
```

## リクエストスペック

### テスト項目

- 各HTTPアクションの動作
- 認証・認可
- レスポンスステータス
- リダイレクト先
- Turbo Streamレスポンス

### 実装例

```ruby
# spec/requests/posts_spec.rb
require 'rails_helper'

RSpec.describe 'Posts', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'GET /posts' do
    it '投稿一覧を表示する' do
      posts = create_list(:post, 3)
      get posts_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /posts/:id' do
    let(:post) { create(:post) }

    it '投稿詳細を表示する' do
      get post_path(post)
      expect(response).to have_http_status(:ok)
    end

    context '存在しない投稿の場合' do
      it '404を返す' do
        get post_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /posts' do
    context 'ログイン済みの場合' do
      before { sign_in user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            post: {
              trigger_content: '良い本を読んだ',
              action_plan: '毎日読書する',
              category: 'text'
            }
          }
        end

        it '投稿を作成する' do
          expect {
            post posts_path, params: valid_params
          }.to change(Post, :count).by(1)
        end

        it '投稿詳細にリダイレクトする' do
          post posts_path, params: valid_params
          expect(response).to redirect_to(Post.last)
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) { { post: { trigger_content: '' } } }

        it '投稿を作成しない' do
          expect {
            post posts_path, params: invalid_params
          }.not_to change(Post, :count)
        end

        it '422を返す' do
          post posts_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context '未ログインの場合' do
      it 'ログイン画面にリダイレクトする' do
        post posts_path, params: { post: { trigger_content: 'test' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /posts/:id' do
    let!(:post_record) { create(:post, user: user) }

    context '自分の投稿の場合' do
      before { sign_in user }

      it '更新できる' do
        patch post_path(post_record), params: {
          post: { trigger_content: '更新後' }
        }
        expect(post_record.reload.trigger_content).to eq('更新後')
      end
    end

    context '他人の投稿の場合' do
      before { sign_in other_user }

      it '更新できない' do
        expect {
          patch post_path(post_record), params: {
            post: { trigger_content: '更新後' }
          }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'DELETE /posts/:id' do
    let!(:post_record) { create(:post, user: user) }

    context '自分の投稿の場合' do
      before { sign_in user }

      it '削除できる' do
        expect {
          delete post_path(post_record)
        }.to change(Post, :count).by(-1)
      end
    end
  end
end
```

```ruby
# spec/requests/achievements_spec.rb
require 'rails_helper'

RSpec.describe 'Achievements', type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post) }

  describe 'POST /posts/:post_id/achievements' do
    before { sign_in user }

    context '初回達成の場合' do
      it '達成を記録する' do
        expect {
          post post_achievements_path(post_record)
        }.to change(Achievement, :count).by(1)
      end

      it 'Turbo Streamを返す' do
        post post_achievements_path(post_record), as: :turbo_stream
        expect(response.media_type).to eq Mime[:turbo_stream]
      end
    end

    context '本日既に達成済みの場合' do
      before do
        create(:achievement, user: user, post: post_record, achieved_on: Date.current)
      end

      it '達成を記録しない' do
        expect {
          post post_achievements_path(post_record)
        }.not_to change(Achievement, :count)
      end
    end
  end
end
```

## システムスペック

### 実装例

```ruby
# spec/system/posts_spec.rb
require 'rails_helper'

RSpec.describe '投稿機能', type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
  end

  describe '新規投稿' do
    it '投稿を作成できる' do
      visit new_post_path

      fill_in 'きっかけ', with: '良い本を読んだ'
      fill_in 'アクションプラン', with: '毎日15分読書する'
      select 'テキスト', from: 'カテゴリ'
      click_button '投稿する'

      expect(page).to have_content('投稿を作成しました')
      expect(page).to have_content('良い本を読んだ')
    end
  end

  describe '達成記録' do
    let!(:post) { create(:post) }

    it '達成ボタンをクリックして達成を記録できる' do
      visit post_path(post)
      click_button '達成！'

      expect(page).to have_content('1')
    end
  end

  describe '検索' do
    before do
      create(:post, trigger_content: 'プログラミングの本')
      create(:post, trigger_content: 'デザインの本')
    end

    it 'キーワードで投稿を検索できる' do
      visit posts_path
      fill_in '検索', with: 'プログラミング'
      click_button '検索'

      expect(page).to have_content('プログラミングの本')
      expect(page).not_to have_content('デザインの本')
    end
  end
end
```

## テスト実行

### コマンド

```bash
# 全テスト実行
bundle exec rspec

# 特定ディレクトリ
bundle exec rspec spec/models/
bundle exec rspec spec/requests/

# 特定ファイル
bundle exec rspec spec/models/post_spec.rb

# 特定テスト
bundle exec rspec spec/models/post_spec.rb:10

# 失敗したテストのみ
bundle exec rspec --only-failures

# カバレッジ付き
COVERAGE=true bundle exec rspec
```

### Docker環境

```bash
docker compose exec web rspec
docker compose exec web rspec spec/models/
```

## CI設定

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Setup database
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: |
          bin/rails db:create
          bin/rails db:schema:load

      - name: Run tests
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: bundle exec rspec
```

---

*関連ドキュメント*: `09_ci_cd.md`, `05_error_handling.md`
