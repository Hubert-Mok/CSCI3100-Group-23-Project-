Feature: Product search
  As a CUHK marketplace user
  In order to find listings quickly
  I want to search the marketplace by title and description

  Background:
    Given the following products exist:
      | Title        | Description                        |
      | Used Laptop  | Reliable laptop with 8GB RAM       |
      | Desk Chair   | Comfortable study chair for desks  |

  Scenario: Search returns exact matches
    Given I am on the marketplace page
    When I search for "Laptop"
    Then I should see a product titled "Used Laptop"
    And I should not see a product titled "Desk Chair"

  Scenario: Fuzzy search returns near matches
    Given I am on the marketplace page
    When I search for "Laptpo"
    Then I should see a product titled "Used Laptop"
