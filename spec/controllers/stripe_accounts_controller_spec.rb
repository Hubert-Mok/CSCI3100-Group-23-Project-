require 'rails_helper'

RSpec.describe StripeAccountsController, type: :controller do
  let(:user) do
    User.create!(
      email: "stripe_user_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Stripe User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  describe 'GET #new' do
    it 'redirects guests to sign in' do
      get :new

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to eq('You must be signed in to access that page.')
    end

    it 'redirects when stripe account is already connected' do
      session[:user_id] = user.id
      user.update!(stripe_account_id: 'acct_connected')

      get :new

      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to eq('Your Stripe account is already connected.')
    end

    it 'creates account and redirects to onboarding link when no session account exists' do
      session[:user_id] = user.id
      allow(Stripe::Account).to receive(:create).and_return(double(id: 'acct_new'))
      allow(Stripe::AccountLink).to receive(:create).and_return(double(url: 'https://connect.stripe.test/onboarding'))

      get :new

      expect(Stripe::Account).to have_received(:create).with(type: 'express', country: 'HK', email: user.email)
      expect(session[:stripe_connect_account_id]).to eq('acct_new')
      expect(response).to redirect_to('https://connect.stripe.test/onboarding')
    end

    it 'reuses existing session account id when creating account link' do
      session[:user_id] = user.id
      session[:stripe_connect_account_id] = 'acct_cached'
      allow(Stripe::Account).to receive(:create)
      allow(Stripe::AccountLink).to receive(:create).and_return(double(url: 'https://connect.stripe.test/onboarding'))

      get :new

      expect(Stripe::Account).not_to have_received(:create)
      expect(Stripe::AccountLink).to have_received(:create).with(
        account: 'acct_cached',
        refresh_url: stripe_account_url,
        return_url: callback_stripe_account_url,
        type: 'account_onboarding'
      )
      expect(response).to redirect_to('https://connect.stripe.test/onboarding')
    end
  end

  describe 'GET #callback' do
    before do
      session[:user_id] = user.id
    end

    it 'redirects with alert when onboarding session has expired' do
      get :callback

      expect(response).to redirect_to(profile_path)
      expect(flash[:alert]).to eq('Stripe onboarding session expired. Please try again.')
    end

    it 'stores stripe account id and clears onboarding session' do
      session[:stripe_connect_account_id] = 'acct_from_session'

      get :callback

      user.reload
      expect(user.stripe_account_id).to eq('acct_from_session')
      expect(session[:stripe_connect_account_id]).to be_nil
      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to eq('Stripe account connected successfully. You can now receive payments.')
    end
  end
end
