Feature: Edit story tracker and status
  As a user
  I want to edit the tracker and the status of a story
  In consideration of existing workflows
  So that I can not make changes that are not permitted by the system

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
        | login | romano |
    And there is a role "manager"
    And the user "romano" is a "manager"
    And the role "manager" may have the following rights:
        | view_master_backlog   |
        | create_stories        |
        | update_stories        |
        | view_issues           |
        | edit_issues           |
        | manage_subtasks       |
    And the project has the following sprints:
        | name       | start_date | effective_date |
        | Sprint 001 | 2010-01-01        | 2010-01-31     |
    And there are the following issue status:
        | name        | is_closed  | is_default  |
        | New         | false      | true        |
        | Resolved    | false      | false       |
        | Closed      | true       | false       |
        | Rejected    | true       | false       |
    And the project has the following stories in the following sprints:
        | position | subject | sprint      | tracker | status | story_points |
        | 5        | Story A | Sprint 001  | Bug    | New     | 10           |
        | 6        | Story B | Sprint 001  | Story  | New     | 20           |
        | 7        | Story C | Sprint 001  | Bug  | Resolved  | 20           |
    And the Tracker "Story" has for the Role "manager" the following workflows:
        | old_status | new_status |
        | New        | Rejected   |
        | Rejected   | Closed     |
        | Rejected   | New        |
    And the Tracker "Bug" has for the Role "manager" the following workflows:
        | old_status | new_status |
        | New        | Closed |
    And I am logged in as "romano"

  @javascript
  Scenario: Display only statuses which are allowed by workflow
    Given I am on the master backlog
     When I click on the text "Story A"
     Then "Closed" should be an option for "status_id" within ".editors"
     And "Rejected" should not be an option for "status_id" within ".editors"
     And I select "Closed" from "status_id"
     And I confirm the story form
     Then I should not see the status "New" for "Story A" within ".status_id.editable"
     And I should see the status "Closed" for "Story A" within ".status_id.editable"
     And "Rejected" should not be an option for "status_id" within ".editors"

  @javascript
  Scenario: Select a status and change to a tracker that does not offer the status
    Given I am on the master backlog
     When I click on the text "Story B"
     Then "Rejected" should be an option for "status_id"
     When I select "Rejected" from "status_id"
     And I select "Bug" from "tracker_id"
     Then the "status_id" field within ".editors" should contain "" 
     And "New" should be an option for "status_id"
     When I confirm the story form
     Then the error alert should show "Status can't be blank"
     When I press "OK"
     When I click on the text "Story B"
     And I select "New" from "status_id"
     And I confirm the story form
     Then I should see the status "New" for "Story B" within ".status_id.editable"

  @javascript
  Scenario: Edit a story having no permission for the status of the current ticket
    Given I am on the master backlog
     When I click on the text "Story C"
     Then "Resolved" should be an option for "status_id"
     And "New" should be an option for "status_id"
     When I confirm the story form
     Then I should see the status "Resolved" for "Story C" within ".status_id.editable"
