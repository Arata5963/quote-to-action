# frozen_string_literal: true

class ReminderCheckJob < ApplicationJob
  queue_as :default

  def perform
    current_time = Time.current.in_time_zone("Tokyo")

    reminders = Reminder.sendable_at(current_time).includes(:user, :post)

    reminders.find_each do |reminder|
      ReminderMailer.daily_reminder(reminder).deliver_later
      Rails.logger.info "[ReminderCheckJob] Sent reminder to #{reminder.user.email} for post##{reminder.post_id}"
    end

    Rails.logger.info "[ReminderCheckJob] Processed #{reminders.count} reminders at #{current_time.strftime('%H:%M')}"
  end
end
