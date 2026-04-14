require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  let(:buyer) do
    User.create!(
      email: "buyer_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Buyer User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:seller) do
    User.create!(
      email: "seller_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Seller User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:other_user) do
    User.create!(
      email: "other_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Other User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:admin) do
    User.create!(
      email: "admin_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Admin User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current,
      admin: true
    )
  end

  let(:product) do
    Product.create!(
      title: 'Used Laptop',
      description: 'Reliable laptop with enough details to pass validation',
      price: 500,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available,
      user: seller
    )
  end

  let(:conversation) do
    Conversation.create!(
      product: product,
      buyer: buyer,
      seller: seller
    )
  end

  before do
    allow_any_instance_of(Product).to receive(:get_ai_fraud_score).and_return({ score: 0.0, is_fraud: false })
    allow(Turbo::StreamsChannel).to receive(:broadcast_prepend_to)
    allow(controller).to receive(:broadcast_notification_badge_to)
  end

  describe 'POST #create' do
    it 'redirects unauthenticated users to sign in' do
      post :create, params: { conversation_id: conversation.id, message: { body: 'hello' } }

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to include('You must be signed in')
    end

    it 'creates message and notification when buyer sends valid message' do
      session[:user_id] = buyer.id

      expect {
        post :create, params: { conversation_id: conversation.id, message: { body: 'Is this still available?' } }
      }.to change(Message, :count).by(1)
        .and change(Notification, :count).by(1)

      created_message = Message.last
      expect(created_message.user).to eq(buyer)
      expect(created_message.conversation).to eq(conversation)
      expect(conversation.reload.last_message_at).to be_present
      expect(response).to redirect_to(conversation_path(conversation))

      notification = Notification.last
      expect(notification.user).to eq(seller)
      expect(notification.product).to eq(product)
      expect(notification.message).to include('New message from Buyer User')
      expect(controller).to have_received(:broadcast_notification_badge_to).with(seller)
    end

    it 'does not create invalid message and renders conversation show' do
      session[:user_id] = buyer.id

      expect {
        post :create, params: { conversation_id: conversation.id, message: { body: '' } }
      }.not_to change(Message, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template('conversations/show')
    end

    it 'blocks non-participants from creating message' do
      session[:user_id] = other_user.id

      post :create, params: { conversation_id: conversation.id, message: { body: 'intrude' } }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('not authorized')
    end
  end

  describe 'DELETE #destroy' do
    let!(:message) do
      Message.create!(conversation: conversation, user: buyer, body: 'hello')
    end

    it 'allows sender to delete from conversation page' do
      session[:user_id] = buyer.id

      expect {
        delete :destroy, params: { conversation_id: conversation.id, id: message.id }
      }.to change(Message, :count).by(-1)

      expect(response).to redirect_to(conversation_path(conversation))
      expect(flash[:notice]).to include('Message deleted')
    end

    it 'blocks non-sender non-admin from deleting' do
      session[:user_id] = seller.id

      expect {
        delete :destroy, params: { conversation_id: conversation.id, id: message.id }
      }.not_to change(Message, :count)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('Not authorized')
    end

    it 'allows admin to delete from top-level route and redirects admin dashboard' do
      session[:user_id] = admin.id

      expect {
        delete :destroy, params: { id: message.id }
      }.to change(Message, :count).by(-1)

      expect(response).to redirect_to(admin_moderation_index_path)
      expect(flash[:notice]).to include('Message deleted successfully')
    end
  end
end
