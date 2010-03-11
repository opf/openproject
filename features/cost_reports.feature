Feature: Cost Reports

  Scenario: Anonymous user sees no costs
    Given I am not logged in
    And there is one Project with the following:
      | Name      | Test |
    And there is one cost entry    
    And I am on the Cost Reports page for the project called Test
    Then I should see "Login:"
    And I should see "Password:"
    
  Scenario: Admin user sees everything
    Given I am admin
    And there is only one project with the following:
      | Name | Test |
    And there is one cost type with the following:
      | name | Translation |
    And there is one cost entry with the following:
      | units | 4242 |
    And I am on the Cost Reports page for the project called Test
    Then I should not see "No data to display"
    And I should see "Translation"
    And I should see "4242"

  Scenario: User who can see own costs, ONLY sees own costs
    Given I am not logged in
    And there is only one project with the following:
      | Name | Test |
    And there is one User with the following:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And the user "Bob" is a "Developer" in the project "Test"
    And the role "Developer" may have the following rights in project "Test":
      | view_own_costs |
    And there is only one cost type with the following:
      | name | Translation |
    And the user with login "Bob" has one cost entry
    And there is 1 cost type with the following:
      | name | Hidden Costs |
    And there are 2 cost entries with the following:
      | units | 128128 |
    And I am logged in as "bob"
    And I am on the Cost Reports page for the project called Test
    Then I should not see "No data to display"
    And I should see "Translation"
    And I should see "Bob Bobbit"
    And I should not see "Hidden Costs"
    And I should not see "128128"
    And I should not see "Redmine Admin"