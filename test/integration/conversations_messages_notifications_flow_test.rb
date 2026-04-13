# frozen_string_literal: true

require "test_helper"

class ConversationsMessagesNotificationsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @suffix = SecureRandom.hex(3)
    @seller = User.create!(
      email: "conv_seller#{@suffix}@link.cuhk.edu.hk",
      password: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      password_confirmation: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      cuhk_id: "1188#{@suffix}",
      username: "convseller#{@suffix}",
      college_affiliation: "United College",
      email_verified_at: Time.current
    )
    @product = @seller.products.create!(
      title: "Bike for sale",
      description: "Lightweight road bike, well maintained and ready for campus commuting.",
      price: 800,
      category: "Sports & Fitness",
      listing_type: :sale,
      status: :available
    )
    @buyer = users(:verified_user)
  end

  test "seller cannot start chat on own listing" do
    sign_in_as @seller
    post conversations_path, params: { product_id: @product.id }
    assert_redirected_to product_path(@product)
  end

  test "buyer can open conversation and send message" do
    sign_in_as @buyer
    assert_difference -> { Conversation.count }, +1 do
      post conversations_path, params: { product_id: @product.id }
    end
    assert_response :redirect
    conversation = Conversation.last

    assert_difference -> { Message.count }, +1 do
      post conversation_messages_path(conversation), params: { message: { body: "Is this still available?" } }
    end
    assert_redirected_to conversation_path(conversation)

    recipient = @seller
    assert_operator recipient.notifications.count, :>=, 1
  end

  test "stranger cannot view others conversation" do
    sign_in_as @buyer
    post conversations_path, params: { product_id: @product.id }
    conversation = Conversation.last

    other = User.create!(
      email: "other#{@suffix}@link.cuhk.edu.hk",
      password: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      password_confirmation: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      cuhk_id: "1177#{@suffix}",
      username: "other#{@suffix}",
      college_affiliation: "New Asia College",
      email_verified_at: Time.current
    )
    sign_in_as other
    get conversation_path(conversation)
    assert_redirected_to root_path
  end

  test "notifications index update clear_all" do
    sign_in_as @buyer
    Notification.create!(
      user: @buyer,
      product: @product,
      message: "Test notification",
      read: false
    )

    get notifications_path
    assert_response :success

    notif = @buyer.notifications.last
    patch notification_path(notif)
    assert_response :redirect
    assert notif.reload.read?

    delete clear_all_notifications_path
    assert_response :redirect
    assert_equal 0, @buyer.notifications.reload.count
  end
end
