# frozen_string_literal: true

require "test_helper"

class OfferTest < ActiveSupport::TestCase
  setup do
    suffix = SecureRandom.hex(3)
    @seller = User.create!(
      email: "offer_seller#{suffix}@link.cuhk.edu.hk",
      password: "password123",
      password_confirmation: "password123",
      cuhk_id: "2255#{suffix}",
      username: "offer_seller_#{suffix}",
      college_affiliation: "Shaw College",
      email_verified_at: Time.current
    )
    @buyer = User.create!(
      email: "offer_buyer#{suffix}@link.cuhk.edu.hk",
      password: "password123",
      password_confirmation: "password123",
      cuhk_id: "2266#{suffix}",
      username: "offer_buyer_#{suffix}",
      college_affiliation: "New Asia College",
      email_verified_at: Time.current
    )
    @product = @seller.products.create!(
      title: "Offer model test listing",
      description: "Used for offer model validation checks in automated test suite.",
      price: 200,
      category: "Electronics",
      listing_type: :sale,
      status: :available
    )
    @conversation = Conversation.create!(product: @product, buyer: @buyer, seller: @seller)
  end

  test "is valid for conversation participants with positive amount" do
    offer = Offer.new(
      conversation: @conversation,
      product: @product,
      buyer: @buyer,
      seller: @seller,
      proposed_by: @buyer,
      amount: 150,
      status: :proposed
    )
    assert offer.valid?
  end

  test "is invalid when proposer is not conversation participant" do
    outsider = users(:verified_user)
    offer = Offer.new(
      conversation: @conversation,
      product: @product,
      buyer: @buyer,
      seller: @seller,
      proposed_by: outsider,
      amount: 100,
      status: :proposed
    )
    assert_not offer.valid?
  end
end
