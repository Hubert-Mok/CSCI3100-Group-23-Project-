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

When('I search for {string}') do |query|
  fill_in 'Search listings…', with: query
  click_button 'Search'
end

Then('I should see a product titled {string}') do |title|
  expect(page).to have_content(title)
end

Then('I should not see a product titled {string}') do |title|
  expect(page).not_to have_content(title)
end