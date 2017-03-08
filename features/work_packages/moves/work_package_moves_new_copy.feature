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

Feature: Copying a work package
  Background:
    Given there is 1 project with the following:
      | identifier | project_1 |
      | name       | project_1 |
    Given there is 1 project with the following:
      | identifier | project_2 |
      | name       | project_2 |
    And I am working in project "project_2"
    And there are the following issue status:
      | name        | is_closed  | is_default  |
      | New         | false      | true        |
    And the project "project_2" has the following types:
      | name    | position |
      | Bug     |     1    |
      | Feature |     2    |
    And there is a default issuepriority with:
      | name   | Normal |
    And there is a issuepriority with:
      | name   | High |
    And there is a issuepriority with:
      | name   | Immediate |
    And I am working in project "project_1"
    And there are the following issue status:
      | name        | is_closed  | is_default  |
      | New         | false      | true        |
    And the project "project_1" has the following types:
      | name    | position |
      | Bug     |     1    |
    And there is a default issuepriority with:
      | name   | Normal |
    And there is a issuepriority with:
      | name   | High |
    And there is a issuepriority with:
      | name   | Immediate |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages |
      | move_work_packages |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "member" in the project "project_1"
    And the user "bob" is a "member" in the project "project_2"
    And there are the following issues in project "project_1":
      | subject | type |
      | issue1  | Bug  |
      | issue2  | Bug  |
    And there are the following issues in project "project_2":
      | subject | type    |
      | issue3  | Feature |
    And the work package "issue1" has the following children:
      | issue2 |
    And I am already logged in as "bob"

  @javascript @selenium
  Scenario: Copy an issue
    When I go to the move new page of the work package "issue1"
     And I select "project_2" from "Project"
    When I click "Copy and follow"
    Then I should see "Successful creation."
    Then I should see "issue1" within ".wp-edit-field.subject"
     And I should see "project_2" within "#projects-menu"

  @javascript @selenium
  Scenario: Issue children are moved
    Given the "cross_project_work_package_relations" setting is set to true
    When I go to the move page of the work package "issue1"
     And I select "project_2" from "Project"
    When I click "Move and follow"
    #Then I should see "Successful update."
    Then I should see "issue1" within ".wp-edit-field.subject"
     And I should see "project_2" within "#projects-menu"


  Scenario: Move an issue to project with missing type
    When I go to the move page of the work package "issue3"
     And I select "project_1" from "Project"
    When I click "Move and follow"
    Then I should see "Failed to save 1 work package(s) on 1 selected:"
