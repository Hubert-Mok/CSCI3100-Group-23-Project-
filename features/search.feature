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

  Scenario: Category filter returns only matching category
    Given the following detailed products exist:
      | Title         | Description                 | Category                | Status    | Price |
      | Calc Book     | Useful formulas for exams   | Books & Notes           | available | 30    |
      | Running Shoes | Good for daily training     | Sports & Fitness        | available | 200   |
      | Power Bank    | Fast charging battery pack  | Electronics             | available | 120   |
    Given I am on the marketplace page
    When I filter by category "Sports & Fitness"
    Then I should see a product titled "Running Shoes"
    And I should not see a product titled "Calc Book"
    And I should not see a product titled "Power Bank"

  Scenario: Status filter returns only sold products
    Given the following detailed products exist:
      | Title             | Description                 | Category      | Status    | Price |
      | Sold Notebook     | Already sold listing        | Books & Notes | sold      | 40    |
      | Available Monitor | Still available monitor     | Electronics   | available | 500   |
    Given I am on the marketplace page
    When I filter by status "sold"
    Then I should see a product titled "Sold Notebook"
    And I should not see a product titled "Available Monitor"

  Scenario: Sort by price high to low
    Given the following detailed products exist:
      | Title        | Description            | Category      | Status    | Price |
      | Cheap Cable  | sorttarget cable item  | Electronics   | available | 20    |
      | Mid Keyboard | sorttarget keyboard    | Electronics   | available | 200   |
      | Pro Tablet   | sorttarget tablet      | Electronics   | available | 800   |
    Given I am on the marketplace page
    And I search for "sorttarget"
    When I sort results by "Price: High → Low"
    Then I should see products in this order:
      | Title        |
      | Pro Tablet   |
      | Mid Keyboard |
      | Cheap Cable  |

  Scenario: Logged-in users do not see their own listings in search results
    Given the following detailed products exist:
      | Title                | Description               | Category      | Status    | Price | Seller Email                    |
      | My Hidden Listing    | Should be hidden from me  | Electronics   | available | 70    | search-seller@link.cuhk.edu.hk  |
      | Other User Listing   | Should still be visible   | Electronics   | available | 90    | another-searcher@link.cuhk.edu.hk |
    And I sign in as the search seller
    When I search for "Listing"
    Then I should not see a product titled "My Hidden Listing"
    And I should see a product titled "Other User Listing"

