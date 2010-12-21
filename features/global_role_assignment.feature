Feature: Global Role Assignment

  @javascript
  Scenario: Assigning a global role to a user
    Given there is the global permission "global1" of the module "global"
    And there is a global role "global_role"
    And the global role "global_role" may have the following rights:
      | global1 |
    And there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And I am admin
    When I go to the edit page of the user called "bob"
    And I click on "tab-global_roles"
    And I select the available role "global_role"
    And I click on "Add"
    Then I should see "global_role" within "#table_principal_roles"
    And I should not see "global_role" within "#available_principal_roles"