class Product < ApplicationRecord
  belongs_to :user
  has_one_attached :thumbnail
  has_many :likes, dependent: :destroy
  has_many :likers, through: :likes, source: :user
  has_many :conversations, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :orders, dependent: :destroy

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

  after_initialize :set_default_status, if: :new_record?

  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :listing_type, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validate :price_matches_listing_type, if: -> { listing_type.present? && price.present? }

  private

  def price_matches_listing_type
    if gift? && price.to_f > 0
      errors.add(:price, "must be 0 for free/gift listings")
    elsif sale? && price.to_f <= 0
      errors.add(:price, "must be greater than 0 for sale listings")
    end
  end

  def set_default_status
    self.status ||= :available
  end

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
