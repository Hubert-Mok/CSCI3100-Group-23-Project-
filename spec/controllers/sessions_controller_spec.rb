require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  describe 'POST #create' do
    let!(:verified_user) do
      User.create!(
        email: 'user@link.cuhk.edu.hk',
        password: 'password123',
        password_confirmation: 'password123',
        cuhk_id: SecureRandom.hex(4),
        username: 'Verified User',
        college_affiliation: User::COLLEGES.first,
        email_verified_at: Time.current
      )
    end

    let!(:unverified_user) do
      User.create!(
        email: 'unverified@link.cuhk.edu.hk',
        password: 'password123',
        password_confirmation: 'password123',
        cuhk_id: SecureRandom.hex(4),
        username: 'Unverified User',
        college_affiliation: User::COLLEGES.first
      )
    end

    it 'signs in a verified user' do
      post :create, params: { email: verified_user.email, password: 'password123' }

      expect(session[:user_id]).to eq(verified_user.id)
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include('Signed in successfully.')
    end

    it 'does not sign in with wrong password' do
      post :create, params: { email: verified_user.email, password: 'wrong' }

      expect(session[:user_id]).to be_nil
      expect(response).to have_http_status(:unprocessable_entity)
      expect(flash[:alert]).to include('Invalid email or password.')
    end

    it 'redirects unverified user to email verification' do
      post :create, params: { email: unverified_user.email, password: 'password123' }

      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(new_email_verification_path(email: unverified_user.email))
      expect(flash[:alert]).to include('Please verify your email before signing in.')
    end
  end

  describe 'DELETE #destroy' do
    let!(:user) do
      User.create!(
        email: 'user@link.cuhk.edu.hk',
        password: 'password123',
        password_confirmation: 'password123',
        cuhk_id: SecureRandom.hex(4),
        username: 'Test User',
        college_affiliation: User::COLLEGES.first,
        email_verified_at: Time.current
      )
    end

    before do
      session[:user_id] = user.id
    end

    it 'signs out the user' do
      delete :destroy

      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include('Signed out successfully.')
    end
  end
end