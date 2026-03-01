class Product < ApplicationRecord
  belongs_to :user
  has_one_attached :thumbnail
  has_many :likes, dependent: :destroy
  has_many :likers, through: :likes, source: :user
  has_many :conversations, dependent: :destroy
  has_many :notifications, dependent: :destroy

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

  scope :latest,      -> { order(created_at: :desc) }
  scope :active,      -> { where.not(status: :sold) }
  scope :search,      ->(q)   { where("title ILIKE :q OR description ILIKE :q", q: "%#{q}%") if q.present? }
  scope :by_category, ->(cat) { where(category: cat) if cat.present? }
  scope :by_status,   ->(st)  { where(status: st) if st.present? }
  scope :sorted_by,   ->(s) {
    case s
    when "price_asc"  then order(price: :asc)
    when "price_desc" then order(price: :desc)
    when "most_liked" then order(likes_count: :desc)
    else order(created_at: :desc)
    end
  }
end
