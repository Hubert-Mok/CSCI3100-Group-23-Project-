require 'securerandom'

Given('an admin account exists with email {string} and password {string}') do |email, password|
  @admin_user = User.create!(
    email: email,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: 'Admin',
    college_affiliation: User::COLLEGES.first,
    email_verified_at: Time.current,
    admin: true
  )
end

Given('a flagged product exists for moderation') do
  Product.class_eval do
    def get_ai_fraud_score
      { score: 0.0, is_fraud: false }
    end
  end

  @seller_for_flagged_product = User.create!(
    email: 'seller_mod@link.cuhk.edu.hk',
    password: 'Password123',
    password_confirmation: 'Password123',
    cuhk_id: SecureRandom.hex(4),
    username: 'Seller Moderation',
    college_affiliation: User::COLLEGES.first,
    email_verified_at: Time.current
  )

  @flagged_product = Product.create!(
    title: 'Suspicious Camera',
    description: 'Clean description that passes validations only.',
    price: 250,
    category: Product::CATEGORIES.first,
    listing_type: 'sale',
    status: :available,
    user: @seller_for_flagged_product
  )

  @flagged_product.update_columns(flagged: true, status: Product.statuses[:pending])
end

Given('{int} flagged products exist for moderation') do |count|
  Product.class_eval do
    def get_ai_fraud_score
      { score: 0.0, is_fraud: false }
    end
  end

  seller = User.create!(
    email: "seller_many_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
    password: 'Password123',
    password_confirmation: 'Password123',
    cuhk_id: SecureRandom.hex(4),
    username: 'Seller Many',
    college_affiliation: User::COLLEGES.first,
    email_verified_at: Time.current
  )

  count.times do |index|
    Product.create!(
      title: "Suspicious Item #{index}",
      description: 'Contact me on whatsapp +85212345678',
      price: 100,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :pending,
      flagged: true,
      user: seller
    )
  end
end

Given('a normal user exists with email {string} and password {string}') do |email, password|
  @normal_user = User.create!(
    email: email,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: 'Buyer',
    college_affiliation: User::COLLEGES.first,
    email_verified_at: Time.current,
    admin: false
  )
end

Given('I sign in as admin with email {string} and password {string}') do |email, password|
  visit '/sign_in'
  fill_in 'Email', with: email
  fill_in 'Password', with: password
  click_button 'Sign In'
end

When('I visit the admin moderation dashboard') do
  visit '/admin/moderation'
end

Then('I should see the flagged product in the moderation queue') do
  raise 'Expected flagged product to appear in moderation queue' unless page.has_content?(@flagged_product.title)
end

When('I approve the flagged product from the dashboard') do
  click_button 'Approve'
end

Then('the product should be unflagged and available') do
  @flagged_product.reload
  raise 'Expected product to be unflagged after approval' if @flagged_product.flagged
  raise "Expected available status, got #{@flagged_product.status}" unless @flagged_product.status == 'available'
  raise 'Expected success message for approval' unless page.has_content?('Product approved and listed!')
end

Then('I should be denied access to the moderation dashboard') do
  raise 'Expected to be redirected from moderation dashboard' unless page.current_path == '/'
  raise 'Expected access denied message' unless page.has_content?('Access denied.')
end
