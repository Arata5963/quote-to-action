# frozen_string_literal: true

class ReminderCheckJob < ApplicationJob
  queue_as :default

  def perform
    current_time = Time.current

    reminders = Reminder.sendable.includes(:user, :post)
    sent_count = 0

    reminders.find_each do |reminder|
      ReminderMailer.reminder_notification(reminder).deliver_later
      Rails.logger.info "[ReminderCheckJob] Sent reminder to #{reminder.user.email} for post##{reminder.post_id}"
      reminder.destroy!
      sent_count += 1
    end

    Rails.logger.info "[ReminderCheckJob] Processed #{sent_count} reminders at #{current_time.strftime('%Y-%m-%d %H:%M')}"
  end
end
