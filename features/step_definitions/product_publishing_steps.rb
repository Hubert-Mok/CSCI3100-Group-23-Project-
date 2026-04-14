require 'capybara'
require 'capybara/dsl'
require 'securerandom'

# Load Rails test environment
rails_root = File.join(File.dirname(__FILE__), '..', '..')
require File.join(rails_root, 'test', 'test_helper')

World(Capybara::DSL)
Capybara.app = Rails.application

# Background steps
Given('there is a registered user with email {string} and password {string}') do |email, password|
  @user = User.create!(
    email: email,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: "Test User",
    college_affiliation: User::COLLEGES.first,
    email_verified_at: Time.current
  )
end

Given('the user\'s email is verified') do
  @user.update!(
    email_verified_at: Time.current,
    email_verification_token_digest: nil,
    email_verification_sent_at: nil
  )
end

Given('the user\'s email is not verified') do
  @user.update!(
    email_verified_at: nil,
    email_verification_token_digest: nil,
    email_verification_sent_at: nil
  )
end

# Navigation steps
Given('I am logged in as {string}') do |email|
  user = User.find_by(email: email)
  visit '/sign_in'
  fill_in 'Email', with: email
  fill_in 'Password', with: 'Password123'
  click_button 'Sign In'
end

Given('I am on the new product page') do
  visit '/products/new'
end

Given('I already have a published product listing titled {string} with status {string}') do |title, status|
  @product = Product.create!(
    title: title,
    description: 'A well-described item that is ready for editing in the listing flow.',
    price: 100,
    category: Product::CATEGORIES.first,
    listing_type: 'sale',
    status: status.downcase.to_sym,
    user: @user
  )
end

Given('I am on the edit listing page for {string}') do |title|
  @product = Product.find_by!(title: title, user: @user)
  visit "/products/#{@product.id}/edit"
end

Given('the listing has existing product photo file {string}') do |filename|
  file_path = Rails.root.join('test', 'fixtures', 'files', filename)
  raise "Missing fixture file: #{file_path}" unless File.exist?(file_path)

  @product.thumbnail.attach(
    io: File.open(file_path),
    filename: filename,
    content_type: 'image/png'
  )
  @product.reload
  @original_photo_blob_id = @product.thumbnail.blob_id
end

Given('I try to visit the new product page') do
  visit '/products/new'
end

Given('I am on the login page') do
  visit '/sign_in'
end

# Form filling steps
When('I fill in the product form with:') do |table|
  form_hash = table.rows_hash

  fill_in 'Title', with: form_hash['Title']
  fill_in 'Description', with: form_hash['Description']
  fill_in 'Price (HKD)', with: form_hash['Price']
  select form_hash['Category'], from: 'Category'
  select form_hash['Status'], from: 'Status' if form_hash['Status'].present?

  if form_hash['Listing Type'].casecmp('Sale').zero?
    choose 'For Sale'
  else
    choose 'Free / Gift'
  end
end

When('I attach product photo file {string}') do |filename|
  file_path = Rails.root.join('test', 'fixtures', 'files', filename)
  raise "Missing fixture file: #{file_path}" unless File.exist?(file_path)

  attach_file('Photo', file_path, visible: false)
end

# Form submission steps
When('I submit the product form') do
  @product_count_before = Product.count
  click_button(page.has_button?('Update Listing') ? 'Update Listing' : 'Publish Listing')
end

# Success assertions
Then('the product should be published successfully') do
  @product = Product.where(user: @user).order(created_at: :desc).first
  raise 'Product was not created' unless @product.present?
  raise 'Product does not belong to the expected user' unless @product.user == @user
end

Then('I should see {string}') do |text|
  raise "Expected to see #{text}" unless page.has_content?(text)
end

Then('I should not see {string}') do |text|
  raise "Expected not to see #{text}" if page.has_content?(text)
end

Then('the product should have status {string}') do |status|
  @product.reload
  raise "Expected product status #{status}, got #{@product.status}" unless @product.status == status
end

Then('the product should be listed on the market') do
  visit "/products/#{@product.id}"
  raise "Expected product #{@product.title} to be visible on its show page" unless page.has_content?(@product.title)
end

Then('the product should have status pending') do
  @product.reload
  raise "Expected product status pending, got #{@product.status}" unless @product.status == 'pending'
end

Then('the product should have title {string}') do |title|
  @product.reload
  raise "Expected product title #{title}, got #{@product.title}" unless @product.title == title
end

Then('the product should have an attached photo') do
  @product.reload
  raise 'Expected product to have an attached photo' unless @product.thumbnail.attached?
end

Then('the product photo should be replaced') do
  @product.reload
  raise 'Expected product to have an attached photo' unless @product.thumbnail.attached?
  raise 'Expected product photo blob to be replaced' if @product.thumbnail.blob_id == @original_photo_blob_id
end

Then('the product photo should remain unchanged') do
  @product.reload
  raise 'Expected product to keep an attached photo' unless @product.thumbnail.attached?
  raise 'Expected product photo blob to stay unchanged' unless @product.thumbnail.blob_id == @original_photo_blob_id
end

# Failure assertions
Then('the product publishing should fail') do
  before_count = @product_count_before || 0
  raise 'Product should not be created for this user' if Product.count > before_count
  raise 'Expected validation errors on the listing form' unless page.has_content?('prevented this listing from being saved') || page.has_content?('must be') || page.has_content?('error')
end
Then('I should see an error about the title') do
  raise 'Expected title error' unless page.has_content?('Title') && page.has_content?('error')
end

Then('I should see an error about the price') do
  raise 'Expected price error' unless page.has_content?('Price') && page.has_content?('error')
end

Then('I should see an error about the description') do
  raise 'Expected description error' unless page.has_content?('Description') && page.has_content?('error')
end

# Redirect assertions
Then('I should be redirected to the login page') do
  raise "Expected login page, got #{page.current_path}" unless page.current_path == '/sign_in'
end

Then('I should be redirected away from the new product page') do
  raise "Expected to be redirected away from /products/new, but stayed there" if page.current_path == '/products/new'
end
