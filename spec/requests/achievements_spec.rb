# spec/requests/achievements_spec.rb
require 'rails_helper'

RSpec.describe "Achievements", type: :request do
  # NOTE: In the new video-based structure, achievements are primarily managed
  # at PostEntry level via PostEntriesController#achieve.
  # AchievementsController now achieves all user's action entries at once.

  describe "POST /posts/:post_id/achievements" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:post_record) { create(:post) }

    context "ユーザーがアクションエントリーを持つ場合" do
      let!(:action_entry) do
        create(:post_entry, :action, post: post_record, user: user, achieved_at: nil)
      end

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
        expect(achievement.achieved_at).to eq(Date.current)
      end

      it "エントリーのachieved_atが設定される" do
        post post_achievements_path(post_record)

        action_entry.reload
        expect(action_entry.achieved_at).to be_present
      end
    end

    context "達成するアクションエントリーがない場合" do
      before do
        sign_in user
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
        expect(response.body).to include("entries")
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        post post_achievements_path(post_record)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /posts/:post_id/achievements/:id" do
    let(:user) { create(:user) }
    let(:post_record) { create(:post) }
    let!(:entry) { create(:post_entry, :action, post: post_record, user: user) }
    let!(:achievement) { create(:achievement, user: user, post: post_record) }

    context "達成記録がある場合" do
      before do
        sign_in user
      end

      it "取り消し不可メッセージが表示される" do
        delete post_achievement_path(post_record, achievement)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include("undone")
      end
    end
  end
end
