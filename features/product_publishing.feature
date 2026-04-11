Feature: Publishing a product
  As a seller
  I want to publish a product listing
  So that buyers can discover and potentially purchase my items

  Background:
    Given there is a registered user with email "seller@link.cuhk.edu.hk" and password "Password123"
    And the user's email is verified

  Scenario: Successfully publish a product for sale
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I am on the new product page
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Used Laptop              |
      | Description | A high-performance laptop in great condition with 16GB RAM and SSD storage. Perfect for students and professionals. |
      | Price       | 500                      |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
    And I submit the product form
    Then the product should be published successfully
    And I should see "Listing published successfully!"
    And the product should have status "available"
    And the product should be listed on the market

  Scenario: Successfully publish a product as a gift
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I am on the new product page
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Free Books Bundle        |
      | Description | A collection of classic novels in excellent condition. First come, first served basis for anyone interested. |
      | Price       | 0                        |
      | Category    | Books & Notes            |
      | Listing Type| Gift                     |
    And I submit the product form
    Then the product should be published successfully
    And I should see "Listing published successfully!"
    And the product should have status "available"
    And the product should be listed on the market

  Scenario: Fail to publish product with invalid title
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I am on the new product page
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | OK                       |
      | Description | A high-performance laptop in great condition with 16GB RAM and SSD storage. Perfect for students and professionals. |
      | Price       | 500                      |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
    And I submit the product form
    Then the product publishing should fail
    And I should see an error about the title

  Scenario: Fail to publish product with invalid price for sale
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I am on the new product page
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Used Book                |
      | Description | A high-performance laptop in great condition with 16GB RAM and SSD storage. Perfect for students and professionals. |
      | Price       | 0                        |
      | Category    | Books & Notes            |
      | Listing Type| Sale                     |
    And I submit the product form
    Then the product publishing should fail
    And I should see an error about the price

  Scenario: Fail to publish product with invalid price for gift
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I am on the new product page
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Free Monitor             |
      | Description | A high-performance laptop in great condition with 16GB RAM and SSD storage. Perfect for students and professionals. |
      | Price       | 50                       |
      | Category    | Electronics              |
      | Listing Type| Gift                     |
    And I submit the product form
    Then the product publishing should fail
    And I should see an error about the price

  Scenario: Fail to publish product with description too short
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I am on the new product page
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Used Phone               |
      | Description | Too short                |
      | Price       | 300                      |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
    And I submit the product form
    Then the product publishing should fail
    And I should see an error about the description

  Scenario: Cannot publish product without logging in
    Given I am on the new product page
    Then I should be redirected to the login page

  Scenario: Cannot publish product without verified email
    Given there is a registered user with email "unverified@link.cuhk.edu.hk" and password "Password123"
    And the user's email is not verified
    And I am logged in as "unverified@link.cuhk.edu.hk"
    When I try to visit the new product page
    Then I should be redirected away from the new product page
