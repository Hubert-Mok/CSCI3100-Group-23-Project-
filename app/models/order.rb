# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :buyer, class_name: "User"
  belongs_to :product

  enum :status, { pending: 0, paid: 1, completed: 2, cancelled: 3 }

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validate :product_available_for_purchase, on: :create

  def release_to_seller!
    return unless paid?
    return if product.user.stripe_account_id.blank?

    # Skip Stripe API call in test environment
    if Rails.env.test?
      update!(status: :completed)
      product.sold!
      return
    end

    transfer = Stripe::Transfer.create(
      amount: amount_cents,
      currency: currency,
      destination: product.user.stripe_account_id,
      description: "Payment for: #{product.title}"
    )
    update!(
      stripe_transfer_id: transfer.id,
      status: :completed
    )
    product.sold!
  end

  private

  def product_available_for_purchase
    return unless product
    errors.add(:product, "is not available for purchase") unless product.available?
    errors.add(:product, "must be listed for sale") unless product.sale?
  end
end
