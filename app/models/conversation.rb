class Conversation < ApplicationRecord
  belongs_to :product
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"

  has_many :messages, dependent: :destroy
  has_many :offers, dependent: :destroy

  validates :product, :buyer, :seller, presence: true
  validates :buyer_id, comparison: { other_than: :seller_id }
  validates :buyer_id, uniqueness: { scope: :product_id }

  def deleted_for?(user)
    case user.id
    when buyer_id then buyer_deleted_at.present?
    when seller_id then seller_deleted_at.present?
    else false
    end
  end

  def mark_deleted_for!(user)
    now = Time.current
    case user.id
    when buyer_id then update!(buyer_deleted_at: now)
    when seller_id then update!(seller_deleted_at: now)
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def both_deleted?
    buyer_deleted_at.present? && seller_deleted_at.present?
  end

  def participant?(user)
    [ buyer_id, seller_id ].include?(user.id)
  end

  def last_read_at_for(user)
    case user.id
    when buyer_id then buyer_last_read_message_at
    when seller_id then seller_last_read_message_at
    end
  end

  def mark_read_for!(user, at: Time.current)
    case user.id
    when buyer_id then update!(buyer_last_read_message_at: at)
    when seller_id then update!(seller_last_read_message_at: at)
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def unread_for?(user)
    return false unless participant?(user)

    last_seen_at = last_read_at_for(user)
    return false if last_message_at.blank?
    return true if last_seen_at.blank?

    last_message_at > last_seen_at
  end
end
