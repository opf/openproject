Feature: User Status
  Background:
    Given I am already logged in as "admin"

  @javascript
  Scenario: Users can be filtered by status
    Given there is a user named "bobby"
    And the user "bobby" is locked
    Then I should not see "bobby"
    And I filter the users list by status "locked (1)"
    Then I should see "bobby"
