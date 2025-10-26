# spec/requests/achievements_spec.rb
require 'rails_helper'

RSpec.describe "Achievements", type: :request do
  # ====================
  # POST /posts/:post_id/achievements (達成記録作成)
  # ====================
  describe "POST /posts/:post_id/achievements" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    context "自分の投稿の場合" do
      let!(:post_record) { create(:post, user: user) }

      before do
        sign_in user
      end

      it "達成記録を作成できる" do
        expect {
          post post_achievements_path(post_record)
        }.to change(Achievement, :count).by(1)
      end

      it "投稿詳細ページにリダイレクトされる" do
        post post_achievements_path(post_record)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include("達成")
      end

      it "今日の日付で記録される" do
        post post_achievements_path(post_record)

        achievement = Achievement.last
        expect(achievement.awarded_at).to eq(Date.current)
      end

      context "既に今日達成済みの場合" do
        before do
          create(:achievement, user: user, post: post_record, awarded_at: Date.current)
        end

        it "達成記録を作成できない" do
          expect {
            post post_achievements_path(post_record)
          }.not_to change(Achievement, :count)
        end

        it "エラーメッセージが表示される" do
          post post_achievements_path(post_record)

          expect(response).to redirect_to(post_path(post_record))
          follow_redirect!
          expect(response.body).to include("すでに達成済み")
        end
      end
    end

    context "他人の投稿の場合" do
      let!(:post_record) { create(:post, user: other_user) }

      before do
        sign_in user
      end

      it "達成記録を作成できない" do
        expect {
          post post_achievements_path(post_record)
        }.not_to change(Achievement, :count)
      end

      it "一覧ページにリダイレクトされる" do
        post post_achievements_path(post_record)

        expect(response).to redirect_to(posts_path)
        follow_redirect!
        expect(response.body).to include("投稿が見つかりません")
      end
    end

    context "ログインしていない場合" do
      let!(:post_record) { create(:post, user: user) }

      it "ログインページにリダイレクトされる" do
        post post_achievements_path(post_record)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # DELETE /posts/:post_id/achievements/:id (達成記録削除)
  # ====================
  describe "DELETE /posts/:post_id/achievements/:id" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, user: user) }

    context "今日の達成記録がある場合" do
      let!(:achievement) { create(:achievement, user: user, post: post_record, awarded_at: Date.current) }

      before do
        sign_in user
      end

      it "達成記録を削除できる" do
        expect {
          delete post_achievement_path(post_record, achievement)
        }.to change(Achievement, :count).by(-1)
      end

      it "投稿詳細ページにリダイレクトされる" do
        delete post_achievement_path(post_record, achievement)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include("達成")
      end
    end

    context "今日の達成記録がない場合" do
      let!(:achievement) { create(:achievement, user: user, post: post_record, awarded_at: 1.day.ago) }

      before do
        sign_in user
      end

      it "削除メッセージが表示される" do
        delete post_achievement_path(post_record, achievement)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include("取り消す達成記録が見つかりません")
      end
    end

    context "ログインしていない場合" do
      let!(:achievement) { create(:achievement, user: user, post: post_record) }

      it "ログインページにリダイレクトされる" do
        delete post_achievement_path(post_record, achievement)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
