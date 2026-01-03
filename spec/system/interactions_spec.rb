# spec/system/interactions_spec.rb
require 'rails_helper'

RSpec.describe "Interactions", type: :system do
  before do
    driven_by(:rack_test)
  end

  # ====================
  # 達成記録
  # ====================
  describe "達成記録" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, user: user) }

    context "自分の投稿の場合" do
      before do
        sign_in user
      end

      it "達成記録を作成できる" do
        visit post_path(post_record)

        # 達成ボタンをクリック
        click_button "達成"

        # 達成記録が作成される（「達成済み」表示に変わる）
        expect(page).to have_content "達成済み"

        # 達成回数が表示される（詳細ページで確認）
        # post.achievements.count が 1 になったことを確認
        expect(Achievement.count).to eq(1)
      end

      it "タスク型なので一度達成すると達成済み表示になる" do
        # 達成を記録（Post.achieved_atも設定）
        post_record.update!(achieved_at: Time.current)
        create(:achievement, user: user, post: post_record, achieved_at: Date.current)

        visit post_path(post_record)

        # 達成済み表示になる（タスク型）
        expect(page).to have_content "達成済み"
        # 達成ボタンは表示されない（達成済み表示のため）
        expect(page).not_to have_button "達成"
      end
    end

    context "他人の投稿の場合" do
      let(:other_user) { create(:user) }

      before do
        sign_in other_user
      end

      it "達成記録できない" do
        visit post_path(post_record)

        # 他人の投稿には達成ボタンが表示されない（達成ボタンセクション自体がない）
        expect(page).not_to have_css "#achievement_button_#{post_record.id}"
      end
    end
  end

  # ====================
  # コメント
  # ====================
  describe "コメント" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post) }

    before do
      sign_in user
    end

    it "コメントを投稿できる" do
      visit post_path(post_record)

      # コメントセクションが表示されている
      expect(page).to have_content "コメント"

      # コメントを入力して投稿
      fill_in "comment_content", with: "素晴らしい投稿ですね！"
      click_button "送信"

      # コメントが表示される
      expect(page).to have_content "コメントを投稿しました"
      expect(page).to have_content "素晴らしい投稿ですね！"
    end

    it "自分のコメントを削除できる" do
      # 事前にコメントを作成
      comment = create(:comment, user: user, post: post_record, content: "テストコメント")

      visit post_path(post_record)

      # コメントが表示されている
      expect(page).to have_content "テストコメント"

      # 削除ボタンをクリック（アイコンボタンなのでformを送信）
      within("#comment_#{comment.id}") do
        find("form[action*='comments']").click_button
      end

      # コメントが削除される
      expect(page).to have_content "コメントを削除しました"
      expect(page).not_to have_content "テストコメント"
    end

    it "コメント数が表示される" do
      # 事前にコメントを3つ作成
      create_list(:comment, 3, post: post_record)

      visit post_path(post_record)

      # コメント数が表示される
      expect(page).to have_content "コメント (3)"
    end
  end

  # ====================
  # 応援
  # ====================
  describe "応援" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post) }

    before do
      sign_in user
    end

    it "応援できる" do
      # 投稿詳細ページに移動（新デザインでは詳細ページで応援）
      visit post_path(post_record)

      # 応援数を確認（初期状態：0）
      expect(Cheer.count).to eq(0)

      # 応援ボタン領域を特定し、その中のformを送信
      within(first("#cheer_button_#{post_record.id}")) do
        # button_to で生成されたフォームを送信
        find("form").click_button
      end

      # 応援が作成される
      expect(Cheer.count).to eq(1)
      expect(Cheer.last.user).to eq(user)
      expect(Cheer.last.post).to eq(post_record)
    end

    it "応援を取り消せる" do
      # 事前に応援を作成
      create(:cheer, user: user, post: post_record)

      # 投稿詳細ページに移動
      visit post_path(post_record)

      # 応援数を確認（初期状態：1）
      expect(Cheer.count).to eq(1)

      # 応援取り消しボタン領域を特定し、その中のformを送信
      within(first("#cheer_button_#{post_record.id}")) do
        # button_to で生成されたフォームを送信
        find("form").click_button
      end

      # 応援が削除される
      expect(Cheer.count).to eq(0)
    end

    it "応援数が表示される" do
      # 事前に応援を2つ作成
      create_list(:cheer, 2, post: post_record)

      # 投稿詳細ページに移動
      visit post_path(post_record)

      # 応援数が表示される（DBレコードで確認）
      expect(Cheer.where(post: post_record).count).to eq(2)
    end
  end

  # ====================
  # 未ログイン時の制御
  # ====================
  describe "未ログイン時の制御" do
    let!(:post_record) { create(:post) }

    it "コメントフォームが表示されない" do
      visit post_path(post_record)

      # ログイン促進メッセージが表示される
      expect(page).to have_content "コメントするにはログインが必要です"
      expect(page).to have_link "ログイン"

      # コメントフォームは表示されない
      expect(page).not_to have_button "コメントする"
    end

    it "達成ボタンが表示されない" do
      visit post_path(post_record)

      # 達成ボタンは表示されない
      expect(page).not_to have_button "達成"
      expect(page).not_to have_button "達成を取り消し"
    end
  end
end
