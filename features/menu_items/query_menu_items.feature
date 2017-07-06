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

Feature: Query menu items
  Background:
    Given there is 1 project with the following:
      | name        | Awesome Project |
      | identifier  | awesome-project |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages |
      | save_queries       |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "member" in the project "Awesome Project"
    And the project "Awesome Project" has the following types:
      | name     | position |
      | Bug      |     1    |
      | Feature  |     2    |
    And there are the following issues in project "Awesome Project":
      | subject  | type     | description |
      | Bug1     | Bug      | "1"         |
      | Feature1 | Feature  | "2"         |
      | Feature2 | Feature  | "3"         |
    And the user "bob" has the following queries by type in the project "Awesome Project":
      | name     | type_value |
      | Bugs     | Bug        |
      | Features | Feature    |
    And I am already logged in as "bob"

  @javascript @selenium
  Scenario: Delete a query menu item
    Given the user "bob" has the following query menu items in the project "Awesome Project":
      | name       | title      | navigatable |
      | bugs_query | Bugs Query | Bugs        |
    When I go to the applied query "Bugs" on the work packages index page of the project "Awesome Project"
    And the work package table has finished loading
    And I click on "Settings"
    And I click on "Publish ..."
    And I uncheck "Show page in menu"
    And I click "Save"
    Then I should not see "Bugs Query" within "#main-menu"
