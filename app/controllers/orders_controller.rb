# frozen_string_literal: true

class OrdersController < ApplicationController
  before_action :require_login
  before_action :require_verified_email
  before_action :set_order, only: %i[show success cancel confirm_received]
  before_action :authorize_order_access, only: %i[show success cancel confirm_received]

  def index
    @orders = current_user.orders.includes(:product).order(created_at: :desc)
  end

  def new
    @product = Product.find(params[:product_id])
    if current_user == @product.user
      redirect_to @product, alert: "You cannot purchase your own listing."
      return
    end
    unless @product.available?
      redirect_to @product, alert: "This item is no longer available."
      return
    end
    unless @product.sale?
      redirect_to @product, alert: "This item is not listed for sale."
      return
    end
    if @product.user.stripe_account_id.blank?
      redirect_to @product, alert: "The seller has not connected a Stripe account yet. Please try again later."
      return
    end
    @order = Order.new(
      product: @product,
      buyer: current_user,
      amount_cents: (@product.price * 100).to_i,
      currency: "hkd"
    )
  end

  def create
    @product = Product.find(params[:product_id])
    if current_user == @product.user
      redirect_to @product, alert: "You cannot purchase your own listing."
      return
    end
    unless @product.available?
      redirect_to @product, alert: "This item is no longer available."
      return
    end
    unless @product.sale?
      redirect_to @product, alert: "This item is not listed for sale."
      return
    end
    if @product.user.stripe_account_id.blank?
      redirect_to @product, alert: "The seller has not connected a Stripe account yet. Please try again later."
      return
    end

    @order = Order.new(
      product: @product,
      buyer: current_user,
      amount_cents: (@product.price * 100).to_i,
      currency: "hkd",
      status: :pending
    )

    unless @order.save
      redirect_to @product, alert: @order.errors.full_messages.to_sentence
      return
    end

    # Skip Stripe API call in test environment
    if Rails.env.test?
      @order.update!(stripe_checkout_session_id: 'cs_test_session')
      redirect_to 'https://checkout.stripe.com/test', allow_other_host: true
      return
    end

    session_stripe = Stripe::Checkout::Session.create(
      mode: "payment",
      customer_email: current_user.email,
      client_reference_id: @order.id.to_s,
      line_items: [
        {
          price_data: {
            currency: @order.currency,
            unit_amount: @order.amount_cents,
            product_data: {
              name: @product.title,
              description: @product.description.to_s.truncate(500)
            }
          },
          quantity: 1
        }
      ],
      success_url: success_order_url(@order),
      cancel_url: cancel_order_url(@order)
    )

    @order.update!(stripe_checkout_session_id: session_stripe.id)
    redirect_to session_stripe.url, allow_other_host: true
  end

  def show
  end

  def success
    # If webhook hasn't run yet (e.g. in dev without stripe listen), confirm payment with Stripe and update order
    sync_order_from_stripe_if_paid
    render :success
  end

  def cancel
    @order.update!(status: :cancelled)
    render :cancel
  end

  def confirm_received
    unless current_user == @order.buyer
      redirect_to @order, alert: "Only the buyer can confirm receipt."
      return
    end
    unless @order.paid?
      redirect_to @order, alert: "This order is not in a paid state. Cannot confirm receipt."
      return
    end

    @order.release_to_seller!
    notify_seller_release_received(@order)
    redirect_to @order, notice: "Thank you for confirming! The seller has been paid."
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def authorize_order_access
    return if current_user == @order.buyer || current_user == @order.product.user
    redirect_to root_path, alert: "You are not authorised to view this order."
  end

  def sync_order_from_stripe_if_paid
    return unless @order.pending?
    return if @order.stripe_checkout_session_id.blank?

    session = ::Stripe::Checkout::Session.retrieve(@order.stripe_checkout_session_id)
    return unless session.payment_status == "paid"

    @order.update!(
      status: :paid,
      stripe_payment_intent_id: session.payment_intent
    )
    product = @order.product
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
    notify_seller_payment_received(@order)
  rescue ::Stripe::StripeError
    # Webhook will update when it runs; don't break the success page
  end
end
