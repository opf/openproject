Feature: Groups

  @javascript
  Scenario: We got some awesome default settings
    Given there is a standard cost control project named "First Project"
    And I am logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    Then I should see "Week (Spent)" in columns
    And I should see "Issue" in rows

  @javascript
  Scenario: A click on clear removes all groups
    Given there is a standard cost control project named "First Project"
    And I am logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I click on "Clear"
    Then I should not see "Week (Spent)" in columns
    And I should not see "Issue" in rows
    And I group rows by "User"
    And I group rows by "Cost type"
    And I click on "Clear"
    Then I should not see "Week (Spent)" in columns
    And I should not see "Issue" in rows
    And I should not see "User" in rows
    And I should not see "Cost type" in rows

  @javascript
  Scenario: Groups can be added to either rows or columns
    Given there is a standard cost control project named "First Project"
    And I am logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I click on "Clear"
    And I group columns by "Issue"
    Then I should see "Issue" in columns
    # And I should "Issues" should be inactive for columns
    # And I should "Issues" should be inactive for rows
    When I group rows by "Project"
    Then I should see "Project" in rows
    And "Project" should be active for rows
    And "Project" should be active for columns

  @javascript
  Scenario: Groups can be removed from rows and columns
    Given there is a standard cost control project named "First Project"
    And I am logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I click on "Clear"
    And I group columns by "Issue"
    And I group rows by "Project"
    Then I should see "Issue" in columns
    And I should see "Project" in rows
    When I remove "Project" from rows
    And I remove "Issue" from columns
    Then I should not see "Issue" in columns
    And I should not see "Project" in rows
    And "Project" should be active for columns
    And "Project" should be active for rows
    And "Issue" should be active for columns
    And "Issue" should be active for rows

  @javascript
  Scenario: Groups get restored after sending a query
    Given there is a standard cost control project named "First Project"
    And I am logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I click on "Clear"
    And I group columns by "Issue"
    And I group columns by "Project"
    And I group rows by "User"
    And I group rows by "Cost type"
    And I send the query
    Then I should see "Project" in columns
    And I should see "Issue" in columns
    And I should see "User" in rows
    And I should see "Cost type" in rows

