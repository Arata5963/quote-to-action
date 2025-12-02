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

        # 2. 新規投稿フォームが表示される
        expect(page).to have_content("新しい投稿を作成")

        # 3. フォームに入力
        fill_in "post_youtube_url", with: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        fill_in "post_trigger_content", with: "テストきっかけ"
        fill_in "post_action_plan", with: "テストアクション"
        choose "post_category_music"  # ラジオボタンで選択

        # 4. 投稿ボタンをクリック
        click_button "投稿する"

        # 5. 投稿詳細ページにリダイレクトされる
        expect(page).to have_current_path(/\/posts\/\d+/)

        # 6. 投稿内容が表示される
        expect(page).to have_content("テストきっかけ")
        expect(page).to have_content("テストアクション")

        # 7. 成功メッセージが表示される
        expect(page).to have_content("きっかけが投稿されました")
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
    let!(:post1) { create(:post, trigger_content: "投稿1のきっかけ", created_at: 2.days.ago) }
    let!(:post2) { create(:post, trigger_content: "投稿2のきっかけ", created_at: 1.day.ago) }

    it "投稿が新しい順に表示される" do
      # 1. トップページにアクセス
      visit root_path

      # 2. 両方の投稿が表示される
      expect(page).to have_content("投稿1のきっかけ")
      expect(page).to have_content("投稿2のきっかけ")

      # 3. 新しい順に並んでいる（投稿2が先）
      post2_position = page.body.index("投稿2のきっかけ")
      post1_position = page.body.index("投稿1のきっかけ")
      expect(post2_position).to be < post1_position
    end
  end

  # ====================
  # 投稿詳細表示
  # ====================
  describe "投稿詳細" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, user: user, trigger_content: "詳細テストきっかけ") }

    it "投稿の詳細が表示される" do
      # 1. 投稿詳細ページにアクセス
      visit post_path(post_record)

      # 2. 投稿内容が表示される
      expect(page).to have_content("詳細テストきっかけ")
      expect(page).to have_content(post_record.action_plan)
    end
  end

  # ====================
  # 投稿編集
  # ====================
  describe "投稿編集" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, user: user, trigger_content: "編集前のきっかけ") }

    context "投稿者本人の場合" do
      before do
        sign_in user
      end

      it "投稿を編集できる" do
        # 1. 投稿詳細ページにアクセス
        visit post_path(post_record)

        # 2. 編集リンクをクリック（"編集"というテキストリンク）
        click_link "編集"

        # 3. 編集フォームが表示される
        expect(page).to have_content("投稿を編集")

        # 4. 内容を変更
        fill_in "post_trigger_content", with: "編集後のきっかけ"

        # 5. 更新ボタンをクリック
        click_button "更新する"

        # 6. 詳細ページにリダイレクトされる
        expect(page).to have_current_path(post_path(post_record))

        # 7. 更新された内容が表示される
        expect(page).to have_content("編集後のきっかけ")

        # 8. 成功メッセージが表示される
        expect(page).to have_content("きっかけが更新されました")
      end
    end
  end

  # ====================
  # 投稿削除
  # ====================
  describe "投稿削除" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, user: user, trigger_content: "削除するきっかけ") }

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
        expect(page).to have_content("きっかけが削除されました")

        # 5. 投稿が表示されない
        expect(page).not_to have_content("削除するきっかけ")
      end
    end
  end
end
