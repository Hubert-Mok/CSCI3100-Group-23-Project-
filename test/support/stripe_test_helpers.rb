# frozen_string_literal: true

# Stubs Stripe API calls and builds signed webhook payloads for integration tests.
# Default STRIPE_* env vars are set in config/environments/test.rb before initializers run.
# Minitest 6 no longer ships minitest/mock; we alias singleton methods and restore in ensure.
module StripeTestHelpers
  FakeCheckoutSession = Struct.new(:id, :url, :payment_status, :payment_intent)
  FakeTransfer = Struct.new(:id)

  def paid_checkout_session(session_id, payment_intent: "pi_test_#{session_id}")
    FakeCheckoutSession.new(session_id, "https://checkout.test/pay", "paid", payment_intent)
  end

  def new_checkout_session(session_id: "cs_test_#{SecureRandom.hex(4)}", url: "https://checkout.test/pay")
    FakeCheckoutSession.new(session_id, url, "unpaid", nil)
  end

  def signed_checkout_completed_webhook(session_id:, payment_intent: "pi_test_1")
    body = {
      id: "evt_test_#{SecureRandom.hex(6)}",
      object: "event",
      type: "checkout.session.completed",
      data: {
        object: {
          id: session_id,
          object: "checkout.session",
          payment_intent: payment_intent
        }
      }
    }
    payload = body.to_json
    timestamp = Time.current
    secret = ENV.fetch("STRIPE_WEBHOOK_SECRET")
    sig = Stripe::Webhook::Signature.compute_signature(timestamp, payload, secret)
    header = Stripe::Webhook::Signature.generate_header(timestamp, sig)
    [ payload, header ]
  end

  def stub_stripe_checkout_session_create(fake_session)
    replace_class_method(Stripe::Checkout::Session, :create, proc { |*_a, **_kw| fake_session }) { yield }
  end

  def stub_stripe_checkout_session_retrieve(fake_session)
    replace_class_method(Stripe::Checkout::Session, :retrieve, proc { |*_a, **_kw| fake_session }) { yield }
  end

  def stub_stripe_transfer_create(fake_transfer = FakeTransfer.new("tr_test_1"))
    replace_class_method(Stripe::Transfer, :create, proc { |*_a, **_kw| fake_transfer }) { yield }
  end

  def stub_stripe_connect_onboarding!(account_id: "acct_test_#{SecureRandom.hex(3)}")
    account = Struct.new(:id).new(account_id)
    link = Struct.new(:url).new("https://connect.stripe.test/onboarding")
    replace_class_method(Stripe::Account, :create, proc { |*_a, **_kw| account }) do
      replace_class_method(Stripe::AccountLink, :create, proc { |*_a, **_kw| link }) do
        yield account
      end
    end
  end

  private

  def replace_class_method(klass, method_name, replacement_proc)
    sc = klass.singleton_class
    backup = :"__stripe_test_backup_#{method_name}_#{SecureRandom.hex(6)}"
    sc.alias_method backup, method_name
    sc.define_method(method_name, &replacement_proc)
    yield
  ensure
    sc.alias_method method_name, backup
    sc.remove_method backup
  end
end
