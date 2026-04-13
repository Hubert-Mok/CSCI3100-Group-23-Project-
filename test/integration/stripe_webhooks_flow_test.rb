# frozen_string_literal: true

require "test_helper"

class StripeWebhooksFlowTest < ActionDispatch::IntegrationTest
  test "rejects invalid signature" do
    payload = { id: "evt_x", type: "checkout.session.completed" }.to_json
    post "/webhooks/stripe",
      params: payload,
      headers: {
        "Content-Type" => "application/json",
        "HTTP_STRIPE_SIGNATURE" => "t=1,v1=deadbeef"
      }
    assert_response :bad_request
  end

  test "checkout.session.completed marks order paid and reserves product" do
    suffix = SecureRandom.hex(3)
    seller = User.create!(
      email: "wh_seller#{suffix}@link.cuhk.edu.hk",
      password: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      password_confirmation: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      cuhk_id: "1133#{suffix}",
      username: "whseller#{suffix}",
      college_affiliation: "Shaw College",
      email_verified_at: Time.current,
      stripe_account_id: "acct_wh_#{suffix}"
    )
    product = seller.products.create!(
      title: "Scientific calculator",
      description: "Approved model for exams, includes cover and quick reference card.",
      price: 40,
      category: "Electronics",
      listing_type: :sale,
      status: :available
    )
    buyer = users(:verified_user)
    session_id = "cs_test_wh_#{SecureRandom.hex(4)}"
    order = Order.create!(
      product: product,
      buyer: buyer,
      amount_cents: 4000,
      currency: "hkd",
      status: :pending,
      stripe_checkout_session_id: session_id
    )

    payload, sig_header = signed_checkout_completed_webhook(session_id: session_id, payment_intent: "pi_wh_1")
    post "/webhooks/stripe",
      params: payload,
      headers: {
        "Content-Type" => "application/json",
        "HTTP_STRIPE_SIGNATURE" => sig_header
      }

    assert_response :ok
    order.reload
    assert order.paid?
    assert_equal "pi_wh_1", order.stripe_payment_intent_id
    assert product.reload.reserved?
  end
end
