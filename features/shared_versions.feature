Feature: Shared Versions
  As a Team Members
  I want to use versions shared by other projects
  So that I can distribute work efficiently

  Background:
    Given there is 1 project with:
        | name  | parent    |
    And the project "parent" has the following sprints:
        | name          | sharing     | start_date | effective_date |
        | ParentSprint  | system      | 2010-01-01        | 2010-01-31     |
    And there is 1 project with:
        | name  | child |
    And the project "child" uses the following modules:
        | backlogs |
    And the following trackers are configured to track stories:
        | story |
        | epic  |
    And the tracker "task" is configured to track tasks
    And the project "parent" uses the following trackers:
        | story |
        | task  |
    And the project "child" uses the following trackers:
        | story |
        | task  |
    And I am working in project "child"
    And there is 1 user with:
        | login | padme |
    And there is a role "project admin"
    And the role "project admin" may have the following rights:
        | manage_versions   |
        | view_issues       |
        | view_master_backlog   |
        | create_stories        |
        | update_stories        |
        | edit_issues           |
        | manage_subtasks       |
    And the user "padme" is a "project admin"
    And the project has the following sprints:
        | name       | start_date | effective_date |
        | ChildSprint | 2010-03-01        | 2010-03-31    |
    And I am logged in as "padme"

  Scenario: Inherited Sprints are displayed
    Given I am on the master backlog
    Then I should see "ParentSprint" within ".sprint .name"

  Scenario: Only stories of current project are displayed
    Given the project "parent" has the following stories in the following sprints:
      | position | subject        | backlog        |
      | 1        | ParentStory    | ParentSprint   |
    And the project "child" has the following stories in the following sprints:
      | position | subject        | backlog        |
      | 1        | ChildStory     | ParentSprint   |
    And I am on the master backlog
    Then I should see "ChildStory" within ".backlog .story .subject"
    And I should not see "ParentStory" within ".backlog .story .subject"
