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
        expect(achievement.achieved_at).to eq(Date.current)
      end

      it "投稿のachieved_atが設定される" do
        post post_achievements_path(post_record)

        post_record.reload
        expect(post_record.achieved_at).to be_present
      end

      context "Turbo Streamリクエストの場合" do
        it "Turbo Streamレスポンスを返す" do
          post post_achievements_path(post_record),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
        end

        it "達成ボタンを更新するストリームを含む" do
          post post_achievements_path(post_record),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response.body).to include("turbo-stream")
        end
      end

      context "既に達成済みの場合" do
        before do
          # タスク型モデル：post.achieved_at を設定
          post_record.update!(achieved_at: Time.current)
          create(:achievement, user: user, post: post_record, achieved_at: Date.current)
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
          expect(response.body).to include("既に達成済みです")
        end

        context "Turbo Streamリクエストの場合" do
          it "リダイレクトされる" do
            post post_achievements_path(post_record),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }

            expect(response).to redirect_to(post_path(post_record))
          end
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

    context "達成記録の保存に失敗した場合" do
      let!(:post_record) { create(:post, user: user) }

      before do
        sign_in user
        # Achievementの保存を失敗させる
        allow_any_instance_of(Achievement).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Achievement.new))
      end

      it "HTMLリクエストでエラーメッセージを表示してリダイレクト" do
        post post_achievements_path(post_record)

        expect(response).to redirect_to(post_path(post_record))
      end

      context "Turbo Streamリクエストの場合" do
        it "リダイレクトされる" do
          post post_achievements_path(post_record),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to redirect_to(post_path(post_record))
        end
      end
    end
  end

  # ====================
  # DELETE /posts/:post_id/achievements/:id (達成記録削除)
  # ====================
  describe "DELETE /posts/:post_id/achievements/:id" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, user: user) }

    context "達成記録がある場合" do
      let!(:achievement) { create(:achievement, user: user, post: post_record, achieved_at: Date.current) }

      before do
        sign_in user
      end

      # タスク型では達成の取り消しは不可
      it "達成記録を削除できない（タスク型では取り消し不可）" do
        expect {
          delete post_achievement_path(post_record, achievement)
        }.not_to change(Achievement, :count)
      end

      it "取り消し不可メッセージが表示される" do
        delete post_achievement_path(post_record, achievement)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include("達成記録は取り消せません")
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
