class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless logged_in?
      flash[:alert] = "You must be signed in to access that page."
      redirect_to sign_in_path
    end
  end

  def broadcast_notification_badge_to(user)
    count = user.notifications.unread.count
    badge_html = if count.zero?
      '<span id="notification_badge" class="notification-badge" style="display: none;">0</span>'
    else
      "<span id=\"notification_badge\" class=\"notification-badge\">#{ERB::Util.html_escape(count)}</span>"
    end
    Turbo::StreamsChannel.broadcast_replace_to(
      "notifications:#{user.id}",
      target: "notification_badge",
      html: badge_html
    )
  end
end
