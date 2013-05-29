Feature: User settings

  Scenario: A user can change its task color
    Given there is 1 user with the following:
      | login     | bob |
    And I am already logged in as "bob"
    And I go to the my account page
    And I fill in "Task color" with "#FBC4B3"
    And I click on "Save"
    Then I should see "Account was successfully updated"
    And the "Task color" field should contain "#FBC4B3"
