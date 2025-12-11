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

    describe ".monthly_calendar_data" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }

      before do
        # 今月の達成
        create(:achievement, user: user, achieved_at: Date.new(2024, 12, 11))
        create(:achievement, user: user, achieved_at: Date.new(2024, 12, 11))
        create(:achievement, user: user, achieved_at: Date.new(2024, 12, 5))

        # 先月の達成（含まれない）
        create(:achievement, user: user, achieved_at: Date.new(2024, 11, 30))

        # 他ユーザーの達成（含まれない）
        create(:achievement, user: other_user, achieved_at: Date.new(2024, 12, 11))
      end

      it "指定月の達成を日付ごとにグループ化する" do
        result = Achievement.monthly_calendar_data(user.id, 2024, 12)

        expect(result[Date.new(2024, 12, 11)]).to eq(2)
        expect(result[Date.new(2024, 12, 5)]).to eq(1)
        expect(result.keys.count).to eq(2)
      end

      it "他の月の達成は含まれない" do
        result = Achievement.monthly_calendar_data(user.id, 2024, 12)

        expect(result.key?(Date.new(2024, 11, 30))).to be false
      end

      it "他ユーザーの達成は含まれない" do
        result = Achievement.monthly_calendar_data(user.id, 2024, 12)

        expect(result.values.sum).to eq(3)
      end
    end

    describe ".current_month_count" do
      include ActiveSupport::Testing::TimeHelpers

      let(:user) { create(:user) }

      around do |example|
        travel_to Date.new(2024, 12, 15) do
          example.run
        end
      end

      before do
        # 今月の達成
        create(:achievement, user: user, achieved_at: Date.new(2024, 12, 11))
        create(:achievement, user: user, achieved_at: Date.new(2024, 12, 5))

        # 先月の達成（含まれない）
        create(:achievement, user: user, achieved_at: Date.new(2024, 11, 30))
      end

      it "今月の達成数を返す" do
        result = Achievement.current_month_count(user.id)

        expect(result).to eq(2)
      end
    end
  end
end
