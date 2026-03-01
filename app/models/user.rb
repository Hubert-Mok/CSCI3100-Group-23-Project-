class User < ApplicationRecord
  has_secure_password

  has_many :products, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_products, through: :likes, source: :product
  has_many :notifications, dependent: :destroy
  has_many :conversations_as_buyer, class_name: "Conversation", foreign_key: :buyer_id, dependent: :nullify
  has_many :conversations_as_seller, class_name: "Conversation", foreign_key: :seller_id, dependent: :nullify
  has_many :messages, dependent: :destroy

  COLLEGES = [
    "Chung Chi College",
    "New Asia College",
    "United College",
    "Shaw College",
    "Morningside College",
    "S.H. Ho College",
    "C.W. Chu College",
    "Wu Yee Sun College",
    "Lee Woo Sing College",
    "Graduate School"
  ].freeze

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :cuhk_id, presence: true, uniqueness: true
  validates :username, presence: true, length: { minimum: 2, maximum: 50 }
  validates :college_affiliation, presence: true, inclusion: { in: COLLEGES }
  validates :password, length: { minimum: 6 }, allow_nil: true

  before_save { self.email = email.downcase }
end
