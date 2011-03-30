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
    And the backlogs module is initialized
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
        | position | subject | sprint     |
        | 5        | Story A | Sprint 001 |
        | 6        | Story B | Sprint 001 |
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
      And I should see 5 stories in "Product Backlog"

  @javascript
  Scenario: Create a new story in a sprint
    Given I am on the master backlog
     When I open the "Sprint 001" menu
      And I follow "New Story" within the "Sprint 001" menu
      And I close the "Sprint 001" menu
      And I fill in "The Wizard of Oz" for "subject"
      And I confirm the story form
     Then the 1st story in the "Sprint 001" should be "The Wizard of Oz"
      And I should see 3 stories in "Sprint 001"

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
      And I confirm the story form
     Then the 1st story in the "Sprint 001" should be "Story A revisited"
      And I should see 2 stories in "Sprint 001"
