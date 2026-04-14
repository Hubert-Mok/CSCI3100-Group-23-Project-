class Product < ApplicationRecord
  include FraudDetectable
  before_save :check_content_safety
  belongs_to :user
  has_one_attached :thumbnail
  has_many :likes, dependent: :destroy
  has_many :likers, through: :likes, source: :user
  has_many :conversations, dependent: :destroy
  has_many :offers, dependent: :destroy
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

  enum :status, { available: 0, reserved: 1, sold: 2 , pending: 3}
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

  def check_content_safety
    return if flagged_changed?(to: false)
    ai_result = get_ai_fraud_score
    if suspicious? || ai_result[:is_fraud]
      # Maybe set the product to "hidden" until approved
      self.flagged = true
      self.status = :pending
      puts "⚠️ Fraud Alert: Suspicious content detected in Product #{id} - \"#{title}\""
      self.fraud_score = ai_result[:score]
    end
  end

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
  scope :search,      ->(q) { perform_search(q) if q.present? }
  scope :by_category, ->(cat) { where(category: cat) if cat.present? }
  scope :by_status,   ->(st)  { where(status: st) if st.present? }
  scope :flagged_for_review, -> { where(flagged: true) }
  scope :sorted_by,   ->(s) {
    case s
    when "price_asc"  then order(price: :asc)
    when "price_desc" then order(price: :desc)
    when "most_liked" then order(likes_count: :desc)
    else order(created_at: :desc)
    end
  }

  def self.perform_search(query)
    exact_matches = where("title ILIKE :q OR description ILIKE :q", q: "%#{query}%")
    return exact_matches if exact_matches.exists?

    fuzzy_matches(query)
  end

  def self.fuzzy_matches(query)
    tokens = normalize_tokens(query)
    return none if tokens.empty?

    where(id: fuzzy_match_ids(tokens, all))
  end

  def self.fuzzy_match_ids(tokens, relation)
    relation.to_a.select { |product| matches_tokens?(product, tokens) }.map(&:id)
  end

  def self.matches_tokens?(product, tokens)
    text_tokens = normalize_tokens([product.title, product.description].join(' '))
    tokens.all? do |token|
      text_tokens.any? do |word|
        levenshtein_distance(token, word) <= fuzzy_threshold_for(token)
      end
    end
  end

  def self.normalize_tokens(text)
    text.to_s.downcase.scan(/\w+/)
  end

  def self.fuzzy_threshold_for(token)
    [2, (token.length * 0.25).ceil].max
  end

  def self.levenshtein_distance(a, b)
    a = a.to_s
    b = b.to_s
    return b.length if a.empty?
    return a.length if b.empty?

    matrix = Array.new(a.length + 1) { |i| [i] + [0] * b.length }
    (1..b.length).each { |j| matrix[0][j] = j }

    (1..a.length).each do |i|
      (1..b.length).each do |j|
        cost = a[i - 1] == b[j - 1] ? 0 : 1
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        ].min
      end
    end

    matrix[a.length][b.length]
  end
end
