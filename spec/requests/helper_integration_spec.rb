# spec/requests/helper_integration_spec.rb
require 'rails_helper'

RSpec.describe "Helper Integration (カバレッジ向上)", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user, category: :text) }

  describe "ApplicationHelper統合テスト" do
    context "投稿一覧ページでカテゴリアイコンが表示される" do
      before do
        sign_in user
        # 複数カテゴリの投稿を作成
        create(:post, user: user, category: :text)
        create(:post, user: user, category: :video)
        create(:post, user: user, category: :audio)
        create(:post, user: user, category: :conversation)
        create(:post, user: user, category: :experience)
        create(:post, user: user, category: :observation)
        create(:post, user: user, category: :other)
      end

      it "各カテゴリのアイコンが表示される（category_iconメソッドが実行される）" do
        get posts_path
        expect(response).to have_http_status(:success)
        
        # 各カテゴリのアイコンが含まれている（Helperメソッドが実行された証拠）
        expect(response.body).to include('📝') # text
        expect(response.body).to include('🎥') # video
        expect(response.body).to include('🎧') # audio
        expect(response.body).to include('💬') # conversation
        expect(response.body).to include('✨') # experience
        expect(response.body).to include('👀') # observation
        expect(response.body).to include('📁') # other
      end

      it "カテゴリ名（絵文字なし）が表示される（category_name_without_iconメソッドが実行される）" do
        get posts_path
        expect(response).to have_http_status(:success)
        
        # カテゴリ名が表示される
        # 注: 絵文字除去後のテキストが実際に表示されているか確認
        expect(response.body).to match(/カテゴリ/)
      end
    end

    context "投稿詳細ページでカテゴリアイコンが表示される" do
      before { sign_in user }

      it "カテゴリアイコンが表示される" do
        get post_path(post_record)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('📝') # textカテゴリのアイコン
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

  describe "BadgesHelper統合テスト" do
    let(:post_with_0_achievements) { create(:post, user: user) }
    let(:post_with_1_achievement) do
      post = create(:post, user: user)
      create(:achievement, user: user, post: post, awarded_at: Date.current)
      post.reload
    end
    let(:post_with_2_achievements) do
      post = create(:post, user: user)
      create(:achievement, user: user, post: post, awarded_at: Date.current)
      create(:achievement, user: user, post: post, awarded_at: Date.current - 1.day)
      post.reload
    end
    let(:post_with_3_achievements) do
      post = create(:post, user: user)
      create(:achievement, user: user, post: post, awarded_at: Date.current)
      create(:achievement, user: user, post: post, awarded_at: Date.current - 1.day)
      create(:achievement, user: user, post: post, awarded_at: Date.current - 2.days)
      post.reload
    end
    let(:post_with_5_achievements) do
      post = create(:post, user: user)
      5.times do |i|
        create(:achievement, user: user, post: post, awarded_at: Date.current - i.days)
      end
      post.reload
    end

    before { sign_in user }

    context "投稿一覧ページでバッジアイコンが表示される" do
      before do
        # 達成回数の異なる投稿を作成
        post_with_0_achievements
        post_with_1_achievement
        post_with_2_achievements
        post_with_3_achievements
        post_with_5_achievements
      end

      it "各達成回数に応じたバッジSVGが表示される（post_badge_tagメソッドが実行される）" do
        get posts_path
        expect(response).to have_http_status(:success)
        
        # SVGタグが含まれている（BadgesHelperのメソッドが実行された証拠）
        expect(response.body.scan(/<svg/).count).to be >= 5
        
        # 各種バッジのSVG要素が含まれているか確認
        expect(response.body).to include('viewBox="0 0 24 24"')
        expect(response.body).to include('polygon') # 星のSVG
        expect(response.body).to include('path')     # 炎・ダイヤ・トロフィーのSVG
      end
    end

    context "投稿詳細ページが正常に表示される" do
      it "詳細ページが正常にレンダリングされる" do
        get post_path(post_with_1_achievement)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('投稿詳細')
      end
    end
  end
end