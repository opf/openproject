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