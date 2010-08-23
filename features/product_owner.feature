Feature: Product Owner
  As a product owner
  I want to manage stories
  So that they get done according to my needs

  Background:
    Given the ecookbook project has the backlogs plugin enabled
    And I am a product owner of the project
    And the project has the following sprints:
      | name       | sprint_start_date | effective_date |
      | sprint 001 | 2010-01-01        | 2010-01-31     |
      | sprint 002 | 2010-02-01        | 2010-02-28     |
      | sprint 003 | 2010-03-01        | 2010-03-31     |
    And the project has the following stories in the product backlog:
      | position | subject |
      | 1        | Story 1 |
      | 2        | Story 2 |
      | 3        | Story 3 |
      | 4        | Story 4 |

  Scenario: View the product backlog
    Given I am viewing the master backlog
    Then I should see the product backlog

  Scenario: Create a new story
    Given I am viewing the master backlog
    And I want to create a new story
    When I set the subject of the story to A Whole New Story
    And I create the story
    Then the 1st story should be A Whole New Story
    And the 1st position should be unique

  Scenario: Update a story
    Given I am viewing the master backlog
    And I want to update the story with subject Story 3
    When I set the subject of the story to Relaxdiego was here
    And I set the tracker of the story to Bug
    When I update the story  
    Then the story should have a subject of Relaxdiego was here
    And the story should have a tracker of Bug
    And the story should have a position of 3

  Scenario: Close a story
    Given I am viewing the master backlog
    When I close Story 2
    Then the status of the story should be set as closed

  Scenario: Move a story to the top
    Given I am viewing the master backlog
    When I move the 3rd story to the 1st position
    Then the 1st story should be Story 3

  Scenario: Move a story to the bottom
    Given I am viewing the master backlog
    When I move the 2nd story to the last position
    Then the 4th story should be Story 2

  Scenario: Move a story down
    Given I am viewing the master backlog
    When I move the 2nd story to the 3rd position
    Then the 2nd story should be Story 3
    And the 3rd story should be Story 2
    And the 4th story should be Story 4

  Scenario: Move a story up
    Given I am viewing the master backlog
    When I move the 4th story to the 2nd position
    Then the 2nd story should be Story 4
    And the 3rd story should be Story 2
    And the 4th story should be Story 3
    