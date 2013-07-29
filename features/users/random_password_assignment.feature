Feature: User Status
  Background:
    Given I am already logged in as "admin"
    Given there is a user named "bobby"

  Scenario: Existing user can be assigned a random password
    When I assign the user "bobby" a random password
    Then an e-mail should be sent containing "Password"
    When I try to log in with user "bobby"
    Then I should not see "Bob Bobbit"
    When I try to log in with user "bobby" and the password sent via email
    Then there should be a flash error message
    And there should be a "New password" field

  @javascript
  Scenario: New user can be assigned a random password
    When I create a new user
    And I check the assign random password to user field
    And I save the new user
    Then an e-mail should be sent containing "Password"
    When I try to log in with user "newbobby"
    Then I should not see "Bob Bobbit"
    When I try to log in with user "newbobby" and the password sent via email
    Then there should be a flash error message
    And there should be a "New password" field

  @javascript
  Scenario: Password fields are disabled and cleared when random password assignment is activated
    When I edit the user "bobby"
    And I check the assign random password to user field
    Then the password and confirmation fields should be empty
    And the password and confirmation fields should be disabled
    And the force password change field should be checked
    And the force password change field should be disabled
    When I click "Save"
    When I try to log in with user "bobby"
    Then I should not see "Bob Bobbit"
