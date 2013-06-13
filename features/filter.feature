Feature: Filter

  @javascript
  Scenario: When using jump-to-project comming from the overall cost report to a projects report sets the project filter to that project
    Given the desired behaviour is described in #32085 on myproject
    Given there is a standard cost control project named "First Project"
    And I am already logged in as "controller"
    And I am on the overall Cost Reports page
    And I jump to project "First Project"
    Then "First Project" should be selected for "project_id_arg_1_val"

  @javascript
  Scenario: When using jump-to-project comming from a projects cost report to the overall cost report page unsets the project filter
    Given the desired behaviour is described in #32085 on myproject
    Given there is a standard cost control project named "First Project"
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I follow "Modules" within "#top-menu-items"
    And I follow "Cost Reports" within "#top-menu-items"
    Then I should see "New Cost Report" within "h2"
    And I should be on the overall Cost Reports page
    And "" should be selected for "project_id_arg_1_val"

  @javascript
  Scenario: When using jump-to-project comming from a projects cost report to another projects report sets the project filter to the second project
    Given the desired behaviour is described in #32085 on myproject
    Given there is a standard cost control project named "First Project"
    And there is a standard cost control project named "Second Project"
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I jump to project "Second Project"
    Then "Second Project" should be selected for "project_id_arg_1_val"

  @javascript
  Scenario: We got some awesome default settings
    Given there is a standard cost control project named "First Project"
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    Then filter "spent_on" should be visible
    And filter "user_id" should be visible

  @javascript
  Scenario: A click on clear removes all filters
    Given there is a standard cost control project named "First Project"
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I click on "Clear"
    Then filter "spent_on" should not be visible
    And filter "user_id" should not be visible

  @javascript
  Scenario: A set filter is getting restored after reload
    Given there is a standard cost control project named "First Project"
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I click on "Clear"
    And I set the filter "user_id" to the user with the login "developer" with the operator "!"
    Then filter "user_id" should be visible
    When I send the query
    And the user with the login "developer" should be selected for "user_id_arg_1_val"
    And "!" should be selected for "operators[user_id]"

  @javascript
  Scenario: A click on clear enables the option in the Add-Filter-Selectbox
    Given the desired behaviour is described in #32085 on myproject
    Given there is a standard cost control project named "First Project"
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    Then "user_id" should not be selectable from "add_filter_select"
    And filter "user_id" should be visible
    When I click on "Clear"
    Then "user_id" should be selectable from "add_filter_select"

  @javascript
  Scenario: Setting a Filter disables the option in the Add-Filter-Selectbox
    Given the desired behaviour is described in #32085 on myproject
    Given there is a standard cost control project named "First Project"
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I click on "Clear"
    Then "user_id" should be selectable from "add_filter_select"
    And I set the filter "user_id" to the user with the login "developer" with the operator "!"
    Then "user_id" should not be selectable from "add_filter_select"
    When I send the query
    Then "user_id" should not be selectable from "add_filter_select"
