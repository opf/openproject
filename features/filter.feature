Feature: Filter

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

