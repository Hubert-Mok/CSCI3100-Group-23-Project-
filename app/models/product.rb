class Product < ApplicationRecord
  belongs_to :user
  has_one_attached :thumbnail
  has_many :likes, dependent: :destroy
  has_many :likers, through: :likes, source: :user

  CATEGORIES = [
    "Books & Notes",
    "Electronics",
    "Clothing & Accessories",
    "Furniture & Home",
    "Sports & Fitness",
    "Stationery & Supplies",
    "Food & Drinks",
    "Tickets & Vouchers",
    "Services",
    "Others"
  ].freeze

  enum :status, { available: 0, reserved: 1, sold: 2 }
  enum :listing_type, { sale: 0, gift: 1 }

  validates :title, presence: true, length: { maximum: 100 }
  validates :description, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  scope :latest, -> { order(created_at: :desc) }
  scope :active, -> { where.not(status: :sold) }
end
