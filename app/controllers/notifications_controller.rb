# app/controllers/notifications_controller.rb
class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications
                                 .order(created_at: :desc)
                                 .page(params[:page])
                                 .per(20)
    @unread_count = current_user.notifications.unopened_only.count
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.open!

    respond_to do |format|
      format.html { redirect_to @notification.notifiable_path }
      format.turbo_stream
    end
  end

  def mark_all_as_read
    current_user.notifications.unopened_only.update_all(opened_at: Time.current)

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: t("notifications.marked_all_as_read") }
      format.turbo_stream
    end
  end
end
