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
    Then the email verification notice should say "Account created"
    And the email verification notice should say "Please check your CUHK email to verify your account"

  Scenario: User verifies email with valid link
    Given a user exists with email "verify@link.cuhk.edu.hk" and unverified status
    When the user generates an email verification token
    And I visit the email verification link with that token
    Then my email should be verified
    And the email verification notice should say "Email verified"
    And the email verification page should be on the sign in page

  Scenario: User sees error with invalid verification link
    When I visit the email verification page with an invalid token "invalid-token-xyz"
      Then the email verification page should be on the sign in page

  Scenario: Verification link expires after 1 hour
    Given a user exists with email "expire@link.cuhk.edu.hk" and unverified status
    When the user generates an email verification token
      And I mark the verification token as expired
    And I visit the email verification link with that token
    Then the email verification alert should say "Verification link has expired"
    And a new verification email should be sent to "expire@link.cuhk.edu.hk"

  Scenario: User can resend verification email
    Given a user exists with email "resend@link.cuhk.edu.hk" and unverified status
    When I visit the email verification page
    And I enter the email "resend@link.cuhk.edu.hk"
    And I submit the resend form
    Then the email verification notice should say "A new verification email has been sent. Please check your inbox."
    And a verification email should be sent to "resend@link.cuhk.edu.hk"

  Scenario: Already verified user cannot verify again
    Given a user exists with email "already@link.cuhk.edu.hk" and verified status
    When the user generates an email verification token
    And I visit the email verification link with that token
    Then the email verification notice should say "Your email is already verified. Please sign in."
    And the email verification page should be on the sign in page

  Scenario: Generic message for non-existent email (security)
    When I visit the email verification page
    And I enter the email "nonexistent@link.cuhk.edu.hk"
    And I submit the resend form
    Then the email verification notice should say "If that email is registered and unverified, we've sent a new verification link."

  Scenario: Generic message for verified email (security)
    Given a user exists with email "verified@link.cuhk.edu.hk" and verified status
    When I visit the email verification page
    And I enter the email "verified@link.cuhk.edu.hk"
    And I submit the resend form
    Then the email verification notice should say "If that email is registered and unverified, we've sent a new verification link."

  Scenario: User cannot sign in without verified email
    Given a user exists with email "unverified@link.cuhk.edu.hk" and unverified status
    When I visit the sign in page
    And I enter the credentials:
      | field | value |
      | email | unverified@link.cuhk.edu.hk |
      | password | password123 |
    And I submit the sign in form
    Then the email verification alert should say "Please verify your email before signing in. Check your inbox or request a new link below."
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
    And the email verification page should be on the home page

  Scenario: Token is not valid for different user
    Given a user exists with email "user1@link.cuhk.edu.hk" and unverified status
    And a user exists with email "user2@link.cuhk.edu.hk" and unverified status
    When the user with email "user1@link.cuhk.edu.hk" generates an email verification token
    And I visit the email verification link for "user2@link.cuhk.edu.hk" using that token
    Then the user with email "user2@link.cuhk.edu.hk" should not be verified

  Scenario: Email address is case-insensitive for resend
    Given a user exists with email "casetest@link.cuhk.edu.hk" and unverified status
    When I visit the email verification page
    And I enter the email "CASETEST@LINK.CUHK.EDU.HK"
    And I submit the resend form
    Then the email verification notice should say "A new verification email has been sent. Please check your inbox."
    And a verification email should be sent to the lowercase email

  Scenario: Verification page shows pre-filled email from signup
    Given a user exists with email "pending@link.cuhk.edu.hk" and unverified status
    When I visit the email verification page with email "pending@link.cuhk.edu.hk"
    Then the email field should be pre-filled with "pending@link.cuhk.edu.hk"

  Scenario: Token digest is stored, not plain token
    Given a user exists with email "token@link.cuhk.edu.hk" and unverified status
    When the user generates an email verification token
    Then the token digest should not be "some_token_value"
    And the token digest should be present in the database
