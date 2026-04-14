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
      # Check that products are sorted by price descending
      prices = products.map(&:price)
      expect(prices).to eq(prices.sort.reverse)

      # Check that our test products are included and in the correct relative order
      test_products = [matching_product, other_product, third_product, viewer_own_product]
      test_products_in_results = products.select { |p| test_products.include?(p) }

      # The test products should be sorted by price descending among themselves
      expected_order = test_products.sort_by(&:price).reverse
      expect(test_products_in_results).to eq(expected_order)
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

    it 'redirects an owner back to their profile after removing a listing' do
      owner = User.create!(
        email: "owner_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
        password: 'Password123',
        password_confirmation: 'Password123',
        cuhk_id: SecureRandom.hex(4),
        username: 'Owner User',
        college_affiliation: User::COLLEGES.first,
        email_verified_at: Time.current
      )
      owned_product = Product.create!(
        title: 'Desk Lamp',
        description: 'Bright desk lamp for study spaces',
        price: 40,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        user: owner
      )

      session[:user_id] = owner.id

      expect {
        delete :destroy, params: { id: owned_product.id }
      }.to change(Product, :count).by(-1)

      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to eq('Listing removed successfully.')
    end
  end

  describe 'GET #edit' do
    let!(:owner) do
      User.create!(
        email: "edit_owner_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
        password: 'Password123',
        password_confirmation: 'Password123',
        cuhk_id: SecureRandom.hex(4),
        username: 'Edit Owner',
        college_affiliation: User::COLLEGES.first,
        email_verified_at: Time.current
      )
    end

    let!(:product) do
      Product.create!(
        title: 'Textbook Bundle',
        description: 'A bundle of textbooks ready for the next semester',
        price: 180,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        user: owner
      )
    end

    before do
      session[:user_id] = owner.id
    end

    it 'renders the edit form for the owner' do
      get :edit, params: { id: product.id }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end
  end

  describe 'PATCH #update' do
    let!(:owner) do
      User.create!(
        email: "update_owner_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
        password: 'Password123',
        password_confirmation: 'Password123',
        cuhk_id: SecureRandom.hex(4),
        username: 'Update Owner',
        college_affiliation: User::COLLEGES.first,
        email_verified_at: Time.current
      )
    end

    let!(:product) do
      Product.create!(
        title: 'Study Table',
        description: 'A sturdy table suitable for study and work',
        price: 220,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        user: owner
      )
    end

    before do
      session[:user_id] = owner.id
    end

    it 'updates the listing details and shows the Stripe prompt for sale listings' do
      patch :update, params: {
        id: product.id,
        product: {
          title: 'Study Table Pro',
          description: 'Updated description with clearer details for interested buyers.',
          price: 260,
          category: Product::CATEGORIES.second,
          listing_type: 'sale'
        }
      }

      product.reload

      expect(product.title).to eq('Study Table Pro')
      expect(product.price).to eq(260)
      expect(response).to redirect_to(product)
      expect(flash[:notice]).to eq('Listing updated successfully!')
      expect(flash[:alert]).to eq('Connect your Stripe account so buyers can use Buy Now and you can receive payments.')
    end

    it 'renders the edit form again when the update is invalid' do
      patch :update, params: {
        id: product.id,
        product: {
          title: 'OK',
          description: 'Updated description with enough length to be valid.',
          price: 260,
          category: Product::CATEGORIES.second,
          listing_type: 'sale'
        }
      }

      product.reload

      expect(product.title).to eq('Study Table')
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:edit)
    end

    it 'broadcasts notifications when the status changes to sold' do
      fan = User.create!(
        email: "fan_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
        password: 'Password123',
        password_confirmation: 'Password123',
        cuhk_id: SecureRandom.hex(4),
        username: 'Fan User',
        college_affiliation: User::COLLEGES.first,
        email_verified_at: Time.current
      )
      Like.create!(user: fan, product: product)

      allow(controller).to receive(:broadcast_notification_badge_to)
      allow(Turbo::StreamsChannel).to receive(:broadcast_prepend_to)

      expect {
        patch :update, params: {
          id: product.id,
          product: {
            title: 'Study Table Pro',
            description: 'Updated description with clearer details for interested buyers.',
            price: 260,
            category: Product::CATEGORIES.second,
            listing_type: 'sale',
            status: 'sold'
          }
        }
      }.to change(Notification, :count).by(1)

      product.reload

      expect(product.status).to eq('sold')
      expect(controller).to have_received(:broadcast_notification_badge_to).with(fan)
      expect(response).to redirect_to(product)
    end

    it 'does not show a Stripe prompt when a sale listing is updated to pending' do
      patch :update, params: {
        id: product.id,
        product: {
          title: 'Study Table',
          description: 'A sturdy table suitable for study and work',
          price: 220,
          category: Product::CATEGORIES.first,
          listing_type: 'sale',
          status: 'pending'
        }
      }

      product.reload

      expect(product.status).to eq('pending')
      expect(response).to redirect_to(product)
      expect(flash[:notice]).to eq('Listing updated successfully!')
      expect(flash[:alert]).to be_nil
    end

    it 'attaches a thumbnail image when updating a listing' do
      upload = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/test-image.png'),
        'image/png'
      )

      patch :update, params: {
        id: product.id,
        product: {
          title: 'Study Table',
          description: 'A sturdy table suitable for study and work',
          price: 220,
          category: Product::CATEGORIES.first,
          listing_type: 'sale',
          status: 'available',
          thumbnail: upload
        }
      }

      product.reload

      expect(response).to redirect_to(product)
      expect(product.thumbnail).to be_attached
    end

    it 'keeps existing thumbnail when updating without a new upload' do
      initial_upload = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/test-image.png'),
        'image/png'
      )
      product.thumbnail.attach(initial_upload)
      product.reload
      original_blob_id = product.thumbnail.blob_id

      patch :update, params: {
        id: product.id,
        product: {
          title: 'Study Table',
          description: 'A sturdy table suitable for study and work',
          price: 220,
          category: Product::CATEGORIES.first,
          listing_type: 'sale',
          status: 'available'
        }
      }

      product.reload

      expect(response).to redirect_to(product)
      expect(product.thumbnail).to be_attached
      expect(product.thumbnail.blob_id).to eq(original_blob_id)
    end

    it 'replaces existing thumbnail when a new upload is provided' do
      initial_upload = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/test-image.png'),
        'image/png'
      )
      replacement_upload = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/test-image-2.png'),
        'image/png'
      )

      product.thumbnail.attach(initial_upload)
      product.reload
      original_blob_id = product.thumbnail.blob_id

      patch :update, params: {
        id: product.id,
        product: {
          title: 'Study Table',
          description: 'A sturdy table suitable for study and work',
          price: 220,
          category: Product::CATEGORIES.first,
          listing_type: 'sale',
          status: 'available',
          thumbnail: replacement_upload
        }
      }

      product.reload

      expect(response).to redirect_to(product)
      expect(product.thumbnail).to be_attached
      expect(product.thumbnail.blob_id).not_to eq(original_blob_id)
    end

    it 'does not show seller Stripe prompt when an admin updates someone else listing' do
      seller_without_stripe = User.create!(
        email: "seller_no_stripe_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
        password: 'Password123',
        password_confirmation: 'Password123',
        cuhk_id: SecureRandom.hex(4),
        username: 'Seller No Stripe',
        college_affiliation: User::COLLEGES.first,
        email_verified_at: Time.current,
        stripe_account_id: nil
      )
      admin_managed_product = Product.create!(
        title: 'Admin Managed Listing',
        description: 'Listing owned by seller but edited by admin for moderation workflow.',
        price: 220,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        user: seller_without_stripe
      )

      session[:user_id] = admin_user.id

      patch :update, params: {
        id: admin_managed_product.id,
        product: {
          title: 'Admin Managed Listing Updated',
          description: 'Listing owned by seller but edited by admin for moderation workflow.',
          price: 220,
          category: Product::CATEGORIES.first,
          listing_type: 'sale',
          status: 'available'
        }
      }

      admin_managed_product.reload

      expect(response).to redirect_to(admin_managed_product)
      expect(flash[:notice]).to eq('Listing updated successfully!')
      expect(flash[:alert]).to be_nil
    end
  end

  describe 'POST #create' do
    let(:seller) do
      User.create!(
        email: "seller_create_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
        password: 'Password123',
        password_confirmation: 'Password123',
        cuhk_id: SecureRandom.hex(4),
        username: 'Seller Create',
        college_affiliation: User::COLLEGES.first,
        email_verified_at: Time.current
      )
    end

    before do
      session[:user_id] = seller.id
      allow_any_instance_of(Product).to receive(:get_ai_fraud_score).and_return({ score: 0.0, is_fraud: false })
    end

    it 'shows a Stripe prompt when a sale listing is published without a Stripe account' do
      post :create, params: {
        product: {
          title: 'Budget Monitor',
          description: 'A clean monitor with HDMI cable and stand included.',
          price: 120,
          category: Product::CATEGORIES.second,
          listing_type: 'sale'
        }
      }

      created_product = Product.where(user: seller).order(:created_at).last
      expect(response).to redirect_to(created_product)
      expect(flash[:notice]).to eq('Listing published successfully!')
      expect(flash[:alert]).to eq('Connect your Stripe account so buyers can use Buy Now and you can receive payments.')
      expect(created_product.status).to eq('available')
    end

    it 'marks suspicious listings as pending and shows approval warning' do
      allow_any_instance_of(Product).to receive(:get_ai_fraud_score).and_return({ score: 0.2, is_fraud: false })

      post :create, params: {
        product: {
          title: 'suspicious laptop, contact via whatsapp 12345678',
          description: 'Clean description for a normal looking listing.',
          price: 100,
          category: Product::CATEGORIES.second,
          listing_type: 'sale'
        }
      }

      created_product = Product.where(user: seller).order(:created_at).last
      expect(response).to redirect_to(created_product)
      expect(flash[:warning]).to eq('Listing created and pending admin approval.')
      expect(flash[:alert]).to be_nil
      expect(created_product.status).to eq('pending')
      expect(created_product.flagged).to be(true)
    end
  end
end
