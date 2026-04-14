class User < ApplicationRecord
  has_secure_password

  has_many :products, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_products, through: :likes, source: :product
  has_many :notifications, dependent: :destroy
  has_many :conversations_as_buyer, class_name: "Conversation", foreign_key: :buyer_id, dependent: :nullify
  has_many :conversations_as_seller, class_name: "Conversation", foreign_key: :seller_id, dependent: :nullify
  has_many :messages, dependent: :destroy
  has_many :orders, foreign_key: :buyer_id, dependent: :destroy
  has_many :offers_as_buyer, class_name: "Offer", foreign_key: :buyer_id, dependent: :nullify
  has_many :offers_as_seller, class_name: "Offer", foreign_key: :seller_id, dependent: :nullify
  has_many :proposed_offers, class_name: "Offer", foreign_key: :proposed_by_id, dependent: :nullify

  has_one_attached :avatar

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

  ALLOWED_EMAIL_DOMAINS = %w[link.cuhk.edu.hk cuhk.edu.hk].freeze
  EMAIL_VERIFICATION_EXPIRY = 1.hour
  PASSWORD_RESET_EXPIRY = 30.minutes
  THEME_PREFERENCES = %w[light dark].freeze

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validate :email_must_be_school_domain
  validate :email_uniqueness
  validates :cuhk_id, presence: true
  validate :cuhk_id_uniqueness
  validates :username, presence: true, length: { minimum: 2, maximum: 50 }
  validates :college_affiliation, presence: true, inclusion: { in: COLLEGES }
  validates :theme_preference, inclusion: { in: THEME_PREFERENCES }
  validates :password, length: { minimum: 6 }, allow_nil: true

  before_save { self.email = email.downcase }

  def email_verified?
    email_verified_at.present?
  end

  # Generates a raw token, stores its digest, returns the raw token to send.
  def generate_email_verification_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    update_columns(
      email_verification_token_digest: digest_token(raw_token),
      email_verification_sent_at: Time.current
    )
    raw_token
  end

  def email_verification_token_valid?(raw_token)
    return false unless email_verification_token_digest.present? && email_verification_sent_at.present?
    return false if Time.current > email_verification_sent_at + EMAIL_VERIFICATION_EXPIRY

    ActiveSupport::SecurityUtils.secure_compare(
      email_verification_token_digest,
      digest_token(raw_token)
    )
  end

  def verify_email!
    update_columns(
      email_verified_at: Time.current,
      email_verification_token_digest: nil,
      email_verification_sent_at: nil
    )
  end

  def generate_password_reset_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    update_columns(
      password_reset_token_digest: digest_token(raw_token),
      password_reset_sent_at: Time.current
    )
    raw_token
  end

  def password_reset_token_valid?(raw_token)
    return false unless password_reset_token_digest.present? && password_reset_sent_at.present?
    return false if Time.current > password_reset_sent_at + PASSWORD_RESET_EXPIRY

    ActiveSupport::SecurityUtils.secure_compare(
      password_reset_token_digest,
      digest_token(raw_token)
    )
  end

  def clear_password_reset_token!
    update_columns(
      password_reset_token_digest: nil,
      password_reset_sent_at: nil
    )
  end

  def dark_theme?
    theme_preference == "dark"
  end

  private

  def digest_token(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def email_must_be_school_domain
    return if email.blank?

    domain = email.downcase.split("@").last
    unless ALLOWED_EMAIL_DOMAINS.include?(domain)
      errors.add(:email, "must be a CUHK school email (@link.cuhk.edu.hk or @cuhk.edu.hk)")
    end
  end

  def email_uniqueness
    return if email.blank?

    if User.where(email: email.downcase).where.not(id: id).exists?
      errors.add(:base, "An account with this email already exists")
    end
  end

  def cuhk_id_uniqueness
    return if cuhk_id.blank?

    if User.where(cuhk_id: cuhk_id).where.not(id: id).exists?
      errors.add(:base, "An account with this CUHK ID already exists")
    end
  end
end
