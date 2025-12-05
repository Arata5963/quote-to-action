# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reminder, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:post) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:remind_at) }

    describe "post_id uniqueness" do
      let(:user) { create(:user) }
      let(:post) { create(:post, user: user) }
      let!(:existing_reminder) { create(:reminder, user: user, post: post) }

      it "does not allow duplicate reminder for same user and post" do
        duplicate = build(:reminder, user: user, post: post)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:post_id]).to include("ごとに設定できるリマインダーは1つです")
      end
    end

    describe "post_belongs_to_user validation" do
      let(:owner) { create(:user) }
      let(:other_user) { create(:user) }
      let(:post) { create(:post, user: owner) }

      it "is valid when post belongs to user" do
        reminder = build(:reminder, user: owner, post: post, create_post: false)
        expect(reminder).to be_valid
      end

      it "is invalid when post does not belong to user" do
        reminder = build(:reminder, user: other_user, post: post, create_post: false)
        expect(reminder).not_to be_valid
        expect(reminder.errors[:post]).to include("は自分の投稿のみ設定できます")
      end
    end

    describe "remind_at_must_be_future validation" do
      let(:user) { create(:user) }
      let(:post) { create(:post, user: user) }

      it "is valid when remind_at is in the future" do
        reminder = build(:reminder, user: user, post: post, remind_at: 1.hour.from_now, create_post: false)
        expect(reminder).to be_valid
      end

      it "is invalid when remind_at is in the past on create" do
        reminder = build(:reminder, user: user, post: post, remind_at: 1.hour.ago, create_post: false)
        expect(reminder).not_to be_valid
        expect(reminder.errors[:remind_at]).to include("は現在より未来の日時を指定してください")
      end

      it "allows past remind_at on update" do
        reminder = create(:reminder, user: user, post: post, remind_at: 1.hour.from_now, create_post: false)
        travel_to 2.hours.from_now do
          reminder.remind_at = 1.hour.ago
          expect(reminder).to be_valid
        end
      end
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }

    describe ".due_now" do
      let(:post1) { create(:post, user: user) }
      let(:post2) { create(:post, user: user) }

      it "returns reminders due at the current minute" do
        # 未来の日時を基準にテスト
        base_time = 1.day.from_now.change(hour: 8, min: 0, sec: 0)
        due_reminder = create(:reminder, user: user, post: post1, remind_at: base_time, create_post: false)
        future_reminder = create(:reminder, user: user, post: post2, remind_at: base_time + 1.hour, create_post: false)

        travel_to base_time + 30.seconds do
          expect(Reminder.due_now).to include(due_reminder)
          expect(Reminder.due_now).not_to include(future_reminder)
        end
      end
    end

    describe ".active" do
      let(:active_post) { create(:post, user: user, achieved_at: nil) }
      let(:achieved_post) { create(:post, :achieved, user: user) }
      let!(:active_reminder) { create(:reminder, user: user, post: active_post, create_post: false) }
      let!(:achieved_reminder) { create(:reminder, user: user, post: achieved_post, create_post: false) }

      it "returns only reminders for non-achieved posts" do
        expect(Reminder.active).to include(active_reminder)
        expect(Reminder.active).not_to include(achieved_reminder)
      end
    end

    describe ".sendable" do
      let(:post1) { create(:post, user: user, achieved_at: nil) }
      let(:post2) { create(:post, :achieved, user: user) }
      let(:post3) { create(:post, user: user, achieved_at: nil) }

      it "returns sendable reminders due now" do
        # 未来の日時を基準にテスト
        base_time = 1.day.from_now.change(hour: 8, min: 0, sec: 0)
        sendable = create(:reminder, user: user, post: post1, remind_at: base_time, create_post: false)
        achieved = create(:reminder, user: user, post: post2, remind_at: base_time, create_post: false)
        different_time = create(:reminder, user: user, post: post3, remind_at: base_time + 1.hour, create_post: false)

        travel_to base_time + 30.seconds do
          result = Reminder.sendable
          expect(result).to include(sendable)
          expect(result).not_to include(achieved)
          expect(result).not_to include(different_time)
        end
      end
    end
  end
end
