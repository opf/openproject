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

Feature: Work Package Query
  Background:
    And there is 1 project with the following:
      | name       | project |
      | identifier | project |
    And there is a default status with:
      | name | New |
    And I am working in project "project"
    And the project "project" has the following types:
      | name | position |
      | Bug  |     1    |

  @javascript @wip
  Scenario: Create a query and give it a name
    When I am already admin
     And I go to the work packages index page for the project "project"
     And I press "Filter"
     And I follow "Save" within "#query_form"
     And I fill in "Query" for "Name"
     And I press "Save"
    Then I should see "Query" within "#content"
     And I should see "Successful creation."

  @javascript @wip
  Scenario: Group on empty Value (Assignee)
    Given the project "project" has 1 issue with the following:
      | subject | issue1 |
     And I am already admin
     And I go to the work packages index page for the project "project"
     And I press "Filter"
     And I follow "Options" within "#query_form"
     And I select "Assignee" from "group_by"
     And I follow "Save"
     And I fill in "Query" for "Name"
     And I press "Save"
    Then I should see "Query" within "#content"
     And I should see "Successful creation."
     And I should see "None" within "#content"

  @wip
  Scenario: Save Button should be visible for users with the proper rights
    Given there is 1 user with the following:
      | login     | bob    |
      | firstname | Bob    |
      | lastname  | Bobbit |
    And there is a role "member_with_privileges"
    And the role "member_with_privileges" may have the following rights:
      | view_work_packages |
      | save_queries       |
    And the user "bob" is a "member_with_privileges" in the project "project"
    When I am already logged in as "bob"
     And I go to the work packages index page for the project "project"
    Then I should see "Save" within "#query_form"

  @wip
  Scenario: Save Button should be invisible for users without the proper rights
    Given there is 1 user with the following:
      | login     | alice  |
      | firstname | Alice  |
      | lastname  | Alison |
    And there is a role "member_without_privileges"
    And the role "member_without_privileges" may have the following rights:
      | view_work_packages |
    And the user "alice" is a "member_without_privileges" in the project "project"
    When I am already logged in as "alice"
     And I go to the work packages index page for the project "project"
    Then I should not see "Save" within "#query_form"
