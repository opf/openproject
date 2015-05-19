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
      | pe1     | Phase1  | status1 | version1      |
      | pe2     |         |         |               |
    And I am already logged in as "manager"

  @javascript
  Scenario: Updating the work package and seeing the results on the show page
    When I go to the edit page of the work package called "pe1"
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
      | % done         | 30 %        |
      | Priority       | prio2       |
      | Status         | status2     |
      | Subject        | New subject |
      | Description    | Desc2       |
    And I fill in the id of work package "pe2" into "Parent"
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
    And the work package "pe2" should be shown as the parent

  Scenario: Concurrent updates to work packages
    When I go to the edit page of the work package called "pe1"
    And I fill in the following:
      | Start date     | 03-04-2013   |
    And the work_package "pe1" is updated with the following:
      | Start date | 04-04-2013 |
    And I submit the form by the "Submit" button
    Then I should see "Information has been updated by at least one other user in the meantime."
    And I should see "The update(s) came from"

  Scenario: Adding a note
    When I go to the edit page of the work package called "pe1"
     And I fill in "Notes" with "Note message"
     And I submit the form by the "Submit" button
    Then I should be on the page of the work package "pe1"
     And I should see a journal with the following:
      | Notes | Note message |
