Feature: Permission View Own hourly and cost rates

  Scenario: Users that by set permission are only allowed to see their own rates, can not see the rates of others.
    Given there is a standard cost control project named "Standard Project"
    And the role "Supplier" may have the following rights:
      | view_own_hourly_rate |
    And there is 1 user with:
      | name | bob |
      | default rate | 10.00 |
    And the user "bob" is a "Supplier" in the project "Standard Project"
    And the project "Standard Project" has 1 issue with the following:
      | subject  | "test_issue" |
    And the issue "test_issue" has 1 time entry with the following:
      | hours | 1.00  |
      | user  | bob   |
    And there is 1 cost type with the following:
      | name | Translation |
      | cost rate | 7.00   |
    And the issue "test_issue" has 1 cost entry with the following:
      | units | 2.00  |
      | user  | bob   |
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
    And I am on the page for the issue "test_issue"
    Then I should see "1.00 h"
		And I should see "2.00 Translations"
		And I should see "10.00 €"
		And I should see "14.00 €"
		And I should not see "33.00 €" # labour costs only of Manager
		And I should not see "35.00 €" # material costs only of Manager
		And I should not see "43.00 €" # labour costs of me and Manager
		And I should not see "49.00 €" # material costs of me and Manager
		And I am on the issues page for the project called "Standard Project" 
		And I select to see column "labour costs"
    Then I should see "1.00 h"
		And I should see "2.00 Translations"
		And I should see "24.00 €"
		And I should not see "33.00 €" # labour costs only of Manager
		And I should not see "35.00 €" # material costs only of Manager
		And I should not see "43.00 €" # labour costs of me and Manager
		And I should not see "49.00 €" # material costs of me and Manager