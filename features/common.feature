Feature: Common
  As a user
  I want to do stuff
  So that I can do my job

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And the backlogs module is initialized
    And there is 1 user with:
        | login | paul |
    And there is a role "team member"
    And the role "team member" may have the following rights:
        | view_master_backlog |
        | view_taskboards     |
        | create_tasks        |
        | update_tasks        |
        | view_issues         |
        | edit_issues         |
        | manage_subtasks     |
    And the user "paul" is a "team member"
    And I am logged in as "paul"

  Scenario: View the product backlog
    Given I am viewing the master backlog
     When I request the server_variables resource
     Then the request should complete successfully

  Scenario: View the product backlog without any stories
    Given there are no stories in the project
     When I view the master backlog
     Then the request should complete successfully
