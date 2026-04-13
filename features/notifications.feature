Feature: Notifications
  As a signed-in marketplace user
  In order to stay up to date on activity
  I want unread notifications to appear in the header and be clearable

  Background:
    Given a registered user exists with email "me@link.cuhk.edu.hk" and password "password123" and is verified
    And I am logged in as a verified user with email "me@link.cuhk.edu.hk"
    And the following notifications exist:
      | Email                   | Message                        | Read  |
      | me@link.cuhk.edu.hk     | New message from Alice         | false |
      | me@link.cuhk.edu.hk     | Your order is ready for pickup | false |

  Scenario: Notification badge count shows unread notifications
    When I visit the home page
    Then I should see "2" within "#notification_badge"
    And I should see a notification with message "New message from Alice"

  Scenario: Clear all notifications resets the badge and hides messages
    When I visit the home page
    And I click the "Clear all" button
    And I visit the home page again
    Then I should see "No notifications yet."
    And the notification badge should be hidden
    And I should not see a notification with message "New message from Alice"
