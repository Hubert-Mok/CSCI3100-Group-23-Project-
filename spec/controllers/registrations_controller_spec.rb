require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  describe 'POST #create' do
    it 'creates a new user with valid data' do
      expect {
        post :create, params: {
          user: {
            email: 'newuser@link.cuhk.edu.hk',
            cuhk_id: '1155123456',
            username: 'newuser',
            college_affiliation: 'Chung Chi College',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(new_email_verification_path(email: 'newuser@link.cuhk.edu.hk'))
      expect(flash[:notice]).to include('Account created!')
    end

    it 'does not create user with invalid data' do
      post :create, params: {
        user: {
          email: 'invalid',
          cuhk_id: '',
          username: '',
          college_affiliation: '',
          password: 'short',
          password_confirmation: 'short'
        }
      }

      expect(response).to render_template(:new)
      expect(controller.instance_variable_get(:@user).errors).to be_present
    end

    it 'does not create user with duplicate email' do
      User.create!(
        email: 'existing@link.cuhk.edu.hk',
        password: 'password123',
        password_confirmation: 'password123',
        cuhk_id: '1155123457',
        username: 'existing',
        college_affiliation: 'Chung Chi College',
        email_verified_at: Time.current
      )

      post :create, params: {
        user: {
          email: 'existing@link.cuhk.edu.hk',
          cuhk_id: '1155123456',
          username: 'newuser',
          college_affiliation: 'Chung Chi College',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }

      expect(response).to render_template(:new)
      expect(controller.instance_variable_get(:@user).errors[:base]).to include('An account with this email already exists')
    end

    it 'does not create user with duplicate CUHK ID' do
      User.create!(
        email: 'existing2@link.cuhk.edu.hk',
        password: 'password123',
        password_confirmation: 'password123',
        cuhk_id: '1155123456',
        username: 'existing2',
        college_affiliation: 'Chung Chi College',
        email_verified_at: Time.current
      )

      post :create, params: {
        user: {
          email: 'newuser@link.cuhk.edu.hk',
          cuhk_id: '1155123456',
          username: 'newuser',
          college_affiliation: 'Chung Chi College',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }

      expect(response).to render_template(:new)
      expect(controller.instance_variable_get(:@user).errors[:base]).to include('An account with this CUHK ID already exists')
    end
  end
end