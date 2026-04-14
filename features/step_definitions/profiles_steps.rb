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
  expect(page).to have_current_path("/profile/edit")
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
