Given('I am on the home page') do
  visit '/'
end

When('I visit the home page') do
  visit '/'
end

When('I visit the home page again') do
  visit '/'
end

When('I follow {string}') do |link_text|
  click_link_or_button(link_text)
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I select {string} from {string}') do |option, field|
  select option, from: field
end

When('I press {string}') do |button_text|
  click_button button_text
end

Given('a registered user exists with email {string} and password {string} and is verified') do |email, password|
  user = User.create!(
    email: email.downcase,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: 'Test User',
    college_affiliation: User::COLLEGES.first
  )
  user.verify_email!
end

Given('a registered user exists with email {string} and password {string} and is not verified') do |email, password|
  User.create!(
    email: email.downcase,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: 'Test User',
    college_affiliation: User::COLLEGES.first,
    email_verified_at: nil,
    email_verification_token_digest: nil,
    email_verification_sent_at: nil
  )
end

Given('I am logged in as a verified user with email {string}') do |email|
  user = User.find_by(email: email.downcase)
  unless user
    user = User.create!(
      email: email.downcase,
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Test User',
      college_affiliation: User::COLLEGES.first
    )
  end
  user.verify_email! unless user.email_verified?

  visit '/sign_in'
  fill_in 'Email', with: email
  fill_in 'Password', with: 'password123'
  click_button 'Sign In'
end

Then('I should be on the {string} page') do |page_name|
  expected_path = case page_name
                  when 'home' then '/'
                  when 'sign up' then '/sign_up'
                  when 'sign in' then '/sign_in'
                  when 'email verification' then '/email_verification/new'
                  else
                    raise "Unknown page name: #{page_name}"
                  end
  expect(page).to have_current_path(expected_path)
end

Then('I should be on the email verification page') do
  expect(page).to have_current_path('/email_verification/new', ignore_query: true)
end

Then('I should see the account created message') do
  unless page.has_content?("Account created!")
    puts "\n=== DEBUG: Page Content ===\n#{page.text[0..800]}\n=== END DEBUG ===" 
  end
  expect(page).to have_content("Account created!")
end

Then('I should be on the sign up page') do
  expect(page).to have_current_path('/sign_up')
end

Then('I should be on the home page') do
  expect(page).to have_current_path('/')
end

Then('I should be on the sign in page') do
  expect(page).to have_current_path('/sign_in')
end
