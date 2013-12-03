Feature: Cost Object activities

  Background:
    Given there is a standard cost control project named "project1"
    And I am already admin

  Scenario: cost object is a selectable activity type
    When I go to the activity page of the project "project1"
    Then I should see "Budgets" within "#sidebar"

  Scenario: Generating a cost object creates an activity
    Given there is a variable cost object with the following:
      | project     | project1            |
      | subject     | Cost Object Subject |
      | created_on  | Time.now - 1.day    |
    When I go to the activity page of the project "project1"
     And I activate activity filter "Cost Objects"
    When I click "Apply"
    Then I should see "Cost Object Subject"

  Scenario: Updating a cost object creates an activity
    Given there is a variable cost object with the following:
      | project     | project1            |
      | subject     | cost_object1        |
      | created_on  | Time.now - 40.days  |
    And I update the variable cost object "cost_object1" with the following:
      | subject     | cost_object1_new_title  |
    When I go to the activity page of the project "project1"
     And I activate activity filter "Cost Objects"
    When I click "Apply"
    Then I should see "cost_object1_new_title"


