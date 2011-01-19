Feature: As an admin
         I want to assign permissions to a global role
         So that global roles enable users to do something

  @javascript
  Scenario: Global Permissions for global role
    Given there is the global permission "glob_test" of the module "global_group"
    And I am admin
    When I go to the new page of "Role"
    And I check "global_role"
    Then I should see "Global group"
    And I should see "Glob test"

  @javascript
  Scenario: Global Roles can not be assigned issues to
    Given I am admin
    When I go to the new page of "Role"
    And I check "global_role"
    Then I should not see "Issues can be assigned to this role"
    And there should not be a "role_assignable" field