class MessagesController < ApplicationController
  before_action :require_login
  before_action :set_conversation
  before_action :authorize_participation!

  def create
    @message = @conversation.messages.build(message_params.merge(user: current_user))

    if @message.save
      @conversation.update!(last_message_at: Time.current)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to conversation_path(@conversation) }
      end
    else
      @messages = @conversation.messages.includes(:user).order(:created_at)

      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { render "conversations/show", status: :unprocessable_entity }
      end
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def authorize_participation!
    return if [@conversation.buyer_id, @conversation.seller_id].include?(current_user.id)

    redirect_to root_path, alert: "You are not authorized to view that conversation."
  end

  def message_params
    params.require(:message).permit(:body)
  end
end

