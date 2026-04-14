require 'rails_helper'

RSpec.describe StripeWebhooksController, type: :controller do
  let(:seller) do
    User.create!(
      email: "webhook_seller_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Webhook Seller',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:buyer) do
    User.create!(
      email: "webhook_buyer_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Webhook Buyer',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:product) do
    Product.create!(
      title: 'Webhook Product',
      description: 'Product used to test Stripe webhook checkout completion flow.',
      price: 250.0,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available,
      user: seller
    )
  end

  let(:order) do
    Order.create!(
      buyer: buyer,
      product: product,
      amount_cents: 25_000,
      currency: 'hkd',
      status: :pending,
      stripe_checkout_session_id: 'cs_test_session'
    )
  end

  before do
    request.env['HTTP_STRIPE_SIGNATURE'] = 'sig_test'
    allow(request).to receive(:body).and_return(StringIO.new('{"id":"evt_test"}'))
    allow(ENV).to receive(:[]).and_call_original
  end

  describe 'POST #create' do
    it 'returns 500 when webhook secret is missing' do
      allow(ENV).to receive(:[]).with('STRIPE_WEBHOOK_SECRET').and_return(nil)

      post :create

      expect(response).to have_http_status(:internal_server_error)
    end

    it 'returns 400 when stripe signature verification fails' do
      allow(ENV).to receive(:[]).with('STRIPE_WEBHOOK_SECRET').and_return('whsec_test')
      allow(Stripe::Webhook).to receive(:construct_event).and_raise(Stripe::SignatureVerificationError.new('bad sig', 'sig'))

      post :create

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 200 for unhandled event types' do
      allow(ENV).to receive(:[]).with('STRIPE_WEBHOOK_SECRET').and_return('whsec_test')
      event = double(type: 'payment_intent.created', data: double(object: double))
      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)

      post :create

      expect(response).to have_http_status(:ok)
    end

    it 'marks pending order paid and reserves product on checkout completion' do
      allow(ENV).to receive(:[]).with('STRIPE_WEBHOOK_SECRET').and_return('whsec_test')
      session_object = double(id: order.stripe_checkout_session_id, payment_intent: 'pi_test_123')
      event = double(type: 'checkout.session.completed', data: double(object: session_object))
      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      allow_any_instance_of(Product).to receive(:broadcast_replace_to)
      allow(controller).to receive(:notify_seller_payment_received)

      post :create

      order.reload
      product.reload
      expect(response).to have_http_status(:ok)
      expect(order.status).to eq('paid')
      expect(order.stripe_payment_intent_id).to eq('pi_test_123')
      expect(product.status).to eq('reserved')
      expect(controller).to have_received(:notify_seller_payment_received).with(order)
    end

    it 'does not update non-pending order on checkout completion' do
      order.update!(status: :paid)
      allow(ENV).to receive(:[]).with('STRIPE_WEBHOOK_SECRET').and_return('whsec_test')
      session_object = double(id: order.stripe_checkout_session_id, payment_intent: 'pi_test_456')
      event = double(type: 'checkout.session.completed', data: double(object: session_object))
      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      allow(controller).to receive(:notify_seller_payment_received)

      post :create

      order.reload
      expect(response).to have_http_status(:ok)
      expect(order.stripe_payment_intent_id).to be_nil
      expect(controller).not_to have_received(:notify_seller_payment_received)
    end
  end
end
