Given('the seller {string} has the following available products:') do |email, table|
  user = User.find_by(email: email.downcase)
  table.rows.each do |row|
    title, price, description = row[0], row[1].to_f, row[2]
    Product.create!(
      title: title,
      price: price,
      description: description,
      category: Product::CATEGORIES.first,
      listing_type: 'sale',
      status: :available,
      flagged: false,
      user: user
    )
  end
end

Given('the seller has sold products not visible in the profile') do
  user = User.last
  Product.create!(
    title: 'Sold Laptop',
    price: 400,
    description: 'Already sold.',
    category: Product::CATEGORIES.first,
    listing_type: 'sale',
    status: :sold,
    flagged: false,
    user: user
  )
end

When('I visit the seller profile for {string}') do |email|
  user = User.find_by(email: email.downcase)
  visit "/sellers/#{user.id}"
end

Then('I should be on the seller profile page') do
  expect(page).to have_current_path(%r{/sellers/\d+})
end

Then('the seller has no available products displayed') do
  has_no_products = page.has_text?('No products available') || !page.has_css?('[data-test="product"]')
  expect(has_no_products).to be true
end

Given('the seller {string} has a product {string} posted {int} days ago') do |email, title, days|
  user = User.find_by(email: email.downcase)
  created_at = days.days.ago
  
  Product.create!(
    title: title,
    price: 100,
    description: "Product posted #{days} days ago.",
    category: Product::CATEGORIES.first,
    listing_type: 'sale',
    status: :available,
    flagged: false,
    user: user,
    created_at: created_at
  )
end

Given('the seller {string} has a product {string} posted {int} day ago') do |email, title, days|
  user = User.find_by(email: email.downcase)
  created_at = days.day.ago
  
  Product.create!(
    title: title,
    price: 100,
    description: "Product posted #{days} day ago.",
    category: Product::CATEGORIES.first,
    listing_type: 'sale',
    status: :available,
    flagged: false,
    user: user,
    created_at: created_at
  )
end

Then('{string} should appear before {string} on the page') do |text1, text2|
  body = page.body
  pos1 = body.index(text1)
  pos2 = body.index(text2)
  
  expect(pos1).not_to be_nil
  expect(pos2).not_to be_nil
  expect(pos1 < pos2).to be true
end
