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

When('I click the flagged product title link') do
  click_link @flagged_product.title
end

Then('I should be on that product page') do
  expected_path = "/products/#{@flagged_product.id}"
  raise "Expected to be on flagged product page (#{expected_path}), got #{page.current_path}" unless page.current_path == expected_path
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

Given('a flagged message exists for moderation') do
  # Create seller and buyer users
  @seller_for_message = User.create!(
    email: "seller_msg_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
    password: 'Password123',
    password_confirmation: 'Password123',
    cuhk_id: SecureRandom.hex(4),
    username: 'Seller Message',
    college_affiliation: User::COLLEGES.first,
    email_verified_at: Time.current
  )

  @buyer_for_message = User.create!(
    email: "buyer_msg_#{SecureRandom.hex(4)}@link.cuhk.edu.hk",
    password: 'Password123',
    password_confirmation: 'Password123',
    cuhk_id: SecureRandom.hex(4),
    username: 'Buyer Message',
    college_affiliation: User::COLLEGES.first,
    email_verified_at: Time.current
  )

  # Create a product
  @product_for_message = Product.create!(
    title: 'Product with Flagged Message',
    description: 'A normal product',
    price: 100,
    category: Product::CATEGORIES.first,
    listing_type: 'sale',
    status: :available,
    user: @seller_for_message
  )

  # Create a conversation
  @conversation_for_message = Conversation.create!(
    product: @product_for_message,
    buyer: @buyer_for_message,
    seller: @seller_for_message
  )

  # Create a flagged message
  @flagged_message = Message.create!(
    conversation: @conversation_for_message,
    user: @buyer_for_message,
    body: 'Contact me on whatsapp +85212345678',
    flagged: true
  )
end

Then('I should see the flagged message in the moderation queue') do
  raise 'Expected flagged message to appear in moderation queue' unless page.has_content?(@flagged_message.body)
  raise 'Expected sender username in moderation queue' unless page.has_content?(@buyer_for_message.username)
  raise 'Expected product title in moderation queue' unless page.has_content?(@product_for_message.title)
end

When('I click the flagged message product title link') do
  click_link @product_for_message.title
end

Then('I should be on the flagged message product page') do
  expected_path = "/products/#{@product_for_message.id}"
  raise "Expected to be on flagged message product page (#{expected_path}), got #{page.current_path}" unless page.current_path == expected_path
end

When('I approve the flagged message from the dashboard') do
  # Find and click the approve button for the message by searching for the message body
  rows = all('table tbody tr')
  row = rows.find { |r| r.has_content?(@flagged_message.body) }
  raise 'Could not find message row' unless row
  row.find('button', text: 'Approve').click
end

Then('the message should be unflagged') do
  @flagged_message.reload
  raise 'Expected message to be unflagged after approval' if @flagged_message.flagged
  raise 'Expected success message for approval' unless page.has_content?('Message approved!')
end

When('I visit the home page to check admin badge') do
  visit '/'
end

Then('I should see {string} in the admin badge') do |text|
  # Wait for badge element and check it contains the text
  begin
    badge = page.find('.admin-badge', visible: true)
    raise "Badge not found with '#{text}'" unless badge.has_content?(text)
  rescue Capybara::ElementNotFound
    # Badge element not found, try to see what's actually on the page
    page_content = page.body
    raise "Badge element (.admin-badge) not found on page. Page content preview: #{page_content[0...500]}"
  end
end
