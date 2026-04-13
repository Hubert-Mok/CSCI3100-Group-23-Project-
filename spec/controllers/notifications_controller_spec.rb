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

  let!(:first_notification) do
    Notification.create!(user: user, product: product, message: 'First notification', read: false)
  end

  let!(:second_notification) do
    Notification.create!(user: user, product: product, message: 'Second notification', read: false)
  end

  before do
    session[:user_id] = user.id
  end

  describe 'GET #index' do
    it 'assigns recent notifications for the current user' do
      get :index

      notifications = controller.instance_variable_get(:@notifications)
      expect(notifications).to eq([second_notification, first_notification])
    end
  end

  describe 'PATCH #update' do
    it 'marks the notification as read and redirects' do
      patch :update, params: { id: first_notification.id }

      expect(first_notification.reload.read).to be true
      expect(response).to redirect_to(notifications_path)
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the notification and broadcasts badge update' do
      expect(controller).to receive(:broadcast_notification_badge_to).with(user)

      delete :destroy, params: { id: first_notification.id }

      expect(Notification.exists?(first_notification.id)).to be false
      expect(response).to redirect_to(notifications_path)
    end
  end

  describe 'DELETE #clear_all' do
    it 'deletes all notifications and broadcasts badge update' do
      expect(controller).to receive(:broadcast_notification_badge_to).with(user)

      delete :clear_all

      expect(user.notifications.count).to eq(0)
      expect(response).to redirect_to(notifications_path)
    end
  end
end