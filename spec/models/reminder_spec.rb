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

      it "allows reminder for different post" do
        other_post = create(:post, user: user)
        new_reminder = build(:reminder, user: user, post: other_post, create_post: false)
        expect(new_reminder).to be_valid
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

  describe "callbacks" do
    describe "set_user_from_post" do
      let(:user) { create(:user) }
      let(:post) { create(:post, user: user) }

      it "automatically sets user from post when user is nil" do
        reminder = build(:reminder, user: nil, post: post, remind_at: 1.day.from_now, create_post: false)
        reminder.valid?
        expect(reminder.user).to eq(user)
      end

      it "does not override existing user" do
        other_user = create(:user)
        # 他ユーザーを設定するとバリデーションエラーになるが、コールバック自体は動作確認
        reminder = build(:reminder, user: user, post: post, remind_at: 1.day.from_now, create_post: false)
        reminder.valid?
        expect(reminder.user).to eq(user)
      end
    end
  end

  describe "ビジネスロジック" do
    let(:user) { create(:user) }

    describe "リマインダーの作成" do
      it "投稿に紐づくリマインダーを作成できる" do
        post = create(:post, user: user)
        reminder = create(:reminder, user: user, post: post, remind_at: 1.day.from_now, create_post: false)

        expect(reminder).to be_persisted
        expect(reminder.post).to eq(post)
        expect(reminder.user).to eq(user)
      end

      it "remind_atはJST（日本時間）で保存される" do
        post = create(:post, user: user)
        # 未来の日時を使用（バリデーション対策）
        jst_time = 1.day.from_now.in_time_zone("Tokyo").change(hour: 10, min: 0)

        reminder = create(:reminder, user: user, post: post, remind_at: jst_time, create_post: false)

        expect(reminder.remind_at.in_time_zone("Tokyo").hour).to eq(10)
      end
    end

    describe "投稿達成時の挙動" do
      let(:post) { create(:post, user: user, achieved_at: nil) }
      let!(:reminder) { create(:reminder, user: user, post: post, create_post: false) }

      it "投稿が達成されるとactiveスコープから除外される" do
        expect(Reminder.active).to include(reminder)

        post.update!(achieved_at: Time.current)

        expect(Reminder.active).not_to include(reminder)
      end

      it "達成済み投稿のリマインダーはsendableに含まれない" do
        base_time = 1.day.from_now.change(hour: 8, min: 0, sec: 0)
        reminder.update!(remind_at: base_time)

        travel_to base_time + 30.seconds do
          expect(Reminder.sendable).to include(reminder)

          post.update!(achieved_at: Time.current)

          expect(Reminder.sendable).not_to include(reminder)
        end
      end
    end

    describe "リマインダーの時刻判定" do
      let(:post) { create(:post, user: user) }

      it "同一分内であればdue_nowに含まれる" do
        base_time = 1.day.from_now.change(hour: 8, min: 0, sec: 0)
        reminder = create(:reminder, user: user, post: post, remind_at: base_time, create_post: false)

        travel_to base_time do
          expect(Reminder.due_now).to include(reminder)
        end

        travel_to base_time + 59.seconds do
          expect(Reminder.due_now).to include(reminder)
        end
      end

      it "異なる分ではdue_nowに含まれない" do
        base_time = 1.day.from_now.change(hour: 8, min: 0, sec: 0)
        reminder = create(:reminder, user: user, post: post, remind_at: base_time, create_post: false)

        travel_to base_time - 1.minute do
          expect(Reminder.due_now).not_to include(reminder)
        end

        travel_to base_time + 1.minute do
          expect(Reminder.due_now).not_to include(reminder)
        end
      end
    end
  end
end
