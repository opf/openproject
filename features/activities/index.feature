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

Feature: Activities

  Background:
    Given there is 1 project with the following:
      | Name | project1 |
    And the project "project1" has the following types:
      | name | position |
      | Bug  |     1    |
    And the project "project1" has 1 issue with the following:
      |  subject | issue1 |
    And there is 1 project with the following:
      | Name | project2 |
    And the project "project2" has the following types:
      | name | position |
      | Bug  |     1    |
    And the project "project2" does not use the following modules:
      | activity |
    And the project "project2" has 1 issue with the following:
      |  subject | issue2 |
    And I am already admin

Scenario: Hide activity from Projects with disabled activity module
    When I go to the overall activity page
    Then I should see "project1" within "#activity"
    And I should not see "project2" within "#activity"

Scenario: Hide wiki activity from Projects with disabled activity module
    Given the project "project1" has 1 wiki page with the following:
      | title | Project1Wiki |
    Given the project "project2" has 1 wiki page with the following:
      | title | Project2Wiki |
    When I go to the overall activity page
    And I check "Wiki edits" within "#menu-sidebar"
    And I press "Apply" within "#menu-sidebar"
    Then I should see "Project1Wiki" within "#activity"
    And I should not see "Project2Wiki" within "#activity"
