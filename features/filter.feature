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

  @javascript
  Scenario: We got some awesome default settings
    Given there is a standard cost control project named "First Project"
    And I am logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    Then filter "spent_on" should be visible
    And filter "user_id" should be visible

  @javascript
  Scenario: A click on clear removes all filters
    Given there is a standard cost control project named "First Project"
    And I am logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I click on "Clear"
    Then filter "spent_on" should not be visible
    And filter "user_id" should not be visible

  @javascript
  Scenario: A set filter is getting restored after reload
    Given there is a standard cost control project named "First Project"
    And I am logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I click on "Clear"
    And I set the filter "user_id" to "2" with the operator "!"
    Then filter "user_id" should be visible
    When I send the query
    And "2" should be selected for "user_id_arg_1_val"
    And "!" should be selected for "operators_user_id"

  @javascript
  Scenario: A click on clear enables the option in the Add-Filter-Selectbox
    Given there is a standard cost control project named "First Project"
    And I am logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    Then "user_id" should not be selectable from "add_filter_select"
    And filter "user_id" should be visible
    When I click on "Clear"
    Then "user_id" should be selectable from "add_filter_select"

  @javascript
  Scenario: Setting a Filter disables the option in the Add-Filter-Selectbox
    Given there is a standard cost control project named "First Project"
    And I am logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I click on "Clear"
    Then "user_id" should be selectable from "add_filter_select"
    And I set the filter "user_id" to "2" with the operator "!"
    Then "user_id" should not be selectable from "add_filter_select"
    When I send the query
    Then "user_id" should not be selectable from "add_filter_select"

