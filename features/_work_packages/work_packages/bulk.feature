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
    And the project "ecookbook" has 1 version with the following:
      | name | version1 |
    And the type "Phase1" has the default workflow for the role "manager"
    And the type "Phase2" has the default workflow for the role "manager"
    And there are the following work packages in project "ecookbook":
      | subject | type    | status  | fixed_version | assigned_to |
      | pe1     | Phase1  | status1 | version1      | manager     |
      | pe2     |         |         |               | manager     |
    And I am already logged in as "manager"

  @wip @javascript
  Scenario: Bulk updating the fixed version of several work packages
    When I go to the work package index page of the project called "ecookbook"
    And  I open the context menu on the work packages:
      | pe1 |
      | pe2 |
    And I hover over ".fixed_version .context_item"
    And I follow "none" within "#work-package-context-menu"
    Then I should see "Successful update"
    And I follow "pe1"
    And I should see "deleted (version1)"

  @javascript
    Scenario: Bulk updating several work packages without back url should return index
      When I go to the work package index page of the project called "ecookbook"
      And  I open the context menu on the work packages:
        | pe1 |
        | pe2 |
      And I follow "Edit" within "#work-package-context-menu"
      And I press "Submit"
      Then I should see "Work Packages" within ".title-container"

  @wip @javascript
  Scenario: Bulk updating the fixed version of several work packages
    When I go to the work package index page of the project called "ecookbook"
    And  I open the context menu on the work packages:
      | pe1 |
      | pe2 |
    And I hover over ".assigned_to .context_item"
    And I follow "none" within "#work-package-context-menu"
    Then I should see "Successful update"
    Then the attribute "assigned_to" of work package "pe1" should be ""
