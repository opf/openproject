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
      | name      | Translation |
      | cost rate | 1           |
    And the project "Test" has 1 cost entry with the following:
      | units | 424 |
    And I am on the Cost Reports page for the project called Test
    Then I should not see "No data to display"
    And I should see "424.00"
    And I should see "Translation"

  @javascript
  Scenario: User who can see own time entries, see's his time, but not other's time, no money and no cost entries
    Given there is a standard cost control project named "testproject"
    And there is 1 cost type with the following:
      | name      | word |
      | cost rate | 1.01 |
    And users have times and the cost type "word" logged on the issue "testprojectissue" with:
      | manager rate    | 10.1 |
      | developer rate  | 10.2 |
      | manager hours   | 5    |
      | developer hours | 11   |
      | manager units   | 20   |
      | developer units | 10   |
    And the role "Manager" may have the following rights:
      | view_own_time_entries |
    And I am logged in as "manager"
    And I am on the Cost Reports page for the project called "testproject" without filters or groups
    And I start debugging
    Then I should not see "No data to display"
    And I should not see "193.00" # EUR 50.50 + 112.20 (manager + developer hours) + 20.20 + 10.10 (manager + developer words)
    And I should not see "30.30" # EUR 20.20 + 10.10 (manager + developer words)
    And I should not see "162.70" # EUR 50.50 + 112.20 (manager + developer hours)
    And I should not see "50.50" # EUR manager hours
    And I should not see "112.20" # EUR developer hours
    And I should not see "20.20" # EUR manager words
    And I should not see "10.10" # EUR developer words
    And I should not see "20" # Units manager words
    And I should not see "10" # Units developer words
    And I should not see "30" # Units manager + developer
    And I should not see "11" # Hours developer
    And I should not see "16" # Hours developer + manager
    And I should see "5" # Hours manager

  Scenario: User who can see time entries, see times, but no money and no cost entries
    Given there is a standard cost control project named "testproject"
    And there is 1 cost type with the following:
      | name      | word |
      | cost rate | 1.01 |
    And users have times and the cost type "word" logged on the issue "testprojectissue" with:
      | manager rate    | 10.1 |
      | developer rate  | 10.2 |
      | manager hours   | 5    |
      | developer hours | 11   |
      | manager units   | 20   |
      | developer units | 10   |
    And the role "Manager" may have the following rights:
      | view_time_entries |
    And I am logged in as "manager"
    And I am on the Cost Reports page for the project "testproject" without filters or groups
    Then I should not see "No data to display"
    And I should not see "193.00" # EUR 50.50 + 112.20 (manager + developer hours) + 20.20 + 10.10 (manager + developer words)
    And I should not see "30.30" # EUR 20.20 + 10.10 (manager + developer words)
    And I should not see "162.70" # EUR 50.50 + 112.20 (manager + developer hours)
    And I should not see "50.50" # EUR manager hours
    And I should not see "112.20" # EUR developer hours
    And I should not see "20.20" # EUR manager words
    And I should not see "10.10" # EUR developer words
    And I should not see "20" # Units manager words
    And I should not see "10" # Units developer words
    And I should not see "30" # Units manager + developer
    And I should see "11" # Hours developer
    And I should see "16" # Hours developer + manager
    And I should see "5" # Hours manager

