#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Updating work packages
  Background:
    Given there is 1 user with:
      | login     | manager |
      | firstname | the     |
      | lastname  | manager |
    And the user "manager" has the following preferences
      | warn_on_leaving_unsaved | false |
    And there are the following types:
      | Name   | Is milestone |
      | Phase1 | false        |
      | Phase2 | false        |
    And there are the following project types:
      | Name                  |
      | Standard Project      |
    And there is 1 project with the following:
      | identifier | ecookbook |
      | name       | ecookbook |
    And the project named "ecookbook" is of the type "Standard Project"
    And the following types are enabled for projects of type "Standard Project"
      | Phase1 |
      | Phase2 |
    And there is a role "manager"
    And the role "manager" may have the following rights:
      | edit_work_packages     |
      | view_work_packages     |
      | manage_subtasks        |
      | add_work_package_notes |
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
    And the project "ecookbook" has 1 version with the following:
      | name | version1 |
    And the type "Phase1" has the default workflow for the role "manager"
    And the type "Phase2" has the default workflow for the role "manager"
    And there are the following work packages in project "ecookbook":
      | subject | type    | status  | fixed_version |
      | wp1     | Phase1  | status1 | version1      |
    And I am already logged in as "manager"

  @javascript
  Scenario: Updating the work package and seeing the results on the show page
    When I go to the edit page of the work package called "wp1"
    And I click the edit work package button
    And I click on "Show all"
    And I fill in the following:
      | Type           | Phase2      |
    # This is to be removed once the bug
    # that clears the inserted/selected values
    # after a type refresh is fixed.
    And I wait for the AJAX requests to finish
    And I fill in the following:
      | Responsible    | the manager |
      | Assignee       | the manager |
      | Start date     | 2013-03-04  |
      | Due date       | 2013-03-06  |
      | Estimated time | 5.00        |
      | Progress (%)   | 30          |
      | Priority       | prio2       |
      | Status         | status2     |
      | Subject        | New subject |
      | Description    | Desc2       |
    And I submit the form by the "Save" button
    And I wait for the AJAX requests to finish
    Then I should see "Successful update"
    Then I should be on the page of the work package "New subject"
    And the work package should be shown with the following values:
      | Responsible    | the manager |
      | Assignee       | the manager |
      | Date           | 03/04/2013 - 03/06/2013 |
      | Estimated time | 5.00        |
      | Progress (%)   | 30          |
      | Priority       | prio2       |
      | Status         | status2     |
      | Subject        | New subject |
      | Type           | Phase2      |
      | Description    | Desc2       |

  @javascript
  Scenario: User adds a comment to a work package with previewing the stuff before
    When I go to the page of the issue "wp1"
    And I click on the edit button
    And I fill in a comment with "human horn"
    And I preview the comment to be added and see "human horn"
    And I submit the form by the "Save" button
    And I should see the comment "human horn"

  @javascript
  Scenario: On a work package with children a user should not be able to change attributes which are overridden by children
    And there are the following work packages in project "ecookbook":
      | subject | type   | status  | fixed_version | priority | done_ratio | estimated_hours | start_date | due_date   |
      | child   | Phase1 | status1 | version1      | prio2    | 50         | 5               | 2015-10-01 | 2015-10-30 |
      | parent  |        |         |               |          | 0          |                 |            |            |
    Given the work package "parent" has the following children:
      | child |
    When I go to the edit page of the work package "parent"
    And I click the edit work package button
    And I click on "Show all"
    Then the work package should be shown with the following values:
      | Priority       | prio2                   |
      | Date           | 10/01/2015 - 10/30/2015 |
      | Estimated time | 5                       |
      | Progress (%)   | 50                      |
    And there should not be a "Progress \(%\)" field
    And there should not be a "Priority" field
    And there should not be a "Start date" field
    And there should not be a "End date" field
    And there should not be a "Estimated time" field
