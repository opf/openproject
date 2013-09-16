#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

Feature: Issue Sum Calculations for Currency
  Background:
    Given there are no custom fields
    Given there is 1 project with the following:
      | name       | project1 |
      | identifier | project1 |
    And the project "project1" has the following types:
      | name | position |
      | Bug  |     1    |
    And the following issue custom fields are defined:
      | name | type   |
      | cf1  | float  |
    And the custom field "cf1" is summable
    And the custom field "cf1" is activated for type "Bug"
    And there is a role "Manager"
    And there is 1 user with:
      | Login        | manager   |
    And the user "manager" is a "Manager" in the project "project1"
    And I am already admin

  @javascript
  Scenario: Should calculate an overall sum for a standard issue query
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 100        |
      | type | Bug        |
    And the user "manager" has 1 issue with the following:
      | subject | Some other issue |
      | cf1     | 50               |
      | type | Bug              |
    When I go to the work package index page for the project called "project1"
    And I select to see columns
      | cf1 |
    And I toggle the Options fieldset
    And I check "display_sums"
    And I click on "Apply"
    And I wait 10 seconds for AJAX
    Then I should see "150" in the overall sum

  @javascript
  Scenario: Should not calculate an overall sum for a standard issue query if the column isn't summable
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 100        |
      | type | Bug        |
    And the user "manager" has 1 issue with the following:
      | subject | Some other issue |
      | cf1     | 50               |
      | type | Bug              |
    And the custom field "cf1" is not summable
    When I go to the work package index page for the project called "project1"
    And I select to see columns
      | cf1 |
    And I toggle the Options fieldset
    And I check "display_sums"
    And I click on "Apply"
    And I wait 10 seconds for AJAX
    Then I should not see "150" in the overall sum

  @javascript
  Scenario: Should tick the checkbox on query edit if we previously displayed sums
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 100        |
      | type | Bug        |
    And the user "manager" has 1 issue with the following:
      | subject | Some other issue |
      | cf1     | 50               |
      | type | Bug              |
    When I go to the work package index page for the project called "project1"
    And I select to see columns
      | cf1 |
    And I toggle the Options fieldset
    And I check "display_sums"
    And I click on "Apply"
    And I click on "Save"
    And I fill in "TestQuery" for "query_name"
    And I press "Save"
    And I go to the work package index page for the project called "project1"
    And I click on "TestQuery"
    Then I should be on the work package index page for the project called "project1"
    And I toggle the Options fieldset
    Then the "display_sums" checkbox should be checked
    And I should see "150" in the overall sum
    And I click on "Edit"
    Then the "query[display_sums]" checkbox should be checked

  @javascript
  Scenario: Should not tick the checkbox on query edit if we did not previously display sums
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 100        |
      | type | Bug        |
    And the user "manager" has 1 issue with the following:
      | subject | Some other issue |
      | cf1     | 50               |
      | type | Bug              |
    When I go to the work package index page for the project called "project1"
    And I select to see columns
      | cf1 |
    And I toggle the Options fieldset
    And I uncheck "display_sums"
    And I click on "Apply"
    And I click on "Save"
    And I fill in "TestQuery" for "query_name"
    And I press "Save"
    And I go to the work package index page for the project called "project1"
    And I click on "TestQuery"
    Then I should be on the work package index page for the project called "project1"
    And I toggle the Options fieldset
    And the "display_sums" checkbox should not be checked
    And I click on "Edit"
    Then the "query[display_sums]" checkbox should not be checked

  @javascript
  Scenario: Should calculate an overall sum for a grouped issue query with multiple groups
    Given there is 1 user with:
      | Login   | alice   |
    And the user "alice" is a "Manager" in the project "project1"
    And there is 1 user with:
      | Login   | bob   |
    And the user "bob" is a "Manager" in the project "project1"
    And the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 100        |
      | type | Bug        |
    And the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 50         |
      | type | Bug        |
    And the user "alice" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 300        |
      | type | Bug        |
    And the user "bob" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 200        |
      | type | Bug        |
    And the user "bob" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 250        |
      | type | Bug        |
    When I go to the work package index page for the project called "project1"
    And I select to see columns
      | cf1 |
    And I toggle the Options fieldset
    And I check "display_sums"
    And I select "Assignee" from "group_by"
    And I click on "Apply"
    And I wait 10 seconds for AJAX
    Then I should see "150" in the grouped sum
    And I should see "300" in the grouped sum
    And I should see "450" in the grouped sum
    And I should see "900" in the overall sum

  @javascript
  Scenario: Should calculate an overall sum for a grouped issue query with a single group
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 100        |
      | type | Bug        |
    And the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | cf1     | 50         |
      | type | Bug        |
    When I go to the work package index page for the project called "project1"
    And I select to see columns
      | cf1 |
    And I toggle the Options fieldset
    And I check "display_sums"
    And I select "Assignee" from "group_by"
    And I click on "Apply"
    And I wait 10 seconds for AJAX
    Then I should see "150" in the grouped sum
    And I should see "150" in the overall sum

  @javascript
  Scenario: Should strip floats down to a precission of 2 number
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue  |
      | cf1     | 100.0000001 |
      | type | Bug         |
    And the user "manager" has 1 issue with the following:
      | subject | Some issue  |
      | cf1     | 50.09       |
      | type | Bug         |
    When I go to the work package index page for the project called "project1"
    And I select to see columns
      | cf1 |
    And I toggle the Options fieldset
    And I check "display_sums"
    And I select "Assignee" from "group_by"
    And I click on "Apply"
    And I wait 10 seconds for AJAX
    Then I should see "150.09" in the grouped sum
    And I should see "150.09" in the overall sum
