Feature: User Authentication
  As a marketplace user
  In order to use the app
  I want to sign up and sign in safely

  Background:
    Given I am on the home page

  Scenario: Successful sign up with valid details
    When I follow "Sign Up"
    And I fill in "Email" with "testuser@link.cuhk.edu.hk"
    And I fill in "CUHK Student ID" with "1155123456"
    And I fill in "Username" with "testuser"
    And I select "Chung Chi College" from "College"
    And I fill in "Password" with "password123"
    And I fill in "Confirm Password" with "password123"
    And I press "Create Account"
    Then I should see "Account created! Please check your CUHK email to verify your account before signing in."
    And I should be on the email verification page

  Scenario: Unsuccessful sign up with mismatched passwords
    When I follow "Sign Up"
    And I fill in "Email" with "newuser@link.cuhk.edu.hk"
    And I fill in "CUHK Student ID" with "1155123456"
    And I fill in "Username" with "newuser"
    And I select "Chung Chi College" from "College"
    And I fill in "Password" with "password123"
    And I fill in "Confirm Password" with "wrongpassword"
    And I press "Create Account"
    Then I should see "Password confirmation doesn't match Password"
    And I should be on the sign up page

  Scenario: Successful sign in
    Given a registered user exists with email "user@link.cuhk.edu.hk" and password "password123" and is verified
    When I follow "Sign In"
    And I fill in "Email" with "user@link.cuhk.edu.hk"
    And I fill in "Password" with "password123"
    And I press "Sign In"
    Then I should see "Signed in successfully."
    And I should be on the home page

  Scenario: Unsuccessful sign in with wrong password
    Given a registered user exists with email "user@link.cuhk.edu.hk" and password "password123" and is verified
    When I follow "Sign In"
    And I fill in "Email" with "user@link.cuhk.edu.hk"
    And I fill in "Password" with "wrongpassword"
    And I press "Sign In"
    Then I should see "Invalid email or password."
    And I should be on the sign in page

  Scenario: Unsuccessful sign in with unverified email
    Given a registered user exists with email "unverified@link.cuhk.edu.hk" and password "password123" and is not verified
    When I follow "Sign In"
    And I fill in "Email" with "unverified@link.cuhk.edu.hk"
    And I fill in "Password" with "password123"
    And I press "Sign In"
    Then I should see "Please verify your email before signing in. Check your inbox or request a new link below."
    And I should be on the email verification page

  Scenario: Successful logout
    Given I am logged in as a verified user with email "user@link.cuhk.edu.hk"
    When I follow "Sign Out"
    Then I should see "Signed out successfully."
    And I should see "Sign In"
