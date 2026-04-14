require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  let(:buyer) do
    User.create!(
      email: 'buyer@link.cuhk.edu.hk',
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Buyer',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end
  let(:seller) do
    User.create!(
      email: 'seller@link.cuhk.edu.hk',
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Seller',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current,
      stripe_account_id: 'acct_test'
    )
  end
  let(:product) do
    Product.create!(
      user: seller,
      title: 'Test Product',
      description: 'Test description',
      price: 500,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available
    )
  end

  before do
    session[:user_id] = buyer.id
  end

  describe 'GET #index' do
    let!(:order) do
      Order.create!(
        buyer: buyer,
        product: product,
        amount_cents: 50000,
        currency: 'hkd'
      )
    end

    it 'assigns user orders to @orders' do
      get :index
      expect(assigns(:orders)).to include(order)
    end

    it 'orders by created_at desc' do
      older_order = Order.create!(
        buyer: buyer,
        product: product,
        amount_cents: 50000,
        currency: 'hkd',
        created_at: 1.day.ago
      )
      get :index
      expect(assigns(:orders).first).to eq(order)
      expect(assigns(:orders).second).to eq(older_order)
    end
  end

  describe 'GET #new' do
    context 'when product is available for purchase' do
      it 'assigns the product' do
        get :new, params: { product_id: product.id }
        expect(assigns(:product)).to eq(product)
      end

      it 'creates a new order' do
        get :new, params: { product_id: product.id }
        expect(assigns(:order)).to be_a_new(Order)
        expect(assigns(:order).product).to eq(product)
        expect(assigns(:order).buyer).to eq(buyer)
      end
    end

    context 'when user tries to buy own product' do
      before { session[:user_id] = seller.id }

      it 'redirects with alert' do
        get :new, params: { product_id: product.id }
        expect(response).to redirect_to(product)
        expect(flash[:alert]).to include("You cannot purchase your own listing")
      end
    end

    context 'when product is not available' do
      before { product.update!(status: :sold) }

      it 'redirects with alert' do
        get :new, params: { product_id: product.id }
        expect(response).to redirect_to(product)
        expect(flash[:alert]).to include("This item is no longer available")
      end
    end

    context 'when product is not for sale' do
      before { product.update!(listing_type: :gift, price: 0) }

      it 'redirects with alert' do
        get :new, params: { product_id: product.id }
        expect(response).to redirect_to(product)
        expect(flash[:alert]).to include("This item is not listed for sale")
      end
    end

    context 'when seller has no stripe account' do
      before { seller.update!(stripe_account_id: nil) }

      it 'redirects with alert' do
        get :new, params: { product_id: product.id }
        expect(response).to redirect_to(product)
        expect(flash[:alert]).to include("The seller has not connected a Stripe account yet")
      end
    end
  end

  describe 'POST #create' do
    let(:stripe_session) { double(id: 'cs_test', url: 'https://checkout.stripe.com/test') }

    before do
      allow(Stripe::Checkout::Session).to receive(:create).and_return(stripe_session)
    end

    context 'when order is valid' do
      it 'creates the order' do
        expect {
          post :create, params: { product_id: product.id }
        }.to change(Order, :count).by(1)
      end

      it 'creates stripe checkout session' do
        allow(Stripe::Checkout::Session).to receive(:create).and_return(double(id: 'cs_test_session', url: 'https://checkout.stripe.com/test'))
        
        post :create, params: { product_id: product.id }
        
        order = Order.last
        expect(Stripe::Checkout::Session).to have_received(:create).with(
          mode: "payment",
          customer_email: buyer.email,
          client_reference_id: order.id.to_s,
          line_items: [{
            price_data: {
              currency: "hkd",
              unit_amount: 50000, # 500 * 100
              product_data: {
                name: product.title,
                description: product.description.truncate(500)
              }
            },
            quantity: 1
          }],
          success_url: success_order_url(order),
          cancel_url: cancel_order_url(order)
        )
      end

      it 'redirects to stripe checkout url' do
        post :create, params: { product_id: product.id }
        expect(response).to redirect_to('https://checkout.stripe.com/test')
      end
    end

    context 'when user tries to buy own product' do
      before { session[:user_id] = seller.id }

      it 'does not create order' do
        expect {
          post :create, params: { product_id: product.id }
        }.not_to change(Order, :count)
      end

      it 'redirects with alert' do
        post :create, params: { product_id: product.id }
        expect(response).to redirect_to(product)
        expect(flash[:alert]).to include("You cannot purchase your own listing")
      end
    end
  end

  describe 'GET #show' do
    let(:order) do
      Order.create!(
        buyer: buyer,
        product: product,
        amount_cents: 50000,
        currency: 'hkd'
      )
    end

    it 'assigns the order' do
      get :show, params: { id: order.id }
      expect(assigns(:order)).to eq(order)
    end
  end

  describe 'GET #success' do
    let(:order) do
      Order.create!(
        buyer: buyer,
        product: product,
        amount_cents: 50000,
        currency: 'hkd',
        status: :pending,
        stripe_checkout_session_id: 'cs_test_session'
      )
    end
    let(:stripe_session) { double(payment_status: 'paid', payment_intent: 'pi_test') }

    before do
      allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(stripe_session)
    end

    it 'syncs order from stripe if paid' do
      get :success, params: { id: order.id }
      order.reload
      expect(order.status).to eq('paid')
      expect(order.stripe_payment_intent_id).to eq('pi_test')
    end

    it 'renders success template' do
      get :success, params: { id: order.id }
      expect(response).to render_template(:success)
    end
  end

  describe 'GET #cancel' do
    let(:order) do
      Order.create!(
        buyer: buyer,
        product: product,
        amount_cents: 50000,
        currency: 'hkd',
        status: :pending
      )
    end

    it 'cancels the order' do
      get :cancel, params: { id: order.id }
      order.reload
      expect(order.status).to eq('cancelled')
    end

    it 'renders cancel template' do
      get :cancel, params: { id: order.id }
      expect(response).to render_template(:cancel)
    end
  end

  describe 'PATCH #confirm_received' do
    let(:order) do
      Order.create!(
        buyer: buyer,
        product: product,
        amount_cents: 50000,
        currency: 'hkd',
        status: :paid
      )
    end

    before do
      allow(Stripe::Transfer).to receive(:create).and_return(double(id: 'tr_test'))
    end

    it 'releases payment to seller' do
      expect_any_instance_of(Order).to receive(:release_to_seller!)
      patch :confirm_received, params: { id: order.id }
    end

    it 'redirects with success message' do
      patch :confirm_received, params: { id: order.id }
      expect(response).to redirect_to(order)
      expect(flash[:notice]).to include("Thank you for confirming! The seller has been paid")
    end

    context 'when user is not the buyer' do
      before { session[:user_id] = seller.id }

      it 'redirects with alert' do
        patch :confirm_received, params: { id: order.id }
        expect(response).to redirect_to(order)
        expect(flash[:alert]).to include("Only the buyer can confirm receipt")
      end
    end

    context 'when order is not paid' do
      before { order.update!(status: :pending) }

      it 'redirects with alert' do
        patch :confirm_received, params: { id: order.id }
        expect(response).to redirect_to(order)
        expect(flash[:alert]).to include("This order is not in a paid state")
      end
    end
  end
end