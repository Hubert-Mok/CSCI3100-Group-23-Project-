# frozen_string_literal: true

class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    if endpoint_secret.blank?
      head :internal_server_error
      return
    end

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      head :bad_request
      return
    end

    case event.type
    when "checkout.session.completed"
      handle_checkout_session_completed(event.data.object)
    end

    head :ok
  end

  private

  def handle_checkout_session_completed(session)
    order = Order.find_by(stripe_checkout_session_id: session.id)
    return unless order&.pending?

    order.update!(
      status: :paid,
      stripe_payment_intent_id: session.payment_intent
    )
    product = order.product
    product.reserved!
    product.broadcast_replace_to(
      product,
      target: "product_status_#{product.id}",
      partial: "products/status_badge",
      locals: { product: product }
    )
    product.broadcast_replace_to(
      product,
      target: "product_buy_now_#{product.id}",
      partial: "products/buy_now_button",
      locals: { product: product }
    )
    notify_seller_payment_received(order)
  end
end
