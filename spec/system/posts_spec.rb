# spec/system/posts_spec.rb
require 'rails_helper'

RSpec.describe "Posts", type: :system do
  # JavaScript を使わないシンプルなテストの場合は rack_test を使用
  before do
    driven_by(:rack_test)
  end

  # ====================
  # 投稿作成フロー
  # ====================
  describe "投稿作成" do
    let(:user) { create(:user) }

    context "ログイン済みの場合" do
      before do
        # System テストでのログイン
        sign_in user
      end

      it "新しい投稿を作成できる" do
        # 1. 新規投稿ページに直接アクセス
        visit new_post_path

        # 2. 新規投稿フォームが表示される（投稿ボタンがある）
        expect(page).to have_button("投稿する")
        expect(page).to have_content("YouTube URL")

        # 3. フォームに入力
        fill_in "post_youtube_url", with: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        fill_in "post_action_plan", with: "テストアクション"
        select "音楽", from: "post_category"  # プルダウンで選択

        # 4. 投稿ボタンをクリック
        click_button "投稿する"

        # 5. 投稿詳細ページにリダイレクトされる
        expect(page).to have_current_path(/\/posts\/\d+/)

        # 6. 投稿内容が表示される
        expect(page).to have_content("テストアクション")

        # 7. 成功メッセージが表示される
        expect(page).to have_content("投稿しました！")
      end

      it "バリデーションエラーが表示される" do
        # 1. 新規投稿ページにアクセス
        visit new_post_path

        # 2. 空のまま投稿ボタンをクリック
        click_button "投稿する"

        # 3. エラーメッセージが表示される
        expect(page).to have_content("入力してください")
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        # 1. 新規投稿ページにアクセスを試みる
        visit new_post_path

        # 2. ログインページにリダイレクトされる
        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end

  # ====================
  # 投稿一覧表示
  # ====================
  describe "投稿一覧" do
    let!(:post1) { create(:post, action_plan: "投稿1のアクション", created_at: 2.days.ago) }
    let!(:post2) { create(:post, action_plan: "投稿2のアクション", created_at: 1.day.ago) }

    it "投稿が新しい順に表示される" do
      # 1. トップページにアクセス
      visit root_path

      # 2. 両方の投稿が表示される
      expect(page).to have_content("投稿1のアクション")
      expect(page).to have_content("投稿2のアクション")

      # 3. 新しい順に並んでいる（投稿2が先）
      post2_position = page.body.index("投稿2のアクション")
      post1_position = page.body.index("投稿1のアクション")
      expect(post2_position).to be < post1_position
    end
  end

  # ====================
  # 投稿詳細表示
  # ====================
  describe "投稿詳細" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, user: user, action_plan: "詳細テストアクション") }

    it "投稿の詳細が表示される" do
      # 1. 投稿詳細ページにアクセス
      visit post_path(post_record)

      # 2. 投稿内容が表示される
      expect(page).to have_content("詳細テストアクション")
    end
  end

  # ====================
  # 投稿編集
  # ====================
  describe "投稿編集" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, user: user, action_plan: "編集前のアクション") }

    context "投稿者本人の場合" do
      before do
        sign_in user
      end

      it "投稿を編集できる" do
        # 1. 編集ページに直接アクセス
        visit edit_post_path(post_record)

        # 2. 編集フォームが表示される（更新ボタンがある）
        expect(page).to have_button("更新する")
        expect(page).to have_content("YouTube URL")

        # 3. 内容を変更
        fill_in "post_action_plan", with: "編集後のアクション"

        # 4. 更新ボタンをクリック
        click_button "更新する"

        # 5. 詳細ページにリダイレクトされる
        expect(page).to have_current_path(post_path(post_record))

        # 6. 更新された内容が表示される
        expect(page).to have_content("編集後のアクション")

        # 7. 成功メッセージが表示される
        expect(page).to have_content("投稿を更新しました")
      end
    end
  end

  # ====================
  # 投稿削除
  # ====================
  describe "投稿削除" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, user: user, action_plan: "削除するアクション") }

    context "投稿者本人の場合" do
      before do
        sign_in user
      end

      it "投稿を削除できる" do
        # 1. 投稿詳細ページにアクセス
        visit post_path(post_record)

        # 2. 削除リンクをクリック（"削除"というテキストリンク）
        click_link "削除"

        # 3. 一覧ページにリダイレクトされる
        expect(page).to have_current_path(posts_path)

        # 4. 成功メッセージが表示される
        expect(page).to have_content("投稿を削除しました")

        # 5. 投稿が表示されない
        expect(page).not_to have_content("削除するアクション")
      end
    end
  end
end
