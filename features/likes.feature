Feature: Like System
  As a marketplace user
  In order to save products I'm interested in
  I want to like and unlike products

  Background:
    Given I am on the home page
    And a seller user exists with email "seller@link.cuhk.edu.hk" and password "password123"
    And the seller has a product listed with title "Used Laptop" and price "500"
    And a buyer user exists with email "buyer@link.cuhk.edu.hk" and password "password123"

  Scenario: Buyer can like a product
    When I sign in as "buyer@link.cuhk.edu.hk" with password "password123"
    And I navigate to the product "Used Laptop"
    And I click "Like"
    Then I should see "Added to your liked items"
    And the product should have 1 like

  Scenario: Buyer can unlike a product
    Given the buyer has liked the product "Used Laptop"
    When I sign in as "buyer@link.cuhk.edu.hk" with password "password123"
    And I navigate to the product "Used Laptop"
    And I click "Unlike"
    Then I should see "Removed from your liked items"
    And the product should have 0 likes

  Scenario: Unauthenticated user cannot like products
    When I navigate to the product "Used Laptop"
    And I try to like the product
    Then I should be redirected to sign in page

  Scenario: Buyer cannot like the same product twice
    Given the buyer has liked the product "Used Laptop"
    When I sign in as "buyer@link.cuhk.edu.hk" with password "password123"
    And I navigate to the product "Used Laptop"
    And I try to like the product again
    Then I should see "Could not like this item."
    And the product should have 1 like

  Scenario: Buyer cannot unlike a product that was not liked
    When I sign in as "buyer@link.cuhk.edu.hk" with password "password123"
    And I navigate to the product "Used Laptop"
    And I try to unlike the product without liking it first
    Then I should see "Could not unlike this item."
    And the product should have 0 likes

  Scenario: Unauthenticated user cannot unlike products
    Given the buyer has liked the product "Used Laptop"
    When I navigate to the product "Used Laptop"
    And I try to unlike the product while signed out
    Then I should be redirected to sign in page

  Scenario: Seller cannot like their own product
    When I sign in as "seller@link.cuhk.edu.hk" with password "password123"
    And I navigate to the product "Used Laptop"
    And I try to like my own product directly
    Then I should see "You cannot like your own listing."
    And the product should have 0 likes

