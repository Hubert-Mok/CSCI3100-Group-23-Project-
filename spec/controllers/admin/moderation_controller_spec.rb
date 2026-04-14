require 'rails_helper'

RSpec.describe Admin::ModerationController, type: :controller do
  before do
    allow_any_instance_of(Product).to receive(:get_ai_fraud_score).and_return({ score: 0.0, is_fraud: false })
  end

  let(:admin_user) do
    User.create!(
      email: "admin_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Admin User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current,
      admin: true
    )
  end

  let(:normal_user) do
    User.create!(
      email: "user_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Normal User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current,
      admin: false
    )
  end

  let(:seller) do
    User.create!(
      email: "seller_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Seller',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  describe 'GET #index' do
    let!(:flagged_product) do
      Product.create!(
        title: 'Flagged iPad',
        description: 'Message me on telegram +85212345678',
        price: 200,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :pending,
        flagged: true,
        user: seller
      )
    end

    let!(:unflagged_product) do
      Product.create!(
        title: 'Clean Product',
        description: 'Clean listing description for valid product content.',
        price: 120,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        flagged: false,
        user: seller
      )
    end

    let!(:conversation) do
      Conversation.create!(product: flagged_product, buyer: normal_user, seller: seller)
    end

    let!(:flagged_message) do
      Message.create!(conversation: conversation, user: normal_user, body: 'whatsapp +85299887766', flagged: true)
    end

    let!(:clean_message) do
      Message.create!(conversation: conversation, user: seller, body: 'See you at campus.', flagged: false)
    end

    it 'allows admin to access moderation queue and loads flagged items only' do
      allow(controller).to receive(:current_user).and_return(admin_user)

      get :index

      expect(response).to have_http_status(:ok)
      expect(assigns(:flagged_products)).to include(flagged_product)
      expect(assigns(:flagged_messages)).to include(flagged_message)
    end

    it 'redirects non-admin users' do
      allow(controller).to receive(:current_user).and_return(normal_user)

      get :index

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied.')
    end

    it 'redirects signed-out users to sign in' do
      allow(controller).to receive(:current_user).and_return(nil)

      get :index

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to eq('You must be signed in to access that page.')
    end
  end

  describe 'PATCH #approve_product' do
    let!(:flagged_product) do
      Product.create!(
        title: 'Pending Laptop',
        description: 'pay outside on telegram now',
        price: 600,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :pending,
        flagged: true,
        user: seller
      )
    end

    it 'unflags and publishes product when admin approves it' do
      allow(controller).to receive(:current_user).and_return(admin_user)

      patch :approve_product, params: { id: flagged_product.id }

      expect(response).to redirect_to(admin_moderation_index_path)
      expect(flash[:notice]).to eq('Product approved and listed!')
      expect(flagged_product.reload.flagged).to be(false)
      expect(flagged_product.status).to eq('available')
    end

    it 'shows an alert when product approval fails' do
      allow(controller).to receive(:current_user).and_return(admin_user)
      allow_any_instance_of(Product).to receive(:update).and_return(false)

      patch :approve_product, params: { id: flagged_product.id }

      expect(response).to redirect_to(admin_moderation_index_path)
      expect(flash[:alert]).to eq('Failed to approve.')
      expect(flagged_product.reload.flagged).to be(true)
      expect(flagged_product.status).to eq('pending')
    end
  end

  describe 'PATCH #approve_message' do
    let!(:product) do
      Product.create!(
        title: 'Test Product',
        description: 'A normal product',
        price: 100,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        user: seller
      )
    end

    let!(:conversation) do
      Conversation.create!(product: product, buyer: normal_user, seller: seller)
    end

    let!(:flagged_message) do
      Message.create!(conversation: conversation, user: normal_user, body: 'contact via whatsapp +85212345678', flagged: true)
    end

    it 'unflags message when admin approves it' do
      allow(controller).to receive(:current_user).and_return(admin_user)

      patch :approve_message, params: { id: flagged_message.id }

      expect(response).to redirect_to(admin_moderation_index_path)
      expect(flash[:notice]).to eq('Message approved!')
      expect(flagged_message.reload.flagged).to be(false)
    end

    it 'shows an alert when message approval fails' do
      allow(controller).to receive(:current_user).and_return(admin_user)
      allow_any_instance_of(Message).to receive(:update).and_return(false)

      patch :approve_message, params: { id: flagged_message.id }

      expect(response).to redirect_to(admin_moderation_index_path)
      expect(flash[:alert]).to eq('Failed to approve message.')
      expect(flagged_message.reload.flagged).to be(true)
    end
  end
end
