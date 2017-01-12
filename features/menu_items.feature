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

Feature: Menu items
  Background:
    Given there is 1 project with the following:
      | name            | Awesome Project      |
      | identifier      | awesome-project      |
    And project "Awesome Project" uses the following modules:
      | calendar |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_calendar  |
      | view_work_packages  |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "member" in the project "Awesome Project"
    And I am already logged in as "bob"

  Scenario: Calendar menu should be visible when calendar is activated
    When I go to the overview page of the project "Awesome Project"
    Then I should see "Calendar" within "#main-menu"

  Scenario: Work Packages Summary should be visible and accessible
    When I go to the overview page of the project "Awesome Project"
    And I toggle the "Work packages" submenu
    Then I should see "Summary" within "#main-menu"

    When I click on "Summary" within "#main-menu"
    Then I should see "SUMMARY" within "#content"
