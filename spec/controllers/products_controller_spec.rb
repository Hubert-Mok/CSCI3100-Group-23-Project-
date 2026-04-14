require 'rails_helper'

RSpec.describe ProductsController, type: :controller do
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

  describe 'GET #index' do
    let!(:viewer) do
      User.create!(
        email: "viewer_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
        password: 'Password123',
        password_confirmation: 'Password123',
        cuhk_id: SecureRandom.hex(4),
        username: 'Viewer',
        college_affiliation: User::COLLEGES.first,
        email_verified_at: Time.current
      )
    end

    let!(:matching_product) do
      Product.create!(
        title: 'Used Laptop',
        description: 'Reliable laptop with 8GB RAM',
        price: 500,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        user: User.create!(
          email: "seller_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
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

    let!(:flagged_product) do
      Product.create!(
        title: 'Flagged Laptop',
        description: 'This should be hidden from index listing',
        price: 20,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        flagged: true,
        user: matching_product.user
      )
    end

    let!(:viewer_own_product) do
      Product.create!(
        title: 'Viewer Owned Item',
        description: 'Owned by the currently logged-in user',
        price: 30,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        user: viewer
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

    it 'filters out flagged products from results' do
      get :index

      products = controller.instance_variable_get(:@products)
      expect(products).not_to include(flagged_product)
      expect(products).to include(matching_product)
    end

    it 'excludes current user products when logged in' do
      session[:user_id] = viewer.id

      get :index

      products = controller.instance_variable_get(:@products)
      expect(products).not_to include(viewer_own_product)
      expect(products).to include(matching_product)
    end

    it 'filters by category parameter' do
      get :index, params: { category: Product::CATEGORIES.second }

      products = controller.instance_variable_get(:@products)
      expect(products).to include(other_product)
      expect(products).not_to include(matching_product)
      expect(products).not_to include(third_product)
    end

    it 'filters by status parameter' do
      third_product.update!(status: :sold)

      get :index, params: { status: 'sold' }

      products = controller.instance_variable_get(:@products)
      expect(products).to include(third_product)
      expect(products).not_to include(matching_product)
    end

    it 'sorts by price descending when requested' do
      get :index, params: { sort: 'price_desc' }

      products = controller.instance_variable_get(:@products)
      prices = products.map(&:price)
      expect(prices).to eq(prices.sort.reverse)
      expect(products.first).to eq(matching_product)
    end

    it 'assigns liked product ids for logged-in user' do
      session[:user_id] = viewer.id
      Like.create!(user: viewer, product: matching_product)

      get :index

      liked_ids = controller.instance_variable_get(:@liked_ids)
      expect(liked_ids).to include(matching_product.id)
    end

    it 'assigns empty liked ids for guests' do
      get :index

      liked_ids = controller.instance_variable_get(:@liked_ids)
      expect(liked_ids).to eq([])
    end
  end

  describe 'DELETE #destroy' do
    let!(:product) do
      Product.create!(
        title: 'Flagged Laptop',
        description: 'This product is pending moderation',
        price: 20,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :pending,
        flagged: true,
        user: User.create!(
          email: "seller_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
          password: 'Password123',
          password_confirmation: 'Password123',
          cuhk_id: SecureRandom.hex(4),
          username: 'Seller',
          college_affiliation: User::COLLEGES.first,
          email_verified_at: Time.current
        )
      )
    end

    it 'redirects admin back to moderation queue when referer is moderation page' do
      session[:user_id] = admin_user.id
      request.env['HTTP_REFERER'] = admin_moderation_index_path

      expect {
        delete :destroy, params: { id: product.id }
      }.to change(Product, :count).by(-1)

      expect(response).to redirect_to(admin_moderation_index_path)
      expect(flash[:notice]).to eq('Listing removed successfully.')
    end
  end
end
