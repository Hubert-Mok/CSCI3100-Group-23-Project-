require 'rails_helper'

RSpec.describe ConversationsController, type: :controller do
  let(:user) do
    User.create!(
      email: 'user@link.cuhk.edu.hk',
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Test User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:other_user) do
    User.create!(
      email: 'other@link.cuhk.edu.hk',
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Other User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:product) do
    Product.create!(
      title: 'Test Product',
      description: 'Test Description',
      price: 100.0,
      user: other_user,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available
    )
  end

  before do
    session[:user_id] = user.id
  end

  describe 'authentication' do
    context 'when user is not logged in' do
      before do
        session[:user_id] = nil
      end

      it 'redirects to sign in for index' do
        get :index
        expect(response).to redirect_to(sign_in_path)
      end

      it 'redirects to sign in for create' do
        post :create, params: { product_id: product.id }
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when user email is not verified' do
      let(:unverified_user) do
        User.create!(
          email: 'unverified@link.cuhk.edu.hk',
          password: 'password123',
          password_confirmation: 'password123',
          cuhk_id: SecureRandom.hex(4),
          username: 'Unverified User',
          college_affiliation: User::COLLEGES.first
        )
      end

      before do
        session[:user_id] = unverified_user.id
      end

      it 'redirects to email verification for index' do
        get :index
        expect(response).to redirect_to(new_email_verification_path(email: unverified_user.email))
      end

      it 'redirects to email verification for create' do
        post :create, params: { product_id: product.id }
        expect(response).to redirect_to(new_email_verification_path(email: unverified_user.email))
      end
    end
  end

  describe 'GET #index' do
    let!(:conversation) do
      Conversation.create!(
        product: product,
        buyer: user,
        seller: other_user
      )
    end

    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns conversations' do
      get :index
      expect(assigns(:conversations)).to include(conversation)
    end

    it 'includes conversations where user is buyer' do
      get :index
      expect(assigns(:conversations)).to include(conversation)
    end

    it 'includes conversations where user is seller' do
      seller_conversation = Conversation.create!(
        product: Product.create!(
          title: 'Seller Product',
          description: 'Test description that is long enough',
          price: 50.0,
          user: user,
          category: Product::CATEGORIES.first,
          listing_type: 'sale',
          status: :available
        ),
        buyer: other_user,
        seller: user
      )
      get :index
      expect(assigns(:conversations)).to include(seller_conversation)
    end

    it 'excludes deleted conversations' do
      conversation.update(buyer_deleted_at: Time.current)
      get :index
      expect(assigns(:conversations)).not_to include(conversation)
    end
  end

  describe 'POST #create' do
    context 'with valid product' do
      it 'creates a new conversation' do
        expect {
          post :create, params: { product_id: product.id }
        }.to change(Conversation, :count).by(1)
      end

      it 'redirects to the conversation' do
        post :create, params: { product_id: product.id }
        expect(response).to redirect_to(conversation_path(Conversation.last))
      end

      it 'finds existing conversation' do
        existing_conversation = Conversation.create!(
          product: product,
          buyer: user,
          seller: other_user
        )
        expect {
          post :create, params: { product_id: product.id }
        }.not_to change(Conversation, :count)
        expect(response).to redirect_to(conversation_path(existing_conversation))
      end
    end

    context 'when user tries to chat with themselves' do
      let(:own_product) do
        Product.create!(
          title: 'Own Product',
          description: 'Test description that is long enough',
          price: 50.0,
          user: user,
          category: Product::CATEGORIES.first,
          listing_type: 'sale',
          status: :available
        )
      end

      it 'redirects with alert' do
        post :create, params: { product_id: own_product.id }
        expect(response).to redirect_to(own_product)
        expect(flash[:alert]).to eq("You cannot start a chat with yourself on your own listing.")
      end
    end
  end

  describe 'GET #show' do
    let(:conversation) do
      Conversation.create!(
        product: product,
        buyer: user,
        seller: other_user
      )
    end

    it 'returns http success' do
      get :show, params: { id: conversation.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns conversation and messages' do
      message = Message.create!(
        conversation: conversation,
        user: user,
        body: 'Test message'
      )
      get :show, params: { id: conversation.id }
      expect(assigns(:conversation)).to eq(conversation)
      expect(assigns(:messages)).to include(message)
      expect(assigns(:message)).to be_a_new(Message)
    end

    context 'when conversation is deleted for user' do
      it 'redirects with alert' do
        conversation.update(buyer_deleted_at: Time.current)
        get :show, params: { id: conversation.id }
        expect(response).to redirect_to(conversations_path)
        expect(flash[:alert]).to eq("That conversation was deleted.")
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) do
        User.create!(
          email: 'unauth@link.cuhk.edu.hk',
          password: 'password123',
          password_confirmation: 'password123',
          cuhk_id: SecureRandom.hex(4),
          username: 'Unauthorized User',
          college_affiliation: User::COLLEGES.first,
          email_verified_at: Time.current
        )
      end

      before do
        session[:user_id] = unauthorized_user.id
      end

      it 'redirects to root path' do
        get :show, params: { id: conversation.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to view that conversation.")
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:conversation) do
      Conversation.create!(
        product: product,
        buyer: user,
        seller: other_user
      )
    end

    it 'marks conversation as deleted for user' do
      delete :destroy, params: { id: conversation.id }
      conversation.reload
      expect(conversation.buyer_deleted_at).to be_present
    end

    it 'redirects to conversations path' do
      delete :destroy, params: { id: conversation.id }
      expect(response).to redirect_to(conversations_path)
      expect(flash[:notice]).to eq("Conversation deleted.")
    end

    context 'when both users have deleted the conversation' do
      it 'destroys the conversation' do
        conversation.update(seller_deleted_at: Time.current)
        expect {
          delete :destroy, params: { id: conversation.id }
        }.to change(Conversation, :count).by(-1)
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) do
        User.create!(
          email: 'unauth2@link.cuhk.edu.hk',
          password: 'password123',
          password_confirmation: 'password123',
          cuhk_id: SecureRandom.hex(4),
          username: 'Unauthorized User 2',
          college_affiliation: User::COLLEGES.first,
          email_verified_at: Time.current
        )
      end

      before do
        session[:user_id] = unauthorized_user.id
      end

      it 'redirects to root path' do
        delete :destroy, params: { id: conversation.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to view that conversation.")
      end
    end
  end
end