Feature: Purchasing products
  As a buyer
  I want to purchase products from sellers
  So that I can complete transactions on the marketplace

  Background:
    Given there is a registered user with email "seller@link.cuhk.edu.hk" and password "Password123"
    And the user's email is verified
    And the seller has connected a Stripe account
    And the seller has a product listed with title "Used Laptop" and price "500"
    And there is a registered user with email "buyer@link.cuhk.edu.hk" and password "Password123"
    And the buyer's email is verified

  Scenario: Successfully purchase a product
    Given I am logged in as "buyer@link.cuhk.edu.hk"
    When I visit the product page for "Used Laptop"
    And I click "Buy Now"
    Then I should be redirected to Stripe checkout
    And the order should be created with status "pending"

  Scenario: Cannot purchase own product
    Given I am logged in as "seller@link.cuhk.edu.hk"
    When I try to purchase the "Used Laptop" product
    Then I should see "You cannot purchase your own listing"
    And no order should be created

  Scenario: Cannot purchase unavailable product
    Given the "Used Laptop" product is sold
    And I am logged in as "buyer@link.cuhk.edu.hk"
    When I try to purchase the "Used Laptop" product
    Then I should see "This item is no longer available"

  Scenario: View order history
    Given I am logged in as "buyer@link.cuhk.edu.hk"
    And I have purchased the "Used Laptop" product
    When I visit my orders page
    Then I should see the order for "Used Laptop"

  Scenario: Confirm receipt of purchased item
    Given I am logged in as "buyer@link.cuhk.edu.hk"
    And I have a paid order for "Used Laptop"
    When I confirm receipt of the order
    Then the seller should receive payment
    And I should see "Thank you for confirming! The seller has been paid"