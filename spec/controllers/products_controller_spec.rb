require 'rails_helper'

RSpec.describe ProductsController, type: :controller do
  describe 'GET #index' do
    let!(:matching_product) do
      Product.create!(
        title: 'Used Laptop',
        description: 'Reliable laptop with 8GB RAM',
        price: 500,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        user: User.create!(
          email: 'seller@link.cuhk.edu.hk',
          password: 'Password123',
          password_confirmation: 'Password123',
          cuhk_id: SecureRandom.hex(4),
          username: 'Seller',
          college_affiliation: User::COLLEGES.first,
          email_verified_at: Time.current
        )
      )
    end

    let!(:other_product) do
      Product.create!(
        title: 'Desk Chair',
        description: 'Comfortable study chair for desks',
        price: 100,
        category: Product::CATEGORIES.second,
        listing_type: 'sale',
        status: :available,
        user: matching_product.user
      )
    end

    it 'returns matching products for an exact query' do
      get :index, params: { q: 'Laptop' }

      products = controller.instance_variable_get(:@products)
      expect(products).to include(matching_product)
      expect(products).not_to include(other_product)
    end

    it 'returns matching products for a fuzzy query' do
      get :index, params: { q: 'Laptpo' }

      products = controller.instance_variable_get(:@products)
      expect(products).to include(matching_product)
      expect(products).not_to include(other_product)
    end
  end
end
