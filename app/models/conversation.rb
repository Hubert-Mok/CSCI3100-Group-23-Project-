class Conversation < ApplicationRecord
  belongs_to :product
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"

  has_many :messages, dependent: :destroy

  validates :product, :buyer, :seller, presence: true
  validates :buyer_id, comparison: { other_than: :seller_id }
  validates :buyer_id, uniqueness: { scope: :product_id }
end

