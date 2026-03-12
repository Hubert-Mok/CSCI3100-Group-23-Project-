class Message < ApplicationRecord
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
end
