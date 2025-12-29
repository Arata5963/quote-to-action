# spec/requests/notifications_spec.rb
require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:post_record) { create(:post, user: user) }

  describe "GET /notifications" do
    context "ログインしている場合" do
      before { sign_in user }

      it "正常にアクセスできる" do
        get notifications_path
        expect(response).to have_http_status(200)
      end

      it "通知がない場合でも表示される" do
        get notifications_path
        expect(response.body).to include("通知はありません")
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        get notifications_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /notifications/:id/mark_as_read" do
    context "ログインしている場合" do
      before { sign_in user }

      it "通知を既読にできる" do
        # 他のユーザーが応援して通知を作成（コールバックで自動作成）
        create(:cheer, post: post_record, user: other_user)

        notification = user.notifications.first
        expect(notification).not_to be_nil

        post mark_as_read_notification_path(notification)

        notification.reload
        expect(notification.opened?).to be true
      end
    end
  end

  describe "POST /notifications/mark_all_as_read" do
    context "ログインしている場合" do
      before { sign_in user }

      it "すべての通知を既読にできる" do
        # 他のユーザーが応援して通知を作成（コールバックで自動作成）
        create(:cheer, post: post_record, user: other_user)

        another_post = create(:post, user: user)
        create(:cheer, post: another_post, user: other_user)

        expect(user.notifications.unopened_only.count).to eq(2)

        post mark_all_as_read_notifications_path

        expect(user.notifications.unopened_only.count).to eq(0)
      end

      it "リダイレクトされる" do
        post mark_all_as_read_notifications_path
        expect(response).to redirect_to(notifications_path)
      end
    end
  end

  describe "通知の作成" do
    context "応援時" do
      it "投稿者に通知が作成される" do
        sign_in other_user

        expect {
          post post_cheers_path(post_record)
        }.to change { user.notifications.count }.by(1)
      end

      it "自分の投稿に応援しても通知は作成されない" do
        sign_in user

        expect {
          post post_cheers_path(post_record)
        }.not_to change { user.notifications.count }
      end
    end

    context "コメント時" do
      it "投稿者に通知が作成される" do
        sign_in other_user

        expect {
          post post_comments_path(post_record), params: { comment: { content: "テストコメント" } }
        }.to change { user.notifications.count }.by(1)
      end

      it "自分の投稿にコメントしても通知は作成されない" do
        sign_in user

        expect {
          post post_comments_path(post_record), params: { comment: { content: "テストコメント" } }
        }.not_to change { user.notifications.count }
      end
    end
  end
end
