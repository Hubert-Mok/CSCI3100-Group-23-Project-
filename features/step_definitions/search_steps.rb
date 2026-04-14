require 'capybara'
require 'capybara/dsl'
require 'securerandom'

# Load Rails test environment
rails_root = File.join(File.dirname(__FILE__), '..', '..')
require File.join(rails_root, 'test', 'test_helper')

World(Capybara::DSL)
Capybara.app = Rails.application

Given('I am on the marketplace page') do
  visit '/'
end

Given('the following products exist:') do |table|
  table.hashes.each do |row|
    user = User.find_by(email: 'search-seller@link.cuhk.edu.hk') || User.create!(
      email: 'search-seller@link.cuhk.edu.hk',
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Search Seller',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
    Product.create!(
      title: row['Title'],
      description: row['Description'],
      price: 100,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available,
      user: user
    )
  end
end

Given('the following detailed products exist:') do |table|
  table.hashes.each do |row|
    seller_email = (row['Seller Email'] || 'search-seller@link.cuhk.edu.hk').downcase
    user = User.find_by(email: seller_email) || User.create!(
      email: seller_email,
      password: 'Password123',
      password_confirmation: 'Password123',
      cuhk_id: SecureRandom.hex(4),
      username: seller_email.split('@').first,
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )

    Product.create!(
      title: row['Title'],
      description: row['Description'],
      price: (row['Price'] || 100).to_i,
      category: row['Category'] || Product::CATEGORIES.first,
      listing_type: (row['Listing Type'] || 'sale'),
      status: (row['Status'] || 'available'),
      user: user,
      flagged: row['Flagged'].to_s.casecmp('true').zero?
    )
  end
end

When('I search for {string}') do |query|
  fill_in 'Search listings…', with: query
  click_button 'Search'
end

When('I filter by category {string}') do |category|
  select category, from: 'category'
  click_button 'Search'
end

When('I filter by status {string}') do |status|
  select status.capitalize, from: 'status'
  click_button 'Search'
end

When('I sort results by {string}') do |sort_option|
  select sort_option, from: 'sort'
  click_button 'Search'
end

When('I sign in as the search seller') do
  visit '/sign_in'
  fill_in 'Email', with: 'search-seller@link.cuhk.edu.hk'
  fill_in 'Password', with: 'Password123'
  click_button 'Sign In'
end

Then('I should see a product titled {string}') do |title|
  expect(page).to have_content(title)
end

Then('I should not see a product titled {string}') do |title|
  expect(page).not_to have_content(title)
end

Then('I should see products in this order:') do |table|
  expected_titles = table.hashes.map { |row| row['Title'] }
  visible_titles = all('.product-title').map(&:text)

  expected_titles.each_with_index do |title, index|
    expect(visible_titles[index]).to eq(title)
  end
end