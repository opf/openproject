#-- copyright
# OpenProject Documents Plugin
#
# Former OpenProject Core functionality extracted into a plugin.
#
# Copyright (C) 2009-2014 the OpenProject Foundation (OPF)
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

Feature: Adding the document widget to personalisable pages

  Background:
    Given there is 1 project with the following:
      | name        | project1      |
    And I am already Admin

  @javascript
  Scenario: Adding a "Documents" widget to the my project page
    Given the plugin "openproject_my_project_page" is loaded
    And I am on the project "project1" overview personalization page
    And I should see "Add" within "#block-select"
    When I select "Documents" from "block-select"
    Then the "Documents" widget should be in the hidden block
    And "Documents" should be disabled in the my project page available widgets drop down

  @javascript
  Scenario: Adding a "Documents" widget to the my page
    Given I am on the My page personalization page
    # Safeguard to ensure the page is loaded
    And I should see "Reported work packages"
    When I select "Documents" from the available widgets drop down
    And I click on "Add"
    Then the "Documents" widget should be in the top block
    And "Documents" should be disabled in the my page available widgets drop down
