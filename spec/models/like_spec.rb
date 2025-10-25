# spec/models/like_spec.rb
require 'rails_helper'

RSpec.describe Like, type: :model do
  # ====================
  # バリデーションのテスト
  # ====================
  describe "validations" do
    # テスト用のLikeレコードを事前に作成
    # （uniqueness検証にはDBへの保存が必要）
    subject { create(:like) }

    it "同じユーザーが同じ投稿に重複していいねできない" do
      # should validate_uniqueness_of(:user_id).scoped_to(:post_id)
      # と同じ意味だが、より明示的に記述
      should validate_uniqueness_of(:user_id)
        .scoped_to(:post_id)
    end
  end

  # ====================
  # アソシエーションのテスト
  # ====================
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:post) }
  end

  # ====================
  # 機能のテスト（実際の動作確認）
  # ====================
  describe "いいね機能" do
    let(:user) { create(:user) }
    let(:post_record) { create(:post) }

    context "正常な場合" do
      it "いいねを作成できる" do
        like = Like.new(user: user, post: post_record)
        expect(like).to be_valid
      end

      it "いいねをDBに保存できる" do
        expect {
          create(:like, user: user, post: post_record)
        }.to change(Like, :count).by(1)
      end
    end

    context "異常な場合" do
      it "同じユーザーが同じ投稿に2回いいねできない" do
        # 1回目のいいね（成功するはず）
        create(:like, user: user, post: post_record)

        # 2回目のいいね（失敗するはず）
        duplicate_like = build(:like, user: user, post: post_record)
        expect(duplicate_like).not_to be_valid
        expect(duplicate_like.errors[:user_id]).to be_present
      end

      it "別のユーザーなら同じ投稿にいいねできる" do
        # ユーザー1のいいね
        create(:like, user: user, post: post_record)

        # ユーザー2のいいね（成功するはず）
        another_user = create(:user)
        another_like = build(:like, user: another_user, post: post_record)
        expect(another_like).to be_valid
      end

      it "同じユーザーでも別の投稿にはいいねできる" do
        # 投稿1へのいいね
        create(:like, user: user, post: post_record)

        # 投稿2へのいいね（成功するはず）
        another_post = create(:post)
        another_like = build(:like, user: user, post: another_post)
        expect(another_like).to be_valid
      end
    end
  end
end
