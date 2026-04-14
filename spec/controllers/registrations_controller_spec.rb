require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  describe 'POST #create' do
    let(:valid_attributes) do
      {
        email: 'testuser@link.cuhk.edu.hk',
        password: 'password123',
        password_confirmation: 'password123',
        cuhk_id: SecureRandom.hex(4),
        username: 'Test User',
        college_affiliation: User::COLLEGES.first
      }
    end

    it 'creates a new user and redirects to email verification' do
      expect {
        post :create, params: { user: valid_attributes }
      }.to change(User, :count).by(1)

      user = User.last
      expect(user.email).to eq(valid_attributes[:email])
      expect(user.email_verified?).to be false
      expect(response).to redirect_to(new_email_verification_path(email: user.email))
      expect(flash[:notice]).to include('Account created! Please check your CUHK email to verify your account before signing in.')
    end

    it 'does not create user with invalid data' do
      invalid_attributes = valid_attributes.merge(email: 'invalid')
      expect {
        post :create, params: { user: invalid_attributes }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'does not create user with duplicate email' do
      User.create!(valid_attributes)

      duplicate_email_attributes = valid_attributes.merge(
        email: valid_attributes[:email],
        cuhk_id: '87654321',
        username: 'different_user'
      )

      expect {
        post :create, params: { user: duplicate_email_attributes }
      }.not_to change(User, :count)

      expect(response).to render_template(:new)
      user = controller.instance_variable_get(:@user)
      expect(user.errors.full_messages.join(', ')).to include('An account with this email already exists')
    end

    it 'does not create user with duplicate CUHK ID' do
      User.create!(valid_attributes)

      duplicate_cuhk_id_attributes = valid_attributes.merge(
        email: 'different@link.cuhk.edu.hk',
        cuhk_id: valid_attributes[:cuhk_id],
        username: 'different_user'
      )

      expect {
        post :create, params: { user: duplicate_cuhk_id_attributes }
      }.not_to change(User, :count)

      expect(response).to render_template(:new)
      user = controller.instance_variable_get(:@user)
      expect(user.errors.full_messages.join(', ')).to include('An account with this CUHK ID already exists')
    end
  end
end