# frozen_string_literal: true

class ReminderMailer < ApplicationMailer
  def daily_reminder(reminder)
    @reminder = reminder
    @user = reminder.user
    @post = reminder.post

    mail(
      to: @user.email,
      subject: I18n.t("reminder_mailer.daily_reminder.subject")
    )
  end
end
