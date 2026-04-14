require 'capybara'
require 'capybara/dsl'
require 'securerandom'

# Load Rails test environment
rails_root = File.join(File.dirname(__FILE__), '..', '..')
require File.join(rails_root, 'test', 'test_helper')

World(Capybara::DSL)
Capybara.app = Rails.application

# Background steps
Given('the seller has connected a Stripe account') do
  @seller.update!(stripe_account_id: 'acct_test_seller')
end

Given('the buyer\'s email is verified') do
  @buyer.update!(
    email_verified_at: Time.current,
    email_verification_token_digest: nil,
    email_verification_sent_at: nil
  )
end

# Navigation and action steps

When('I visit the product page for {string}') do |title|
  product = Product.find_by(title: title)
  visit "/products/#{product.id}"
end

When('I click {string}') do |button_text|
  click_on button_text
end

When('I try to purchase the {string} product') do |title|
  product = Product.find_by(title: title)
  visit "/orders/new?product_id=#{product.id}"
end

When('I visit my orders page') do
  visit "/orders"
end

When('I confirm receipt of the order') do
  @order = Order.where(buyer: @buyer).last
  visit "/orders/#{@order.id}"
  click_button 'Confirm I Received the Item'
end

# Assertion steps
Then('I should be redirected to Stripe checkout') do
  # In test environment, we check that the order was created with a Stripe session
  order = Order.where(buyer: @buyer).last
  expect(order).to be_present
  expect(order.stripe_checkout_session_id).to be_present
  expect(order.status).to eq('pending')
end

Then('the order should be created with status {string}') do |status|
  @order = Order.where(buyer: @buyer).last
  expect(@order.status).to eq(status)
end

Then('no order should be created') do
  order_count = Order.where(buyer: @buyer).count
  expect(order_count).to eq(0)
end

Then('the {string} product is sold') do |title|
  product = Product.find_by(title: title)
  product.update!(status: :sold)
end

Then('I have purchased the {string} product') do |title|
  product = Product.find_by(title: title)
  @order = Order.create!(
    product: product,
    buyer: @buyer,
    amount_cents: (product.price * 100).to_i,
    currency: 'hkd',
    status: :paid
  )
end

Then('I should see the order for {string}') do |title|
  expect(page).to have_content(title)
end

Then('I have a paid order for {string}') do |title|
  product = Product.find_by(title: title)
  @order = Order.create!(
    product: product,
    buyer: @buyer,
    amount_cents: (product.price * 100).to_i,
    currency: 'hkd',
    status: :paid
  )
end

Then('the seller should receive payment') do
  @order.reload
  expect(@order.status).to eq('completed')
end