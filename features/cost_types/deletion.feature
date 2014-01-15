Feature: Cost type deletion

  Background:
    Given there is 1 cost type with the following:
      | name | cost_type1 |
    And I am already admin

  @javascript
  Scenario: Deleting a cost type
    When I delete the cost type "cost_type1"

    Then the cost type "cost_type1" should not be listed on the index page

  @javascript
  Scenario: Deleted cost types are listed as deleted
    When I delete the cost type "cost_type1"

    Then the cost type "cost_type1" should be listed as deleted on the index page

