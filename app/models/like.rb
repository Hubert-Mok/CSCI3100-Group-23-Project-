class Like < ApplicationRecord
  belongs_to :user
  belongs_to :product, counter_cache: true

  validates :user_id, uniqueness: { scope: :product_id, message: "already liked this product" }
end
