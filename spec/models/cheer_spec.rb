# spec/models/cheer_spec.rb
require 'rails_helper'

RSpec.describe Cheer, type: :model do
  # ====================
  # バリデーションのテスト
  # ====================
  describe "validations" do
    # テスト用のCheerレコードを事前に作成
    # （uniqueness検証にはDBへの保存が必要）
    subject { create(:cheer) }

    it "同じユーザーが同じ投稿に重複して応援できない" do
      should validate_uniqueness_of(:user_id)
        .scoped_to(:post_id)
    end

    describe "二重応援の防止" do
      let(:user) { create(:user) }
      let(:post_record) { create(:post) }
      let!(:existing_cheer) { create(:cheer, user: user, post: post_record) }

      it "同じユーザーが同じ投稿に二重応援できない" do
        duplicate = build(:cheer, user: user, post: post_record)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to be_present
      end

      it "異なるユーザーは同じ投稿に応援できる" do
        other_user = create(:user)
        other_cheer = build(:cheer, user: other_user, post: post_record)
        expect(other_cheer).to be_valid
      end

      it "同じユーザーが異なる投稿に応援できる" do
        other_post = create(:post)
        other_cheer = build(:cheer, user: user, post: other_post)
        expect(other_cheer).to be_valid
      end
    end
  end

  # ====================
  # アソシエーションのテスト
  # ====================
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:post) }

    it "userが必須" do
      cheer = build(:cheer, user: nil)
      expect(cheer).not_to be_valid
    end

    it "postが必須" do
      cheer = build(:cheer, post: nil)
      expect(cheer).not_to be_valid
    end
  end

  # ====================
  # 機能のテスト（実際の動作確認）
  # ====================
  describe "応援機能" do
    let(:user) { create(:user) }
    let(:post_record) { create(:post) }

    context "正常な場合" do
      it "応援を作成できる" do
        cheer = Cheer.new(user: user, post: post_record)
        expect(cheer).to be_valid
      end

      it "応援をDBに保存できる" do
        expect {
          create(:cheer, user: user, post: post_record)
        }.to change(Cheer, :count).by(1)
      end
    end

    context "異常な場合" do
      it "同じユーザーが同じ投稿に2回応援できない" do
        # 1回目の応援（成功するはず）
        create(:cheer, user: user, post: post_record)

        # 2回目の応援（失敗するはず）
        duplicate_cheer = build(:cheer, user: user, post: post_record)
        expect(duplicate_cheer).not_to be_valid
        expect(duplicate_cheer.errors[:user_id]).to be_present
      end

      it "別のユーザーなら同じ投稿に応援できる" do
        # ユーザー1の応援
        create(:cheer, user: user, post: post_record)

        # ユーザー2の応援（成功するはず）
        another_user = create(:user)
        another_cheer = build(:cheer, user: another_user, post: post_record)
        expect(another_cheer).to be_valid
      end

      it "同じユーザーでも別の投稿には応援できる" do
        # 投稿1への応援
        create(:cheer, user: user, post: post_record)

        # 投稿2への応援（成功するはず）
        another_post = create(:post)
        another_cheer = build(:cheer, user: user, post: another_post)
        expect(another_cheer).to be_valid
      end
    end
  end

  describe "ビジネスロジック" do
    let(:user) { create(:user) }
    let(:post_record) { create(:post) }

    it "応援を削除できる" do
      cheer = create(:cheer, user: user, post: post_record)
      expect { cheer.destroy }.to change(Cheer, :count).by(-1)
    end

    it "投稿の応援数をカウントできる" do
      create_list(:cheer, 3, post: post_record)
      expect(post_record.cheers.count).to eq(3)
    end

    it "ユーザーの応援数をカウントできる" do
      create_list(:cheer, 2, user: user)
      expect(user.cheers.count).to eq(2)
    end
  end
end
