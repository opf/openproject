Feature: As an admin
         I want to administrate global roles with permissions
         So that I can modify permission groups

  @javascript
  Scenario: Global Role creation
    Given there is the global permission "glob_test" of the module "global_group"
    And I am admin
    When I go to the new page of "Role"
    And I check "global_role"
    Then I should see "Global group"
    And I should see "Glob test"
    And I should not see "Issues can be assigned to this role"

  @javascript
  Scenario: Global Roles can not be assigned issues to
    Given there is a global role "global_role_x"
    And I am admin
    When I go to the edit page of the role called "global_role_x"
    Then I should not see "Issues can be assigned to this role"