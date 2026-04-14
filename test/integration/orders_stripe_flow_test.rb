# frozen_string_literal: true

require "test_helper"

class OrdersStripeFlowTest < ActionDispatch::IntegrationTest
  def paid_sale_setup
    suffix = SecureRandom.hex(3)
    seller = User.create!(
      email: "ord_seller#{suffix}@link.cuhk.edu.hk",
      password: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      password_confirmation: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      cuhk_id: "1166#{suffix}",
      username: "ordseller#{suffix}",
      college_affiliation: "Shaw College",
      email_verified_at: Time.current,
      stripe_account_id: "acct_test_#{suffix}"
    )
    product = seller.products.create!(
      title: "Graphing calculator",
      description: "TI calculator suitable for exams and engineering courses, batteries included.",
      price: 50,
      category: "Electronics",
      listing_type: :sale,
      status: :available
    )
    buyer = users(:verified_user)
    [ seller, product, buyer ]
  end

  test "cannot buy own listing" do
    seller, product, = paid_sale_setup
    sign_in_as seller
    get new_order_path(product_id: product.id)
    assert_redirected_to product_path(product)
  end

  test "cannot buy gift listing" do
    suffix = SecureRandom.hex(3)
    seller = User.create!(
      email: "gift_s#{suffix}@link.cuhk.edu.hk",
      password: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      password_confirmation: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      cuhk_id: "1144#{suffix}",
      username: "gifts#{suffix}",
      college_affiliation: "Shaw College",
      email_verified_at: Time.current,
      stripe_account_id: "acct_test_g#{suffix}"
    )
    gift = seller.products.create!(
      title: "Free notes",
      description: "Printed lecture notes from last semester, pick up on campus anytime.",
      price: 0,
      category: "Books & Notes",
      listing_type: :gift,
      status: :available
    )
    sign_in_as users(:verified_user)
    get new_order_path(product_id: gift.id)
    assert_redirected_to product_path(gift)
  end

  test "cannot buy when seller has no Stripe account" do
    seller, product, buyer = paid_sale_setup
    seller.update!(stripe_account_id: nil)
    sign_in_as buyer
    get new_order_path(product_id: product.id)
    assert_redirected_to product_path(product)
  end

  test "create order redirects to Stripe checkout URL" do
    _seller, product, buyer = paid_sale_setup
    sign_in_as buyer
    fake = new_checkout_session(session_id: "cs_test_order_#{SecureRandom.hex(4)}")
    stub_stripe_checkout_session_create(fake) do
      assert_difference -> { Order.count }, +1 do
        post orders_path, params: { product_id: product.id }
      end
    end
    order = Order.order(:created_at).last
    assert_equal fake.id, order.stripe_checkout_session_id
    assert_redirected_to fake.url
  end

  test "accepted offer amount is used for checkout" do
    seller, product, buyer = paid_sale_setup
    conversation = Conversation.create!(product: product, buyer: buyer, seller: seller)
    Offer.create!(
      conversation: conversation,
      product: product,
      buyer: buyer,
      seller: seller,
      proposed_by: buyer,
      amount: 42.5,
      status: :accepted
    )

    sign_in_as buyer

    fake = new_checkout_session(session_id: "cs_test_offer_#{SecureRandom.hex(4)}")
    stub_stripe_checkout_session_create(fake) do
      post orders_path, params: { product_id: product.id }
    end
    order = Order.order(:created_at).last
    assert_equal 4250, order.amount_cents
  end

  test "buyer can cancel pending order" do
    _seller, product, buyer = paid_sale_setup
    order = Order.create!(
      product: product,
      buyer: buyer,
      amount_cents: 5000,
      currency: "hkd",
      status: :pending,
      stripe_checkout_session_id: "cs_test_cancel_#{SecureRandom.hex(4)}"
    )
    sign_in_as buyer
    get cancel_order_path(order)
    assert_response :success
    assert order.reload.cancelled?
  end

  test "success page syncs paid order from Stripe when pending" do
    _seller, product, buyer = paid_sale_setup
    session_id = "cs_test_succ_#{SecureRandom.hex(4)}"
    order = Order.create!(
      product: product,
      buyer: buyer,
      amount_cents: 5000,
      currency: "hkd",
      status: :pending,
      stripe_checkout_session_id: session_id
    )
    paid = paid_checkout_session(session_id, payment_intent: "pi_test_succ")
    sign_in_as buyer
    stub_stripe_checkout_session_retrieve(paid) do
      get success_order_path(order)
    end
    assert_response :success
    order.reload
    assert order.paid?
    assert product.reload.reserved?
  end

  test "buyer can confirm receipt when paid" do
    _seller, product, buyer = paid_sale_setup
    order = Order.create!(
      product: product,
      buyer: buyer,
      amount_cents: 5000,
      currency: "hkd",
      status: :paid,
      stripe_checkout_session_id: "cs_test_cr_#{SecureRandom.hex(4)}",
      stripe_payment_intent_id: "pi_test_cr"
    )
    sign_in_as buyer
    stub_stripe_transfer_create do
      post confirm_received_order_path(order)
    end
    assert_redirected_to order_path(order)
    assert order.reload.completed?
    assert product.reload.sold?
  end

  test "stripe connect onboarding redirects to Stripe" do
    user = users(:verified_user)
    user.update!(stripe_account_id: nil)
    sign_in_as user
    stub_stripe_connect_onboarding! do
      get stripe_account_path
    end
    assert_response :redirect
    assert_match %r{connect\.stripe\.test}, @response.redirect_url
  end

  test "stripe connect callback saves account id" do
    user = users(:verified_user)
    user.update!(stripe_account_id: nil)
    sign_in_as user
    stub_stripe_connect_onboarding! do |account|
      get stripe_account_path
      assert_response :redirect
      get callback_stripe_account_path
      assert_redirected_to profile_path
      assert_equal account.id, user.reload.stripe_account_id
    end
  end
end
