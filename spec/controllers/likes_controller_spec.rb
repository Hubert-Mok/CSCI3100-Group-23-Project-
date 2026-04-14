require 'rails_helper'

RSpec.describe LikesController, type: :controller do
  let(:user) do
    User.create!(
      email: "user_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Test User',
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
      username: 'Other User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:product) do
    Product.create!(
      title: 'Test Product',
      description: 'This is a test product with enough description text',
      price: 100.0,
      user: other_user,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available
    )
  end

  before do
    session[:user_id] = user.id
  end

  describe 'POST #create' do
    context 'when like is created successfully' do
      it 'creates a new like' do
        expect {
          post :create, params: { product_id: product.id }
        }.to change(Like, :count).by(1)
      end

      it 'redirects to the product with success notice' do
        post :create, params: { product_id: product.id }
        expect(response).to redirect_to(product)
        expect(flash[:notice]).to eq('Added to your liked items.')
      end

      it 'increments the likes_count on product' do
        expect {
          post :create, params: { product_id: product.id }
          product.reload
        }.to change { product.likes_count }.from(0).to(1)
      end

      it 'associates the like with the current user' do
        post :create, params: { product_id: product.id }
        expect(user.likes.first.product).to eq(product)
      end
    end

    context 'when like creation fails' do
      before do
        # Create existing like
        Like.create!(user: user, product: product)
      end

      it 'does not create duplicate like' do
        expect {
          post :create, params: { product_id: product.id }
        }.not_to change(Like, :count)
      end

      it 'redirects to the product with alert' do
        post :create, params: { product_id: product.id }
        expect(response).to redirect_to(product)
        expect(flash[:alert]).to eq('Could not like this item.')
      end

      it 'does not increment likes_count twice' do
        post :create, params: { product_id: product.id }
        product.reload
        expect(product.likes_count).to eq(1)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when like exists' do
      let!(:like) { Like.create!(user: user, product: product) }

      it 'destroys the like' do
        expect {
          delete :destroy, params: { product_id: product.id }
        }.to change(Like, :count).by(-1)
      end

      it 'redirects to the product with success notice' do
        delete :destroy, params: { product_id: product.id }
        expect(response).to redirect_to(product)
        expect(flash[:notice]).to eq('Removed from your liked items.')
      end

      it 'decrements the likes_count on product' do
        expect {
          delete :destroy, params: { product_id: product.id }
          product.reload
        }.to change { product.likes_count }.from(1).to(0)
      end

      it 'removes the association between user and product' do
        delete :destroy, params: { product_id: product.id }
        expect(user.likes.find_by(product: product)).to be_nil
      end
    end

    context 'when like does not exist' do
      it 'does not change like count' do
        expect {
          delete :destroy, params: { product_id: product.id }
        }.not_to change(Like, :count)
      end

      it 'redirects to the product with alert' do
        delete :destroy, params: { product_id: product.id }
        expect(response).to redirect_to(product)
        expect(flash[:alert]).to eq('Could not unlike this item.')
      end
    end
  end

  describe 'authentication' do
    context 'when user is not logged in' do
      before do
        session[:user_id] = nil
      end

      it 'requires login for create' do
        post :create, params: { product_id: product.id }
        expect(response).to redirect_to(sign_in_path)
      end

      it 'requires login for destroy' do
        delete :destroy, params: { product_id: product.id }
        expect(response).to redirect_to(sign_in_path)
      end
    end
  end
end
