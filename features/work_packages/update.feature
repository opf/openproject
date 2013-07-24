#-- copyright
#
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Updating work packages
  Background:
    Given there is 1 user with:
      | login     | manager |
      | firstname | the     |
      | lastname  | manager |
    And there are the following planning element types:
      | Name      |
      | Phase1    |
      | Phase2    |
    And there are the following project types:
      | Name                  |
      | Standard Project      |
    And the following planning element types are default for projects of type "Standard Project"
      | Phase1 |
      | Phase2 |
    And there is 1 project with the following:
      | identifier | ecookbook |
      | name       | ecookbook |
    And the project named "ecookbook" is of the type "Standard Project"
    And there is a role "manager"
    And the role "manager" may have the following rights:
      | edit_work_packages |
      | view_work_packages |
      | manage_subtasks    |
    And I am working in project "ecookbook"
    And the user "manager" is a "manager"
    And there are the following priorities:
      | name  | default |
      | prio1 | true    |
      | prio2 |         |
    And there are the following status:
      | name    | default |
      | status1 | true    |
      | status2 |         |
    And there are the following planning elements in project "ecookbook":
      | subject |
      | pe1     |
      | pe2     |
    And I am already logged in as "manager"

  @javascript
  Scenario: Updating the work package and seeing the results on the show page
    When I go to the edit page of the work package called "pe1"
    And I follow "More"
    And I fill in the following:
      | Responsible    | the manager |
      | Assignee       | the manager |
      | Start date     | 2013-03-04  |
      | Due date       | 2013-03-06  |
      | Estimated time | 5.00        |
      | % done         | 30 %        |
      | Priority       | prio2       |
      | Status         | status2     |
      | Subject        | New subject |
      | Type           | Phase2      |
      | Description    | Desc2       |
    # Nested set is broken right now for planning elements
    #And I fill in the id of work package "pe2" into "Parent"
    And I submit the form by the "Submit" button

    Then I should be on the page of the work package "New subject"
    And the work package should be shown with the following values:
      | Responsible    | the manager |
      | Assignee       | the manager |
      | Start date     | 03/04/2013  |
      | Due date       | 03/06/2013  |
      | Estimated time | 5.00        |
      | % done         | 30          |
      | Priority       | prio2       |
      | Status         | status2     |
      | Subject        | New subject |
      | Type           | Phase2      |
      | Description    | Desc2       |
    #And the work package "pe2" should be shown as the parent

  Scenario: Adding a note
    When I go to the edit page of the work package called "pe1"
     And I fill in "Notes" with "Note message"
     And I submit the form by the "Submit" button
    Then I should be on the page of the work package "pe1"
     And I should see a journal with the following:
      | Notes | Note message |
