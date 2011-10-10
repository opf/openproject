Feature: The issue hierarchy between backlogs stories and backlogs tasks can not span project boundaries
  As a scrum user
  I want to limit the issue hierarchy to not span project boundaries between backlogs stories and backlogs tasks
  So that I can manage stories more securely

  Background:
    Given there is 1 project with:
        | name  | parent_project |
    And I am working in project "parent_project"
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
    And there are the following issue status:
        | name        | is_closed  | is_default  |
        | New         | false      | true        |
        | In Progress | false      | false       |
        | Resolved    | false      | false       |
        | Closed      | true       | false       |
        | Rejected    | true       | false       |
    And there is 1 user with:
        | login | markus |
        | firstname | Markus |
        | Lastname | Master |
    And there is 1 project with:
        | name  | child_project  |
    And the project uses the following modules:
        | backlogs |
    And the user "markus" is a "scrum master" in the project "parent_project"
    And the user "markus" is a "scrum master" in the project "child_project"
    And I am logged in as "markus"

  @javascript
  Scenario: Adding a task in the child project as a child to the story is inhibited
   Given the project "parent_project" has the following issues:
        | subject      | tracker    |
        | Story A      | Story      |
   When I go to the issues/new page of the project called "child_project"
    And I select "Task" from "issue_tracker_id"
    And I fill in "Task 0815" for "issue_subject"
    And I fill in the id of the issue "Story A" as the parent issue
    And I press "Create"
   Then I should be notified that the issue "Story A" is an invalid parent to the issue "Task 0815" because of cross project limitations
