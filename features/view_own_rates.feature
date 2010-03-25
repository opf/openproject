Feature: Permission View Own hourly and cost rates

  Scenario: Users that by set permission are only allowed to see their own rates, can not see the rates of others.
    Given there is a standard cost control project named "Standard Project"
    And I am "Supplier" # I am allowed to see my own hourly and cost rates.
    And I am member of "Standard Project":
			| hourly rate | 10.00 |
    And the project with name "Standard Project" has 1 issue with the following:
      | subject  | "test_issue" |
    And this issue has one time entry with the following:
      | hours | 1.00  |
      | user  | me    |
    And this issue has one material cost entry with the following:
      | units | 2.00  |
      | user  | me    |
			| cost type | Translation | 
			# One translation costs 7.00 €
		And "Manager" is member of "Standard Project":
			| hourly rate | 11.00 |
		And "test_issue" has time entry:
			| hours | 3.00 |
			| user | Manager |
		And "test_issue" has cost entry:
			| units | 5.00 |
			| user | Manager |
			| cost type | Translation |
    And I am on the Issue page for the issue test_issue
    Then I should see "1.00 h"
		And I should see "2.00 Translations"
		And I should see "10.00 €"
		And I should see "14.00 €"
		And I should not see "33.00 €" # labour costs only of Manager
		And I should not see "35.00 €" # material costs only of Manager
		And I should not see "43.00 €" # labour costs of me and Manager
		And I should not see "49.00 €" # material costs of me and Manager
		And then I go to issues page 
		And I select to see column "labour costs" 
    Then I should see "1.00 h"
		And I should see "2.00 Translations"
		And I should see "24.00 €"
		And I should not see "33.00 €" # labour costs only of Manager
		And I should not see "35.00 €" # material costs only of Manager
		And I should not see "43.00 €" # labour costs of me and Manager
		And I should not see "49.00 €" # material costs of me and Manager