# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReminderMailer, type: :mailer do
  describe "#reminder_notification" do
    let(:user) { create(:user, email: "test@example.com", name: "テストユーザー") }
    let(:post_record) { create(:post, user: user, action_plan: "Test action plan", youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ") }
    let(:reminder) { create(:reminder, user: user, post: post_record, remind_at: 1.day.from_now, create_post: false) }
    let(:mail) { described_class.reminder_notification(reminder) }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("reminder_mailer.reminder_notification.subject"))
      expect(mail.to).to eq([ "test@example.com" ])
    end

    it "Fromアドレスが正しい" do
      expect(mail.from).to include(Rails.application.config.action_mailer.default_options&.dig(:from) || "from@example.com")
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

    it "includes CTA button to view post" do
      html_part = mail.html_part.body.decoded
      expect(html_part).to include("cta-button")
      expect(html_part).to include("投稿を確認する")
    end

    it "includes greeting message" do
      html_part = mail.html_part.body.decoded
      expect(html_part).to include("こんにちは")
    end

    it "includes encouragement message" do
      html_part = mail.html_part.body.decoded
      expect(html_part).to include("小さな一歩")
    end

    it "includes footer with copyright" do
      html_part = mail.html_part.body.decoded
      expect(html_part).to include("mitadake?")
    end

    context "異なるアクションプランの場合" do
      let(:another_post) { create(:post, user: user, action_plan: "別のアクションプラン") }
      let(:another_reminder) { create(:reminder, user: user, post: another_post, remind_at: 1.day.from_now, create_post: false) }
      let(:another_mail) { described_class.reminder_notification(another_reminder) }

      it "異なるアクションプランが含まれる" do
        html_part = another_mail.html_part.body.decoded
        expect(html_part).to include("別のアクションプラン")
      end
    end
  end
end
