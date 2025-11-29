require 'rails_helper'

RSpec.describe Achievement, type: :model do
  describe "validations" do
    subject { create(:achievement) }

    # タスク型：1投稿につき1ユーザー1回のみ
    it do
      should validate_uniqueness_of(:post_id)
        .scoped_to(:user_id)
        .with_message("既に達成済みです")
    end

    it { should validate_presence_of(:achieved_at) }
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:post) }
  end

  describe "scopes" do
    describe ".today" do
      let(:user) { create(:user) }
      let!(:today_achievement) { create(:achievement, user: user, achieved_at: Date.current) }
      let!(:yesterday_achievement) { create(:achievement, user: user, achieved_at: 1.day.ago) }

      it "今日の達成のみを返す" do
        expect(Achievement.today).to include(today_achievement)
        expect(Achievement.today).not_to include(yesterday_achievement)
      end
    end

    describe ".recent" do
      let(:user) { create(:user) }
      let!(:old_achievement) { create(:achievement, user: user, achieved_at: 3.days.ago) }
      let!(:recent_achievement) { create(:achievement, user: user, achieved_at: 1.day.ago) }

      it "新しい順に並ぶ" do
        expect(Achievement.recent.first).to eq(recent_achievement)
      end
    end
  end
end
