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

Feature: Parent wiki page

  Background:
    Given there is 1 project with the following:
      | Name | Test |
    And the project "Test" has 1 wiki page with the following:
      | Title | Test_page |
    Given the project "Test" has 1 wiki page with the following:
      | Title | Parent_page |
    And I am already admin

  @javascript
  Scenario: Changing parent page for wiki page
    When I go to the wiki page "Test page" for the project called "Test"
    And I click on "More functions"
    And I follow "Change parent page"
    When I select "Parent page" from "Parent page"
    And I press "Save"
    Then I should be on the wiki page "Test_page" for the project called "Test"
    And the breadcrumbs should have the element "Parent page"
    # no check removing the parent
    When I go to the wiki page "Test page" for the project called "Test"
    And I click on "More functions"
    And I follow "Change parent page"
    And I select "" from "Parent page"
    And I press "Save"
    Then I should be on the wiki page "Test_page" for the project called "Test"
    And the breadcrumbs should not have the element "Parent page"
