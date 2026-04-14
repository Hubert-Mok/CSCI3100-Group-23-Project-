Given('a seller user exists with email {string} and password {string}') do |email, password|
  @seller = User.create!(
    email: email.downcase,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: 'Seller User',
    college_affiliation: User::COLLEGES.first
  )
  @seller.verify_email!
end

Given('a buyer user exists with email {string} and password {string}') do |email, password|
  @buyer = User.create!(
    email: email.downcase,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: 'Buyer User',
    college_affiliation: User::COLLEGES.first
  )
  @buyer.verify_email!
end

Given('another user exists with email {string} and password {string}') do |email, password|
  @other_user = User.create!(
    email: email.downcase,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: 'Other User',
    college_affiliation: User::COLLEGES.first
  )
  @other_user.verify_email!
end

Given('the seller has a product listed with title {string} and price {string}') do |title, price|
  @product = Product.create!(
    user: @seller,
    title: title,
    description: 'This is a high quality product that works perfectly',
    price: price,
    category: Product::CATEGORIES.first,
    listing_type: 'sale',
    status: :available
  )
end

When('I sign in as {string} with password {string}') do |email, password|
  visit '/sign_in'
  fill_in 'Email', with: email
  fill_in 'Password', with: password
  click_button 'Sign In'
end

When('I search for a product {string}') do |search_term|
  fill_in 'search', with: search_term
  click_button 'Search'
end

When('I view the product details') do
  click_link @product.title
end

When('I go to the conversation') do
  visit "/conversations/#{@conversation.id}"
end

When('I fill in the message body with {string}') do |message_body|
  fill_in 'message[body]', with: message_body
  @last_message_body = message_body
end

When('I click {string} without filling in message body') do |button_text|
  click_button button_text
end

When('I try to access the conversation') do
  visit "/conversations/#{@conversation.id}"
end

Given('a conversation exists between buyer and seller about {string}') do |product_title|
  @conversation = Conversation.create!(
    product: @product,
    buyer: @buyer,
    seller: @seller
  )
end

Given('the buyer has sent a message {string}') do |message_text|
  @buyer_message = Message.create!(
    conversation: @conversation,
    user: @buyer,
    body: message_text
  )
end

Given('the seller has sent a reply {string}') do |message_text|
  Message.create!(
    conversation: @conversation,
    user: @seller,
    body: message_text
  )
end

Then('a notification should be created for the seller') do
  expect(Notification.where(user: @seller)).to exist
end

Then('the notification should contain {string}') do |notification_text|
  notification = Notification.where(user: @seller).last
  expect(notification.message).to include(notification_text)
end

Then('no message should be created') do
  expect(Message.where(user: @buyer, conversation: @conversation).count).to eq(0)
end

Then('I should see {string} in the conversation') do |message_text|
  expect(page).to have_content(message_text)
end

Then('I should be on the conversation page') do
  expect(current_path).to eq("/conversations/#{@conversation.id}")
end

Then('I should be on a conversation page') do
  expect(current_path).to match(%r{\A/conversations/\d+\z})
end

Then('I should be redirected to home page') do
  expect(current_path).to eq("/")
end

When('I open the conversation page directly without signing in') do
  visit "/conversations/#{@conversation.id}"
end

Then('I should be redirected to the sign-in page') do
  expect(current_path).to eq('/sign_in')
end

When('I submit an empty message in the conversation') do
  fill_in 'message[body]', with: ''
  click_button 'Send'
end

When('I delete the flagged message from the moderation queue') do
  rows = all('table tbody tr')
  row = rows.find { |r| r.has_content?(@flagged_message.body) }
  raise 'Could not find flagged message row' unless row

  row.find('button', text: 'Delete').click
end

Then('the flagged message should be deleted') do
  expect(Message.exists?(@flagged_message.id)).to be(false)
end

When('I submit a direct message create request with body {string}') do |message_body|
  page.driver.submit :post,
                     "/conversations/#{@conversation.id}/messages",
                     { message: { body: message_body } }
end

When('I submit a direct conversation create request for the listed product') do
  page.driver.submit :post, '/conversations', { product_id: @product.id }
end

When('I visit the messages inbox') do
  visit '/conversations'
end

Given('the conversation is marked deleted for buyer') do
  @conversation.update!(buyer_deleted_at: Time.current)
end

When('I submit a direct delete request for the buyer message in the conversation') do
  page.driver.submit :delete,
                     "/conversations/#{@conversation.id}/messages/#{@buyer_message.id}",
                     {}
end
