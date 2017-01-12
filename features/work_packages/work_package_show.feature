#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
      | add_work_packages             |
      | edit_work_packages            |
      | log_time                      |
      | delete_work_packages          |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "member" in the project "omicronpersei8"
    And there are the following issue status:
      | name        | is_closed  | is_default  |
      | New         | false      | true        |
    And there are the following issues in project "omicronpersei8":
      | subject | type | description | author |
      | issue1  | Bug  | "1"         | bob    |
      | issue2  | Bug  | "2"         | bob    |
      | issue3  | Bug  | "3"         | bob    |
    And there are the following work packages in project "omicronpersei8":
      | subject | start_date | due_date   |
      | pe1     | 2013-01-01 | 2013-12-31 |
      | pe2     | 2013-01-01 | 2013-12-31 |
    And the work package "issue1" has the following children:
      | issue2 |
    And the work package "pe1" has the following children:
      | pe2    |
    And I am already logged in as "bob"

  @javascript
  Scenario: View child work package of type issue
    When I go to the page of the work package "issue1"
     And I open the work package tab "Relations"
     And I click on "issue2" within ".work-packages--right-panel"
    Then I should see "issue2" within ".wp-edit-field.subject"
     And I should see "Bug #2" within ".work-packages--left-panel"
    When I open the work package tab "Relations"
    Then I should see "issue1" within ".work-packages--right-panel"

  @javascript
  Scenario: Log time leads to time entry creation page for issues
    When I go to the page of the work package "issue1"
    When I select "Log time" from the action menu
    Then I should see "Spent time"

  @javascript
  Scenario: For an issue move leads to work package copy page
    When I go to the page of the work package "issue1"
    # saveguard to ensure that the page is loaded
    Then I should see "Anonymous"
    When I select "Move" from the action menu
    Then I should see "Move"

  @javascript @selenium
  Scenario: For an issue deletion leads to the work package list
    When I go to the page of the work package "issue1"
    When I select "Delete" from the action menu
     And I confirm popups
    Then I should see "Work packages"
