class NotificationsController < ApplicationController
  before_action :require_login
  before_action :set_notification, only: :update

  def index
    @notifications = current_user.notifications.recent
  end

  def update
    @notification.update(read: true)

    respond_to do |format|
      format.html { redirect_back fallback_location: notifications_path }
      format.turbo_stream
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end

