require 'rails_helper'

RSpec.describe Post, type: :model do
  describe "validations" do
    it { should validate_presence_of(:trigger_content) }
    it { should validate_presence_of(:action_plan) }
    it { should validate_presence_of(:category) }
    it { should validate_length_of(:trigger_content).is_at_most(100) }
    it { should validate_length_of(:action_plan).is_at_most(100) }
    it { should allow_value('https://example.com').for(:related_url) }
    it { should allow_value('http://example.com').for(:related_url) }
    it { should_not allow_value('invalid-url').for(:related_url) }
  end
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:achievements) }
    it { should have_many(:comments) }
    it { should have_many(:likes) }
  end
  describe "#liked_by?" do
    let(:user) { create(:user) }
    let(:post) { create(:post) }

    context "いいねしている場合" do
      before { create(:like, post: post, user: user) }

      it "true を返す" do
        expect(post.liked_by?(user)).to be true
      end
    end

    context "いいねしていない場合" do
      it "false を返す" do
        expect(post.liked_by?(user)).to be false
      end
    end
  end
  describe ".recent" do
    it "新しい順に並ぶ" do
      old_post = create(:post, created_at: 3.days.ago)
      middle_post = create(:post, created_at: 1.day.ago)
      new_post = create(:post, created_at: Time.current)

      expect(Post.recent).to eq([ new_post, middle_post, old_post ])
    end
  end
end
