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

  Scenario: Successfully publish a product with one decimal place price
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I am on the new product page
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Decimal Price Mouse      |
      | Description | A lightweight mouse with smooth tracking and silent clicks. |
      | Price       | 123.4                    |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
    And I submit the product form
    Then the product should be published successfully
    And the product should have price "123.4"
    And I should see product page price "HK$123.4"

  Scenario: Fail to publish product with too high price
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I am on the new product page
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Overpriced Car           |
      | Description | Extremely expensive listing used to validate max price checks. |
      | Price       | 1000000                  |
      | Category    | Others                   |
      | Listing Type| Sale                     |
    And I submit the product form
    Then the product publishing should fail
    And I should see "Price is too high (maximum is 999999.9)"

  Scenario: Fail to publish product with more than one decimal place
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I am on the new product page
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Invalid Decimal Keyboard |
      | Description | Listing used to verify decimal precision validation for prices. |
      | Price       | 123.45                   |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
    And I submit the product form
    Then the product publishing should fail
    And I should see "Price can have at most 1 decimal place"

  Scenario: Product image appears on home and product page after publishing
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I am on the new product page
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Photo Market Laptop      |
      | Description | Listing with image to verify image rendering in cards and detail page. |
      | Price       | 499.9                    |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
    And I attach product photo file "test-image.png"
    And I submit the product form
    Then the product should be published successfully
    And I sign out
    When I visit the marketplace home page
    Then I should see the product image for "Photo Market Laptop" in listing cards
    When I open the listing page for "Photo Market Laptop"
    Then I should see the product image on the product page

  Scenario: Seller sees Stripe prompt after publishing a sale listing without Stripe account
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I am on the new product page
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Budget Monitor           |
      | Description | A clean monitor with HDMI cable and stand included. |
      | Price       | 120                      |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
    And I submit the product form
    Then the product should be published successfully
    And I should see "Connect your Stripe account so buyers can use Buy Now and you can receive payments."
    And the product should have status "available"

  Scenario: Suspicious product listing is marked pending and needs admin approval
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I am on the new product page
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | suspicious laptop, contact via whatsapp 12345678 |
      | Description | Clean description for a normal looking listing. |
      | Price       | 100                      |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
    And I submit the product form
    Then the product should be published successfully
    And I should see "Listing created and pending admin approval."
    And the product should have status "pending"
    And I should not see "Connect your Stripe account so buyers can use Buy Now and you can receive payments."
    And I should not see "Connect with Stripe to receive payments"

  Scenario: Seller can update an existing sale listing
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I already have a published product listing titled "Used Laptop" with status "available"
    And I am on the edit listing page for "Used Laptop"
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Updated Laptop           |
      | Description | Updated description with a cleaner summary and more detail for buyers. |
      | Price       | 650                      |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
      | Status      | Sold                     |
    And I submit the product form
    Then I should see "Listing updated successfully!"
    And the product should have title "Updated Laptop"
    And the product should have status "sold"

  Scenario: Invalid edit keeps the listing on the edit form
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I already have a published product listing titled "Old Desk Lamp" with status "available"
    And I am on the edit listing page for "Old Desk Lamp"
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | OK                       |
      | Description | Updated description with enough length to be valid. |
      | Price       | 80                       |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
      | Status      | Available                |
    And I submit the product form
    Then the product publishing should fail
    And I should see an error about the title
    And the product should have title "Old Desk Lamp"

  Scenario: Seller uploads a photo while editing a listing
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I already have a published product listing titled "Photo Ready Lamp" with status "available"
    And I am on the edit listing page for "Photo Ready Lamp"
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Photo Ready Lamp         |
      | Description | Updated listing with a fresh photo for buyers to review. |
      | Price       | 120                      |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
      | Status      | Available                |
    And I attach product photo file "test-image.png"
    And I submit the product form
    Then I should see "Listing updated successfully!"
    And the product should have an attached photo
    When I am on the edit listing page for "Photo Ready Lamp"
    Then I should see "Current photo"

  Scenario: Seller replaces an existing photo while editing a listing
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I already have a published product listing titled "Photo Replace Lamp" with status "available"
    And the listing has existing product photo file "test-image.png"
    And I am on the edit listing page for "Photo Replace Lamp"
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Photo Replace Lamp       |
      | Description | Updated listing and replacing old photo with a new one. |
      | Price       | 140                      |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
      | Status      | Available                |
    And I attach product photo file "test-image-2.png"
    And I submit the product form
    Then I should see "Listing updated successfully!"
    And the product photo should be replaced

  Scenario: Seller keeps existing photo when updating without uploading a new one
    Given I am logged in as "seller@link.cuhk.edu.hk"
    And I already have a published product listing titled "Photo Keep Lamp" with status "available"
    And the listing has existing product photo file "test-image.png"
    And I am on the edit listing page for "Photo Keep Lamp"
    When I fill in the product form with:
      | Field       | Value                    |
      | Title       | Photo Keep Lamp          |
      | Description | Updated listing while keeping the currently attached photo. |
      | Price       | 160                      |
      | Category    | Electronics              |
      | Listing Type| Sale                     |
      | Status      | Available                |
    And I submit the product form
    Then I should see "Listing updated successfully!"
    And the product photo should remain unchanged

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
