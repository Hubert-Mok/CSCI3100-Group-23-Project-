require 'rails_helper'

RSpec.describe Like, type: :model do
  let(:user) do
    User.create!(
      email: "user_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Like User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:other_user) do
    User.create!(
      email: "other_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Other User',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:product) do
    Product.create!(
      title: 'Likeable Product',
      description: 'A test listing with enough length for validation checks.',
      price: 123,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available,
      user: other_user
    )
  end

  let(:another_product) do
    Product.create!(
      title: 'Another Product',
      description: 'Another valid listing used for uniqueness tests.',
      price: 88,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available,
      user: other_user
    )
  end

  it 'is valid for a unique user-product pair' do
    like = Like.new(user: user, product: product)

    expect(like).to be_valid
  end

  it 'prevents duplicate likes for the same user and product' do
    Like.create!(user: user, product: product)
    duplicate = Like.new(user: user, product: product)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to include('already liked this product')
  end

  it 'allows same user to like different products' do
    Like.create!(user: user, product: product)
    like = Like.new(user: user, product: another_product)

    expect(like).to be_valid
  end

  it 'increments and decrements product likes_count via counter cache' do
    expect {
      @like = Like.create!(user: user, product: product)
    }.to change { product.reload.likes_count }.by(1)

    expect {
      @like.destroy!
    }.to change { product.reload.likes_count }.by(-1)
  end
end
