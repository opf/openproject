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

Feature: Relating issues to each other
  Background:
    Given there is 1 user with the following:
      | login | bob |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages |
    And there is 1 project with the following:
      | name       | project1 |
      | identifier | project1 |
    And the project "project1" has the following types:
      | name | position |
      | Bug  | 1        |
    And the user "bob" is a "member" in the project "project1"
    And the user "bob" has 1 issue with the following:
      | subject | Some Issue |
      | type    | Bug        |
    And the user "bob" has 1 issue with the following:
      | subject | Another Issue |
      | type    | Bug           |
    And I am already admin

  @javascript @wip
  Scenario: Adding a relation will add it to the list of related issues through AJAX instantly
    When I go to the page of the issue "Some Issue"
    And I open the work package tab "Relations"
    And I click on "Add related work package"
    And I fill in "relation_to_id" with "2"
    And I press "Add"
    And I wait for the AJAX requests to finish
    Then I should be on the page of the issue "Some Issue"
    And I should see "related to Bug #2: Another Issue"

  @javascript @wip
  Scenario: Adding a relation to an issue with special chars in subject should not end in broken html
    Given the user "bob" has 1 issue with the following:
      | subject | Anothe'r & Issue |
      | type    | Bug              |
    When I go to the page of the issue "Some Issue"
    And I click on "Add related work package"
    And I fill in "relation_to_id" with "3"
    And I press "Add"
    And I wait for the AJAX requests to finish
    Then I should be on the page of the issue "Some Issue"
    And I should see "related to Bug #3: Anothe'r & Issue"
