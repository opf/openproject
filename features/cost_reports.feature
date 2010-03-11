Feature: Cost Reports

  Scenario: Anonymous user sees no costs
    Given I am not logged in
    And there is one Project with the following:
      | Name | Test |
    And there is one cost entry    
    And I am on the Cost Reports page for the project called Test
    Then I should see "No data to display"
    
  Scenario: Admin user sees everything
    Given I am admin
    And there is one project with the following:
      | Name | Test |
    And there is one cost type with the following:
      | name | Translation |
    And there is one cost entry with the following:
      | units | 4242 |
    And I am on the Cost Reports page for the project called Test
    Then I should not see "No data to display"
    And I should see "Translation"
    And I should see "4242"
    And I should see "Redmine Admin"

  Scenario: User who can see own costs, ONLY sees own costs
    Given I am not logged in
    And there is one project with the following:
      | Name | Test |
    And there is one User with the following:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And there is one cost type with the following:
      | name | Translation |
    And the user with login "Bob" has one cost entry
    And there are 2 additional cost types with the following:
      | name | Hidden Costs |
    And there are 2 additional cost entries with the following:
      | units | 128128 |
    And the user with login "Bob" may have the following rights:
      | View own costs |
    And I am logged in as "Bob"
    And I am on the Cost Reports page for the project called Test
    Then I should not see "No data to display"
    And I should see "Translation"
    And I should see "4242"
    And I should see "Bob Bobbit"
    And I should not see "Hidden Costs"
    And I should not see "128128"
    And I should not see "Redmine Admin"