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

Feature: Tracking Time

  Background:
    Given there is 1 project with the following:
      | name        | project1      |
      | identifier  | project1      |
    And I am working in project "parent"
    And the project "project1" has the following types:
      | name | position |
      | Bug  |     1    |
    And there is a role "member"
    And there is an activity "Development"
    And there is an activity "Design"
    And the role "member" may have the following rights:
      | add_work_packages  |
      | view_work_packages |
      | edit_work_packages |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "member" in the project "project1"
    And the user "bob" has 1 issue with the following:
      |  subject      | issue1             |
      |  due_date     | 2012-05-04         |
      |  start_date   | 2011-05-04         |
      |  description  | Aioli Sali Grande  |
    And there is a time entry for "issue1" with 4 hours
    And I am already admin
    And I am on the time entry page of issue "issue1"

  @javascript
  Scenario: Adding a time entry
    When I log 2 hours with the comment "test"
    Then I should see a time entry with 2 hours and comment "test"
    And I should see a total spent time of 6 hours

  @javascript @selenium
  Scenario: Editing a time entry
    When I update the first time entry with 4 hours and the comment "updated test"
    Then I should see a time entry with 4 hours and comment "updated test"
    And I should see a total spent time of 4 hours

  @javascript
  Scenario: Selecting time period
    When I go to the time entry page of issue "issue1"
     And I select "yesterday" from "period"
    Then I should not see a total spent time of 0 hours
    When I click "Apply"
    Then I should see a total spent time of 0 hours
