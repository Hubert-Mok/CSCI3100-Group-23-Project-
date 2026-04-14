When('I visit the edit password page') do
  visit '/password/edit'
end

Then('I should be on the edit password page') do
  # Check either by path or by looking for the form heading
  has_path = page.current_path == '/password/edit'
  unless has_path
    expect(page).to have_text('Change Password')
  end
end

Then('I should be on the profile page') do
  expect(page).to have_current_path('/profile')
end
