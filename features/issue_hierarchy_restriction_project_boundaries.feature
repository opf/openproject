Feature: The work_package hierarchy between backlogs stories and backlogs tasks can not span project boundaries
  As a scrum user
  I want to limit the work_package hierarchy to not span project boundaries between backlogs stories and backlogs tasks
  So that I can manage stories more securely

  Background:
    Given there is 1 project with:
        | name       | parent_project |
        | identifier | parent_project |
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
        | view_work_packages      |
        | edit_work_packages      |
        | manage_subtasks         |
        | create_tasks            |
        | add_work_packages              |
        | add_work_packages       |
    And the backlogs module is initialized
    And the following types are configured to track stories:
        | Story |
    And the type "Task" is configured to track tasks
    And the project uses the following types:
        | Story |
        | Epic  |
        | Task  |
        | Bug   |
    And the type "Task" has the default workflow for the role "scrum master"
    And there are the following work_package status:
        | name        | is_closed  | is_default  |
        | New         | false      | true        |
        | In Progress | false      | false       |
        | Resolved    | false      | false       |
        | Closed      | true       | false       |
        | Rejected    | true       | false       |
    And there is a default issuepriority with:
        | name   | Normal |
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
    And the "cross_project_issue_relations" setting is set to true
    And I am already logged in as "markus"

  @javascript
  Scenario: Adding a task in the child project as a child to the story is inhibited
   Given the project "parent_project" has the following work_packages:
        | subject      | type    |
        | Story A      | Story      |
   When I go to the work_packages/new page of the project called "child_project"
    And I select "Task" from "work_package_type_id"
    And I fill in "Task 0815" for "work_package_subject"
    And I fill in the id of the work_package "Story A" as the parent work_package
    And I click on the first button matching "Create"
   Then I should be notified that the work_package "Story A" is an invalid parent to the work_package "Task 0815" because of cross project limitations
