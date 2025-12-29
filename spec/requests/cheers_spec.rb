# spec/requests/cheers_spec.rb
require 'rails_helper'

RSpec.describe "Cheers", type: :request do
  # ====================
  # POST /posts/:post_id/cheers (応援作成)
  # ====================
  describe "POST /posts/:post_id/cheers" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post) }

    context "ログイン済みの場合" do
      before { sign_in user }

      context "まだ応援していない場合" do
        it "応援を作成できる" do
          expect {
            post post_cheers_path(post_record)
          }.to change(Cheer, :count).by(1)
        end

        it "投稿一覧ページにリダイレクトされる" do
          post post_cheers_path(post_record)
          expect(response).to redirect_to(posts_path)
        end

        context "Turbo Streamリクエストの場合" do
          it "Turbo Streamレスポンスを返す" do
            post post_cheers_path(post_record),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }

            expect(response).to have_http_status(:ok)
            expect(response.media_type).to eq Mime[:turbo_stream]
          end

          it "応援ボタンを更新するストリームを含む" do
            post post_cheers_path(post_record),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }

            expect(response.body).to include("turbo-stream")
            expect(response.body).to include("cheer_button_#{post_record.id}")
          end
        end
      end

      context "既に応援済みの場合" do
        before { create(:cheer, user: user, post: post_record) }

        it "応援を作成しない（冪等）" do
          expect {
            post post_cheers_path(post_record)
          }.not_to change(Cheer, :count)
        end

        it "投稿一覧ページにリダイレクトされる" do
          post post_cheers_path(post_record)
          expect(response).to redirect_to(posts_path)
        end

        context "Turbo Streamリクエストの場合" do
          it "Turbo Streamレスポンスを返す" do
            post post_cheers_path(post_record),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }

            expect(response).to have_http_status(:ok)
            expect(response.media_type).to eq Mime[:turbo_stream]
          end
        end
      end

      context "応援保存に失敗した場合" do
        before do
          allow_any_instance_of(Cheer).to receive(:save).and_return(false)
          allow_any_instance_of(Cheer).to receive_message_chain(:errors, :full_messages, :first).and_return("エラー")
        end

        it "HTMLリクエストでエラーメッセージを表示" do
          post post_cheers_path(post_record)
          expect(response).to redirect_to(posts_path)
        end

        context "Turbo Streamリクエストの場合" do
          it "Turbo Streamレスポンスを返す" do
            post post_cheers_path(post_record),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }

            expect(response).to have_http_status(:ok)
            expect(response.media_type).to eq Mime[:turbo_stream]
          end
        end
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        post post_cheers_path(post_record)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # DELETE /posts/:post_id/cheers/:id (応援削除)
  # ====================
  describe "DELETE /posts/:post_id/cheers/:id" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post) }

    context "自分の応援の場合" do
      let!(:cheer) { create(:cheer, user: user, post: post_record) }
      before { sign_in user }

      it "応援を削除できる" do
        expect {
          delete post_cheer_path(post_record, cheer)
        }.to change(Cheer, :count).by(-1)
      end

      it "投稿一覧ページにリダイレクトされる" do
        delete post_cheer_path(post_record, cheer)
        expect(response).to redirect_to(posts_path)
      end

      context "Turbo Streamリクエストの場合" do
        it "Turbo Streamレスポンスを返す" do
          delete post_cheer_path(post_record, cheer),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
        end

        it "応援ボタンを更新するストリームを含む" do
          delete post_cheer_path(post_record, cheer),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response.body).to include("turbo-stream")
          expect(response.body).to include("cheer_button_#{post_record.id}")
        end
      end
    end

    context "ログインしていない場合" do
      let!(:cheer) { create(:cheer, user: user, post: post_record) }

      it "ログインページにリダイレクトされる" do
        delete post_cheer_path(post_record, cheer)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # 追加の異常系（存在しない投稿 / 存在しないcheer / 他人のcheer / 二重削除）
  # ====================
  describe "Cheers edge cases" do
    let(:user)  { create(:user) }
    let(:other) { create(:user) }
    let!(:post_record) { create(:post) }

    describe "POST /posts/:post_id/cheers (create)" do
      context "投稿が存在しない場合" do
        it "投稿一覧へリダイレクトされる（set_post rescue）" do
          sign_in user
          post post_cheers_path(-1)
          expect(response).to redirect_to(posts_path)
        end
      end
    end

    describe "DELETE /posts/:post_id/cheers/:id (destroy)" do
      context "ログイン済み" do
        before { sign_in user }

        it "存在しないcheerを削除しようとすると投稿一覧へリダイレクト" do
          delete post_cheer_path(post_record, 999_999)
          expect(response).to redirect_to(posts_path)
        end

        it "投稿が存在しない場合は投稿一覧へリダイレクト（set_post rescue）" do
          delete post_cheer_path(-1, 1) # post_id が先に解決され rescue へ
          expect(response).to redirect_to(posts_path)
        end

        it "他人のcheerは削除できず、件数は変わらない" do
          others_cheer = create(:cheer, user: other, post: post_record)
          expect {
            delete post_cheer_path(post_record, others_cheer)
          }.not_to change(Cheer, :count)
          expect(response).to redirect_to(posts_path)
        end

        context "Turbo Streamリクエストで他人のcheerを削除しようとした場合" do
          it "Turbo Streamレスポンスを返す" do
            others_cheer = create(:cheer, user: other, post: post_record)
            delete post_cheer_path(post_record, others_cheer),
                   headers: { "Accept" => "text/vnd.turbo-stream.html" }

            expect(response).to have_http_status(:ok)
            expect(response.media_type).to eq Mime[:turbo_stream]
          end
        end

        it "二重削除時は2回目でnot found相当（件数は変わらない）" do
          own_cheer = create(:cheer, user: user, post: post_record)

          # 1回目は削除される
          expect {
            delete post_cheer_path(post_record, own_cheer)
          }.to change(Cheer, :count).by(-1)

          # 2回目は見つからない扱い（穏当な遷移）
          expect {
            delete post_cheer_path(post_record, own_cheer.id)
          }.not_to change(Cheer, :count)
          expect(response).to redirect_to(posts_path)
        end
      end
    end
  end
end
