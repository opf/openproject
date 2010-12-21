Feature: Global Role Assignment

  @javascript
  Scenario: Assigning Role to user
    Given there is the global permission "global1" of the module "global"
    And there is the global permission "global2" of the module "global"
    And there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And I am admin
    When I go to the edit page of the user called "bob"
    And I click on "tab-global_roles"
    And I click on "principal_role_role_ids_0"
    And I click on "Add"
    Then I should see "global1" within "#table_principal_roles"
    And I should not see "global1" within ".principal_role_option"