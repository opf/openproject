Feature: Backlog Settings
  As a Project Admin
  I want to configure the backlogs plugin
  So that my team and I can work effectively

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And the backlogs module is initialized
    And there is 1 user with:
        | login | padme |
    And there is a role "project admin"
    And the role "project admin" may have the following rights:
        | manage_versions     |
        | view_master_backlog |
        | edit_project |
    And the user "padme" is a "project admin"
    And I am logged in as "padme"

@javascript
  Scenario: One can select which status indicate that an issue is done
    Given there is 1 project with:
        | name  | parent  |
    And I am working in project "parent"
    And the project uses the following modules:
        | backlogs |
    And I am working in project "ecookbook"
    When I go to the settings/project_issue_statuses page of the project called "ecookbook"
    Then there should be a "Resolved" field
    When I check "Resolved"
    And I press "Save" within "#tab-content-project_issue_statuses"
    When I go to the settings/project_issue_statuses page of the project called "ecookbook"
    Then the "Resolved" checkbox should be checked