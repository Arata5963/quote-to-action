# spec/requests/comments_spec.rb
require 'rails_helper'

RSpec.describe "Comments", type: :request do
  # ====================
  # POST /posts/:post_id/comments (コメント作成)
  # ====================
  describe "POST /posts/:post_id/comments" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post) }

    context "ログイン済みの場合" do
      before do
        sign_in user
      end

      context "有効なパラメータの場合" do
        let(:valid_params) do
          {
            comment: {
              content: "素晴らしい投稿ですね！"
            }
          }
        end

        it "コメントを作成できる" do
          expect {
            post post_comments_path(post_record), params: valid_params
          }.to change(Comment, :count).by(1)
        end

        it "投稿詳細ページにリダイレクトされる" do
          post post_comments_path(post_record), params: valid_params

          expect(response).to redirect_to(post_path(post_record))
          follow_redirect!
          expect(response.body).to include("コメント")
        end

        it "作成したコメントが表示される" do
          post post_comments_path(post_record), params: valid_params

          follow_redirect!
          expect(response.body).to include("素晴らしい投稿ですね！")
        end
      end

      context "無効なパラメータの場合" do
        let(:invalid_params) do
          {
            comment: {
              content: "" # 必須項目を空に
            }
          }
        end

        it "コメントが作成されない" do
          expect {
            post post_comments_path(post_record), params: invalid_params
          }.not_to change(Comment, :count)
        end

        it "エラーメッセージが表示される" do
          post post_comments_path(post_record), params: invalid_params

          expect(response).to redirect_to(post_path(post_record))
          follow_redirect!
          expect(response.body).to include("入力してください")
        end
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        post post_comments_path(post_record), params: { comment: { content: "コメント" } }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # DELETE /posts/:post_id/comments/:id (コメント削除)
  # ====================
  describe "DELETE /posts/:post_id/comments/:id" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:post_record) { create(:post) }

    context "自分のコメントの場合" do
      let!(:comment) { create(:comment, post: post_record, user: user) }

      before do
        sign_in user
      end

      it "コメントを削除できる" do
        expect {
          delete post_comment_path(post_record, comment)
        }.to change(Comment, :count).by(-1)
      end

      it "投稿詳細ページにリダイレクトされる" do
        delete post_comment_path(post_record, comment)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include("コメント")
      end
    end

    context "他人のコメントの場合" do
      let!(:comment) { create(:comment, post: post_record, user: other_user) }

      before do
        sign_in user
      end

      it "コメントを削除できない" do
        expect {
          delete post_comment_path(post_record, comment)
        }.not_to change(Comment, :count)
      end

      it "投稿詳細ページにリダイレクトされる" do
        delete post_comment_path(post_record, comment)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include("削除できません")
      end
    end

    context "ログインしていない場合" do
      let!(:comment) { create(:comment, post: post_record, user: user) }

      it "ログインページにリダイレクトされる" do
        delete post_comment_path(post_record, comment)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
