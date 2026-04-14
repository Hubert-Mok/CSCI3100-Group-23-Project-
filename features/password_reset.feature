@password_reset
Feature: Password Reset
  As a user
  I want to reset my password securely
  So that I can regain access to my account

  Scenario: Verified user can request a password reset link
    Given a password-reset verified user exists with email "reset_ok@link.cuhk.edu.hk" and password "password123"
    When I open the forgot password page
    And I submit forgot password email "reset_ok@link.cuhk.edu.hk"
    Then I should see password reset notice "If an account with that email exists, we've sent a password reset link. Please check your inbox."
    And password reset token should be generated for "reset_ok@link.cuhk.edu.hk"
    And password reset email should be delivered to "reset_ok@link.cuhk.edu.hk"

  Scenario: Unverified user gets generic response and no reset token
    Given a password-reset unverified user exists with email "reset_unverified@link.cuhk.edu.hk" and password "password123"
    When I open the forgot password page
    And I submit forgot password email "reset_unverified@link.cuhk.edu.hk"
    Then I should see password reset notice "If an account with that email exists, we've sent a password reset link. Please check your inbox."
    And password reset token should not be generated for "reset_unverified@link.cuhk.edu.hk"

  Scenario: Non-existent email gets generic response
    When I open the forgot password page
    And I submit forgot password email "unknown_user@link.cuhk.edu.hk"
    Then I should see password reset notice "If an account with that email exists, we've sent a password reset link. Please check your inbox."

  Scenario: Valid reset token opens reset form
    Given a password-reset verified user exists with email "token_valid@link.cuhk.edu.hk" and password "password123"
    And password reset token exists for "token_valid@link.cuhk.edu.hk"
    When I open password reset page with current token
    Then I should see reset password form

  Scenario: Invalid reset token redirects to forgot password page
    When I open password reset page with token "bad-token"
    Then I should be on forgot password page
    And I should see password reset alert "Password reset link is invalid or has expired. Please request a new one."

  Scenario: Expired reset token redirects to forgot password page
    Given a password-reset verified user exists with email "token_expired@link.cuhk.edu.hk" and password "password123"
    And password reset token exists for "token_expired@link.cuhk.edu.hk"
    And the password reset token for "token_expired@link.cuhk.edu.hk" is expired
    When I open password reset page with current token
    Then I should be on forgot password page
    And I should see password reset alert "Password reset link is invalid or has expired. Please request a new one."

  Scenario: User resets password successfully with valid token
    Given a password-reset verified user exists with email "reset_success@link.cuhk.edu.hk" and password "password123"
    And password reset token exists for "reset_success@link.cuhk.edu.hk"
    When I open password reset page with current token
    And I submit new password "newpassword123" and confirmation "newpassword123"
    Then I should be redirected to sign in page from password reset
    And I should see password reset notice "Password reset successfully. Please sign in with your new password."
    And user "reset_success@link.cuhk.edu.hk" can sign in with password "newpassword123"

  Scenario: User sees validation error when confirmation mismatches
    Given a password-reset verified user exists with email "reset_error@link.cuhk.edu.hk" and password "password123"
    And password reset token exists for "reset_error@link.cuhk.edu.hk"
    When I open password reset page with current token
    And I submit new password "newpassword123" and confirmation "different"
    Then I should remain on reset password page
    And I should see password reset validation errors
