Feature: Global Role Assignment

  @javascript
  Scenario: Going to the global role assignment page
    Given there is the global permission "global1" of the module "global"
    And there is the global permission "global2" of the module "global"
    And there is a global role "global_role1"
    And there is a global role "global_role2"
    And the global role "global_role1" may have the following rights:
      | global1 |
    And the global role "global_role2" may have the following rights:
      | global2 |
    And there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And the user "bob" has the global role "global_role1"
    And I am admin
    When I go to the edit page of the user called "bob"
    And I click on "tab-global_roles"
    Then I should see "global_role1" within "#table_principal_roles"
    And I should not see "global_role1" within "#available_principal_roles"
    And I should see "global_role2" within "#available_principal_roles"

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
    And I satisfy the "redmine_dtag_privacy" plugin to modify a principal_role
    Then I should see "global_role" within "#table_principal_roles"
    And I should not see "global_role" within "#available_principal_roles"
    And I should see "No global role available for assignment"

  @javascript
  Scenario: Deleting a global role of a user
    Given there is the global permission "global1" of the module "global"
    And there is a global role "global_role"
    And the global role "global_role" may have the following rights:
      | global1 |
    And there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And the user "bob" has the global role "global_role"
    And I am admin
    When I go to the edit page of the user called "bob"
    And I click on "tab-global_roles"
    And I delete the assigned role "global_role"
    Then I should not see "global_role" within "#table_principal_roles"
    And I should see "global_role" within "#available_principal_roles"