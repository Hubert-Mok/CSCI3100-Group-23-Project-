require 'rails_helper'

RSpec.describe ProfilesController, type: :controller do
  let(:user) do
    User.create!(
      email: "user_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'testuser',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:other_user) do
    User.create!(
      email: "other_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'otheruser',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  before do
    session[:user_id] = user.id
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show
      expect(response).to have_http_status(:success)
    end

    it 'renders the show template' do
      get :show
      expect(response).to render_template(:show)
    end

    it 'assigns user products' do
      product = Product.create!(
        title: 'Test Product',
        description: 'Test description',
        price: 100,
        user: user,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available
      )
      get :show
      products = controller.instance_variable_get(:@products)
      expect(products).to include(product)
    end

    it 'assigns liked products' do
      product = Product.create!(
        title: 'Test Product',
        description: 'Test description',
        price: 100,
        user: other_user,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available
      )
      Like.create!(user: user, product: product)
      get :show
      liked_products = controller.instance_variable_get(:@liked_products)
      expect(liked_products).to include(product)
    end
  end

  describe 'GET #edit' do
    it 'returns http success' do
      get :edit
      expect(response).to have_http_status(:success)
    end

    it 'renders the edit template' do
      get :edit
      expect(response).to render_template(:edit)
    end

    it 'assigns current user' do
      get :edit
      assigned_user = controller.instance_variable_get(:@user)
      expect(assigned_user).to eq(user)
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_username) { 'newusernametest' }
      let(:new_email) { "newemail_#{SecureRandom.hex(4)}@link.cuhk.edu.hk" }

      it 'updates the user username' do
        patch :update, params: { user: { username: new_username } }
        user.reload
        expect(user.username).to eq(new_username)
      end

      it 'updates the user email' do
        patch :update, params: { user: { email: new_email } }
        user.reload
        expect(user.email).to eq(new_email)
      end

      it 'redirects to profile path' do
        patch :update, params: { user: { username: new_username } }
        expect(response).to redirect_to(profile_path)
      end

      it 'sets success notice' do
        patch :update, params: { user: { username: new_username } }
        expect(flash[:notice]).to eq("Profile updated successfully.")
      end

      it 'updates college affiliation' do
        new_college = User::COLLEGES.second
        patch :update, params: { user: { college_affiliation: new_college } }
        user.reload
        expect(user.college_affiliation).to eq(new_college)
      end
    end

    context 'with invalid parameters' do
      it 'does not update username with blank value' do
        original_username = user.username
        patch :update, params: { user: { username: '' } }
        user.reload
        expect(user.username).to eq(original_username)
      end

      it 'renders edit template on failure' do
        patch :update, params: { user: { username: '' } }
        expect(response).to render_template(:edit)
      end

      it 'returns unprocessable entity status on failure' do
        patch :update, params: { user: { username: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not update with invalid email' do
        original_email = user.email
        patch :update, params: { user: { email: 'invalid-email' } }
        user.reload
        expect(user.email).to eq(original_email)
      end
    end
  end

  describe 'before_action :require_login' do
    it 'redirects to sign in when not logged in' do
      session.clear
      get :show
      expect(response).to redirect_to(sign_in_path)
    end

    it 'redirects to sign in for edit when not logged in' do
      session.clear
      get :edit
      expect(response).to redirect_to(sign_in_path)
    end

    it 'redirects to sign in for update when not logged in' do
      session.clear
      patch :update, params: { user: { username: 'newname' } }
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
