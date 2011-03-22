Feature: Project Admin
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
        | name       | sprint_start_date | effective_date |
        | Sprint 001 | 2010-01-01        | 2010-01-31     |
        | Sprint 002 | 2010-02-01        | 2010-02-28     |
        | Sprint 003 | 2010-03-01        | 2010-03-31     |
        | Sprint 004 | 2010-03-01        | 2010-03-31     |
    And I am logged in as "padme"

  Scenario: One can select whether versions are displayed left or right (left is default) in the backlogs page
    When I go to the edit page of the version called "Sprint 001"
    Then there should be a "version_version_setting_attributes_display" field within "#content form"
    And the "version_version_setting_attributes_display" field within "#content form" should contain "2"