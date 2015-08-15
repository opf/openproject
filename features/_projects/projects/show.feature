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

Feature: Showing Projects
  Background:
    Given there is 1 project with the following:
      | identifier | omicronpersei8 |
      | name       | omicronpersei8 |
    And I am working in project "omicronpersei8"
    And project "omicronpersei8" uses the following modules:
      | calendar |
    And there is a role "CanViewCal"
    And the role "CanViewCal" may have the following rights:
      | view_calendar   |
      | view_work_packages |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "CanViewCal" in the project "omicronpersei8"
    And I am already logged in as "bob"

  Scenario: Calendar link in the 'tickets box' should work when calendar is activated
    When I go to the overview page of the project "omicronpersei8"
    Then I should see "Calendar" within "#content .issues.content-box"
    When I click on "Calendar" within "#content .issues.content-box"
    Then I should see "Calendar" within ".title-container h2"
    And I should see "Sunday" within "#content > table.cal"
