Feature: Cost Control

  Scenario: Editing a cost entry does not duplicate, but update it
    Given there is a standard cost control project named "CostProject"
    And the project "CostProject" has 1 cost entry with the following:
      | units | 1234.0 |
    And I am admin
    And I am on the overall Cost Reports page without filters or groups
    When I click on "Edit"
    When I fill in "4321.0" for "cost_entry_units"
    When I click on "Save"
    Then I should see "4321.0"
    And I should not see "1234.0"

