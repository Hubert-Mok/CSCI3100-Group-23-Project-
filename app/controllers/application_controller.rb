class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?, :unread_conversations_count_for

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def redirect_if_authenticated
    redirect_to root_path, notice: "You are already signed in." if logged_in?
  end

  def require_login
    unless logged_in?
      flash[:alert] = "You must be signed in to access that page."
      redirect_to sign_in_path
    end
  end

  def require_verified_email
    return unless logged_in?

    unless current_user.email_verified?
      redirect_to new_email_verification_path(email: current_user.email),
        alert: "Please verify your email address before continuing."
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    flash[:alert] = "The page you were looking for doesn't exist."
    redirect_to root_path
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

  def notify_seller_payment_received(order)
    seller = order.product.user
    notif = Notification.create!(
      user: seller,
      product: order.product,
      message: "A buyer has paid for \"#{order.product.title}\". Payment is held until they confirm receipt."
    )
    Turbo::StreamsChannel.broadcast_prepend_to(
      "notifications:#{seller.id}",
      target: "notifications_list",
      partial: "notifications/notification",
      locals: { notification: notif }
    )
    broadcast_notification_badge_to(seller)
  end

  def notify_seller_release_received(order)
    seller = order.product.user
    notif = Notification.create!(
      user: seller,
      product: order.product,
      message: "The buyer confirmed receipt. You've been paid for \"#{order.product.title}\"."
    )
    Turbo::StreamsChannel.broadcast_prepend_to(
      "notifications:#{seller.id}",
      target: "notifications_list",
      partial: "notifications/notification",
      locals: { notification: notif }
    )
    broadcast_notification_badge_to(seller)
  end

  def recipient_for_offer(offer)
    offer.proposed_by_id == offer.buyer_id ? offer.seller : offer.buyer
  end

  def notify_offer_event!(offer, recipient, message)
    notif = Notification.create!(
      user: recipient,
      product: offer.product,
      message: message
    )

    Turbo::StreamsChannel.broadcast_prepend_to(
      "notifications:#{recipient.id}",
      target: "notifications_list",
      partial: "notifications/notification",
      locals: { notification: notif }
    )
    broadcast_notification_badge_to(recipient)
  end

  def unread_conversations_count_for(user)
    base = Conversation.where(buyer_deleted_at: nil).where(buyer: user)
      .or(Conversation.where(seller_deleted_at: nil).where(seller: user))
    base.count { |conversation| conversation.unread_for?(user) }
  end
end
