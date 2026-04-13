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

    let!(:third_product) do
      Product.create!(
        title: 'Gaming Mouse',
        description: 'Wireless mouse for gaming',
        price: 50,
        category: Product::CATEGORIES.third,
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
      expect(products).not_to include(third_product)
    end

    it 'returns matching products for a fuzzy query' do
      get :index, params: { q: 'Laptpo' }

      products = controller.instance_variable_get(:@products)
      expect(products).to include(matching_product)
      expect(products).not_to include(other_product)
    end

    it 'is case insensitive' do
      get :index, params: { q: 'laptop' }

      products = controller.instance_variable_get(:@products)
      expect(products).to include(matching_product)
    end

    it 'returns partial matches in description' do
      get :index, params: { q: 'RAM' }

      products = controller.instance_variable_get(:@products)
      expect(products).to include(matching_product)
    end

    it 'returns no results for nonexistent query' do
      get :index, params: { q: 'Nonexistent' }

      products = controller.instance_variable_get(:@products)
      expect(products).to be_empty
    end
  end
end
