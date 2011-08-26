Feature: The issue hierarchy defines the allowed versions for each issue dependent on the type
  As a team member
  I want to CRUD issues with a reliable target version system
  So that I know what target version an issue can have or will be assigned

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And there is a role "scrum master"
    And the role "scrum master" may have the following rights:
        | view_master_backlog     |
        | view_taskboards         |
        | update_sprints          |
        | update_stories          |
        | create_impediments      |
        | update_impediments      |
        | update_tasks            |
        | subscribe_to_calendars  |
        | view_wiki_pages         |
        | edit_wiki_pages         |
        | view_issues             |
        | edit_issues             |
        | manage_subtasks         |
        | create_tasks            |
        | add_issues              |
    And the backlogs module is initialized
    And the following trackers are configured to track stories:
        | Story |
    And the tracker "Task" is configured to track tasks
    And the project uses the following trackers:
        | Story |
        | Epic  |
        | Task  |
        | Bug   |
    And the tracker "Task" has the default workflow for the role "scrum master"
    And there is 1 user with:
        | login | markus |
        | firstname | Markus |
        | Lastname | Master |
    And the user "markus" is a "scrum master"
    And the project has the following sprints:
        | name       | start_date | effective_date  |
        | Sprint 001 | 2010-01-01        | 2010-01-31      |
        | Sprint 002 | 2010-02-01        | 2010-02-28      |
        | Sprint 003 | 2010-03-01        | 2010-03-31      |
        | Sprint 004 | 2.weeks.ago       | 1.week.from_now |
        | Sprint 005 | 3.weeks.ago       | 2.weeks.from_now|
    And the project has the following stories in the following sprints:
        | position | subject | sprint     |
        | 5        | Story A | Sprint 001 |
        | 6        | Story B | Sprint 001 |
        | 7        | Story C | Sprint 002 |
    And there are the following issue status:
        | name        | is_closed  | is_default  |
        | New         | false      | true        |
        | In Progress | false      | false       |
        | Resolved    | false      | false       |
        | Closed      | true       | false       |
        | Rejected    | true       | false       |
    And I am logged in as "markus"

  @javascript
  Scenario: Creating a task, via the taskboard, as a subtask to a story sets the target version to the story´s version
    Given I am on the taskboard for "Sprint 001"
     When I click to add a new task for story "Story A"
      And I fill in "Task 0815" for "subject"
      And I press "OK"
     Then I should see "Task 0815" as a task to story "Story A"
      And the task "Task 0815" should have "Sprint 001" as its target version

  @javascript
  Scenario: Stale Object Error when creating task via the taskboard without 'Remaining Hours' after having created a task with 'Remaining Hours' after having created a task without 'Remaining Hours' (bug 9057)
    Given I am on the taskboard for "Sprint 001"
     When I click to add a new task for story "Story A"
      And I fill in "Task1" for "subject"
      And I fill in "3" for "remaining_hours"
      And I press "OK"
      And I click to add a new task for story "Story A"
      And I fill in "Task2" for "subject"
      And I press "OK"
      And I click to add a new task for story "Story A"
      And I fill in "Task3" for "subject"
      And I fill in "3" for "remaining_hours"
      And I press "OK"
      And the request on task "Task1" is finished
      And the request on task "Task2" is finished
      And the request on task "Task3" is finished
     Then there should not be a saving error on task "Task3"
      And the task "Task1" should have "Sprint 001" as its target version
      And the task "Task2" should have "Sprint 001" as its target version
      And the task "Task3" should have "Sprint 001" as its target version
      And task Task1 should have remaining_hours set to 3
      And task Task3 should have remaining_hours set to 3

  #Scenario: Moving a task between stories on the taskboard
  # not testable for now

  @javascript
  Scenario: Creating a task, via subtask, as a subtask to a story set´s the new task´s fixed version to the parent´s fixed version
     When I go to the page of the issue "Story A"
      And I follow "Add" within "div#issue_tree"
      And I select "Task" from "issue_tracker_id"
      And I fill in "Task 0815" for "issue_subject"
      And I press "Create"
     Then I should see "Sprint 001" within "td.fixed-version"

  @javascript
  Scenario: Creating a task, via new issue, as a subtask to a story is not possible
     When I go to the issues/new page of the project called "ecookbook"
      And I follow "New issue" within "#main-menu"
      And I select "Task" from "issue_tracker_id"
      And I fill in "Task 0815" for "issue_subject"
      And I fill in the id of the issue "Story A" as the parent issue
      And I press "Create"
     Then I should see "Sprint 001" within "td.fixed-version"

  @javascript
  Scenario: Moving a task between stories via issue/edit
    Given the project has the following tasks:
          | subject | parent  |
          | Task 1  | Story 1 |
    When I go to the edit page of the issue "Task 1"
     And I follow "More" within "#issue-form"
     And I fill in the id of the issue "Story C" as the parent issue
     And I press "Submit"
    Then I should see "Sprint 002" within "td.fixed-version"

  @javascript
  Scenario: Changing the fixed_version of a task with a non backlogs parent issue (bug 8354)
    Given the project has the following issues:
      | subject      | sprint     | tracker    |
      | Epic 1       | Sprint 001 | Epic       |
      And the project has the following tasks:
      | subject | parent |
      | Task 1  | Epic 1 |
    When I go to the edit page of the issue "Task 1"
     And I select "Sprint 002" from "issue_fixed_version_id"
     And I press "Submit"
    Then I should see "Successful update." within "div.flash"

