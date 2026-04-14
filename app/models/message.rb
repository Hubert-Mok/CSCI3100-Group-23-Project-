class Message < ApplicationRecord
  include FraudDetectable
  after_create_commit :check_for_fraud
  belongs_to :conversation
  belongs_to :user

  has_many_attached :attachments

  validates :body, length: { maximum: 1000 }, allow_blank: true
  validate :body_or_attachments_present
  # TODO: consider adding Active Storage validations for file size (e.g. 10 MB) and content types (e.g. images, PDF, DOC)

  private

  def body_or_attachments_present
    return if body.present? || attachments.attached?

    errors.add(:base, "Message must have text or at least one attachment")
  end

  def check_for_fraud
    if suspicious?
      # You could notify an admin, or just mark it in the DB
      flag_for_review!
      puts "⚠️ Fraud Alert: Suspicious message detected from User #{user_id}"
    end
  end
end
