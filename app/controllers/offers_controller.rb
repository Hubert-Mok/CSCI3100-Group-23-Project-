class OffersController < ApplicationController
  before_action :require_login
  before_action :require_verified_email
  before_action :set_conversation
  before_action :authorize_participation!
  before_action :set_offer, only: %i[accept reject counter]

  def create
    ensure_buyer_action!
    return if performed?
    ensure_product_can_receive_offers!
    return if performed?

    offer =
      @conversation.offers.create!(
        product: @conversation.product,
        buyer: @conversation.buyer,
        seller: @conversation.seller,
        proposed_by: current_user,
        amount: params.require(:offer).fetch(:amount),
        status: :proposed
      )

    @conversation.update!(last_message_at: Time.current)
    @conversation.mark_read_for!(current_user)
    notify_offer_event!(offer, recipient_for_offer(offer), "Offer: New offer HK$#{format('%.2f', offer.amount)} on \"#{@conversation.product.title}\"")

    redirect_to conversation_path(@conversation), notice: "Offer sent."
  rescue ActionController::ParameterMissing
    redirect_to conversation_path(@conversation), alert: "Please provide an offer amount."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to conversation_path(@conversation), alert: e.record.errors.full_messages.to_sentence
  end

  def accept
    ensure_actor_can_respond_to!(@offer)
    return if performed?
    ensure_offer_actionable!(@offer)
    return if performed?

    @offer.update!(status: :accepted)
    @conversation.update!(last_message_at: Time.current)
    @conversation.mark_read_for!(current_user)
    notify_offer_event!(@offer, recipient_for_offer(@offer), "Offer: Your offer of HK$#{format('%.2f', @offer.amount)} was accepted")

    redirect_to conversation_path(@conversation), notice: "Offer accepted."
  end

  def reject
    ensure_actor_can_respond_to!(@offer)
    return if performed?
    ensure_offer_actionable!(@offer)
    return if performed?

    @offer.update!(status: :rejected)
    @conversation.update!(last_message_at: Time.current)
    @conversation.mark_read_for!(current_user)
    notify_offer_event!(@offer, recipient_for_offer(@offer), "Offer: Your offer of HK$#{format('%.2f', @offer.amount)} was rejected")

    redirect_to conversation_path(@conversation), notice: "Offer rejected."
  end

  def counter
    ensure_actor_can_respond_to!(@offer)
    return if performed?
    ensure_offer_actionable!(@offer)
    return if performed?
    ensure_product_can_receive_offers!
    return if performed?

    counter_offer =
      @conversation.offers.create!(
        product: @conversation.product,
        buyer: @conversation.buyer,
        seller: @conversation.seller,
        proposed_by: current_user,
        parent_offer: @offer,
        amount: params.require(:offer).fetch(:amount),
        status: :countered
      )

    @offer.update!(status: :rejected)
    @conversation.update!(last_message_at: Time.current)
    @conversation.mark_read_for!(current_user)
    notify_offer_event!(
      counter_offer,
      recipient_for_offer(counter_offer),
      "Offer: Counter-offer HK$#{format('%.2f', counter_offer.amount)} on \"#{@conversation.product.title}\""
    )

    redirect_to conversation_path(@conversation), notice: "Counter-offer sent."
  rescue ActionController::ParameterMissing
    redirect_to conversation_path(@conversation), alert: "Please provide a counter-offer amount."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to conversation_path(@conversation), alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def authorize_participation!
    return if @conversation.participant?(current_user)

    redirect_to root_path, alert: "You are not authorized to view that conversation."
  end

  def set_offer
    @offer = @conversation.offers.find(params[:id])
  end

  def ensure_offer_actionable!(offer)
    return if offer.proposed? || offer.countered?

    redirect_to conversation_path(@conversation), alert: "This offer can no longer be changed."
  end

  def ensure_actor_can_respond_to!(offer)
    # The actor who created an offer cannot accept/reject/counter their own offer.
    return if offer.proposed_by_id != current_user.id

    redirect_to conversation_path(@conversation), alert: "You cannot respond to your own offer."
  end

  def ensure_buyer_action!
    return if current_user == @conversation.buyer

    redirect_to conversation_path(@conversation), alert: "Only the buyer can send an offer."
  end

  def ensure_product_can_receive_offers!
    return if @conversation.product.available? && @conversation.product.sale?

    redirect_to conversation_path(@conversation), alert: "Offers are only allowed for available sale listings."
  end
end
