class Offer < ApplicationRecord
  belongs_to :conversation
  belongs_to :product
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"
  belongs_to :proposed_by, class_name: "User"
  belongs_to :parent_offer, class_name: "Offer", optional: true

  has_many :counter_offers, class_name: "Offer", foreign_key: :parent_offer_id, dependent: :nullify

  enum :status, { proposed: 0, countered: 1, accepted: 2, rejected: 3, expired: 4 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validate :proposer_must_be_conversation_participant
  validate :participants_must_match_conversation
  validate :parent_offer_must_be_same_conversation

  scope :active, -> { where(status: %i[proposed countered]) }
  scope :latest_first, -> { order(created_at: :desc) }

  def terminal?
    accepted? || rejected? || expired?
  end

  private

  def proposer_must_be_conversation_participant
    return if conversation.blank? || proposed_by.blank?
    return if [ buyer_id, seller_id ].include?(proposed_by_id)

    errors.add(:proposed_by, "must be the buyer or seller in this conversation")
  end

  def participants_must_match_conversation
    return if conversation.blank? || buyer.blank? || seller.blank?
    return if conversation.buyer_id == buyer_id && conversation.seller_id == seller_id

    errors.add(:base, "offer participants must match conversation participants")
  end

  def parent_offer_must_be_same_conversation
    return if parent_offer.blank? || conversation.blank?
    return if parent_offer.conversation_id == conversation_id

    errors.add(:parent_offer, "must belong to the same conversation")
  end
end
