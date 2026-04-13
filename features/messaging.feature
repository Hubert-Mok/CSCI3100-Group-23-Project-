Feature: Messaging System
  As a marketplace user
  In order to communicate about products
  I want to send and receive messages in conversations

  Background:
    Given I am on the home page
    And a seller user exists with email "seller@link.cuhk.edu.hk" and password "password123"
    And a buyer user exists with email "buyer@link.cuhk.edu.hk" and password "password123"
    And the seller has a product listed with title "Used Laptop" and price "500"

  Scenario: Buyer sends a message in conversation
    Given a conversation exists between buyer and seller about "Used Laptop"
    When I sign in as "buyer@link.cuhk.edu.hk" with password "password123"
    And I go to the conversation
    And I fill in the message body with "Is this laptop still available?"
    And I click "Send"
    Then I should see "Is this laptop still available?" in the conversation

  Scenario: Both users can see conversation history
    Given a conversation exists between buyer and seller about "Used Laptop"
    And the buyer has sent a message "Is this laptop new?"
    And the seller has sent a reply "It's 1 year old"
    When I sign in as "buyer@link.cuhk.edu.hk" with password "password123"
    And I go to the conversation
    Then I should see "Is this laptop new?" in the conversation
    And I should see "It's 1 year old" in the conversation

  Scenario: Unauthorized users cannot access conversation
    Given a conversation exists between buyer and seller about "Used Laptop"
    And another user exists with email "other@link.cuhk.edu.hk" and password "password123"
    When I sign in as "other@link.cuhk.edu.hk" with password "password123"
    And I try to access the conversation
    Then I should see "You are not authorized"

