Feature: Team Member
  As a team member
  I want to manage update stories and tasks
  So that I can update everyone on the status of the project

  Background:
    Given the ecookbook project has the backlogs plugin enabled
      And I am a team member of the project
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

  Scenario: Create a task for a story
    Given I am viewing the taskboard for Sprint 001
      And I want to create a task for Story 1
      And I set the subject of the task to A Whole New Task
     When I create the task
     Then the request should complete successfully
      And the 1st task for Story 1 should be A Whole New Task
     