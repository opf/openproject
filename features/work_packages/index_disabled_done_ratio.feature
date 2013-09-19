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

Feature: Disabled done ratio on the work package index

  Background:
    Given there is 1 project with the following:
      | identifier | project1 |
      | name       | project1 |
    And the project "project1" has the following types:
      | name | position |
      | Bug  |     1    |
    And the project "project1" has 4 issues with the following:
      | subject    | Issuesubject |
    And I am already admin

  @javascript
  Scenario: Column should be available when done ratio is enabled
    When I go to the work packages index page of the project "project1"
    And I click "Options"
    Then I should see "% done" within "#available_columns"

  @javascript
  Scenario: Column should not be available when done ratio is disabled
    Given the "work_package_done_ratio" setting is set to disabled
    When I go to the work packages index page of the project "project1"
    And I click "Options"
    Then I should not see "% done" within "#available_columns"

  @javascript
  Scenario: Column is selected and done ratio is disabled afterwards
    When I go to the work packages index page of the project "project1"
    And I select to see columns
      | % done |
    Then I should see "% done" within ".list"
    Given the "work_package_done_ratio" setting is set to disabled
    When I go to the work packages index page of the project "project1"
    Then I should not see "% done" within ".list"
