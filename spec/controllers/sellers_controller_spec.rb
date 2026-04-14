require 'rails_helper'

RSpec.describe SellersController, type: :controller do
  let(:seller) do
    User.create!(
      email: "seller_profile_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Seller Profile',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  describe 'GET #show' do
    let!(:old_available) do
      Product.create!(
        title: 'Old Available',
        description: 'Old available listing for ordering checks.',
        price: 100.0,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        user: seller,
        created_at: 2.days.ago
      )
    end

    let!(:new_available) do
      Product.create!(
        title: 'New Available',
        description: 'Newest available listing for ordering checks.',
        price: 120.0,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        user: seller,
        created_at: 1.day.ago
      )
    end

    let!(:sold_product) do
      Product.create!(
        title: 'Sold Listing',
        description: 'Sold listing should not be shown on seller public page.',
        price: 80.0,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :sold,
        user: seller
      )
    end

    it 'assigns seller and only available products ordered by newest first' do
      get :show, params: { id: seller.id }

      expect(response).to have_http_status(:success)
      expect(assigns(:seller)).to eq(seller)
      expect(assigns(:products)).to eq([new_available, old_available])
      expect(assigns(:products)).not_to include(sold_product)
    end
  end
end
