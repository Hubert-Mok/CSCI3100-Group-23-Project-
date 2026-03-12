class ConversationsController < ApplicationController
  before_action :require_login
  before_action :set_conversation, only: %i[show destroy]
  before_action :authorize_participation!, only: %i[show destroy]

  def index
    base = Conversation.includes(:product, :buyer, :seller, :messages)
    as_buyer = base.where(buyer: current_user, buyer_deleted_at: nil)
    as_seller = base.where(seller: current_user, seller_deleted_at: nil)

    @conversations =
      as_buyer
        .or(as_seller)
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
    if @conversation.deleted_for?(current_user)
      redirect_to conversations_path, alert: "That conversation was deleted."
      return
    end

    @messages = @conversation.messages.includes(:user).order(:created_at)
    @message = @conversation.messages.build
  end

  def destroy
    @conversation.mark_deleted_for!(current_user)
    @conversation.destroy if @conversation.both_deleted?

    redirect_to conversations_path, notice: "Conversation deleted."
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end

  def authorize_participation!
    return if [ @conversation.buyer_id, @conversation.seller_id ].include?(current_user.id)

    redirect_to root_path, alert: "You are not authorized to view that conversation."
  end
end
