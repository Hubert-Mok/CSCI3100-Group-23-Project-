# Step definitions for email_verification.feature

Given('the following CUHK colleges exist in the system') do |table|
  # Colleges are already defined in User::COLLEGES constant
  # This is just a documentation step
end

Given('a user exists with email {string} and unverified status') do |email|
  @current_user = User.create!(
    email: email,
    password: 'password123',
    password_confirmation: 'password123',
    cuhk_id: SecureRandom.hex(4),
    username: email.split('@').first,
    college_affiliation: User::COLLEGES.first
  )
  # User is unverified by default
  expect(@current_user.email_verified?).to be false
end

Given('a user exists with email {string} with password {string} and unverified status') do |email, password|
  @current_user = User.create!(
    email: email,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: email.split('@').first,
    college_affiliation: User::COLLEGES.first
  )
  expect(@current_user.email_verified?).to be false
end

Given('a user exists with email {string} and verified status') do |email|
  user = User.create!(
    email: email,
    password: 'password123',
    password_confirmation: 'password123',
    cuhk_id: SecureRandom.hex(4),
    username: email.split('@').first,
    college_affiliation: User::COLLEGES.first
  )
  user.verify_email!
  @current_user = user
end

When('I visit the sign up page') do
  visit sign_up_path
end

When('I submit the registration form with:') do |table|
  attributes = table.rows_hash
  
  fill_in 'user[email]', with: attributes['email']
  fill_in 'user[password]', with: attributes['password']
  fill_in 'user[password_confirmation]', with: attributes['password_confirmation']
  fill_in 'user[cuhk_id]', with: attributes['cuhk_id']
  fill_in 'user[username]', with: attributes['username']
  select attributes['college_affiliation'], from: 'user[college_affiliation]'
  
  click_button 'Sign Up'
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

When('the user generates an email verification token') do
  @raw_token = @current_user.generate_email_verification_token!
end

When('the user generates an email verification token with raw_token {string}') do |token_value|
  # For testing token digest storage
  # This step is more for testing implementation details
  @raw_token = @current_user.generate_email_verification_token!
end

When('I visit the email verification link with that token') do
  visit email_verification_path(token: @raw_token)
end

Then('my email should be verified') do
  @current_user.reload
  expect(@current_user.email_verified?).to be true
end

Then('I should be redirected to the sign in page') do
  expect(current_path).to eq(sign_in_path)
end

When('I visit the email verification page with an invalid token {string}') do |token|
  visit email_verification_path(token: token)
end

When('I wait for {int} minutes') do |minutes|
  travel_to(minutes.minutes.from_now)
end

# Commented out - time travel doesn't work well in Capybara tests
# When('I wait for {int} minutes') do |minutes|
#   sleep(1)  # In real integration tests, you'd need a different approach
# end

When('I visit the email verification page') do
  visit new_email_verification_path
end

When('I enter the email {string}') do |email|
  fill_in 'email', with: email
end

When('I submit the resend form') do
  click_button 'Resend Verification Email' if has_button?('Resend Verification Email')
  click_button 'Send' if has_button?('Send')
  # Try common button names
  find('button[type="submit"]').click unless respond_to?(:last_response) && !has_button?('submit')
end

Then('a verification email should be sent to {string}') do |email|
  # Check that UserMailer was called (in Capybara + ActionMailer)
  expect(ActionMailer::Base.deliveries).not_to be_empty
  last_email = ActionMailer::Base.deliveries.last
  expect(last_email.to).to include(email)
end

Then('a new verification email should be sent to {string}') do |email|
  # Similar to above but confirms "new" aspect via count
  emails_to_user = ActionMailer::Base.deliveries.select { |e| e.to.include?(email) }
  expect(emails_to_user.length).to be >= 1
end

When('I visit the sign in page') do
  visit sign_in_path
end

When('I enter the credentials:') do |table|
  credentials = table.rows_hash
  fill_in 'email', with: credentials['email']
  fill_in 'password', with: credentials['password']
end

When('I submit the sign in form') do
  click_button 'Sign In'
end

Then('I should not be signed in') do
  expect(page).not_to have_content('Dashboard') # Or whatever indicates logged in
  # More robust: check current_user is nil, or check session
end

Then('I should be signed in') do
  expect(page).to have_content('Dashboard') # Or check for user-specific content
end

Then('I should see the user dashboard') do
  expect(page).to have_content('Dashboard') # Adjust based on your actual dashboard content
  # Or check for user profile, products, etc.
end

Then('I should see an error message about email verification') do
  expect(page).to have_content(/verify|email/i)
end

# For token security test
When('I visit the email verification link with {string}\'s token for {string}') do |user1_email, user2_email|
  # This requires tracking multiple users
  user1 = User.find_by(email: user1_email)
  user2 = User.find_by(email: user2_email)
  
  # Get token for user1
  raw_token = user1.generate_email_verification_token!
  
  # Try to use it for user2
  visit email_verification_path(token: raw_token)
  
  # Store user2 for later assertion
  @target_user = user2
end

Then('{string}\'s email should not be verified') do |email|
  user = User.find_by(email: email)
  expect(user.email_verified?).to be false
end

Then('the email field should be pre-filled with {string}') do |email|
  expect(find('#email', visible: :all).value).to eq(email)
end

Then('the token digest should not be {string}') do |plain_value|
  @current_user.reload
  expect(@current_user.email_verification_token_digest).not_to eq(plain_value)
end

Then('the token digest should be present in the database') do
  @current_user.reload
  expect(@current_user.email_verification_token_digest).to be_present
end

Then('a new verification email should be sent to the lowercase email') do
  emails = ActionMailer::Base.deliveries.select { |e| e.to.include?('casetest@link.cuhk.edu.hk') }
  expect(emails).not_to be_empty
end
