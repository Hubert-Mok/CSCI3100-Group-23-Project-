Feature: User Profile Management
  As a marketplace user
  In order to manage my profile
  I want to view and update my user information

  Background:
    Given I am logged in as a verified user with email "user@link.cuhk.edu.hk"

  Scenario: View profile page
    When I navigate to my profile
    Then I should see my profile page
    And I should see my username

  Scenario: Edit profile page loads
    When I navigate to edit profile
    Then I should see the edit profile form
    And I should see the username field

  Scenario: Update profile with valid details
    When I navigate to edit profile
    And I update my username to "newusername"
    And I update my email to "newemail@link.cuhk.edu.hk"
    And I submit the profile form
    Then I should see "Profile updated successfully."
    And I should be on my profile page

  Scenario: Update profile with only username
    When I navigate to edit profile
    And I update my username to "anotheruser"
    And I submit the profile form
    Then I should see "Profile updated successfully."

  Scenario: Signed-out user is redirected from profile page
    When I click the "Sign Out" button
    And I navigate to my profile
    Then I should be on the sign in page
    And I should see "You must be signed in to access that page."

  Scenario: Invalid profile update shows validation errors
    When I navigate to edit profile
    And I clear the username field in profile form
    And I submit the profile form
    Then I should see "prevented your profile from being saved"
    And I should see "Username can't be blank"
    And I should see the edit profile form

  Scenario: Duplicate email update is rejected
    Given another verified user exists for profile email conflict
    When I navigate to edit profile
    And I update my email to "existing_profile_user@link.cuhk.edu.hk"
    And I submit the profile form
    Then I should see "An account with this email already exists"
    And I should see the edit profile form

  Scenario: Non-CUHK email update is rejected
    When I navigate to edit profile
    And I update my email to "user@gmail.com"
    And I submit the profile form
    Then I should see "must be a CUHK school email"
    And I should see the edit profile form

  Scenario: Profile shows my listings and liked items
    Given I have listed a product titled "My Profile Item"
    And I have liked a product titled "Liked Profile Item"
    When I navigate to my profile
    Then I should see "My Listings"
    And I should see "My Profile Item"
    And I should see "My Likes"
    And I should see "Liked Profile Item"
