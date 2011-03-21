Feature: Product Owner
  As a product owner
  I want to manage story details and story priority
  So that they get done according to my requirements

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And the backlogs module is initialized
    And there is 1 user with:
        | login | mathias |
    And there is a role "product owner"
    And the role "product owner" may have the following rights:
        | view_master_backlog   |
        | create_stories        |
        | update_stories        |
        | view_issues           |
        | edit_issues           |
        | manage_subtasks       |
    And the user "mathias" is a "product owner"
    And the project has the following sprints:
        | name       | sprint_start_date | effective_date |
        | Sprint 001 | 2010-01-01        | 2010-01-31     |
        | Sprint 002 | 2010-02-01        | 2010-02-28     |
        | Sprint 003 | 2010-03-01        | 2010-03-31     |
        | Sprint 004 | 2010-03-01        | 2010-03-31     |
    And the project has the following stories in the product backlog:
        | position | subject |
        | 1        | Story 1 |
        | 2        | Story 2 |
        | 3        | Story 3 |
        | 4        | Story 4 |
    And the project has the following stories in the following sprints:
        | position | subject | sprint     |
        | 5        | Story A | Sprint 001 |
        | 6        | Story B | Sprint 001 |
    And I am logged in as "mathias"

  Scenario: View the product backlog
     When I go to the master backlog
     Then I should see the product backlog
      And I should see 4 stories in the product backlog
      And I should see 4 sprint backlogs

  Scenario: Create a new story
     When I go to the master backlog
      And I want to create a story
      And I set the subject of the story to A Whole New Story
      And I create the story
     Then the 1st story in the product backlog should be A Whole New Story
      And all positions should be unique

  Scenario: Update a story
    Given I am on the master backlog
      And I want to edit the story with subject Story 3
      And I set the subject of the story to Relaxdiego was here
      And I set the tracker of the story to Bug
     When I update the story
     Then the story should have a subject of Relaxdiego was here
      And the story should have a tracker of Bug
      And the story should be at position 3

  Scenario: Close a story
    Given I am on the master backlog
      And I want to edit the story with subject Story 4
      And I set the status of the story to Closed
     When I update the story
     Then the status of the story should be set as closed

  Scenario: Move a story to the top
    Given I am on the master backlog
     When I move the 3rd story to the 1st position
     Then the 1st story in the product backlog should be Story 3

  Scenario: Move a story to the bottom
    Given I am on the master backlog
     When I move the 2nd story to the last position
     Then the 4th story in the product backlog should be Story 2

  Scenario: Move a story down
    Given I am on the master backlog
     When I move the 2nd story to the 3rd position
     Then the 2nd story in the product backlog should be Story 3
      And the 3rd story in the product backlog should be Story 2
      And the 4th story in the product backlog should be Story 4

  Scenario: Move a story up
    Given I am on the master backlog
     When I move the 4th story to the 2nd position
     Then the 2nd story in the product backlog should be Story 4
      And the 3rd story in the product backlog should be Story 2
      And the 4th story in the product backlog should be Story 3

