require 'rails_helper'

RSpec.describe PasswordsController, type: :controller do
  let(:user) do
    User.create!(
      email: "password_user_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Password User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  describe 'GET #edit' do
    it 'redirects guests to sign in' do
      get :edit

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to eq('You must be signed in to access that page.')
    end

    it 'renders edit for logged-in user' do
      session[:user_id] = user.id

      get :edit

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end
  end

  describe 'PATCH #update' do
    before do
      session[:user_id] = user.id
    end

    it 'rejects update when current password is incorrect' do
      patch :update, params: {
        current_password: 'WrongPassword',
        password: 'NewPassword123',
        password_confirmation: 'NewPassword123'
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:edit)
      expect(flash.now[:alert]).to eq('Current password is incorrect.')
    end

    it 'updates password when current password is correct' do
      patch :update, params: {
        current_password: 'Password123',
        password: 'NewPassword123',
        password_confirmation: 'NewPassword123'
      }

      user.reload
      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to eq('Password updated successfully.')
      expect(user.authenticate('NewPassword123')).to be_present
    end

    it 'renders edit with validation errors when new password is invalid' do
      patch :update, params: {
        current_password: 'Password123',
        password: 'short',
        password_confirmation: 'different'
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:edit)
      expect(flash.now[:alert]).to be_present
    end
  end
end
