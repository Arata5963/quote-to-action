require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe "validations" do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_least(1).is_at_most(255) }
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:post) }
  end

  describe "scopes" do
    describe ".recent" do
      it "新しい順に並ぶ" do
        old_comment = create(:comment, created_at: 2.days.ago)
        new_comment = create(:comment, created_at: 1.day.ago)

        expect(Comment.recent).to eq([ new_comment, old_comment ])
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
end
