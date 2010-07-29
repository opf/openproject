Feature: Permissions

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
    And the user "Bob" is a "Developer" in the project "Test"
    And the role "Developer" may have the following rights:
      | View own time entries |
    And the user "Bob" has 1 time entry
    And the project "Test" has 2 time entries with the following:
      | hours | 11 |
    And I am logged in as "bob"
    And I am on the Cost Reports page for the project called Test
    Then I should not see "No data to display"
    And I should see "Bob Bobbit"
    And I should not see "11"
    And I should not see "220.0"
    And I should not see "Redmine Admin"Scenario: Users that by set permission are only allowed to see their own rates, can not see the rates of others.
    Given there is a standard cost control project named "Standard Project"
    And the role "Supplier" may have the following rights:
      | view_own_hourly_rate |
      | view_issues |
      | view_own_time_entries |
      | view_own_cost_entries |
      | view_cost_rates |
    And there is 1 User with:
    | Login 				  | testuser |
      | Firstname 		| Bob 		|
      | Lastname 			| Bobbit 	|
      | default rate | 10.00 |
    And the user "testuser" is a "Supplier" in the project "Standard Project"
    And the project "Standard Project" has 1 issue with the following:
      | subject  | test_issue |
    And the issue "test_issue" has 1 time entry with the following:
      | hours | 1.00  |
      | user  | testuser   |
    And there is 1 cost type with the following:
      | name | Translation |
      | cost rate | 7.00   |
    And the issue "test_issue" has 1 cost entry with the following:
      | units | 2.00  |
      | user  | testuser   |
			| cost type | Translation |
    And the user "manager" has:
			| hourly rate | 11.00 |
		And the issue "test_issue" has 1 time entry with the following:
			| hours | 3.00 |
			| user | manager |
		And the issue "test_issue" has 1 cost entry with the following:
			| units | 5.00 |
			| user | manager |
			| cost type | Translation |
    And I am logged in as "testuser"
    And I am on the page for the issue "test_issue"
    Then I should see "1.00 hour"
		And I should see "2.0 Translations"
		And I should see "24.00 EUR"
		And I should not see "33.00 EUR" # labour costs only of Manager
		And I should not see "35.00 EUR" # material costs only of Manager
		And I should not see "43.00 EUR" # labour costs of me and Manager
		And I should not see "49.00 EUR" # material costs of me and Manager
		And I am on the issues page for the project called "Standard Project"
    And I finish these definitions
		And I select to see column "overall costs"
    And I select to see column "labour costs"
    And I select to see column "material costs"
		Then I should see "24.00 EUR"
    And I should see "10.00 EUR"
    And I should see "14.00 EUR"
		And I should not see "33.00 EUR" # labour costs only of Manager
		And I should not see "35.00 EUR" # material costs only of Manager
		And I should not see "43.00 EUR" # labour costs of me and Manager
		And I should not see "49.00 EUR" # material costs of me and Manager
    
