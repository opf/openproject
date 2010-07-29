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
