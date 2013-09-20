Feature: Groups

  Background:
    Given there is a standard cost control project named "First Project"
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"

  @javascript
  Scenario: We got some awesome default settings
    Then I should see "Week (Spent)" in columns
    And I should see "WorkPackage" in rows

  @javascript
  Scenario: A click on clear removes all groups
    When I click on "Clear"
    Then I should not see "Week (Spent)" in columns
    And I should not see "WorkPackage" in rows
    And I group rows by "User"
    And I group rows by "Cost type"

    When I click on "Clear"

    Then I should not see "Week (Spent)" in columns
    And I should not see "WorkPackage" in rows
    And I should not see "User" in rows
    And I should not see "Cost type" in rows

  @javascript
  Scenario: Groups can be added to either rows or columns
    When I click on "Clear"
    And I group columns by "WorkPackage"

    Then I should see "WorkPackage" in columns
    When I group rows by "Project"
    Then I should see "Project" in rows

  @javascript
  Scenario: Groups can be removed from rows and columns
    When I click on "Clear"
    And I group columns by "WorkPackage"
    And I group rows by "Project"

    Then I should see "WorkPackage" in columns
    And I should see "Project" in rows

    When I remove "Project" from rows
    And I remove "WorkPackage" from columns

    Then I should not see "WorkPackage" in columns
    And I should not see "Project" in rows

  @javascript
  Scenario: Groups get restored after sending a query
    When I click on "Clear"
    And I group columns by "WorkPackage"
    And I group columns by "Project"
    And I group rows by "User"
    And I group rows by "Cost type"
    And I send the query

    Then I should see "Project" in columns
    And I should see "WorkPackage" in columns
    And I should see "User" in rows
    And I should see "Cost type" in rows

