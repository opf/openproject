#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Viewing a work package
  Background:
    Given there is 1 project with the following:
      | identifier | omicronpersei8 |
      | name       | omicronpersei8 |
    And I am working in project "omicronpersei8"
    And the project "omicronpersei8" has the following types:
      | name | position |
      | Bug  |     1    |
    And there is a default issuepriority with:
      | name   | Normal |
    And there is a issuepriority with:
      | name   | High |
    And there is a issuepriority with:
      | name   | Immediate |

    And there are the following types:
      | Name  | Is Milestone | In aggregation | Is default |
      | Phase | false        | true           | true       |

    And there is a role "member"
    And the role "member" may have the following rights:
      | manage_subtasks               |
      | manage_work_package_relations |
      | view_work_packages            |
      | edit_work_packages            |
      | move_work_packages            |
      | add_issues                    |
      | add_work_package              |
      | edit_planning_elements        |
      | log_time                      |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "member" in the project "omicronpersei8"
    And there are the following issue status:
      | name        | is_closed  | is_default  |
      | New         | false      | true        |

    And there are the following issues in project "omicronpersei8":
      | subject | type |
      | issue1  | Bug  |
      | issue2  | Bug  |
      | issue3  | Bug  |

    And there are the following planning elements in project "omicronpersei8":
      | subject | start_date | due_date   |
      | pe1     | 2013-01-01 | 2013-12-31 |
      | pe2     | 2013-01-01 | 2013-12-31 |

    And the work package "issue1" has the following children:
      | issue2 |

    And the work package "pe1" has the following children:
      | pe2    |

    And I am already logged in as "bob"

  Scenario: Call the work package page for an issue and view the issue
    When I go to the page of the work package "issue1"
    Then I should see "Bug #1: issue1"
    Then I should see "Bug #2: issue2" within ".idnt-1"

  Scenario: Call the work package page for a planning element and view the planning element
    When I go to the page of the planning element "pe1" of the project called "omicronpersei8"
    Then I should see "#4: pe1"
    Then I should see "#5: pe2" within ".idnt-1"

  Scenario: View child work package of type issue
    When I go to the page of the work package "issue1"
    When I click on "Bug #2" within ".idnt-1"
    Then I should see "Bug #2: issue2"
    Then I should see "Bug #1: issue1" within ".work-package-1"

  Scenario: View child work package of type planning element
    When I go to the page of the work package "pe1"
    When I click on "#5" within ".idnt-1"
    Then I should see "#5: pe2"
    Then I should see "#4: pe1" within ".work-package-4"

  Scenario: Add subtask leads to issue creation page for a parent issue
    When I go to the page of the work package "issue1"
    Then I should see "Add subtask"
    When I click on "Add subtask"
    Then I should be on the new work_package page of the project called "omicronpersei8"

  Scenario: Add subtask leads to planning element creation page for a parent planning element
    When I go to the page of the work package "pe1"
    Then I should see "Add subtask"
    When I click on "Add subtask"
    Then I should be on the new work_package page of the project called "omicronpersei8"

  @javascript
  Scenario: Adding a relation will add it to the list of related work packages through AJAX instantly
    When I go to the page of the work package "issue1"
    And I click on "Add related work package"
    And I fill in "relation_issue_to_id" with "3"
    And I press "Add"
    And I wait for the AJAX requests to finish
    Then I should be on the page of the work package "issue1"
    And I should see "related to Bug #3: issue3"

  @javascript
  Scenario: Removing an existing relation will remove it from the list of related work packages through AJAX instantly
    Given a relation between "issue1" and "issue3"
    When I go to the page of the work package "issue1"
    Then I should see "Bug #3: issue3"
    When I click "Delete relation"
    And I wait for the AJAX requests to finish
    Then I should be on the page of the work package "issue1"
    Then I should not see "Bug #3: issue3"

  @javascript
  Scenario: User adds herself as watcher to an issue
    When I go to the page of the work package "issue1"
    Then I should see "Watch" within "#content > .action_menu_main"
    When I click "Watch" within "#content > .action_menu_main"
    Then I should see "Unwatch" within "#content > .action_menu_main"

  @javascript
  Scenario: User adds herself as watcher to a planning element
    When I go to the page of the work package "pe1"
    Then I should see "Watch" within "#content > .action_menu_main"
    When I click "Watch" within "#content > .action_menu_main"
    Then I should see "Unwatch" within "#content > .action_menu_main"

  @javascript
  Scenario: User removes herself as watcher from an issue
    Given user is already watching "issue1"
    When I go to the page of the work package "issue1"
    Then I should see "Unwatch" within "#content > .action_menu_main"
    When I click "Unwatch" within "#content > .action_menu_main"
    Then I should see "Watch" within "#content > .action_menu_main"

  @javascript
  Scenario: User removes herself as watcher from a planning element
    Given user is already watching "pe1"
    When I go to the page of the work package "pe1"
    Then I should see "Unwatch" within "#content > .action_menu_main"
    When I click "Unwatch" within "#content > .action_menu_main"
    Then I should see "Watch" within "#content > .action_menu_main"

  @javascript
  Scenario: Log time leads to time entry creation page for issues
    When I go to the page of the work package "issue1"
    When I select "Log time" from the action menu

    Then I should see "Spent time"

  @javascript
  Scenario: Log time leads to time entry creation page for planning element
    When I go to the page of the work package "pe1"
    When I select "Log time" from the action menu

    Then I should see "Spent time"

  @javascript
  Scenario: For an issue copy leads to work package copy page
    When I go to the page of the work package "issue1"
    When I select "Copy" from the action menu

    Then I should see "Copy"

  @javascript
  Scenario: For a planning element copy leads to work package copy page
    When I go to the page of the work package "pe1"
    When I select "Copy" from the action menu

    Then I should see "Copy"

  @javascript
  Scenario: For an issue move leads to work package copy page
    When I go to the page of the work package "issue1"
    When I select "Move" from the action menu

    Then I should see "Move"

  @javascript
  Scenario: For a planning element move leads to work package copy page
    When I go to the page of the work package "pe1"
    When I select "Move" from the action menu

    Then I should see "Move"
