require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:buyer) do
    User.create!(
      email: "buyer_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Buyer User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:seller) do
    User.create!(
      email: "seller_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Seller User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:product) do
    Product.create!(
      title: 'Used Laptop',
      description: 'Reliable laptop with enough details to pass validation',
      price: 500,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available,
      user: seller
    )
  end

  let(:conversation) do
    Conversation.create!(
      product: product,
      buyer: buyer,
      seller: seller
    )
  end

  before do
    allow_any_instance_of(Product).to receive(:get_ai_fraud_score).and_return({ score: 0.0, is_fraud: false })
  end

  it 'is valid with conversation, user, and body' do
    message = Message.new(conversation: conversation, user: buyer, body: 'Hello there')

    expect(message).to be_valid
  end

  it 'is invalid without body and without attachments' do
    message = Message.new(conversation: conversation, user: buyer, body: '')

    expect(message).not_to be_valid
    expect(message.errors.full_messages.join).to include('Message must have text or at least one attachment')
  end

  it 'is invalid when body exceeds 1000 characters' do
    message = Message.new(conversation: conversation, user: buyer, body: 'a' * 1001)

    expect(message).not_to be_valid
    expect(message.errors[:body]).to include('is too long (maximum is 1000 characters)')
  end

  it 'belongs to conversation and user' do
    message = Message.create!(conversation: conversation, user: buyer, body: 'Hi')

    expect(message.conversation).to eq(conversation)
    expect(message.user).to eq(buyer)
  end
end
