Feature: Credit unit costs

  Background:
    Given there is a standard cost control project named "project1"
    And the project "project1" has 1 issue with the following:
      | subject | issue1 |
    And the role "Manager" may have the following rights:
      | view_issues |
      | edit_issues |
      | log_costs   |
    And there is 1 cost type with the following:
      | name        | cost_type_1 |
      | unit        | single_unit |
      | unit_plural | multi_unit  |

  @javascript
  Scenario: Crediting units costs to an issue
    When I am already logged in as "manager"
    And I go to the page of the issue "issue1"
    And I follow "More functions" within ".action_menu_main"
    And I follow "Log unit costs" within ".action_menu_main"
    And I fill in "cost_entry_units" with "100"
    And I press "Save"
    Then I should be on the page of the issue "issue1"
