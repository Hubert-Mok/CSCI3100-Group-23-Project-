require 'rails_helper'

RSpec.describe PasswordResetsController, type: :controller do
  let(:verified_user) do
    User.create!(
      email: "verified_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Verified User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:unverified_user) do
    User.create!(
      email: "unverified_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Unverified User',
      college_affiliation: User::COLLEGES.first
    )
  end

  describe 'GET #new' do
    it 'renders successfully' do
      get :new

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    it 'generates reset token and enqueues mail for verified user' do
      mailer = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
      allow(UserMailer).to receive(:password_reset).and_return(mailer)

      post :create, params: { email: verified_user.email }

      verified_user.reload
      expect(verified_user.password_reset_token_digest).to be_present
      expect(verified_user.password_reset_sent_at).to be_present
      expect(UserMailer).to have_received(:password_reset)
        .with(verified_user, kind_of(String))
      expect(response).to redirect_to(new_password_reset_path)
      expect(flash[:notice]).to include("If an account with that email exists")
    end

    it 'does not enqueue mail for unverified user but returns generic response' do
      allow(UserMailer).to receive(:password_reset)

      post :create, params: { email: unverified_user.email }

      unverified_user.reload
      expect(unverified_user.password_reset_token_digest).to be_nil
      expect(UserMailer).not_to have_received(:password_reset)
      expect(response).to redirect_to(new_password_reset_path)
      expect(flash[:notice]).to include("If an account with that email exists")
    end

    it 'does not enqueue mail for non-existent user and still returns generic response' do
      allow(UserMailer).to receive(:password_reset)

      post :create, params: { email: 'nope@link.cuhk.edu.hk' }

      expect(UserMailer).not_to have_received(:password_reset)
      expect(response).to redirect_to(new_password_reset_path)
      expect(flash[:notice]).to include("If an account with that email exists")
    end

    it 'treats input email case-insensitively' do
      mailer = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
      allow(UserMailer).to receive(:password_reset).and_return(mailer)

      post :create, params: { email: verified_user.email.upcase }

      expect(UserMailer).to have_received(:password_reset)
        .with(verified_user, kind_of(String))
    end
  end

  describe 'GET #edit' do
    it 'renders reset form for a valid token' do
      raw_token = verified_user.generate_password_reset_token!

      get :edit, params: { token: raw_token }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
      expect(assigns(:user)).to eq(verified_user)
      expect(assigns(:token)).to eq(raw_token)
    end

    it 'redirects for an invalid token' do
      get :edit, params: { token: 'invalid-token' }

      expect(response).to redirect_to(new_password_reset_path)
      expect(flash[:alert]).to include('invalid or has expired')
    end

    it 'redirects for an expired token' do
      raw_token = verified_user.generate_password_reset_token!
      verified_user.update_columns(password_reset_sent_at: 31.minutes.ago)

      get :edit, params: { token: raw_token }

      expect(response).to redirect_to(new_password_reset_path)
      expect(flash[:alert]).to include('invalid or has expired')
    end
  end

  describe 'PATCH #update' do
    it 'updates password, clears reset token and redirects for valid token/password' do
      raw_token = verified_user.generate_password_reset_token!
      session[:user_id] = verified_user.id

      patch :update, params: {
        token: raw_token,
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }

      verified_user.reload
      expect(verified_user.authenticate('newpassword123')).to be_truthy
      expect(verified_user.password_reset_token_digest).to be_nil
      expect(verified_user.password_reset_sent_at).to be_nil
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(sign_in_path)
      expect(flash[:notice]).to include('Password reset successfully')
    end

    it 'renders edit with errors when password is invalid' do
      raw_token = verified_user.generate_password_reset_token!

      patch :update, params: {
        token: raw_token,
        password: '123',
        password_confirmation: '123'
      }

      verified_user.reload
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:edit)
      expect(flash[:alert]).to be_present
      expect(verified_user.password_reset_token_digest).to be_present
    end

    it 'renders edit with errors when confirmation does not match' do
      raw_token = verified_user.generate_password_reset_token!

      patch :update, params: {
        token: raw_token,
        password: 'newpassword123',
        password_confirmation: 'different'
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:edit)
      expect(flash[:alert]).to be_present
    end

    it 'redirects when token is invalid' do
      patch :update, params: {
        token: 'invalid-token',
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }

      expect(response).to redirect_to(new_password_reset_path)
      expect(flash[:alert]).to include('invalid or has expired')
    end

    it 'redirects when token is expired' do
      raw_token = verified_user.generate_password_reset_token!
      verified_user.update_columns(password_reset_sent_at: 31.minutes.ago)

      patch :update, params: {
        token: raw_token,
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }

      expect(response).to redirect_to(new_password_reset_path)
      expect(flash[:alert]).to include('invalid or has expired')
    end
  end
end
