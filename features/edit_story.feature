Feature: Edit story on backlogs view
  As a team member
  I want to manage story details and story priority on the scrum backlogs view
  So that I do not loose context while filling in details

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And the following trackers are configured to track stories:
        | Story |
        | Epic  |
        | Bug   |
    And the tracker "Task" is configured to track tasks
    And the project uses the following trackers:
        | Story |
        | Bug   |
        | Task  |
    And there is 1 user with:
        | login | mathias |
    And there is a role "team member"
    And the role "team member" may have the following rights:
        | view_master_backlog   |
        | create_stories        |
        | update_stories        |
        | view_issues           |
        | edit_issues           |
        | manage_subtasks       |
    And the user "mathias" is a "team member"
    And the project has the following sprints:
        | name       | sprint_start_date | effective_date |
        | Sprint 001 | 2010-01-01        | 2010-01-31     |
        | Sprint 002 | 2010-02-01        | 2010-02-28     |
        | Sprint 003 | 2010-03-01        | 2010-03-31     |
        | Sprint 004 | 2010-03-01        | 2010-03-31     |
    And the project has the following owner backlogs:
        | Product Backlog |
        | Wishlist        |
    And the project has the following stories in the following owner backlogs:
        | position | subject | backlog         |
        | 1        | Story 1 | Product Backlog |
        | 2        | Story 2 | Product Backlog |
        | 3        | Story 3 | Product Backlog |
        | 4        | Story 4 | Product Backlog |
    And the project has the following stories in the following sprints:
        | position | subject | sprint     | story_points |
        | 5        | Story A | Sprint 001 | 10           |
        | 6        | Story B | Sprint 001 | 20           |
    And I am logged in as "mathias"

  @javascript
  Scenario: Create a new story in the backlog
    Given I am on the master backlog
     When I open the "Product Backlog" menu
      And I follow "New Story" within the "Product Backlog" menu
      And I close the "Product Backlog" menu
      And I fill in "Alice in Wonderland" for "subject"
      And I confirm the story form
     Then the 1st story in the "Product Backlog" should be "Alice in Wonderland"
      And the 1st story in the "Product Backlog" should have the ID of "Alice in Wonderland"
      And I should see 5 stories in "Product Backlog"

  @javascript
  Scenario: Create a new story in a sprint
    Given I am on the master backlog
     When I open the "Sprint 001" menu
      And I follow "New Story" within the "Sprint 001" menu
      And I close the "Sprint 001" menu
      And I fill in "The Wizard of Oz" for "subject"
      And I fill in "3" for "story_points"
      And I confirm the story form
     Then the 1st story in the "Sprint 001" should be "The Wizard of Oz"
      And the 1st story in the "Sprint 001" should have the ID of "The Wizard of Oz"
      And I should see 3 stories in "Sprint 001"
      And the velocity of "Sprint 001" should be "33"

  @javascript
  Scenario: Edit story in the backlog
    Given I am on the master backlog
     When I click on the text "Story 2"
      And I fill in "Story 2 revisited" for "subject"
      And I confirm the story form
     Then the 2nd story in the "Product Backlog" should be "Story 2 revisited"
      And I should see 4 stories in "Product Backlog"

  @javascript
  Scenario: Edit story in a sprint
    Given I am on the master backlog
     When I click on the text "Story A"
      And I fill in "Story A revisited" for "subject"
      And I fill in "11" for "story_points"
      And I confirm the story form
     Then the 1st story in the "Sprint 001" should be "Story A revisited"
      And I should see 2 stories in "Sprint 001"
      And the velocity of "Sprint 001" should be "31"

  @javascript
  Scenario: Setting trackers of a story
    Given I am on the master backlog
     When I open the "Sprint 001" menu
      And I follow "New Story" within the "Sprint 001" menu
      And I close the "Sprint 001" menu
      And I fill in "The Wizard of Oz" for "subject"
      And I select "Bug" from "tracker_id"
      And I confirm the story form
     Then the 1st story in "Sprint 001" should be "The Wizard of Oz"
      And the 1st story in "Sprint 001" should be in the "Bug" tracker

  @javascript
  Scenario: Hiding trackers, that are not active in the project
    Given I am on the master backlog
     When I open the "Sprint 001" menu
      And I follow "New Story" within the "Sprint 001" menu
      And I close the "Sprint 001" menu
     Then I should not see "Epic" within "select[name=tracker_id]"
