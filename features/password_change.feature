@password_change
Feature: Password Change
  As a logged-in user
  I want to change my password
  So that I can update my account security

  Scenario: User can access password change form
    Given a registered user exists with email "user_pwd@link.cuhk.edu.hk" and password "password123" and is verified
    When I am logged in as a verified user with email "user_pwd@link.cuhk.edu.hk"
    And I visit the edit password page
    Then I should see "Change Password"

  Scenario: User can change password with correct current password
    Given a registered user exists with email "user_pwd2@link.cuhk.edu.hk" and password "password123" and is verified
    When I am logged in as a verified user with email "user_pwd2@link.cuhk.edu.hk"
    And I visit the edit password page
    And I fill in "Current Password" with "password123"
    And I fill in "New Password" with "NewPassword123"
    And I fill in "Confirm New Password" with "NewPassword123"
    And I press "Update Password"
    Then I should see "Password updated successfully."
    And I should be on the profile page

  Scenario: User cannot change password with incorrect current password
    Given a registered user exists with email "user_pwd3@link.cuhk.edu.hk" and password "password123" and is verified
    When I am logged in as a verified user with email "user_pwd3@link.cuhk.edu.hk"
    And I visit the edit password page
    And I fill in "Current Password" with "WrongPassword123"
    And I fill in "New Password" with "NewPassword123"
    And I fill in "Confirm New Password" with "NewPassword123"
    And I press "Update Password"
    Then I should see "Current password is incorrect."
    And I should be on the edit password page

  Scenario: User cannot change password with mismatched confirmation
    Given a registered user exists with email "user_pwd4@link.cuhk.edu.hk" and password "password123" and is verified
    When I am logged in as a verified user with email "user_pwd4@link.cuhk.edu.hk"
    And I visit the edit password page
    And I fill in "Current Password" with "password123"
    And I fill in "New Password" with "NewPassword123"
    And I fill in "Confirm New Password" with "DifferentPassword123"
    And I press "Update Password"
    Then I should see "doesn't match"
    And I should be on the edit password page
