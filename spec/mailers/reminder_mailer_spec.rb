# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReminderMailer, type: :mailer do
  describe "#daily_reminder" do
    let(:user) { create(:user, email: "test@example.com") }
    let(:post_record) { create(:post, user: user, action_plan: "Test action plan") }
    let(:reminder) { create(:reminder, user: user, post: post_record, remind_time: "08:00", create_post: false) }
    let(:mail) { described_class.daily_reminder(reminder) }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("reminder_mailer.daily_reminder.subject"))
      expect(mail.to).to eq([ "test@example.com" ])
    end

    it "renders the HTML body with post content" do
      html_part = mail.html_part.body.decoded
      expect(html_part).to include("Test action plan")
    end

    it "renders the text body with post content" do
      text_part = mail.text_part.body.decoded
      expect(text_part).to include("Test action plan")
    end

    it "includes post URL in the body" do
      html_part = mail.html_part.body.decoded
      expect(html_part).to include("/posts/#{post_record.id}")
    end
  end
end
