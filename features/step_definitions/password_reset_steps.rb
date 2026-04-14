Before('@password_reset') do
  @previous_queue_adapter = ActiveJob::Base.queue_adapter
  ActiveJob::Base.queue_adapter = :inline
  ActionMailer::Base.deliveries.clear
  @password_reset_users = {}
  @current_reset_token = nil
  @current_reset_user = nil
end

After('@password_reset') do
  ActiveJob::Base.queue_adapter = @previous_queue_adapter if defined?(@previous_queue_adapter)
end

Given('a password-reset verified user exists with email {string} and password {string}') do |email, password|
  user = User.create!(
    email: email,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: email.split('@').first,
    college_affiliation: User::COLLEGES.first,
    email_verified_at: Time.current
  )

  @password_reset_users[email] = user
  @current_reset_user = user
end

Given('a password-reset unverified user exists with email {string} and password {string}') do |email, password|
  user = User.create!(
    email: email,
    password: password,
    password_confirmation: password,
    cuhk_id: SecureRandom.hex(4),
    username: email.split('@').first,
    college_affiliation: User::COLLEGES.first
  )

  @password_reset_users[email] = user
  @current_reset_user = user
end

When('I open the forgot password page') do
  visit '/password/forgot'
end

When('I submit forgot password email {string}') do |email|
  fill_in 'School email address', with: email
  click_button 'Send reset link'
end

Then('I should see password reset notice {string}') do |message|
  expect(page).to have_content(message)
end

Then('I should see password reset alert {string}') do |message|
  expect(page).to have_content(message)
end

Then('password reset token should be generated for {string}') do |email|
  user = @password_reset_users.fetch(email).reload
  expect(user.password_reset_token_digest).to be_present
  expect(user.password_reset_sent_at).to be_present
end

Then('password reset token should not be generated for {string}') do |email|
  user = @password_reset_users.fetch(email).reload
  expect(user.password_reset_token_digest).to be_nil
  expect(user.password_reset_sent_at).to be_nil
end

Then('password reset email should be delivered to {string}') do |email|
  delivered = ActionMailer::Base.deliveries.any? { |mail| mail.to&.include?(email) }
  expect(delivered).to be true
end

Given('password reset token exists for {string}') do |email|
  @current_reset_user = @password_reset_users.fetch(email)
  @current_reset_token = @current_reset_user.generate_password_reset_token!
end

Given('the password reset token for {string} is expired') do |email|
  user = @password_reset_users.fetch(email)
  user.update_columns(password_reset_sent_at: 31.minutes.ago)
end

When('I open password reset page with current token') do
  visit "/password/reset?token=#{CGI.escape(@current_reset_token)}"
end

When('I open password reset page with token {string}') do |token|
  visit "/password/reset?token=#{CGI.escape(token)}"
end

Then('I should be on forgot password page') do
  expect(page).to have_current_path('/password/forgot')
end

Then('I should see reset password form') do
  expect(page).to have_content('Set a new password')
  expect(page).to have_field('New password')
  expect(page).to have_field('Confirm new password')
end

When('I submit new password {string} and confirmation {string}') do |password, confirmation|
  fill_in 'New password', with: password
  fill_in 'Confirm new password', with: confirmation
  click_button 'Reset password'
end

When('I submit password reset update with token {string} password {string} and confirmation {string}') do |token, password, confirmation|
  page.driver.submit :patch, '/password/reset', {
    token: token,
    password: password,
    password_confirmation: confirmation
  }
end

Then('I should be redirected to sign in page from password reset') do
  expect(page).to have_current_path('/sign_in')
end

Then('user {string} can sign in with password {string}') do |email, password|
  visit '/sign_in'
  fill_in 'Email', with: email
  fill_in 'Password', with: password
  click_button 'Sign In'

  expect(page).to have_current_path('/')
  expect(page).to have_content('Signed in successfully')
end

Then('I should remain on reset password page') do
  expect(page).to have_current_path('/password/reset')
end

Then('I should see password reset validation errors') do
  expect(page).to have_css('.error-messages')
end
