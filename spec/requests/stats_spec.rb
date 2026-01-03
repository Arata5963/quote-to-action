# spec/requests/stats_spec.rb
require 'rails_helper'

RSpec.describe "Stats", type: :request do
  describe "GET /stats" do
    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        get stats_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログインしている場合" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "統計ページが表示される" do
        get stats_path
        expect(response).to have_http_status(:success)
      end

      it "基本統計が表示される" do
        create(:post, user: user)
        get stats_path
        expect(response.body).to include("視聴動画")
        expect(response.body).to include("アウトプット")
        expect(response.body).to include("達成率")
      end

      context "エントリーがある場合" do
        let!(:post) { create(:post, user: user) }
        let!(:entry_action) { create(:post_entry, :action, post: post, satisfaction_rating: 5) }
        let!(:entry_key_point) { create(:post_entry, :key_point, post: post, satisfaction_rating: 3) }

        it "アウトプット内訳が表示される" do
          get stats_path
          expect(response.body).to include("アウトプット内訳")
        end

        it "満足度分布が表示される" do
          get stats_path
          expect(response.body).to include("満足度分布")
        end
      end
    end
  end
end
