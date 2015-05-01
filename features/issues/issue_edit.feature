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

Feature: Issue edit
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
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages     |
      | edit_work_packages     |
      | add_work_package_notes |
    And there is 1 user with the following:
      | login | bob|
    And the user "bob" is a "member" in the project "omicronpersei8"
    And there are the following issue status:
      | name        | is_closed  | is_default  |
      | New         | false      | true        |
    Given the user "bob" has 1 issue with the following:
      |  subject      | issue1             |
      |  description  | Aioli Sali Grande  |
    And I am already logged in as "bob"

  Scenario: User updates an issue successfully
    When I go to the page of the issue "issue1"
    And I select "Update" from the action menu
    Then I fill in "Notes" with "human Horn"
    And I submit the form by the "Submit" button
    And I should see "Successful update." within ".notice"
    And I should see "human Horn" within "#history"

  @javascript
  Scenario: User updates an issue with previewing the stuff before
    When I go to the page of the issue "issue1"
    And I select "Update" from the action menu
    Then I fill in "Notes" with "human Horn"
    When I follow "Preview"
    Then I should see "human Horn" within "#preview"
    And I submit the form by the "Submit" button
    And I should see "Successful update." within ".notice"
    And I should see "human Horn" within "#history"

  Scenario: On an issue with children a user should not be able to change attributes which are overridden by children
    Given the user "bob" has 1 issue with the following:
      | subject | child1      |
    When I go to the edit page of the work package "issue1"
    Then there should not be a "% Done" field
    And there should be a disabled "Priority" field
    And there should be a disabled "Start date" field
    And there should be a disabled "Due date" field
    And there should be a disabled "Estimated time" field
