# Step definitions for email_verification.feature

Before do
  @previous_queue_adapter = ActiveJob::Base.queue_adapter
  ActiveJob::Base.queue_adapter = :inline
  ActionMailer::Base.deliveries.clear
  @users = {}
end

After do
  ActiveJob::Base.queue_adapter = @previous_queue_adapter if defined?(@previous_queue_adapter)
end

def verification_user
  @current_user || @users.values.last
end

Given('the following CUHK colleges exist in the system') do |_table|
  # Colleges are defined in User::COLLEGES.
end

Given('a user exists with email {string} and unverified status') do |email|
  @current_user = @users[email] = User.create!(
    email: email,
    password: 'password123',
    password_confirmation: 'password123',
    cuhk_id: SecureRandom.hex(4),
    username: email.split('@').first,
    college_affiliation: User::COLLEGES.first
  )
end

Given('a user exists with email {string} with password {string} and unverified status') do |email, password|
  @current_user = @users[email] = User.create!(
    email: email,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: email.split('@').first,
    college_affiliation: User::COLLEGES.first
  )
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
  @current_user = @users[email] = user
end

When('I visit the sign up page') do
  visit '/sign_up'
end

When('I submit the registration form with:') do |table|
  attributes = table.rows_hash

  fill_in 'Email', with: attributes['email']
  fill_in 'CUHK Student ID', with: attributes['cuhk_id']
  fill_in 'Username', with: attributes['username']
  select attributes['college_affiliation'], from: 'College'
  fill_in 'Password', with: attributes['password']
  fill_in 'Confirm Password', with: attributes['password_confirmation']

  click_button 'Create Account'
end

When('the user generates an email verification token') do
  @current_user = verification_user
  @raw_token = @current_user.generate_email_verification_token!
end

When('the user with email {string} generates an email verification token') do |email|
  @current_user = @users.fetch(email)
  @raw_token = @current_user.generate_email_verification_token!
end

When('I visit the email verification link with that token') do
  visit "/email_verification?token=#{CGI.escape(@raw_token)}"
end

When('I visit the email verification link for {string} using that token') do |email|
  @target_user = @users.fetch(email)
  visit "/email_verification?token=#{CGI.escape(@raw_token)}"
end

When('I visit the email verification page with an invalid token {string}') do |token|
  visit "/email_verification?token=#{CGI.escape(token)}"
end

When('I mark the verification token as expired') do
  verification_user.update_columns(email_verification_sent_at: 2.hours.ago)
end

When('I visit the email verification page') do
  visit '/email_verification/new'
end

When('I visit the email verification page with email {string}') do |email|
  visit "/email_verification/new?email=#{CGI.escape(email)}"
end

When('I enter the email {string}') do |email|
  fill_in 'School email address', with: email
end

When('I submit the resend form') do
  click_button 'Resend verification email'
end

When('I visit the sign in page') do
  visit '/sign_in'
end

When('I enter the credentials:') do |table|
  credentials = table.rows_hash
  fill_in 'Email', with: credentials['email']
  fill_in 'Password', with: credentials['password']
end

When('I submit the sign in form') do
  click_button 'Sign In'
end

Then('the email verification notice should say {string}') do |text|
  expect(page).to have_content(text)
end

Then('the email verification alert should say {string}') do |text|
  expect(page).to have_content(text)
end

Then('the email verification page should be on the sign in page') do
  expect(page).to have_current_path('/sign_in')
end

Then('the email verification page should be on the home page') do
  expect(page).to have_current_path('/')
end

Then('I should be signed in') do
  expect(page).to have_content('Signed in successfully')
end

Then('I should not be signed in') do
  expect(page).not_to have_content('Signed in successfully')
end

Then('my email should be verified') do
  verification_user.reload
  expect(verification_user.email_verified?).to be true
end

Then('the user with email {string} should not be verified') do |email|
  expect(@users.fetch(email).reload.email_verified?).to be false
end

Then('a verification email should be sent to {string}') do |email|
  expect(ActionMailer::Base.deliveries.any? { |message| message.to&.include?(email) }).to be true
end

Then('a new verification email should be sent to {string}') do |email|
  expect(ActionMailer::Base.deliveries.any? { |message| message.to&.include?(email) }).to be true
end

Then('a verification email should be sent to the lowercase email') do
  email = @users.values.last.email.downcase
  expect(ActionMailer::Base.deliveries.any? { |message| message.to&.include?(email) }).to be true
end

Then('the email field should be pre-filled with {string}') do |email|
  expect(find_field('School email address').value).to eq(email)
end

Then('the token digest should not be {string}') do |plain_value|
  verification_user.reload
  expect(verification_user.email_verification_token_digest).not_to eq(plain_value)
end

Then('the token digest should be present in the database') do
  verification_user.reload
  expect(verification_user.email_verification_token_digest).to be_present
end
