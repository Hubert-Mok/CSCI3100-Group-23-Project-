require 'rails_helper'

RSpec.describe Product, type: :model do
  let(:user) do
    User.create!(
      email: "seller_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
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

    it 'is invalid when price is above the allowed maximum' do
      product = Product.new(valid_attributes.merge(price: 1_000_000))
      expect(product).not_to be_valid
      expect(product.errors[:price]).to include('is too high (maximum is 999999.9)')
    end

    it 'accepts price with one decimal place' do
      product = Product.new(valid_attributes.merge(price: 123.4))
      expect(product).to be_valid
    end

    it 'is invalid when price has more than one decimal place' do
      product = Product.new(valid_attributes.merge(price: 123.45))
      expect(product).not_to be_valid
      expect(product.errors[:price]).to include('can have at most 1 decimal place')
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

  describe 'fraud moderation flow' do
    it 'flags suspicious content and sets pending status' do
      product = Product.new(valid_attributes.merge(description: 'Please contact me on WhatsApp +85212345678'))
      allow(product).to receive(:get_ai_fraud_score).and_return({ score: 0.15, is_fraud: false })

      product.save!

      expect(product.flagged).to be(true)
      expect(product.status).to eq('pending')
      expect(product.fraud_score).to eq(0.15)
    end

    it 'flags suspicious product title and sets pending status' do
      product = Product.new(valid_attributes.merge(title: 'suspicious laptop, contact via whatsapp 12345678'))
      allow(product).to receive(:get_ai_fraud_score).and_return({ score: 0.12, is_fraud: false })

      product.save!

      expect(product.flagged).to be(true)
      expect(product.status).to eq('pending')
      expect(product.fraud_score).to eq(0.12)
    end

    it 'flags product when AI marks it as fraud even if text is clean' do
      product = Product.new(valid_attributes)
      allow(product).to receive(:get_ai_fraud_score).and_return({ score: 0.91, is_fraud: true })

      product.save!

      expect(product.flagged).to be(true)
      expect(product.status).to eq('pending')
      expect(product.fraud_score).to eq(0.91)
    end

    it 'does not re-flag immediately when an admin clears flagged state' do
      product = Product.new(valid_attributes.merge(description: 'Telegram me at +85212345678'))
      allow(product).to receive(:get_ai_fraud_score).and_return({ score: 0.25, is_fraud: false })
      product.save!

      product.update!(flagged: false, status: :available)

      expect(product.reload.flagged).to be(false)
      expect(product.status).to eq('available')
    end

    it 'falls back safely when the AI service is unavailable' do
      product = Product.new(valid_attributes)
      stub_const('HTTParty', Class.new do
        def self.post(*)
        end
      end)
      allow(HTTParty).to receive(:post).and_raise(StandardError, 'AI down')
      allow(Rails.logger).to receive(:error)

      expect(product.get_ai_fraud_score).to eq({ score: 0.0, is_fraud: false })
    end
  end

  describe '.search' do
    let!(:laptop) do
      Product.create!(
        title: 'Used Laptop',
        description: 'Reliable laptop with 8GB RAM',
        price: 500,
        category: Product::CATEGORIES.first,
        listing_type: 'sale',
        status: :available,
        user: user
      )
    end

    let!(:chair) do
      Product.create!(
        title: 'Desk Chair',
        description: 'Comfortable study chair for desks',
        price: 100,
        category: Product::CATEGORIES.second,
        listing_type: 'sale',
        status: :available,
        user: user
      )
    end

    it 'returns exact title matches' do
      results = Product.search('Laptop')

      expect(results).to include(laptop)
      expect(results).not_to include(chair)
    end

    it 'returns fuzzy matches when no exact match exists' do
      results = Product.search('Laptpo')

      expect(results).to include(laptop)
      expect(results).not_to include(chair)
    end

    it 'is case insensitive' do
      results = Product.search('lApToP')

      expect(results).to include(laptop)
    end

    it 'matches description text' do
      results = Product.search('RAM')

      expect(results).to include(laptop)
    end

    it 'returns none when fuzzy and exact matching both fail' do
      results = Product.search('totally-unmatched-query')

      expect(results).to be_empty
    end

    it 'returns all records when query is blank' do
      results = Product.search(nil)

      expect(results).to include(laptop, chair)
    end
  end
end
