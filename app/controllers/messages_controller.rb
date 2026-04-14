class MessagesController < ApplicationController
  before_action :require_login
  before_action :set_conversation
  before_action :authorize_participation!

  def create
    @message = @conversation.messages.build(message_params.merge(user: current_user))

    if @message.save
      @conversation.update!(last_message_at: Time.current)

      recipient =
        if @conversation.buyer_id == current_user.id
          @conversation.seller
        else
          @conversation.buyer
        end

      notification = Notification.create!(
        user: recipient,
        product: @conversation.product,
        message: "New message from #{current_user.username} about \"#{@conversation.product.title}\""
      )

      Turbo::StreamsChannel.broadcast_prepend_to(
        "notifications:#{recipient.id}",
        target: "notifications_list",
        partial: "notifications/notification",
        locals: { notification: }
      )

      broadcast_notification_badge_to(recipient)

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

  def destroy
    @message = Message.find(params[:id])
    conversation = @message.conversation
    
    # Allow admin or the sender to delete
    return redirect_to root_path, alert: "Not authorized" unless current_user.admin? || @message.user_id == current_user.id
    
    @message.destroy
    
    # If called from admin dashboard (no conversation_id param), redirect there
    if params[:conversation_id].blank?
      redirect_to admin_moderation_index_path, notice: "Message deleted successfully"
    else
      redirect_to conversation_path(conversation), notice: "Message deleted"
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def authorize_participation!
    return if [ @conversation.buyer_id, @conversation.seller_id ].include?(current_user.id)

    redirect_to root_path, alert: "You are not authorized to view that conversation."
  end

  def message_params
    params.require(:message).permit(:body, attachments: [])
  end
end
