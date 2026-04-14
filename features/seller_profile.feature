@seller_profile
Feature: Seller Profile
  As a buyer
  I want to view seller profiles with their available products
  So that I can see what items they're selling

  Background:
    Given a registered user exists with email "seller@link.cuhk.edu.hk" and password "password123" and is verified

  Scenario: View seller profile with available products
    Given the seller "seller@link.cuhk.edu.hk" has the following available products:
      | title          | price | description                    |
      | Laptop         | 800   | A great laptop in condition   |
      | Phone          | 500   | A modern smartphone            |
    And the seller has sold products not visible in the profile
    When I visit the seller profile for "seller@link.cuhk.edu.hk"
    Then I should see "Laptop"
    And I should see "Phone"
    And I should see "800"
    And I should see "500"

  Scenario: View empty seller profile
    When I visit the seller profile for "seller@link.cuhk.edu.hk"
    Then I should be on the seller profile page
    And the seller has no available products displayed

  Scenario: Seller profile displays products in reverse chronological order
    Given the seller "seller@link.cuhk.edu.hk" has a product "Old Laptop" posted 2 days ago
    And the seller "seller@link.cuhk.edu.hk" has a product "New Phone" posted 1 day ago
    When I visit the seller profile for "seller@link.cuhk.edu.hk"
    Then "New Phone" should appear before "Old Laptop" on the page
