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
