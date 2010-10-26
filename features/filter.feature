Feature: Filter

  @javascript
  Scenario: When using jump-to-project comming from the overall cost report to a projects report sets the project filter to that project
    Given there is a standard cost control project named "First Project"
    And I am logged in as "controller"
    And I am on the overall Cost Reports page
    And I jump to project "First Project"
    Then "First Project" should be selected for "project_id_arg_1_val"

  @javascript
  Scenario: When using jump-to-project comming from a projects cost report to the overall cost report page unsets the project filter
    Given there is a standard cost control project named "First Project"
    And I am logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I follow "Cost Reports"
    Then "" should be selected for "project_id_arg_1_val"

  @javascript
  Scenario: When using jump-to-project comming from a projects cost report to another projects report sets the project filter to the second project
    Given there is a standard cost control project named "First Project"
    And there is a standard cost control project named "Second Project"
    And I am logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I jump to project "Second Project"
    Then "Second Project" should be selected for "project_id_arg_1_val"
