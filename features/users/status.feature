Feature: User Status
  Background:
    Given I am already logged in as "admin"
    Given there is a user named "bobby"

  @javascript
  Scenario: Users can be filtered by status
    And the user "bobby" is locked
    And the user "bobby" had too many recently failed logins
    Then I should not see "bobby"
    And I filter the users list by status "locked permanently (1)"
    Then I should see "bobby"
    And I should not see "admin"
    And I should not see "Anonymous"
    And I filter the users list by status "locked temporarily (1)"
    Then I should see "bobby"
    And I should not see "admin"
    And I should not see "Anonymous"
    And I filter the users list by status "all (2)"
    Then I should see "bobby"
    And I should see "admin"
    And I should not see "Anonymous"

  Scenario: A locked and blocked user gets unlocked and unblocked
    Given the user "bobby" is locked
    And the user "bobby" had too many recently failed logins
    When I edit the user "bobby"
    And I click "Unlock and reset failed logins"
    When I try to log in with user "bobby"
    Then I should see "Bob Bobbit"

  Scenario: An active user gets locked
    When I edit the user "bobby"
    And I click "Lock permanently"
    When I try to log in with user "bobby"
    Then I should not see "Bob Bobbit"

  Scenario: A registered user gets activated
    Given the user "bobby" is registered and not activated
    When I try to log in with user "bobby"
    Then I should not see "Bob Bobbit"
    When I am already logged in as "admin"
    And I edit the user "bobby"
    And I click "Activate"
    When I try to log in with user "bobby"
    Then I should see "Bob Bobbit"
