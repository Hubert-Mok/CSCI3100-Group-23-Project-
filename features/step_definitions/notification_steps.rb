Given('the following notifications exist:') do |table|
  table.hashes.each do |row|
    user = User.find_by(email: row['Email'].downcase)
    raise "User not found: #{row['Email']}" unless user

    product = Product.find_or_create_by!(title: "Notification test product") do |product|
      product.description = "Test product for notifications"
      product.price = 1
      product.category = Product::CATEGORIES.first
      product.listing_type = 'sale'
      product.status = :available
      product.user = user
    end

    Notification.create!(
      user: user,
      product: product,
      message: row['Message'],
      read: row['Read'].to_s.casecmp('true').zero?
    )
  end
end

Then('I should see {string} within {string}') do |text, selector|
  within(selector, visible: :all) do
    expect(page).to have_content(text)
  end
end

Then('I should see a notification with message {string}') do |message|
  expect(page).to have_content(message)
end

Then('I should not see a notification with message {string}') do |message|
  expect(page).not_to have_content(message)
end

Then('the notification badge should be hidden') do
  badge = page.find('#notification_badge', visible: :all)
  expect(badge[:style]).to include('display: none')
end

When('I click the {string} button') do |button_text|
  click_button(button_text, visible: :all)
end

When('I visit the notifications page') do
  visit '/notifications'
end

When('I delete the notification with message {string}') do |message|
  notification = Notification.find_by!(message: message)
  page.driver.submit :delete, "/notifications/#{notification.id}", {}
  visit '/notifications'
end

When('I mark the notification with message {string} as read') do |message|
  notification = Notification.find_by!(message: message)
  page.driver.submit :patch, "/notifications/#{notification.id}", {}
  visit '/notifications'
end

Then('the notification with message {string} should be marked as read') do |message|
  notification = Notification.find_by!(message: message)
  expect(notification.read).to be(true)
end
