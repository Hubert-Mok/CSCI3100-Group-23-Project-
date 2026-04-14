require 'rails_helper'

RSpec.describe NotificationsController, type: :controller do
  let(:user) do
    User.create!(
      email: 'me@link.cuhk.edu.hk',
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Notification User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:product) do
    Product.create!(
      title: 'Test Product',
      description: 'Test product for notifications',
      price: 100,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available,
      user: user
    )
  end

  let(:other_user) do
    User.create!(
      email: "other_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Other Notification User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:other_product) do
    Product.create!(
      title: 'Other Product',
      description: 'Other product for notification ownership tests',
      price: 99,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available,
      user: other_user
    )
  end

  let!(:first_notification) do
    Notification.create!(user: user, product: product, message: 'First notification', read: false)
  end

  let!(:second_notification) do
    Notification.create!(user: user, product: product, message: 'Second notification', read: false)
  end

  let!(:other_notification) do
    Notification.create!(user: other_user, product: other_product, message: 'Other user notification', read: false)
  end

  before do
    session[:user_id] = user.id
  end

  describe 'GET #index' do
    it 'redirects unauthenticated users to sign in' do
      session[:user_id] = nil

      get :index

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to include('You must be signed in')
    end

    it 'assigns recent notifications for the current user' do
      get :index

      notifications = controller.instance_variable_get(:@notifications)
      expect(notifications).to eq([second_notification, first_notification])
    end

    it 'does not include notifications from other users' do
      get :index

      notifications = controller.instance_variable_get(:@notifications)
      expect(notifications).not_to include(other_notification)
    end
  end

  describe 'PATCH #update' do
    it 'marks the notification as read and redirects' do
      patch :update, params: { id: first_notification.id }

      expect(first_notification.reload.read).to be true
      expect(response).to redirect_to(notifications_path)
    end

    it 'uses redirect_back when referer is present' do
      request.env['HTTP_REFERER'] = '/products'

      patch :update, params: { id: first_notification.id }

      expect(response).to redirect_to('/products')
    end

    it 'returns turbo stream response when requested' do
      patch :update, params: { id: first_notification.id }, format: :turbo_stream

      expect(response).to have_http_status(:no_content)
    end

    it 'does not allow updating another user notification' do
      patch :update, params: { id: other_notification.id }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("doesn't exist")
      expect(other_notification.reload.read).to be(false)
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the notification and broadcasts badge update' do
      expect(controller).to receive(:broadcast_notification_badge_to).with(user)

      delete :destroy, params: { id: first_notification.id }

      expect(Notification.exists?(first_notification.id)).to be false
      expect(response).to redirect_to(notifications_path)
    end

    it 'returns turbo stream response when requested' do
      delete :destroy, params: { id: second_notification.id }, format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end

    it 'does not allow deleting another user notification' do
      expect {
        delete :destroy, params: { id: other_notification.id }
      }.not_to change(Notification, :count)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("doesn't exist")
    end
  end

  describe 'DELETE #clear_all' do
    it 'deletes all notifications and broadcasts badge update' do
      expect(controller).to receive(:broadcast_notification_badge_to).with(user)

      delete :clear_all

      expect(user.notifications.count).to eq(0)
      expect(response).to redirect_to(notifications_path)
    end

    it 'returns turbo stream response when requested' do
      delete :clear_all, format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end

    it 'only clears current user notifications' do
      delete :clear_all

      expect(user.notifications.count).to eq(0)
      expect(other_user.notifications.count).to eq(1)
    end
  end
end