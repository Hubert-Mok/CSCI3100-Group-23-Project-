Feature: Admin dashboard moderation
  As an admin
  I want to review and approve flagged listings
  So that safe listings can be published

  Background:
    Given an admin account exists with email "admin@link.cuhk.edu.hk" and password "Password123"
    And a flagged product exists for moderation

  Scenario: Admin can view flagged product on moderation queue
    Given I sign in as admin with email "admin@link.cuhk.edu.hk" and password "Password123"
    When I visit the admin moderation dashboard
    Then I should see the flagged product in the moderation queue

  Scenario: Admin approves a flagged product from moderation queue
    Given I sign in as admin with email "admin@link.cuhk.edu.hk" and password "Password123"
    When I visit the admin moderation dashboard
    And I approve the flagged product from the dashboard
    Then the product should be unflagged and available

  Scenario: Non-admin cannot access moderation dashboard
    Given a normal user exists with email "buyer@link.cuhk.edu.hk" and password "Password123"
    And I sign in as admin with email "buyer@link.cuhk.edu.hk" and password "Password123"
    When I visit the admin moderation dashboard
    Then I should be denied access to the moderation dashboard

  Scenario: Admin dashboard badge shows 99 plus for many flagged products
    Given 105 flagged products exist for moderation
    And I sign in as admin with email "admin@link.cuhk.edu.hk" and password "Password123"
    When I visit the home page
    Then I should see "99+"
