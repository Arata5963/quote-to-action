# spec/requests/likes_spec.rb
require 'rails_helper'

RSpec.describe "Likes", type: :request do
  # ====================
  # POST /posts/:post_id/likes (いいね作成)
  # ====================
  describe "POST /posts/:post_id/likes" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post) }

    context "ログイン済みの場合" do
      before { sign_in user }

      context "まだいいねしていない場合" do
        it "いいねを作成できる" do
          expect {
            post post_likes_path(post_record)
          }.to change(Like, :count).by(1)
        end

        it "投稿一覧ページにリダイレクトされる" do
          post post_likes_path(post_record)
          expect(response).to redirect_to(posts_path)
        end
      end

      context "既にいいね済みの場合" do
        before { create(:like, user: user, post: post_record) }

        it "いいねを作成しない（冪等）" do
          expect {
            post post_likes_path(post_record)
          }.not_to change(Like, :count)
        end

        it "投稿一覧ページにリダイレクトされる" do
          post post_likes_path(post_record)
          expect(response).to redirect_to(posts_path)
        end
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        post post_likes_path(post_record)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # DELETE /posts/:post_id/likes/:id (いいね削除)
  # ====================
  describe "DELETE /posts/:post_id/likes/:id" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post) }

    context "自分のいいねの場合" do
      let!(:like) { create(:like, user: user, post: post_record) }
      before { sign_in user }

      it "いいねを削除できる" do
        expect {
          delete post_like_path(post_record, like)
        }.to change(Like, :count).by(-1)
      end

      it "投稿一覧ページにリダイレクトされる" do
        delete post_like_path(post_record, like)
        expect(response).to redirect_to(posts_path)
      end
    end

    context "ログインしていない場合" do
      let!(:like) { create(:like, user: user, post: post_record) }

      it "ログインページにリダイレクトされる" do
        delete post_like_path(post_record, like)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # 追加の異常系（存在しない投稿 / 存在しないlike / 他人のlike / 二重削除）
  # ====================
  describe "Likes edge cases" do
    let(:user)  { create(:user) }
    let(:other) { create(:user) }
    let!(:post_record) { create(:post) }

    describe "POST /posts/:post_id/likes (create)" do
      context "投稿が存在しない場合" do
        it "投稿一覧へリダイレクトされる（set_post rescue）" do
          sign_in user
          post post_likes_path(-1)
          expect(response).to redirect_to(posts_path)
        end
      end
    end

    describe "DELETE /posts/:post_id/likes/:id (destroy)" do
      context "ログイン済み" do
        before { sign_in user }

        it "存在しないlikeを削除しようとすると投稿一覧へリダイレクト" do
          delete post_like_path(post_record, 999_999)
          expect(response).to redirect_to(posts_path)
        end

        it "投稿が存在しない場合は投稿一覧へリダイレクト（set_post rescue）" do
          delete post_like_path(-1, 1) # post_id が先に解決され rescue へ
          expect(response).to redirect_to(posts_path)
        end

        it "他人のlikeは削除できず、件数は変わらない" do
          others_like = create(:like, user: other, post: post_record)
          expect {
            delete post_like_path(post_record, others_like)
          }.not_to change(Like, :count)
          expect(response).to redirect_to(posts_path)
        end

        it "二重削除時は2回目でnot found相当（件数は変わらない）" do
          own_like = create(:like, user: user, post: post_record)

          # 1回目は削除される
          expect {
            delete post_like_path(post_record, own_like)
          }.to change(Like, :count).by(-1)

          # 2回目は見つからない扱い（穏当な遷移）
          expect {
            delete post_like_path(post_record, own_like.id)
          }.not_to change(Like, :count)
          expect(response).to redirect_to(posts_path)
        end
      end
    end
  end
end
