Feature: Issue Sum Calculations for Currency
  Background:
    Given there is 1 project with the following:
      | name       | project1 |
      | identifier | project1 |
    And the following issue custom fields are defined:
      | name | type   |
      | cf1  | float  |
    And the custom field "cf1" is summable
    And there is a role "Manager"
    And there is 1 user with:
      | Login        | manager   |
    And the user "manager" is a "Manager" in the project "project1"
    And I am already logged in as "admin"

  @javascript
  Scenario: Should calculate an overall sum for a standard issue query
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 100        |
    And the user "manager" has 1 issue with the following:
      | subject | Some other issue |
      | cf1     | 50               |
    When I go to the issues index page for the project called "project1"
    And I select to see columns
    | cf1 |
    And I toggle the Options fieldset
    And I check "display_sums"
    And I click on "Apply"
    And I wait 10 seconds for AJAX
    Then I should see "150" in the overall sum

  @javascript
  Scenario: Should not calculate an overall sum for a standard issue query if the column isn't summable
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 100        |
    And the user "manager" has 1 issue with the following:
      | subject | Some other issue |
      | cf1     | 50               |
    And the custom field "cf1" is not summable
    When I go to the issues index page for the project called "project1"
    And I select to see columns
    | cf1 |
    And I toggle the Options fieldset
    And I check "display_sums"
    And I click on "Apply"
    And I wait 10 seconds for AJAX
    Then I should not see "150" in the overall sum

  @javascript
  Scenario: Should tick the checkbox on query edit if we previously displayed sums
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 100        |
    And the user "manager" has 1 issue with the following:
      | subject | Some other issue |
      | cf1     | 50               |
    When I go to the issues index page for the project called "project1"
    And I select to see columns
    | cf1 |
    And I toggle the Options fieldset
    And I check "display_sums"
    And I click on "Apply"
    And I click on "Save"
    And I fill in "TestQuery" for "query_name"
    And I press "Save"
    And I go to the issues index page for the project called "project1"
    And I click on "TestQuery"
    Then I should be on the issues index page for the project called "project1"
    And the "display_sums" checkbox should be checked
    And I should see "150" in the overall sum
    And I click on "Edit"
    Then the "query[display_sums]" checkbox should be checked

  @javascript
  Scenario: Should not tick the checkbox on query edit if we did not previously display sums
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 100        |
    And the user "manager" has 1 issue with the following:
      | subject | Some other issue |
      | cf1     | 50               |
    When I go to the issues index page for the project called "project1"
    And I select to see columns
    | cf1 |
    And I toggle the Options fieldset
    And I uncheck "display_sums"
    And I click on "Apply"
    And I click on "Save"
    And I fill in "TestQuery" for "query_name"
    And I press "Save"
    And I go to the issues index page for the project called "project1"
    And I click on "TestQuery"
    Then I should be on the issues index page for the project called "project1"
    And the "display_sums" checkbox should not be checked
    And I click on "Edit"
    Then the "query[display_sums]" checkbox should not be checked

  @javascript
  Scenario: Should calculate an overall sum for a grouped issue query with multiple groups
    Given there is 1 user with:
      | Login        | alice   |
    And the user "alice" is a "Manager" in the project "project1"
    And there is 1 user with:
      | Login        | bob   |
    And the user "bob" is a "Manager" in the project "project1"
    And the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 100        |
    And the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 50         |
    And the user "alice" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 300        |
    And the user "bob" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 200        |
    And the user "bob" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 250        |
    When I go to the issues index page for the project called "project1"
    And I select to see columns
    | cf1 |
    And I toggle the Options fieldset
    And I check "display_sums"
    And I select "Assignee" from "group_by"
    And I click on "Apply"
    And I wait 10 seconds for AJAX
    Then I should see "150" in the grouped sum
    And I should see "300" in the grouped sum
    And I should see "450" in the grouped sum
    And I should see "900" in the overall sum

  @javascript
  Scenario: Should calculate an overall sum for a grouped issue query with a single group
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 100        |
    And the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 50         |
    When I go to the issues index page for the project called "project1"
    And I select to see columns
    | cf1 |
    And I toggle the Options fieldset
    And I check "display_sums"
    And I select "Assignee" from "group_by"
    And I click on "Apply"
    And I wait 10 seconds for AJAX
    Then I should see "150" in the grouped sum
    And I should see "150" in the overall sum

  @javascript
  Scenario: Should strip floats down to a precission of 2 number
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue  |
      | cf1     | 100.0000001 |
    And the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 50.09      |
    When I go to the issues index page for the project called "project1"
    And I select to see columns
    | cf1 |
    And I toggle the Options fieldset
    And I check "display_sums"
    And I select "Assignee" from "group_by"
    And I click on "Apply"
    And I wait 10 seconds for AJAX
    Then I should see "150.09" in the grouped sum
    And I should see "150.09" in the overall sum
