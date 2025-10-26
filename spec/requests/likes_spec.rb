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
      before do
        sign_in user
      end

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
        before do
          create(:like, user: user, post: post_record)
        end

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

      before do
        sign_in user
      end

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
end
