Feature: Suspicious product moderation
  As a marketplace operator
  I want suspicious product listings to be flagged automatically
  So that risky listings are not shown publicly until reviewed

  Scenario: Suspicious listing is flagged and hidden from marketplace index
    Given a verified seller exists with email "seller_flag@link.cuhk.edu.hk" and password "Password123"
    When the seller creates a suspicious product listing
    Then the listing should be flagged for moderation
    And the listing status should be "pending"
    And the flagged listing should not appear on the marketplace index
