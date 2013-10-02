Feature: Version Settings
  As a Project Admin
  I want to configure the backlogs plugin
  So that my team and I can work effectively

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And the backlogs module is initialized
    And there is 1 user with:
        | login | padme |
    And there is a role "project admin"
    And the role "project admin" may have the following rights:
        | manage_versions     |
        | view_master_backlog |
    And the user "padme" is a "project admin"
    And there is a default Status with:
        | name | new |
    And the project has the following sprints:
        | name       | start_date        | effective_date |
        | Sprint 001 | 2010-01-01        | 2010-01-31     |
        | Sprint 002 | 2010-02-01        | 2010-02-28     |
        | Sprint 003 | 2010-03-01        | 2010-03-31     |
        | Sprint 004 | 2010-03-01        | 2010-03-31     |
    And I am already logged in as "padme"

  Scenario: Creating a new version
    When I go to the versions/new page of the project called "ecookbook"
     And I fill in "version_name" with "Sprint X"
     And I press "Create"
    Then I should be on the settings/versions page of the project called "ecookbook"
     And I should see "Successful creation." within "div.notice"
     And I should see "Sprint X" within "table.versions"

  Scenario: One can select whether versions are displayed left or right (left is default) in the backlogs page
    When I go to the edit page of the version called "Sprint 001"

    Then the editable attributes of the version should be the following:
      | Column in backlog | left |

    When I select "right" from "Column in backlog"
    And I press "Save"

    Then I should be on the settings/versions page of the project called "ecookbook"

  Scenario: Inherited versions can also be configured to be displayed left, right or not at all
    Given there is 1 project with:
        | name  | parent  |
    And I am working in project "parent"
    And the project uses the following modules:
        | backlogs |
    And the project has the following sprints:
        | name       | start_date | effective_date | sharing       |
        | shared     | 2010-01-01        | 2010-01-31     | system        |
    And I am working in project "ecookbook"

    When I go to the settings/versions page of the project called "ecookbook"

    Then I should see "Edit" within ".version.shared .buttons"

    When I follow "Edit" within ".version.shared .buttons"

    Then the editable attributes of the version should be the following:
      | Column in backlog | left |

    When I select "right" from "Column in backlog"
    And I press "Save"

    Then I should be on the settings/versions page of the project called "ecookbook"

  Scenario: Setting "Column in backlog" to the different settings
    When I go to the edit page of the version called "Sprint 001"
    And I select "right" from "Column in backlog"
    And I press "Save"
    And I go to the edit page of the version called "Sprint 001"

    Then the editable attributes of the version should be the following:
      | Column in backlog | right |

    When I go to the edit page of the version called "Sprint 002"
    And I select "left" from "Column in backlog"
    And I press "Save"
    And I go to the edit page of the version called "Sprint 002"

    Then the editable attributes of the version should be the following:
      | Column in backlog | left |

    When I go to the edit page of the version called "Sprint 003"
    And I select "none" from "Column in backlog"
    And I press "Save"
    And I go to the edit page of the version called "Sprint 003"

    Then the editable attributes of the version should be the following:
      | Column in backlog | none |

    When I go to the master backlog of the project "ecookbook"

    Then I should see "Sprint 001" within "#owner_backlogs_container"
    And I should see "Sprint 002" within "#sprint_backlogs_container"
    And I should not see "Sprint 003" within "#owner_backlogs_container"
    And I should not see "Sprint 003" within "#sprint_backlogs_container"

  Scenario: There should be a version start date field
    When I go to the edit page of the version called "Sprint 001"
    Then the editable attributes of the version should be the following:
      | Start date | 2010-01-01 |

  Scenario: former sprint_start_date and start_date are the same
    When I go to the edit page of the version called "Sprint 001"
    And I fill in "2010-01-20" for "version_start_date"
    And I press "Save"
    And I go to the master backlog of the project "ecookbook"
    Then the start date of "Sprint 001" should be "2010-01-20"
