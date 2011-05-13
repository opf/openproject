Feature: Version Settings
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
        | manage_versions   |
    And the user "padme" is a "project admin"
    And the project has the following sprints:
        | name       | start_date | effective_date |
        | Sprint 001 | 2010-01-01        | 2010-01-31     |
        | Sprint 002 | 2010-02-01        | 2010-02-28     |
        | Sprint 003 | 2010-03-01        | 2010-03-31     |
        | Sprint 004 | 2010-03-01        | 2010-03-31     |
    And I am logged in as "padme"

  Scenario: One can select whether versions are displayed left or right (left is default) in the backlogs page
    When I go to the edit page of the version called "Sprint 001"
    Then there should be a "version[version_settings_attributes][][display]" field within "#content form"
    And the "version[version_settings_attributes][][display]" field within "#content form" should contain "2"
    When I select "right" from "version[version_settings_attributes][][display]"
    And I press "Save"
    Then I should be on the settings/versions page of the project called "ecookbook"

  Scenario: Inherited versions can also be configured to be displayed left, right or not at all
    Given there is 1 project with:
        | name  | parent  |
    And I am working in project "parent"
    And the project uses the following modules:
        | backlogs |
    And the project has the following sprints:
        | name       | start_date | effective_date | sharing       |
        | shared     | 2010-01-01        | 2010-01-31     | system        |
    And I am working in project "ecookbook"
    When I go to the settings/versions page of the project called "ecookbook"
    Then I should see "Edit" within ".version.shared .buttons"
    When I follow "Edit" within ".version.shared .buttons"
    Then there should be a "version[version_settings_attributes][][display]" field within "#content form"
    And the "version[version_settings_attributes][][display]" field within "#content form" should contain "2"
    When I select "right" from "version[version_settings_attributes][][display]"
    And I press "Save"
    Then I should be on the settings/versions page of the project called "ecookbook"