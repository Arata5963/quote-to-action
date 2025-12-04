# spec/requests/helper_integration_spec.rb
require 'rails_helper'

RSpec.describe "Helper Integration (カバレッジ向上)", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user, category: :music) }

  describe "ApplicationHelper統合テスト" do
    context "投稿一覧ページでカテゴリアイコンが表示される" do
      before do
        sign_in user
        # 複数カテゴリの投稿を作成（YouTube公式カテゴリ）
        create(:post, user: user, category: :music)
        create(:post, user: user, category: :education)
        create(:post, user: user, category: :gaming)
        create(:post, user: user, category: :sports)
        create(:post, user: user, category: :entertainment)
        create(:post, user: user, category: :science_technology)
        create(:post, user: user, category: :howto_style)
      end

      it "各カテゴリのアイコンが表示される（category_iconメソッドが実行される）" do
        get posts_path
        expect(response).to have_http_status(:success)

        # 各カテゴリのアイコンが含まれている（Helperメソッドが実行された証拠）
        expect(response.body).to include('🎵') # music
        expect(response.body).to include('📚') # education
        expect(response.body).to include('🎮') # gaming
        expect(response.body).to include('⚽') # sports
      end

      it "カテゴリ名（絵文字なし）が表示される（category_name_without_iconメソッドが実行される）" do
        get posts_path
        expect(response).to have_http_status(:success)

        # カテゴリ名が表示される
        expect(response.body).to match(/カテゴリ/)
      end
    end

    context "投稿詳細ページでカテゴリアイコンが表示される" do
      before { sign_in user }

      it "カテゴリアイコンが表示される" do
        get post_path(post_record)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('🎵') # musicカテゴリのアイコン
      end
    end

    context "OGPメタタグが設定される（default_meta_tagsメソッドが実行される）" do
      it "トップページにOGPタグが含まれる" do
        get root_path
        expect(response).to have_http_status(:success)

        # OGPメタタグの存在確認（default_meta_tagsが実行された証拠）
        expect(response.body).to include('og:title')
        expect(response.body).to include('og:description')
        expect(response.body).to include('og:image')
        expect(response.body).to include('ActionSpark')
      end

      it "投稿一覧ページにもOGPタグが含まれる" do
        sign_in user
        get posts_path
        expect(response).to have_http_status(:success)

        expect(response.body).to include('og:title')
        expect(response.body).to include('ActionSpark')
      end
    end
  end
end
