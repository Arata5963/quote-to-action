# frozen_string_literal: true

class ReminderMailer < ApplicationMailer
  def reminder_notification(reminder)
    @reminder = reminder
    @user = reminder.user
    @post = reminder.post

    mail(
      to: @user.email,
      subject: I18n.t("reminder_mailer.reminder_notification.subject")
    )
  end
end
