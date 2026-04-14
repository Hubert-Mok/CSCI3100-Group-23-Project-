@registration_form
Feature: Registration Form Access
  As a new user
  I want to access the sign up form
  So that I can create a new account

  Scenario: Unauthenticated user can access sign up form
    When I visit the sign up page
    Then I should see "Sign Up"
    And I should see "Email"
    And I should see "CUHK Student ID"
    And I should see "Username"
    And I should see "College"
    And I should see "Password"
    And I should see "Confirm Password"

  Scenario: Authenticated user is redirected away from sign up form
    Given a registered user exists with email "existing@link.cuhk.edu.hk" and password "password123" and is verified
    When I am logged in as a verified user with email "existing@link.cuhk.edu.hk"
    And I visit the sign up page
    Then I should be on the home page
    And I should see "You are already signed in."
