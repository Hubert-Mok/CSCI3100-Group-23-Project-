require 'rails_helper'

RSpec.describe Product, type: :model do
  let(:user) do
    User.create!(
      email: 'seller@link.cuhk.edu.hk',
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Test Seller',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  let(:valid_attributes) do
    {
      title: 'Used Laptop',
      description: 'A high-performance laptop in great condition with 16GB RAM and SSD storage.',
      price: 500,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available,
      user: user
    }
  end

  it 'is valid with valid sale attributes' do
    product = Product.new(valid_attributes)
    expect(product).to be_valid
  end

  it 'is valid with valid gift attributes and zero price' do
    product = Product.new(valid_attributes.merge(listing_type: 'gift', price: 0))
    expect(product).to be_valid
  end

  it 'defaults status to available' do
    product = Product.new(valid_attributes.except(:status))
    expect(product.status).to eq('available')
  end

  describe 'validations' do
    it 'is invalid when the title is too short' do
      product = Product.new(valid_attributes.merge(title: 'OK'))
      expect(product).not_to be_valid
      expect(product.errors[:title]).to include(/too short/i)
    end

    it 'is invalid when a sale listing has a non-positive price' do
      product = Product.new(valid_attributes.merge(price: 0, listing_type: 'sale'))
      expect(product).not_to be_valid
      expect(product.errors[:price]).to include('must be greater than 0 for sale listings')
    end

    it 'is invalid when a gift listing has a positive price' do
      product = Product.new(valid_attributes.merge(price: 50, listing_type: 'gift'))
      expect(product).not_to be_valid
      expect(product.errors[:price]).to include('must be 0 for free/gift listings')
    end

    it 'is invalid without a category' do
      product = Product.new(valid_attributes.except(:category))
      expect(product).not_to be_valid
      expect(product.errors[:category]).to include("can't be blank")
    end

    it 'is invalid when the description is too short' do
      product = Product.new(valid_attributes.merge(description: 'Too short'))
      expect(product).not_to be_valid
      expect(product.errors[:description]).to include(/too short/i)
    end
  end
end
