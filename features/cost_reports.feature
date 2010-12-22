Feature: Cost Control

  Scenario: Anonymous user sees no costs
    Given I am not logged in
    And there is 1 Project with the following:
      | Name      | Test |
    And the project "Test" has 1 cost entry
    And I am on the Cost Reports page for the project called Test
    Then I should see "Login:"
    And I should see "Password:"

  Scenario: Admin user sees everything
    Given I am admin
    And there is 1 project with the following:
      | Name | Test |
    And there is 1 cost type with the following:
      | name | Translation |
    And the project "Test" has 1 cost entry with the following:
      | units | 4242 |
    And I am on the Cost Reports page for the project called Test
    Then I should not see "No data to display"
    And I should see "Translation"
    And I should see "4242"

  Scenario: User who can see own costs, ONLY sees own costs
    Given I am not logged in
    And there is 1 project with the following:
      | Name | Test |
    And there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And the user "bob" is a "Developer" in the project "Test"
    And the role "Developer" may have the following rights:
      | View own cost entries |
    And there is 1 cost type with the following:
      | name | Translation |
    And the user "bob" has 1 cost entry
    And there is 1 cost type with the following:
      | name | Hidden Costs |
    And the project "Test" has 2 cost entries with the following:
      | units | 128128 |
    And I am logged in as "bob"
    And I am on the Cost Reports page for the project called Test
    Then I should not see "No data to display"
    And I should see "Translation"
    And I should see "Bob Bobbit"
    And I should not see "Hidden Costs"
    And I should not see "128128"
    And I should not see "Redmine Admin"

  Scenario: User who can see own time entries, ONLY sees own time entries
    Given I am not logged in
    And there is 1 project with the following:
      | Name | Test |
    And there is 1 User with:
      | Login 				| bob 		|
      | Firstname 		| Bob 		|
      | Lastname 			| Bobbit 	|
      | default rate  | 20.0    |
    And the user "bob" is a "Developer" in the project "Test"
    And the role "Developer" may have the following rights:
      | View own time entries |
    And the user "bob" has 1 time entry
    And the project "Test" has 2 time entries with the following:
      | hours | 11 |
    And I am logged in as "bob"
    And I am on the Cost Reports page for the project called Test
    Then I should not see "No data to display"
    And I should see "Bob Bobbit"
    And I should not see "11"
    And I should not see "220.0"
    And I should not see "Redmine Admin"

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

