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
        | edit_project              |
        | manage_project_activities |
    And the user "padme" is a "project admin"
    And there are the following work_package status:
        | name        | is_closed  | is_default  |
        | New         | false      | true        |
        | In Progress | false      | false       |
        | Resolved    | false      | false       |
        | Closed      | true       | false       |
        | Rejected    | true       | false       |
    And I am already logged in as "padme"

  @javascript
  Scenario: One can select which status indicate that an work_package is done
    Given there is 1 project with:
        | name  | parent  |
    And I am working in project "parent"
    And the project uses the following modules:
        | backlogs |
    And I am working in project "ecookbook"
    When I go to the settings/backlogs_settings page of the project called "ecookbook"
    Then there should be a "Resolved" field
    When I check "Resolved"
    And I press "Save" within "#tab-content-backlogs_settings"
    When I go to the settings/backlogs_settings page of the project called "ecookbook"
    Then the "Resolved" checkbox should be checked
