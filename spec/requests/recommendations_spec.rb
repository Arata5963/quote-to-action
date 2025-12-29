# spec/requests/recommendations_spec.rb
require "rails_helper"

RSpec.describe "Recommendations", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:post_record) { create(:post, user: user) }

  describe "GET /posts/:post_id/recommendation" do
    context "ログイン済みの場合" do
      before { sign_in user }

      context "Turbo Streamリクエストの場合" do
        let!(:recommended_posts) { create_list(:post, 3, user: other_user) }

        it "Turbo Streamレスポンスを返す" do
          get post_recommendation_path(post_record),
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
        end

        it "recommendation_modalを更新するストリームを含む" do
          get post_recommendation_path(post_record),
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response.body).to include('turbo-stream action="update" target="recommendation_modal"')
        end
      end

      context "HTMLリクエストの場合" do
        it "投稿詳細ページにリダイレクトする" do
          get post_recommendation_path(post_record)

          expect(response).to redirect_to(post_record)
        end
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトする" do
        get post_recommendation_path(post_record)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
