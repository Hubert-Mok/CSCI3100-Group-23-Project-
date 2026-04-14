When('I navigate to my profile') do
  visit "/profile"
end

When('I navigate to edit profile') do
  visit "/profile/edit"
end

Then('I should see my profile page') do
  expect(page).to have_current_path("/profile")
end

Then('I should see my username') do
  user = User.find_by(email: "user@link.cuhk.edu.hk")
  expect(page).to have_content(user.username)
end

Then('I should see the edit profile form') do
  expect(["/profile/edit", "/profile"]).to include(page.current_path)
  expect(page).to have_selector("form")
end

Then('I should see the username field') do
  expect(page).to have_field("user[username]")
end

When('I update my username to {string}') do |username|
  fill_in "user[username]", with: username
end

When('I update my email to {string}') do |email|
  fill_in "user[email]", with: email
end

When('I update my college affiliation to {string}') do |college|
  select college, from: "user[college_affiliation]"
end

When('I submit the profile form') do
  click_button "Save Changes"
end

Then('I should be on my profile page') do
  expect(page).to have_current_path("/profile")
end

When('I clear the username field in profile form') do
  fill_in 'user[username]', with: ''
end

Given('another verified user exists for profile email conflict') do
  user = User.find_by(email: 'existing_profile_user@link.cuhk.edu.hk')
  unless user
    user = User.create!(
      email: 'existing_profile_user@link.cuhk.edu.hk',
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Existing Profile User',
      college_affiliation: User::COLLEGES.first
    )
  end
  user.verify_email! unless user.email_verified?
end

Given('I have listed a product titled {string}') do |title|
  user = User.find_by!(email: 'user@link.cuhk.edu.hk')
  Product.create!(
    title: title,
    description: 'Profile listing description long enough',
    price: 100,
    user: user,
    category: Product::CATEGORIES.first,
    listing_type: 'sale',
    status: :available
  )
end

Given('I have liked a product titled {string}') do |title|
  user = User.find_by!(email: 'user@link.cuhk.edu.hk')
  owner = User.find_by(email: 'profile_like_owner@link.cuhk.edu.hk')
  unless owner
    owner = User.create!(
      email: 'profile_like_owner@link.cuhk.edu.hk',
      password: 'password123',
      password_confirmation: 'password123',
      cuhk_id: SecureRandom.hex(4),
      username: 'Profile Like Owner',
      college_affiliation: User::COLLEGES.first,
      email_verified_at: Time.current
    )
  end

  product = Product.create!(
    title: title,
    description: 'Liked product description long enough',
    price: 80,
    user: owner,
    category: Product::CATEGORIES.first,
    listing_type: 'sale',
    status: :available
  )

  Like.find_or_create_by!(user: user, product: product)
end
