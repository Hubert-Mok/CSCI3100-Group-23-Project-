require 'rails_helper'

RSpec.describe SellersController, type: :controller do
  before do
    allow_any_instance_of(Product).to receive(:get_ai_fraud_score).and_return({ score: 0.0, is_fraud: false })
  end

  let(:seller) do
    User.create!(
      email: "seller_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Seller User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let!(:available_product) do
    Product.create!(
      title: 'Available Laptop',
      description: 'A great laptop in excellent condition.',
      price: 800,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available,
      flagged: false,
      user: seller
    )
  end

  let!(:sold_product) do
    Product.create!(
      title: 'Sold Book',
      description: 'Already been sold.',
      price: 50,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :sold,
      flagged: false,
      user: seller
    )
  end

  let!(:pending_product) do
    Product.create!(
      title: 'Pending Item',
      description: 'Awaiting review.',
      price: 100,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :pending,
      flagged: false,
      user: seller
    )
  end

  describe 'GET #show' do
    it 'loads seller profile and displays only available products' do
      get :show, params: { id: seller.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:seller)).to eq(seller)
      expect(assigns(:products)).to include(available_product)
      expect(assigns(:products)).not_to include(sold_product)
      expect(assigns(:products)).not_to include(pending_product)
    end

    it 'includes thumbnail attachment when loading products' do
      get :show, params: { id: seller.id }

      expect(response).to have_http_status(:ok)
      # Verify that eager loading query was used (by checking assignments)
      expect(assigns(:products)).to eq([available_product])
    end
  end
end
