Feature: Creating Projects

  @javascript
  Scenario: Creating a Subproject
    Given there is 1 project with the following:
      | name        | Parent      |
      | identifier  | parent      |
    And I am admin
    When I go to the overview page of the project "Parent"
    And I follow "New subproject"
    And I fill in "project_name" with "child"
    And I press "Save"
    Then I should be on the settings page of the project called "child"
