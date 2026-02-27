class ConversationsController < ApplicationController
  before_action :require_login
  before_action :set_conversation, only: :show
  before_action :authorize_participation!, only: :show

  def index
    @conversations =
      Conversation
        .includes(:product, :buyer, :seller, :messages)
        .where("buyer_id = :user_id OR seller_id = :user_id", user_id: current_user.id)
        .order(Arel.sql("COALESCE(last_message_at, created_at) DESC"))
  end

  def create
    product = Product.find(params[:product_id])

    if product.user_id == current_user.id
      redirect_to product, alert: "You cannot start a chat with yourself on your own listing."
      return
    end

    conversation =
      Conversation.find_or_create_by!(product: product, buyer: current_user, seller: product.user)

    redirect_to conversation_path(conversation)
  end

  def show
    @messages = @conversation.messages.includes(:user).order(:created_at)
    @message = @conversation.messages.build
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end

  def authorize_participation!
    return if [@conversation.buyer_id, @conversation.seller_id].include?(current_user.id)

    redirect_to root_path, alert: "You are not authorized to view that conversation."
  end
end

