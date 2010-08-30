Feature: Scrum Master
  As a scrum master
  I want to manage sprints and their stories
  So that they get done according the product owner's requirements

  Background:
    Given the ecookbook project has the backlogs plugin enabled
      And I am a scrum master of the project
      And the project has the following sprints:
        | name       | sprint_start_date | effective_date  |
        | Sprint 001 | 2010-01-01        | 2010-01-31      |
        | Sprint 002 | 2010-02-01        | 2010-02-28      |
        | Sprint 003 | 2010-03-01        | 2010-03-31      |
        | Sprint 004 | 2.weeks.ago       | 1.week.from_now |
      And the project has the following stories in the product backlog:
        | position | subject |
        | 1        | Story 1 |
        | 2        | Story 2 |
        | 3        | Story 3 |
        | 4        | Story 4 |

  Scenario: Update sprint details
    Given I am viewing the master backlog
      And I want to edit the sprint named Sprint 001
      And I want to set the name of the sprint to sprint xxx
      And I want to set the sprint_start_date of the sprint to 2010-03-01
      And I want to set the effective_date of the sprint to 2010-03-20
     When I update the sprint
     Then the sprint should be updated accordingly
      And the request should complete successfully

  Scenario: Update sprint with no name
    Given I am viewing the master backlog
      And I want to edit the sprint named Sprint 001
      And I want to set the name of the sprint to an empty string
     When I update the sprint
     Then the server should return an update error

  Scenario: Move a story from product backlog to sprint backlog
    Given I am viewing the master backlog
     When I move the story named Story 1 to the 1st position of the sprint named Sprint 001
      And I move the story named Story 4 to the 2nd position of the sprint named Sprint 001
      And I move the story named Story 2 to the 1st position of the sprint named Sprint 002
      And I move the story named Story 4 to the 1st position of the sprint named Sprint 001
      And Story 4 should be in the 1st position of the sprint named Sprint 001
     Then Story 1 should be in the 2nd position of the sprint named Sprint 001
      And Story 2 should be in the 1st position of the sprint named Sprint 002
     
  Scenario: Request the project calendar feed
    Given I have set my API access key
      And I move the story named Story 4 to the 1st position of the sprint named Sprint 004
      And I am viewing the issues list
     When I download the calendar feed
     Then the request should complete successfully
