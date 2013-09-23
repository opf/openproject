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
        | view_work_packages  |
        | edit_work_packages  |
        | manage_subtasks     |
    And there are the following work_package status:
        | name        | is_closed  | is_default  |
        | New         | false      | true        |
        | In Progress | false      | false       |
        | Resolved    | false      | false       |
        | Closed      | true       | false       |
        | Rejected    | true       | false       |
    And the user "paul" is a "team member"
    And I am already logged in as "paul"

  Scenario: View the master backlog
    Given I am on the overview page of the project
      And I follow "Backlogs"
     Then I should be on the master backlog

  Scenario: View the product backlog
     When I go to the master backlog
      And I request the server_variables resource
     Then the request should complete successfully

  Scenario: View the product backlog without any stories
    Given there are no stories in the project
     When I go to the master backlog
     Then the request should complete successfully
