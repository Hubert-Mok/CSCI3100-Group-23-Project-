require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:buyer) do
    User.create!(
      email: 'buyer@test.com',
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Buyer',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end
  let(:seller) do
    User.create!(
      email: 'seller@test.com',
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Seller',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current,
      stripe_account_id: 'acct_test'
    )
  end
  let(:product) do
    Product.create!(
      user: seller,
      title: 'Test Product',
      description: 'Test description',
      price: 100,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available
    )
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      order = build(:order, buyer: buyer, product: product)
      expect(order).to be_valid
    end

    it 'requires amount_cents to be present and greater than 0' do
      order = build(:order, buyer: buyer, product: product, amount_cents: nil)
      expect(order).not_to be_valid
      expect(order.errors[:amount_cents]).to include("can't be blank")

      order.amount_cents = 0
      expect(order).not_to be_valid
      expect(order.errors[:amount_cents]).to include("must be greater than 0")
    end

    it 'requires currency to be present' do
      order = build(:order, buyer: buyer, product: product, currency: nil)
      expect(order).not_to be_valid
      expect(order.errors[:currency]).to include("can't be blank")
    end

    it 'validates product availability on create' do
      product.update!(status: :sold)
      order = build(:order, buyer: buyer, product: product)
      expect(order).not_to be_valid
      expect(order.errors[:product]).to include("is not available for purchase")
    end

    it 'validates product is for sale on create' do
      product.update!(listing_type: :gift)
      order = build(:order, buyer: buyer, product: product)
      expect(order).not_to be_valid
      expect(order.errors[:product]).to include("must be listed for sale")
    end
  end

  describe 'associations' do
    it 'belongs to buyer' do
      order = Order.create!(
        buyer: buyer,
        product: product,
        amount_cents: 10000,
        currency: 'hkd'
      )
      expect(order.buyer).to eq(buyer)
    end

    it 'belongs to product' do
      order = Order.create!(
        buyer: buyer,
        product: product,
        amount_cents: 10000,
        currency: 'hkd'
      )
      expect(order.product).to eq(product)
    end
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(Order.statuses).to eq({
        'pending' => 0,
        'paid' => 1,
        'completed' => 2,
        'cancelled' => 3
      })
    end
  end

  describe '#release_to_seller!' do
    let(:order) do
      Order.create!(
        buyer: buyer,
        product: product,
        amount_cents: 10000,
        currency: 'hkd',
        status: :paid
      )
    end

    context 'when order is paid and seller has stripe account' do
      before do
        allow(Stripe::Transfer).to receive(:create).and_return(double(id: 'tr_test'))
      end

      it 'creates a stripe transfer' do
        expect(Stripe::Transfer).to receive(:create).with(
          amount: order.amount_cents,
          currency: order.currency,
          destination: seller.stripe_account_id,
          description: "Payment for: #{product.title}"
        )
        order.release_to_seller!
      end

      it 'updates order status to completed' do
        order.release_to_seller!
        expect(order.status).to eq('completed')
      end

      it 'sets stripe_transfer_id' do
        order.release_to_seller!
        expect(order.stripe_transfer_id).to eq('tr_test')
      end

      it 'marks product as sold' do
        order.release_to_seller!
        expect(product.reload.status).to eq('sold')
      end
    end

    context 'when order is not paid' do
      before { order.update!(status: :pending) }

      it 'does not create transfer' do
        expect(Stripe::Transfer).not_to receive(:create)
        order.release_to_seller!
      end
    end

    context 'when seller has no stripe account' do
      before { seller.update!(stripe_account_id: nil) }

      it 'does not create transfer' do
        expect(Stripe::Transfer).not_to receive(:create)
        order.release_to_seller!
      end
    end
  end
end