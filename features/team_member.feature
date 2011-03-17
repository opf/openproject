Feature: Team Member
  As a team member
  I want to manage update stories and tasks
  So that I can update everyone on the status of the project

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And the backlogs module is initialized
    And there is 1 user with:
        | login | jsmith |
    And there is a role "team member"
    And the role "team member" may have the following rights:
        | view_master_backlog |
        | view_taskboards     |
        | create_tasks        |
        | update_tasks        |
        | view_issues         |
        | edit_issues         |
        | manage_subtasks     |
    And the user "jsmith" is a "team member"
    And the project has the following sprints:
        | name       | sprint_start_date | effective_date |
        | Sprint 001 | 2010-01-01        | 2010-01-31     |
        | Sprint 002 | 2010-02-01        | 2010-02-28     |
        | Sprint 003 | 2010-03-01        | 2010-03-31     |
        | Sprint 004 | 2010-03-01        | 2010-03-31     |
    And the project has the following stories in the following sprints:
        | position | subject | sprint     |
        | 1        | Story 1 | Sprint 001 |
        | 2        | Story 2 | Sprint 001 |
        | 3        | Story 3 | Sprint 001 |
        | 4        | Story 4 | Sprint 002 |
    And the project has the following tasks:
        | subject | parent  |
        | Task 1  | Story 1 |
    And the project has the following impediments:
        | subject      | sprint     | blocks  |
        | Impediment 1 | Sprint 001 | Story 1 |
        | Impediment 2 | Sprint 001 | Story 2 |
    And I am logged in as "jsmith"

  Scenario: Create a task for a story
    Given I am viewing the taskboard for Sprint 001
      And I want to create a task for Story 1
      And I set the subject of the task to A Whole New Task
     When I create the task
     Then the request should complete successfully
      And the 1st task for Story 1 should be A Whole New Task

  Scenario: Update a task for a story
    Given I am viewing the taskboard for Sprint 001
      And I want to edit the task named Task 1
      And I set the subject of the task to Whoa there, Sparky
     When I update the task
     Then the request should complete successfully
      And the story named Story 1 should have 1 task named Whoa there, Sparky

  Scenario: View a taskboard
    Given I am viewing the taskboard for Sprint 001
     Then I should see the taskboard

  Scenario: View the burndown chart
    Given I am viewing the burndown for Sprint 002
     Then I should see the burndown chart

  Scenario: View sprint stories in the issues tab
    Given I am viewing the master backlog
     When I view the stories of Sprint 001 in the issues tab
     Then I should see the Issues page

  Scenario: View the project stories in the issues tab
    Given I am viewing the master backlog
     When I view the stories in the issues tab
     Then I should see the Issues page

  Scenario: Fetch the updated stories
    Given I am viewing the master backlog
     When the browser fetches stories updated since 1 week ago
     Then the request should complete successfully
      And the server should return 4 updated stories

  Scenario: Fetch the updated tasks
    Given I am viewing the taskboard for Sprint 001
     When the browser fetches tasks updated since 1 week ago
     Then the request should complete successfully
      And the server should return 1 updated task

  Scenario: Fetch the updated impediments
    Given I am viewing the taskboard for Sprint 001
     When the browser fetches impediments updated since 1 week ago
     Then the request should complete successfully
      And the server should return 2 updated impediments

  Scenario: Fetch zero updated impediments
    Given I am viewing the taskboard for Sprint 001
     When the browser fetches impediments updated since 1 week from now
     Then the request should complete successfully
      And the server should return 0 updated impediments

  Scenario: Copy estimate to remaining
    Given I am viewing the taskboard for Sprint 001
      And I want to create a task for Story 1
      And I set the subject of the task to A Whole New Task
      And I set the estimated_hours of the task to 3
     When I create the task
     Then the request should complete successfully
      And task A Whole New Task should have remaining_hours set to 3

  Scenario: Copy remaining to estimate
    Given I am viewing the taskboard for Sprint 001
      And I want to create a task for Story 1
      And I set the subject of the task to A Whole New Task
      And I set the remaining_hours of the task to 3
     When I create the task
     Then the request should complete successfully
      And task A Whole New Task should have estimated_hours set to 3

  Scenario: Set both estimate and remaining
    Given I am viewing the taskboard for Sprint 001
      And I want to create a task for Story 1
      And I set the subject of the task to A Whole New Task
      And I set the remaining_hours of the task to 3
      And I set the estimated_hours of the task to 8
     When I create the task
      And I want to create a task for Story 1
      And I set the subject of the task to A Second New Task
      And I set the remaining_hours of the task to 1
      And I set the estimated_hours of the task to 2
     When I create the task
     Then the request should complete successfully
      And task A Whole New Task should have remaining_hours set to 3
      And task A Whole New Task should have estimated_hours set to 8
      And story Story 1 should have remaining_hours set to 4
      And story Story 1 should have estimated_hours set to 10
