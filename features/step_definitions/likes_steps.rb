When('I navigate to the product {string}') do |product_title|
  @product = Product.find_by(title: product_title)
  visit "/products/#{@product.id}"
end

When('I try to like the product') do
  click_button 'Like'
end

When('I try to like the product again') do
  # The button currently shows "Unlike" since the buyer already likes the product
  # Try to post directly to the like endpoint again to test duplicate like prevention
  page.driver.post "/products/#{@product.id}/like"
  follow_redirect_after_direct_request
end

When('I try to unlike the product without liking it first') do
  page.driver.delete "/products/#{@product.id}/like"
  follow_redirect_after_direct_request
end

When('I try to unlike the product while signed out') do
  page.driver.delete "/products/#{@product.id}/like"
  follow_redirect_after_direct_request
end

Given('the buyer has liked the product {string}') do |product_title|
  @product = Product.find_by(title: product_title)
  Like.create!(user: @buyer, product: @product)
end

Then('the product should have {int} like(s)') do |count|
  @product.reload
  expect(@product.likes_count).to eq(count)
end

Then('I should see {string} displayed on the product') do |text|
  expect(page).to have_content(text)
end

Then('I should be redirected to sign in page') do
  expect(current_path).to eq('/sign_in')
end

def follow_redirect_after_direct_request
  location = page.driver.response_headers['Location']
  return visit(location) if location && !location.empty?

  visit "/products/#{@product.id}"
end
