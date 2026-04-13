class NotificationsController < ApplicationController
  before_action :require_login
  before_action :set_notification, only: %i[update destroy]
  after_action :broadcast_notification_badge, only: %i[destroy clear_all]

  def index
    @notifications = current_user.notifications.recent
  end

  def update
    @notification.update(read: true)
    respond_with_notifications
  end

  def destroy
    @notification.destroy
    respond_with_notifications
  end

  def clear_all
    current_user.notifications.delete_all
    respond_with_notifications
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def respond_with_notifications
    respond_to do |format|
      format.html { redirect_back fallback_location: notifications_path }
      format.turbo_stream
    end
  end

  def broadcast_notification_badge
    broadcast_notification_badge_to(current_user)
  end
end
