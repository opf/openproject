Feature: Permission Assignment

  @javascript
  Scenario: Global Permissions for new role
    Given there is the global permission "glob_test" of the module "global_group"
    And I am admin
    When I go to the new page of "Role"
    And I check "global_role"
    Then I should see "Global group"
    And I should see "Glob test"