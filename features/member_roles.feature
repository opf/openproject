Feature: Unchanged Member Roles

  @javascript
  Scenario: Global Roles should not be displayed as assignable project roles
    Given there is 1 project with the following:
      | Name | projectname |
      | Identifier | projectid |
    And there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And there is a global role "GlobalRole1"
    And there is a role "MemberRole1"
    And I am admin
    When I go to the settings page of the project called "projectname"
    And I click on "tab-members"
    Then I should see "MemberRole1"
    And I should not see "GlobalRole1"