require 'rails_helper'

RSpec.describe EmailVerificationsController, type: :controller do
  let(:user) do
    User.create!(
      email: "test_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Test User',
      college_affiliation: User::COLLEGES.first
    )
  end

  let(:verified_user) do
    u = User.create!(
      email: "verified_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Verified User',
      college_affiliation: User::COLLEGES.first
    )
    u.verify_email!
    u
  end

  describe 'GET #new' do
    context 'without email parameter' do
      it 'displays the new verification page' do
        get :new
        expect(response).to be_successful
        expect(response).to render_template(:new)
      end

      it 'sets @email to empty string' do
        get :new
        expect(assigns(:email)).to eq('')
      end
    end

    context 'with email parameter' do
      it 'pre-fills the email field' do
        email = 'user@link.cuhk.edu.hk'
        get :new, params: { email: email }
        expect(assigns(:email)).to eq(email)
      end
    end
  end

  describe 'GET #show (verification token click)' do
    context 'with valid token' do
      it 'verifies the email and redirects to sign in' do
        raw_token = user.generate_email_verification_token!
        
        get :show, params: { token: raw_token }

        user.reload
        expect(user.email_verified?).to be true
        expect(response).to redirect_to(sign_in_path)
        expect(flash[:notice]).to include('Email verified')
      end

      it 'clears the token digest after verification' do
        raw_token = user.generate_email_verification_token!
        
        get :show, params: { token: raw_token }

        user.reload
        expect(user.email_verification_token_digest).to be_nil
        expect(user.email_verification_sent_at).to be_nil
      end
    end

    context 'with invalid token format' do
      it 'redirects to sign in with error' do
        get :show, params: { token: 'invalid-token-xyz' }

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to include('invalid')
      end
    end

    context 'with token for non-existent user' do
      it 'redirects to sign in with error' do
        fake_token = SecureRandom.urlsafe_base64(32)
        
        get :show, params: { token: fake_token }

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to include('invalid')
      end
    end

    context 'with already verified email' do
      it 'redirects to sign in' do
        raw_token = verified_user.generate_email_verification_token!
        
        get :show, params: { token: raw_token }

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:notice]).to include('already verified')
      end
    end

    context 'token security' do
      it 'does not verify with wrong token for same user' do
        user.generate_email_verification_token!
        wrong_token = SecureRandom.urlsafe_base64(32)

        get :show, params: { token: wrong_token }

        user.reload
        expect(user.email_verified?).to be false
      end

      it 'uses secure token comparison' do
        raw_token = user.generate_email_verification_token!
        
        # Token should only work as-is, not as modified version
        tampered_token = raw_token.chop + 'X'

        get :show, params: { token: tampered_token }

        user.reload
        expect(user.email_verified?).to be false
      end
    end
  end

  describe 'POST #create (resend verification)' do
    context 'with valid unverified email' do
      it 'sends verification email' do
        allow(UserMailer).to receive_message_chain('email_verification.deliver_later').and_return(true)

        post :create, params: { email: user.email }

        expect(UserMailer).to have_received(:email_verification)
        expect(response).to redirect_to(new_email_verification_path(email: user.email))
        expect(flash[:notice]).to include('sent')
      end

      it 'generates and stores new token' do
        allow(UserMailer).to receive_message_chain('email_verification.deliver_later')

        post :create, params: { email: user.email }

        user.reload
        expect(user.email_verification_token_digest).to be_present
      end

      it 'accepts email in different cases' do
        allow(UserMailer).to receive_message_chain('email_verification.deliver_later')

        post :create, params: { email: user.email.upcase }

        expect(response).to redirect_to(new_email_verification_path(email: user.email.downcase))
        expect(UserMailer).to have_received(:email_verification)
      end
    end

    context 'with already verified email' do
      it 'does not send another email (security)' do
        allow(UserMailer).to receive_message_chain('email_verification.deliver_later')

        post :create, params: { email: verified_user.email }

        expect(UserMailer).not_to have_received(:email_verification)
      end

      it 'shows generic message to avoid account enumeration' do
        post :create, params: { email: verified_user.email }

        expect(flash[:notice]).to include('If that email is registered')
      end
    end

    context 'with non-existent email' do
      it 'does not send email' do
        allow(UserMailer).to receive_message_chain('email_verification.deliver_later')

        post :create, params: { email: 'nonexistent@link.cuhk.edu.hk' }

        expect(UserMailer).not_to have_received(:email_verification)
      end

      it 'shows generic message (security)' do
        post :create, params: { email: 'nonexistent@link.cuhk.edu.hk' }

        expect(flash[:notice]).to include('If that email is registered')
      end
    end

    context 'security - account enumeration prevention' do
      it 'returns same message for verified and non-existent emails' do
        message_for_verified = nil
        message_for_nonexistent = nil

        allow(UserMailer).to receive_message_chain('email_verification.deliver_later')

        post :create, params: { email: verified_user.email }
        message_for_verified = flash[:notice]

        flash.clear

        post :create, params: { email: 'fake@link.cuhk.edu.hk' }
        message_for_nonexistent = flash[:notice]

        expect(message_for_verified).to eq(message_for_nonexistent)
      end
    end
  end

  describe 'token management' do
    it 'generates secure tokens' do
      token1 = user.generate_email_verification_token!
      token2 = user.generate_email_verification_token!

      expect(token1).not_to eq(token2)
      expect(token1.length).to be > 40 # Base64 encoded
    end

    it 'stores token digest, not plain token' do
      raw_token = user.generate_email_verification_token!

      user.reload
      # Token digest should be present but different from raw token
      expect(user.email_verification_token_digest).to be_present
      expect(user.email_verification_token_digest).not_to eq(raw_token)
    end

    it 'tracks token sent time' do
      before_time = Time.current
      raw_token = user.generate_email_verification_token!
      after_time = Time.current

      user.reload
      expect(user.email_verification_sent_at).to be_between(before_time, after_time)
    end
  end

  describe 'integration with verification flow' do
    it 'email cannot be verified twice' do
      raw_token = user.generate_email_verification_token!
      
      # First verification
      get :show, params: { token: raw_token }
      user.reload
      expect(user.email_verified?).to be true
      
      # Try to use same token again
      get :show, params: { token: raw_token }
      user.reload
      
      # Should still be verified (idempotent)
      expect(user.email_verified?).to be true
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
