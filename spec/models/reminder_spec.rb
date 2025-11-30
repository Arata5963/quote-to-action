# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reminder, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:post) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:remind_time) }

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
  end

  describe "scopes" do
    let(:user) { create(:user) }

    describe ".at_time" do
      let(:post1) { create(:post, user: user) }
      let(:post2) { create(:post, user: user) }
      let!(:reminder_at_8) { create(:reminder, user: user, post: post1, remind_time: "08:00", create_post: false) }
      let!(:reminder_at_9) { create(:reminder, user: user, post: post2, remind_time: "09:00", create_post: false) }

      it "returns reminders at specified time" do
        time = Time.zone.parse("08:00:30")
        expect(Reminder.at_time(time)).to include(reminder_at_8)
        expect(Reminder.at_time(time)).not_to include(reminder_at_9)
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

    describe ".sendable_at" do
      let(:post1) { create(:post, user: user, achieved_at: nil) }
      let(:post2) { create(:post, :achieved, user: user) }
      let(:post3) { create(:post, user: user, achieved_at: nil) }
      let!(:sendable) { create(:reminder, user: user, post: post1, remind_time: "08:00", create_post: false) }
      let!(:achieved) { create(:reminder, user: user, post: post2, remind_time: "08:00", create_post: false) }
      let!(:different_time) { create(:reminder, user: user, post: post3, remind_time: "09:00", create_post: false) }

      it "returns sendable reminders at specified time" do
        time = Time.zone.parse("08:00:30")
        result = Reminder.sendable_at(time)
        expect(result).to include(sendable)
        expect(result).not_to include(achieved)
        expect(result).not_to include(different_time)
      end
    end
  end
end
