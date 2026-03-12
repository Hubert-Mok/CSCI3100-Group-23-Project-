class Conversation < ApplicationRecord
  belongs_to :product
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"

  has_many :messages, dependent: :destroy

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
end
