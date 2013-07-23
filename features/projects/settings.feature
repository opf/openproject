Feature: Project Settings
  Background:
    Given there is 1 project with the following:
      | name        | project1 |
      | identifier  | project1 |
    And there is 1 user with the following:
      | login     | bob        |
      | firstname | Bob        |
      | Lastname  | Bobbit     |
    And there is 1 user with the following:
      | login     | alice      |
      | firstname | Alice      |
      | Lastname  | Alison     |
    And there is a role "alpha"
    And there is a role "beta"
    And the user "bob" is a "alpha" in the project "project1"
    And the user "alice" is a "beta" in the project "project1"

  @javascript
  Scenario: Adding a Role to a Member
    Given I am admin
    When I go to the members tab of the settings page of the project "project1"
    When I click on "Edit" within "#member-1"
    And I check "beta" within "#member-1-roles-form"
    And I click "Change" within "#member-1-roles-form"
    Then I should see "alpha" within "#member-1-roles"
    And I should see "beta" within "#member-1-roles"

@javascript
  Scenario: Removing one Role from while adding another Role to a Member
    Given I am admin
    When I go to the members tab of the settings page of the project "project1"
    When I click on "Edit" within "#member-1"
    And I uncheck "alpha" within "#member-1-roles-form"
    And I check "beta" within "#member-1-roles-form"
    And I click "Change" within "#member-1-roles-form"
    Then I should see "beta" within "#member-1-roles"
    And I should not see "alpha" within "#member-1-roles"

@javascript
  Scenario: Removing the last Role of a Member
    Given I am admin
    When I go to the members tab of the settings page of the project "project1"
    When I click on "Edit" within "#member-1"
    And I uncheck "alpha" within "#member-1-roles-form"
    And I click "Change" within "#member-1-roles-form"
    Then I should not see "Bob Bobbit" within ".list.members"
