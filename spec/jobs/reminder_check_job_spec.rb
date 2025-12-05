# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReminderCheckJob, type: :job do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  before do
    # テスト環境でもメールをenqueueするように設定
    ActiveJob::Base.queue_adapter = :test
  end

  describe "#perform" do
    context "when there are sendable reminders" do
      it "sends emails for matching reminders" do
        # 未来の日時を基準にテスト
        base_time = 1.day.from_now.change(hour: 8, min: 0, sec: 0)
        post1 = create(:post, user: user, achieved_at: nil)
        post2 = create(:post, user: user, achieved_at: nil)
        create(:reminder, user: user, post: post1, remind_at: base_time, create_post: false)
        create(:reminder, user: user, post: post2, remind_at: base_time, create_post: false)

        travel_to base_time + 30.seconds do
          expect {
            described_class.perform_now
          }.to change { ActionMailer::Base.deliveries.size }.by(0)
            .and change { enqueued_jobs.count { |j| j[:job] == ActionMailer::MailDeliveryJob } }.by(2)
        end
      end

      it "deletes reminders after sending" do
        # 未来の日時を基準にテスト
        base_time = 1.day.from_now.change(hour: 8, min: 0, sec: 0)
        post1 = create(:post, user: user, achieved_at: nil)
        create(:reminder, user: user, post: post1, remind_at: base_time, create_post: false)

        travel_to base_time + 30.seconds do
          expect {
            described_class.perform_now
          }.to change(Reminder, :count).by(-1)
        end
      end
    end

    context "when there are no sendable reminders" do
      it "does not send any emails" do
        # 未来の日時を基準にテスト
        base_time = 1.day.from_now.change(hour: 8, min: 0, sec: 0)
        post = create(:post, user: user, achieved_at: nil)
        create(:reminder, user: user, post: post, remind_at: base_time + 16.hours, create_post: false)

        travel_to base_time + 30.seconds do
          expect {
            described_class.perform_now
          }.not_to have_enqueued_mail(ReminderMailer, :reminder_notification)
        end
      end
    end

    context "when post is achieved" do
      it "does not send email for achieved posts" do
        # 未来の日時を基準にテスト
        base_time = 1.day.from_now.change(hour: 8, min: 0, sec: 0)
        achieved_post = create(:post, :achieved, user: user)
        create(:reminder, user: user, post: achieved_post, remind_at: base_time, create_post: false)

        travel_to base_time + 30.seconds do
          expect {
            described_class.perform_now
          }.not_to have_enqueued_mail(ReminderMailer, :reminder_notification)
        end
      end
    end
  end

  describe "queue" do
    it "is enqueued in the default queue" do
      expect {
        described_class.perform_later
      }.to have_enqueued_job(described_class).on_queue("default")
    end
  end
end
