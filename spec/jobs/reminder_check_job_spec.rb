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
        # 現在時刻を固定してテスト
        travel_to Time.zone.parse("08:00:30") do
          post1 = create(:post, user: user, achieved_at: nil)
          post2 = create(:post, user: user, achieved_at: nil)
          create(:reminder, user: user, post: post1, remind_time: "08:00", create_post: false)
          create(:reminder, user: user, post: post2, remind_time: "08:00", create_post: false)

          expect {
            described_class.perform_now
          }.to have_enqueued_mail(ReminderMailer, :daily_reminder).twice
        end
      end
    end

    context "when there are no sendable reminders" do
      it "does not send any emails" do
        travel_to Time.zone.parse("08:00:30") do
          post = create(:post, user: user, achieved_at: nil)
          create(:reminder, user: user, post: post, remind_time: "23:59", create_post: false)

          expect {
            described_class.perform_now
          }.not_to have_enqueued_mail(ReminderMailer, :daily_reminder)
        end
      end
    end

    context "when post is achieved" do
      it "does not send email for achieved posts" do
        travel_to Time.zone.parse("08:00:30") do
          achieved_post = create(:post, :achieved, user: user)
          create(:reminder, user: user, post: achieved_post, remind_time: "08:00", create_post: false)

          expect {
            described_class.perform_now
          }.not_to have_enqueued_mail(ReminderMailer, :daily_reminder)
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
