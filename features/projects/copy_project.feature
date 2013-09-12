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
    And the role "alpha" may have the following rights:
      | copy_projects |
      | edit_project  |
    And the role "beta" may have the following rights:
      | edit_project  |
    And the user "alice" is a "alpha" in the project "project1"
    And the user "bob" is a "beta" in the project "project1"

  Scenario: Check for the existence of a copy button
    When I am already admin
    And  I go to the settings page of the project "project1"
    Then I should see "Copy" within "#content"

  Scenario: Permission test for copy button with authorized role
    When I am already logged in as "alice"
    And  I go to the settings page of the project "project1"
    Then I should see "Copy" within "#content"

  Scenario: Permission test for copy button without authorized role
    When I am already logged in as "bob"
    And  I go to the members tab of the settings page of the project "project1"
    Then I should not see "Copy" within "#content"

  Scenario: Check for differences in admin's and settings' copy
    When I am already admin
    And  I go to the admin page
    And  I follow "Projects" within "#main-menu"
    #just one project, so we should be fine
    And  I click on "Copy" within "#content"
    Then I should see "Modules" within "#content"
    When I go to the settings page of the project "project1"
    And  I follow "Copy" within "#content"
    Then I should not see "Modules" within "#content"
