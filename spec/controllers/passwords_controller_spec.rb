require 'rails_helper'

RSpec.describe PasswordsController, type: :controller do
  let(:user) do
    User.create!(
      email: "user_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'OldPassword123',
      password_confirmation: 'OldPassword123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Test User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  before do
    session[:user_id] = user.id
  end

  describe 'GET #edit' do
    it 'renders the edit template' do
      get :edit

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit)
    end
  end

  describe 'PATCH #update' do
    context 'with correct current password' do
      it 'updates the password successfully' do
        patch :update, params: {
          current_password: 'OldPassword123',
          password: 'NewPassword123',
          password_confirmation: 'NewPassword123'
        }

        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to eq('Password updated successfully.')
        expect(user.reload.authenticate('NewPassword123')).to be_truthy
      end
    end

    context 'with incorrect current password' do
      it 'shows an error message' do
        patch :update, params: {
          current_password: 'WrongPassword123',
          password: 'NewPassword123',
          password_confirmation: 'NewPassword123'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
        expect(flash.now[:alert]).to eq('Current password is incorrect.')
      end
    end

    context 'with mismatched password confirmation' do
      it 'shows validation error and does not update password' do
        patch :update, params: {
          current_password: 'OldPassword123',
          password: 'NewPassword123',
          password_confirmation: 'DifferentPassword123'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
        expect(flash.now[:alert]).to include("doesn't match")
        expect(user.reload.authenticate('OldPassword123')).to be_truthy
      end
    end
  end
end
