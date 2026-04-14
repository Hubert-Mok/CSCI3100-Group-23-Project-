Feature: Product search
  As a CUHK marketplace user
  In order to find listings quickly
  I want to search the marketplace by title and description

  Background:
    Given the following products exist:
      | Title        | Description                        |
      | Used Laptop  | Reliable laptop with 8GB RAM       |
      | Desk Chair   | Comfortable study chair for desks  |
      | Gaming Mouse | Wireless mouse for gaming          |

  Scenario: Search returns exact matches
    Given I am on the marketplace page
    When I search for "Laptop"
    Then I should see a product titled "Used Laptop"
    And I should not see a product titled "Desk Chair"
    And I should not see a product titled "Gaming Mouse"

  Scenario: Fuzzy search returns near matches
    Given I am on the marketplace page
    When I search for "Laptpo"
    Then I should see a product titled "Used Laptop"
    And I should not see a product titled "Desk Chair"

  Scenario: Search is case insensitive
    Given I am on the marketplace page
    When I search for "laptop"
    Then I should see a product titled "Used Laptop"

  Scenario: Search returns partial matches in description
    Given I am on the marketplace page
    When I search for "RAM"
    Then I should see a product titled "Used Laptop"

  Scenario: Search with no results shows empty state
    Given I am on the marketplace page
    When I search for "Nonexistent"
    Then I should not see a product titled "Used Laptop"
    And I should not see a product titled "Desk Chair"
    And I should not see a product titled "Gaming Mouse"

