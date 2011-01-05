Feature: Global Create Project

  @javascript
  Scenario: Create Project is not a member permission
    Given there is a role "Member"
    And I am admin
    When I go to the edit page of the role "Member"
    Then I should not see "Create project"

  @javascript
  Scenario: Create Project is a global permission
    Given there is a global role "Global"
    And I am admin
    When I go to the edit page of the role "Global"
    Then I should see "Create project"

  @javascript
  Scenario: Create Project displayed to user
    Given there is a global role "Global"
    And the global role "Global" may have the following rights:
      | add_project |
    And there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And the user "bob" has the global role "Global"
    When I login as "bob"
    And I go to the overall projects page
    Then I should see "New project"