Feature: Email Verification
  As a new user
  I want to verify my email address
  So that I can sign in and access the marketplace

  Background:
    Given the following CUHK colleges exist in the system
      | name |
      | Chung Chi College |

  Scenario: User receives verification email upon signup
    When I visit the sign up page
    And I submit the registration form with:
      | field | value |
      | email | newuser@link.cuhk.edu.hk |
      | password | SecurePass123 |
      | password_confirmation | SecurePass123 |
      | cuhk_id | 1234567 |
      | username | New User |
      | college_affiliation | Chung Chi College |
    Then I should see "Account created"
    And I should see "Please check your CUHK email to verify your account"

  Scenario: User verifies email with valid link
    Given a user exists with email "verify@link.cuhk.edu.hk" and unverified status
    When the user generates an email verification token
    And I visit the email verification link with that token
    Then my email should be verified
    And I should see "Email verified"
    And I should be redirected to the sign in page

  Scenario: User sees error with invalid verification link
    When I visit the email verification page with an invalid token "invalid-token-xyz"
    Then I should see "Verification link is invalid"
    And I should be redirected to the sign in page

  Scenario: Verification link expires after 1 hour
    Given a user exists with email "expire@link.cuhk.edu.hk" and unverified status
    When the user generates an email verification token
    And I wait for 61 minutes
    And I visit the email verification link with that token
    Then I should see "Verification link has expired"
    And a new verification email should be sent to "expire@link.cuhk.edu.hk"

  Scenario: User can resend verification email
    Given a user exists with email "resend@link.cuhk.edu.hk" and unverified status
    When I visit the email verification page
    And I enter the email "resend@link.cuhk.edu.hk"
    And I submit the resend form
    Then I should see "new verification email has been sent"
    And a verification email should be sent to "resend@link.cuhk.edu.hk"

  Scenario: Already verified user cannot verify again
    Given a user exists with email "already@link.cuhk.edu.hk" and verified status
    When the user generates an email verification token
    And I visit the email verification link with that token
    Then I should see "already verified"
    And I should be redirected to the sign in page

  Scenario: Generic message for non-existent email (security)
    When I visit the email verification page
    And I enter the email "nonexistent@link.cuhk.edu.hk"
    And I submit the resend form
    Then I should see "If that email is registered"

  Scenario: Generic message for verified email (security)
    Given a user exists with email "verified@link.cuhk.edu.hk" and verified status
    When I visit the email verification page
    And I enter the email "verified@link.cuhk.edu.hk"
    And I submit the resend form
    Then I should see "If that email is registered"

  Scenario: User cannot sign in without verified email
    Given a user exists with email "unverified@link.cuhk.edu.hk" and unverified status
    When I visit the sign in page
    And I enter the credentials:
      | field | value |
      | email | unverified@link.cuhk.edu.hk |
      | password | password123 |
    And I submit the sign in form
    Then I should see an error message about email verification
    And I should not be signed in

  Scenario: User can sign in after email verification
    Given a user exists with email "verify_then_signin@link.cuhk.edu.hk" with password "password123" and unverified status
    When the user generates an email verification token
    And I visit the email verification link with that token
    And I visit the sign in page
    And I enter the credentials:
      | field | value |
      | email | verify_then_signin@link.cuhk.edu.hk |
      | password | password123 |
    And I submit the sign in form
    Then I should be signed in
    And I should see the user dashboard

  Scenario: Token is not valid for different user
    Given a user exists with email "user1@link.cuhk.edu.hk" and unverified status
    And a user exists with email "user2@link.cuhk.edu.hk" and unverified status
    When user1 generates an email verification token
    And I visit the email verification link with user1's token for user2
    Then user2's email should not be verified
    And I should see "invalid"

  Scenario: Email address is case-insensitive for resend
    Given a user exists with email "casetest@link.cuhk.edu.hk" and unverified status
    When I visit the email verification page
    And I enter the email "CASETEST@LINK.CUHK.EDU.HK"
    And I submit the resend form
    Then I should see "new verification email has been sent"
    And a verification email should be sent to the lowercase email

  Scenario: Verification page shows pre-filled email from signup
    Given a user exists with email "pending@link.cuhk.edu.hk" and unverified status
    When I visit the email verification page with email "pending@link.cuhk.edu.hk"
    Then the email field should be pre-filled with "pending@link.cuhk.edu.hk"

  Scenario: Token digest is stored, not plain token
    Given a user exists with email "token@link.cuhk.edu.hk" and unverified status
    When the user generates an email verification token with raw_token "some_token_value"
    Then the token digest should not be "some_token_value"
    And the token digest should be present in the database
