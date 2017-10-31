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

Feature: Navigating to reports page
  Background:
    Given there is 1 project with the following:
      | name | ParentProject |
      | identifier | parent_project_1 |
    And the project "ParentProject" has 1 subproject with the following:
      | name | SubProject |
      | identifier | parent_project_1_sub_1 |

@javascript @selenium
  Scenario: Archiving and unarchiving a project with a subproject
    Given I am already admin
    When I go to the projects page
    Then I should be on the projects page
    And I should see "Projects"
    And I hover over "tbody > tr:nth-of-type(1)"
    And I click on "More" within "tbody > tr:nth-of-type(1)"
    And I click on "Archive" within ".dropdown-menu"
    And I confirm popups
    Then I should be on the projects page
    And I should not see "ParentProject"
    And I should not see "SubProject"
    When I go to the page of the project called "ParentProject"
    Then I should see "403"
    When I go to the page of the project called "SubProject"
    Then I should see "403"
    When I go to the projects page
    And I click on "projects-filter-toggle-button"
    When I select "all" from "operator"
    And I click on "Filter"
    And I hover over "tbody > tr:nth-of-type(1)"
    And I click on "More" within "tbody > tr:nth-of-type(1)"
    And I click on "Unarchive" within ".dropdown-menu"
    Then I should be on the projects page
    And I should see "ParentProject"
    When I go to the page of the project called "ParentProject"
    Then I should see "ParentProject"
