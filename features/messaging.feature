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

  Scenario: Signed-out users are redirected when opening a conversation
    Given a conversation exists between buyer and seller about "Used Laptop"
    When I open the conversation page directly without signing in
    Then I should be redirected to the sign-in page
    And I should see "You must be signed in to access that page."

  Scenario: Blank message body is rejected
    Given a conversation exists between buyer and seller about "Used Laptop"
    When I sign in as "buyer@link.cuhk.edu.hk" with password "password123"
    And I go to the conversation
    And I submit an empty message in the conversation
    Then no message should be created

  Scenario: Admin can delete a flagged message from moderation dashboard
    Given an admin account exists with email "admin@link.cuhk.edu.hk" and password "password123"
    And a flagged message exists for moderation
    When I sign in as admin with email "admin@link.cuhk.edu.hk" and password "password123"
    And I visit the admin moderation dashboard
    And I delete the flagged message from the moderation queue
    Then I should see "Message deleted successfully"
    And the flagged message should be deleted

  Scenario: Seller can send a reply in conversation
    Given a conversation exists between buyer and seller about "Used Laptop"
    When I sign in as "seller@link.cuhk.edu.hk" with password "password123"
    And I go to the conversation
    And I fill in the message body with "Yes, still available"
    And I click "Send"
    Then I should see "Yes, still available" in the conversation

  Scenario: Unauthorized user cannot send message in conversation
    Given a conversation exists between buyer and seller about "Used Laptop"
    And another user exists with email "intruder@link.cuhk.edu.hk" and password "password123"
    When I sign in as "intruder@link.cuhk.edu.hk" with password "password123"
    And I submit a direct message create request with body "Intruding"
    Then I should be redirected to home page
    And I should see "You are not authorized to view that conversation."

  Scenario: Buyer can start a chat from product details
    When I sign in as "buyer@link.cuhk.edu.hk" with password "password123"
    And I view the product details
    And I click "💬 Chat with Seller"
    Then I should be on a conversation page

  Scenario: Seller cannot start chat with own listing
    When I sign in as "seller@link.cuhk.edu.hk" with password "password123"
    And I submit a direct conversation create request for the listed product
    Then I should see "You cannot start a chat with yourself on your own listing."

  Scenario: User can view messages inbox list
    Given a conversation exists between buyer and seller about "Used Laptop"
    When I sign in as "buyer@link.cuhk.edu.hk" with password "password123"
    And I visit the messages inbox
    Then I should see "Messages"
    And I should see "Used Laptop"

  Scenario: Deleted conversation cannot be opened
    Given a conversation exists between buyer and seller about "Used Laptop"
    And the conversation is marked deleted for buyer
    When I sign in as "buyer@link.cuhk.edu.hk" with password "password123"
    And I go to the conversation
    Then I should see "That conversation was deleted."

  Scenario: Participant can delete chat from conversation page
    Given a conversation exists between buyer and seller about "Used Laptop"
    When I sign in as "buyer@link.cuhk.edu.hk" with password "password123"
    And I go to the conversation
    And I click "Delete chat"
    Then I should see "Conversation deleted."
    And I should see "Messages"

  Scenario: Sender can delete own message via conversation route
    Given a conversation exists between buyer and seller about "Used Laptop"
    And the buyer has sent a message "Temporary message"
    When I sign in as "buyer@link.cuhk.edu.hk" with password "password123"
    And I submit a direct delete request for the buyer message in the conversation
    Then I should see "Message deleted"

