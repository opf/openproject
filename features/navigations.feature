Feature: Navigating to reports page

  @javascript
  Scenario: Navigating to the cost report of a project which is a subproject
    Given there is 1 project with the following:
      | name | ParentProject |
      | identifier | parent_project_1 |
    And the project "ParentProject" has 1 subproject with the following:
      | name | SubProject |
      | identifier | parent_project_1_sub_1 |
    And there is 1 user with the following:
      | login | bob |
    And there is a role "Testrole"
    And the role "Testrole" may have the following rights:
      | view_cost_entries |
      | view_own_cost_entries |
    And the user "bob" is a "Testrole" in the project "SubProject"
    When I login as "bob"
    And I go to the page of the project called "SubProject"
    And I follow "Cost Reports" within "#main-menu"
    Then I should see "Cost Report" within "#content"
