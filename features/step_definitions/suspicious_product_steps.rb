require 'securerandom'

Given('a verified seller exists with email {string} and password {string}') do |email, password|
  @seller = User.create!(
    email: email,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: 'Flag Seller',
    college_affiliation: User::COLLEGES.first,
    email_verified_at: Time.current
  )
end

When('the seller creates a suspicious product listing') do
  create_suspicious_listing(
    title: 'Cheap iPhone',
    description: 'Contact me on WhatsApp +85212345678 for fast deal'
  )
end

When('the seller creates a suspicious product listing with title {string} and description {string}') do |title, description|
  create_suspicious_listing(title: title, description: description)
end

def create_suspicious_listing(title:, description:)
  Product.class_eval do
    def get_ai_fraud_score
      { score: 0.0, is_fraud: false }
    end
  end

  @suspicious_product = Product.create!(
    title: title,
    description: description,
    price: 300,
    category: Product::CATEGORIES.first,
    listing_type: 'sale',
    status: :available,
    user: @seller
  )
end

Then('the listing should be flagged for moderation') do
  raise 'Expected listing to be flagged' unless @suspicious_product.reload.flagged
end

Then('the listing status should be {string}') do |status|
  raise "Expected status #{status}, got #{@suspicious_product.reload.status}" unless @suspicious_product.status == status
end

Then('the flagged listing should not appear on the marketplace index') do
  visit '/'
  raise 'Flagged listing should not be visible on marketplace index' if page.has_content?(@suspicious_product.title)
end
