require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe "validations" do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_least(1).is_at_most(255) }

    describe "content長さ制限" do
      let(:user) { create(:user) }
      let(:post) { create(:post) }

      it "255文字のコメントは有効" do
        comment = build(:comment, user: user, post: post, content: "a" * 255)
        expect(comment).to be_valid
      end

      it "256文字のコメントは無効" do
        comment = build(:comment, user: user, post: post, content: "a" * 256)
        expect(comment).not_to be_valid
      end

      it "空白のみのコメントは無効" do
        comment = build(:comment, user: user, post: post, content: "   ")
        # presence: trueは空白をstripして判定する
        expect(comment).not_to be_valid
      end

      it "空のコメントは無効" do
        comment = build(:comment, user: user, post: post, content: "")
        expect(comment).not_to be_valid
      end
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:post) }

    it "userが必須" do
      comment = build(:comment, user: nil)
      expect(comment).not_to be_valid
    end

    it "postが必須" do
      comment = build(:comment, post: nil)
      expect(comment).not_to be_valid
    end
  end

  describe "scopes" do
    describe ".recent" do
      it "新しい順に並ぶ" do
        old_comment = create(:comment, created_at: 2.days.ago)
        new_comment = create(:comment, created_at: 1.day.ago)

        expect(Comment.recent).to eq([ new_comment, old_comment ])
      end

      it "3件以上でも正しい順序" do
        oldest = create(:comment, created_at: 3.days.ago)
        middle = create(:comment, created_at: 2.days.ago)
        newest = create(:comment, created_at: 1.day.ago)

        expect(Comment.recent).to eq([ newest, middle, oldest ])
      end
    end

    describe ".oldest_first" do
      it "古い順に並ぶ" do
        old_comment = create(:comment, created_at: 2.days.ago)
        new_comment = create(:comment, created_at: 1.day.ago)

        expect(Comment.oldest_first).to eq([ old_comment, new_comment ])
      end
    end
  end

  describe "ビジネスロジック" do
    let(:user) { create(:user) }
    let(:post) { create(:post) }

    it "コメントを作成できる" do
      comment = create(:comment, user: user, post: post, content: "テストコメント")
      expect(comment).to be_persisted
      expect(comment.user).to eq(user)
      expect(comment.post).to eq(post)
    end

    it "同じユーザーが同じ投稿に複数コメントできる" do
      create(:comment, user: user, post: post, content: "1つ目")
      second_comment = build(:comment, user: user, post: post, content: "2つ目")
      expect(second_comment).to be_valid
    end

    it "created_atが自動設定される" do
      comment = create(:comment, user: user, post: post)
      expect(comment.created_at).to be_present
    end
  end
end
